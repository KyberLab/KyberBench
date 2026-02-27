package main

import (
	"bytes"
	"crypto/md5"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"

	"github.com/alessio/shellescape"
	"github.com/dustin/go-humanize"
	"github.com/spf13/cobra"
)

var (
	aptCmd = &cobra.Command{
		Use:   "apt {pin|install}",
		Short: "Pinning and installing apt packages",
	}

	aptPinCmd = &cobra.Command{
		Use:          "pin",
		Short:        "Pin which versions to install (but don't install them)",
		Args:         cobra.NoArgs,
		SilenceUsage: true,
		RunE:         runAptPin,
	}

	aptInstallCmd = &cobra.Command{
		Use:          "install",
		Short:        "Install the pinned versions",
		Args:         cobra.NoArgs,
		SilenceUsage: true,
		RunE:         runAptInstall,
	}

	aptPinFile          *string
	aptRequirementsFile *string
	baseImage           *string
)

func init() {
	aptPinFile = aptCmd.PersistentFlags().StringP("pin-file", "p", "dockpin-apt.lock", "File with pinned package versions")
	aptCmd.MarkPersistentFlagFilename("pin-file", "lock")
	aptRequirementsFile = aptPinCmd.Flags().StringP("selection-file", "s", "dockpin-apt.pkgs", "File with packages to be installed")
	aptPinCmd.MarkPersistentFlagFilename("selection-file", "pkgs")
	baseImage = aptPinCmd.Flags().String("base-image", "", "Docker image you're going to use dockpin in, so we can figure out your additional dependencies.")
	aptPinCmd.Flags().BoolP("sudo", "S", false, "Use sudo when executing commands")
}

func runAptPin(cmd *cobra.Command, args []string) error {
	b, err := ioutil.ReadFile(*aptRequirementsFile)
	if err != nil {
		return fmt.Errorf("failed to read selection file %q: %v", *aptRequirementsFile, err)
	}

	if *baseImage == "" {
		b, err := ioutil.ReadFile(ifDash(*dockerfile, "/dev/stdin"))
		if err != nil {
			return fmt.Errorf("failed to read %q (needed to determine your base image): %v", *dockerfile, err)
		}
		*baseImage = getLastBaseImage(b)
		if *baseImage == "" {
			return errors.New("no images found in your Dockerfile")
		}
		fmt.Fprintf(os.Stderr, "\033[34mBased on your Dockerfile, it looks like you'll use dockpin in an image based on %s. Pass --base-image if that's incorrect.\033[0m\n", *baseImage)
	}

	// Let me know if you know a nice way that doesn't depend on composing a shell script.

	// Check if sudo flag is set
	useSudo, _ := cmd.Flags().GetBool("sudo")
	sudoPrefix := ""
	if useSudo {
		sudoPrefix = "sudo "
	}

	shcmd := sudoPrefix + "apt-get update >&2 && echo Determining dependencies... >&2 && " + sudoPrefix + "apt-get install --print-uris -qq"
	for _, p := range strings.Split(string(b), "\n") {
		shcmd += " " + shellescape.Quote(p)
	}
	var buf bytes.Buffer
	buf.WriteString("# dockpin apt lock file v1\n")
	buf.WriteString("base-image=" + *baseImage + "\n")
	buf.WriteString("\n")
	c := exec.Command("docker", "run", "--rm", *baseImage, "bash", "-c", shcmd)
	c.Stdout = &buf
	c.Stderr = os.Stderr
	if err := c.Run(); err != nil {
		return err
	}
	b = buf.Bytes()
	if _, err := parseAptURIsList(b); err != nil {
		return fmt.Errorf("bug: lock file generated from docker container is invalid: %v", err)
	}
	return ioutil.WriteFile(*aptPinFile, buf.Bytes(), 0644)
}

func runAptInstall(cmd *cobra.Command, args []string) error {
	b, err := ioutil.ReadFile(*aptPinFile)
	if err != nil {
		return fmt.Errorf("failed to read pin file %q: %v", *aptPinFile, err)
	}
	pkgs, err := parseAptURIsList(b)
	if err != nil {
		return fmt.Errorf("failed to parse pin file: %v", err)
	}

	if len(pkgs) == 0 {
		fmt.Fprintf(os.Stderr, "\033[34mNo packages in the lock file, nothing to be done\033[0m\n")
		return nil
	}

	// Track installation path to detect circular dependencies
	installing := make(map[string]bool)
	for _, p := range pkgs {
		if err := aptInstallHelper(p, pkgs, installing); err != nil {
			return err
		}
	}

	return nil
}

func aptInstallHelper(p AptPackage, pkgs []AptPackage, installing map[string]bool) error {
	// Check for circular dependency
	if installing[p.Filename] {
		fmt.Fprintf(os.Stderr, "\033[33mWarning: Circular dependency detected for %s\033[0m\n", p.Filename)
		// For circular dependencies, just install the package without checking dependencies
		// to break the cycle
		return installPackageOnly(p)
	}

	// Mark this package as being installed
	installing[p.Filename] = true
	defer func() {
		delete(installing, p.Filename)
	}()

	// Download package first
	f, err := fetchPackage(p)
	if err != nil {
		return err
	}
	defer os.Remove(f)

	// Check dependencies using the downloaded package
	depends, err := getPackageDependencies(f)
	if err != nil {
		return fmt.Errorf("failed to get dependencies for %s: %v", p.Filename, err)
	}

	// Print package name and its dependencies in green
	fmt.Fprintf(os.Stderr, "\033[32m%s - Dependencies: %v\033[0m\n", p.Filename, depends)

	// Install missing dependencies recursively
	/*for _, dep := range depends {
		if !isPackageInstalled(dep) {
			// Find the dependency package in pkgs
			if depPkg, found := findPackageByName(pkgs, dep); found {
				fmt.Fprintf(os.Stderr, "\033[36mInstalling dependency %s for %s...\033[0m\n", dep, p.Filename)
				if err := aptInstallHelper(depPkg, pkgs, installing); err != nil {
					return fmt.Errorf("failed to install dependency %s: %v", dep, err)
				}
			} else {
				fmt.Fprintf(os.Stderr, "\033[31mWarning: Dependency %s not found in package list, skipping...\033[0m\n", dep)
			}
		}
	}*/

	dpkgArgs := []string{"-i", "--force-depends", f}
	c := exec.Command("dpkg", dpkgArgs...)
	c.Stdout = os.Stdout
	c.Stderr = os.Stderr
	// Set DEBIAN_FRONTEND=noninteractive to avoid interactive prompts
	c.Env = append(os.Environ(), "DEBIAN_FRONTEND=noninteractive")
	if err := c.Run(); err != nil {
		return err
	}

	// Configure all unconfigured packages after successful installation
	/*configureCmd := exec.Command("dpkg", "--configure", "-a")
	configureCmd.Stdout = os.Stdout
	configureCmd.Stderr = os.Stderr
	configureCmd.Env = append(os.Environ(), "DEBIAN_FRONTEND=noninteractive")
	if err := configureCmd.Run(); err != nil {
		return err
	}*/

	return nil
}

// installPackageOnly installs a package without checking dependencies
// Used for breaking circular dependencies
func installPackageOnly(p AptPackage) error {
	// Download package first
	f, err := fetchPackage(p)
	if err != nil {
		return err
	}
	defer os.Remove(f)

	fmt.Fprintf(os.Stderr, "\033[35mInstalling package %s (circular dependency)...\033[0m\n", p.Filename)

	dpkgArgs := []string{"-i", "--force-depends", f}
	c := exec.Command("dpkg", dpkgArgs...)
	c.Stdout = os.Stdout
	c.Stderr = os.Stderr
	// Set DEBIAN_FRONTEND=noninteractive to avoid interactive prompts
	c.Env = append(os.Environ(), "DEBIAN_FRONTEND=noninteractive")
	if err := c.Run(); err != nil {
		return err
	}

	// Configure all unconfigured packages after successful installation
	/*configureCmd := exec.Command("dpkg", "--configure", "-a")
	configureCmd.Stdout = os.Stdout
	configureCmd.Stderr = os.Stderr
	configureCmd.Env = append(os.Environ(), "DEBIAN_FRONTEND=noninteractive")
	if err := configureCmd.Run(); err != nil {
		return err
	}*/

	return nil
}

// getPackageDependencies extracts dependencies from a deb package using dpkg -I
func getPackageDependencies(packagePath string) ([]string, error) {
	cmd := exec.Command("dpkg", "-I", packagePath)
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return nil, err
	}

	// Parse dependencies from output
	var dependencies []string
	for _, line := range strings.Split(out.String(), "\n") {
		if strings.HasPrefix(line, " Depends:") {
			// Extract dependencies from the line
			depLine := strings.TrimPrefix(line, " Depends:")
			// Split dependencies and remove version constraints
			for _, dep := range strings.Split(depLine, ",") {
				dep = strings.TrimSpace(dep)
				// Extract package name before version constraint
				if idx := strings.IndexAny(dep, " ("); idx != -1 {
					dep = dep[:idx]
				}
				if dep != "" {
					dependencies = append(dependencies, dep)
				}
			}
			break
		}
	}

	return dependencies, nil
}

// isPackageInstalled checks if a package is installed using dpkg -s
func isPackageInstalled(packageName string) bool {
	cmd := exec.Command("dpkg", "-s", packageName)
	var out bytes.Buffer
	cmd.Stdout = &out
	// Redirect stderr to /dev/null to avoid error messages
	cmd.Stderr = nil
	if err := cmd.Run(); err != nil {
		return false
	}
	// Check if the output contains "Status: install ok installed"
	output := out.String()
	return strings.Contains(output, "Status: install ok installed")
}

// findPackageByName finds a package in the list by its name
func findPackageByName(pkgs []AptPackage, name string) (AptPackage, bool) {
	for _, pkg := range pkgs {
		// Check if filename starts with name + "_" or name + "-"
		if strings.HasPrefix(pkg.Filename, name+"_") || strings.HasPrefix(pkg.Filename, name+"-") {
			return pkg, true
		}
	}
	return AptPackage{}, false
}

func fetchPackage(p AptPackage) (string, error) {
	target := filepath.Join("/var/cache/apt/archives", p.Filename)
	if _, err := os.Stat(target); err == nil { // Return immediately if the file exists.
		return target, nil
	}
	fh, err := os.OpenFile(filepath.Join("/var/cache/apt/archives/partial", p.Filename), os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0644)
	if err != nil {
		return "", err
	}
	fmt.Fprintf(os.Stderr, "\033[36mDownloading %s... (%s)\033[0m\n", p.URL, humanize.IBytes(uint64(p.Size)))
	req, err := http.NewRequest("GET", p.URL, nil)
	if err != nil {
		return "", fmt.Errorf("failed to download %q: %v", p.URL, err)
	}
	req.Header.Set("User-Agent", "Dockpin "+rootCmd.Version+" (https://github.com/Jille/dockpin)")
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to download %q: %v", p.URL, err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != 200 {
		return "", fmt.Errorf("failed to download %q: HTTP %s", p.URL, resp.Status)
	}
	h := md5.New()
	n, err := io.Copy(io.MultiWriter(fh, h), resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to download %q: %v", p.URL, err)
	}
	if n != p.Size {
		return "", fmt.Errorf("size mismatch for %q: %d instead of %d", p.URL, n, p.Size)
	}
	sum := hex.EncodeToString(h.Sum(nil))
	if sum != p.MD5 {
		return "", fmt.Errorf("hash mismatch for %q: %q instead of %q", p.URL, sum, p.MD5)
	}
	if err := fh.Close(); err != nil {
		return "", err
	}
	if err := os.Rename(fh.Name(), target); err != nil {
		return "", err
	}
	return target, nil
}

type AptPackage struct {
	URL      string
	Filename string
	Size     int64
	MD5      string
}

var aptUriRe = regexp.MustCompile(`^'([^']+)' (\S+) (\d+) MD5Sum:([0-9a-f]{32})`)

func parseAptURIsList(b []byte) ([]AptPackage, error) {
	var ret []AptPackage
	for _, l := range bytes.Split(b, []byte{'\n'}) {
		s := string(l)
		if strings.HasPrefix(s, "#") || s == "" {
			continue
		}
		if strings.HasPrefix(s, "base-image=") {
			// TODO: Use this
			continue
		}
		m := aptUriRe.FindStringSubmatch(s)
		if m == nil {
			return nil, fmt.Errorf("failed to parse line %q", s)
		}
		p := AptPackage{
			URL:      m[1],
			Filename: m[2],
			MD5:      m[4],
		}
		p.Size, _ = strconv.ParseInt(m[3], 10, 64)
		ret = append(ret, p)
	}
	return ret, nil
}

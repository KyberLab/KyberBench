#
#                                 KyberBench
# Copyright (c) 2025-2026, Kyber Development Team, all right reserved.
#

# Docker Build Notes
# BENCH_BUILDKIT=1 docker build --ssh default --progress=plain . -t bench:md

# Add ssh-agent for zsh.
# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/ssh-agent
# vi ~/.zshrc
# plugins=(... ssh-agent)
# zstyle :omz:plugins:ssh-agent agent-forwarding yes





###############################################################################
# Default Macros


# file_is_exist
# $(1) file path
# return empty if exist.
ifeq ($(origin file_is_exist),undefined)
define file_is_exist
$(shell ls $(1) > /dev/null 2>&1;echo $$? | grep -v 0)
endef
endif


# rule_inc
# $(1) rule file path
ifeq ($(origin rule_inc),undefined)
define rule_inc
$(if $(call file_is_exist,$(1)),$(error Rule File "$(1)" Not Exist !!!),include $(1))
endef
endif


# is_in_docker
# return : empty if in docker
ifeq ($(origin is_in_docker),undefined)
define is_in_docker
$(shell echo `[ ! -f /.dockerenv ]` $$? | grep -v 1)
endef
endif


# cur_dir
# return : current directory path
ifeq ($(origin cur_dir),undefined)
define cur_dir
$(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
endef
endif



###############################################################################
# Path Check

ifeq ($(origin BENCH_ROOT_PATH),undefined)
#$(warning "BENCH_ROOT_PATH has not been defined.")
BENCH_ROOT_PATH				:= $(call cur_dir)
#$(warning Define BENCH_ROOT_PATH = $(BENCH_ROOT_PATH))
endif


ifneq ($(call file_is_exist,$(BENCH_ROOT_PATH)/Main.mk),)
$(error "Main.mk not exist !!!")
endif



###############################################################################
# Bench Targets

.PHONY	: all help

help : bench_help

all	: build_base



###############################################################################
# Bench Rules

$(eval $(call rule_inc,$(BENCH_ROOT_PATH)/Main.mk))


###############################################################################
# Multi-Architecture Build Convenience Targets

# Multi-Arch Setup and Build
.PHONY : multiarch-enable multiarch-disable

multiarch-enable :
	$(Q)$(call xprint_title,"Enable Multi-Arch Build",$(BENCH_TITLE_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)make multiarch-setup
	$(Q)make multiarch-create
	$(Q)$(call xprint_filled,$(BENCH_COLOR))


multiarch-disable :
	$(Q)$(call xprint_title,"Disable Multi-Arch Build",$(BENCH_TITLE_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)make multiarch-default
	$(Q)$(call xprint_filled,$(BENCH_COLOR))


# Build with specific platforms
# Usage: make multiarch-build PLATFORMS=linux/amd64,linux/arm64
.PHONY : multiarch-build-platforms

multiarch-build-platforms :
	$(Q)$(call xprint_title,"Build Multi-Arch Images",$(BENCH_TITLE_COLOR))
	$(Q)$(call xprint_info,"Platforms: $(or $(PLATFORMS),$(BENCH_MULTIARCH_PLATFORMS))",$(BENCH_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)make multiarch-build BENCH_MULTIARCH_PLATFORMS=$(or $(PLATFORMS),$(BENCH_MULTIARCH_PLATFORMS))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))


# Push with specific platforms
# Usage: make multiarch-push-platforms PLATFORMS=linux/amd64,linux/arm64
.PHONY : multiarch-push-platforms

multiarch-push-platforms :
	$(Q)$(call xprint_title,"Build and Push Multi-Arch Images",$(BENCH_TITLE_COLOR))
	$(Q)$(call xprint_info,"Platforms: $(or $(PLATFORMS),$(BENCH_MULTIARCH_PLATFORMS))",$(BENCH_COLOR))
	$(Q)$(call xprint_info,"Registry: $(BENCH_REPO_BASE)",$(BENCH_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)make multiarch-push BENCH_MULTIARCH_PLATFORMS=$(or $(PLATFORMS),$(BENCH_MULTIARCH_PLATFORMS))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))


# Build specific image for multiple platforms
# Usage: make multiarch-build-image IMAGE=develop
.PHONY : multiarch-build-image

multiarch-build-image :
	$(Q)$(call xprint_title,"Build Multi-Arch Image: $(or $(IMAGE),$(firstword $(BENCH_IMAGE_TAG)))",$(BENCH_TITLE_COLOR))
	$(Q)$(call xprint_info,"Platforms: $(BENCH_MULTIARCH_PLATFORMS)",$(BENCH_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)make multiarch_build_$(or $(IMAGE),$(firstword $(BENCH_IMAGE_TAG)))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))


# Push specific image for multiple platforms
# Usage: make multiarch-push-image IMAGE=develop
.PHONY : multiarch-push-image

multiarch-push-image :
	$(Q)$(call xprint_title,"Build and Push Multi-Arch Image: $(or $(IMAGE),$(firstword $(BENCH_IMAGE_TAG)))",$(BENCH_TITLE_COLOR))
	$(Q)$(call xprint_info,"Platforms: $(BENCH_MULTIARCH_PLATFORMS)",$(BENCH_COLOR))
	$(Q)$(call xprint_info,"Registry: $(BENCH_REPO_BASE)",$(BENCH_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)make multiarch_push_$(or $(IMAGE),$(firstword $(BENCH_IMAGE_TAG)))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))


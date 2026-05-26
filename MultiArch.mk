#                                 KyberBench
# Copyright (c) 2025-2026, Kyber Development Team, all right reserved.
#
# Multi-Architecture Image Build Support
# Reference: https://mp.weixin.qq.com/s/eHpGyeXpvUL2g54iHf9VUQ
# Reference: https://docs.docker.com/build/building/multi-platform/



###############################################################################
# Multi-Architecture Configuration

BENCH_MULTIARCH_ENABLE		?= 0
BENCH_MULTIARCH_BUILDER		?= multiarch-builder
BENCH_MULTIARCH_PLATFORMS	?= linux/amd64,linux/arm64

BENCH_MULTIARCH_TARGETS		:= $(patsubst %,multiarch_%,$(BENCH_IMAGE_TAG))
BENCH_MULTIARCH_PUSH_TARGETS	:= $(patsubst %,multiarch_push_%,$(BENCH_IMAGE_TAG))
BENCH_MULTIARCH_INSPECT_TARGETS	:= $(patsubst %,multiarch_inspect_%,$(BENCH_IMAGE_TAG))

.PHONY : $(BENCH_MULTIARCH_TARGETS) $(BENCH_MULTIARCH_PUSH_TARGETS) $(BENCH_MULTIARCH_INSPECT_TARGETS)
.PHONY : multiarch-setup multiarch-info multiarch-create multiarch-inspect



###############################################################################
# Multi-Architecture Setup

multiarch-setup :
	$(Q)$(call xprint_title,"Multi-Arch Setup",$(BENCH_TITLE_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)$(call xprint_info,"Installing QEMU binfmt support...",$(BENCH_COLOR))
	$(Q)docker run --privileged --rm tonistiigi/binfmt --install all
	$(Q)$(call xprint_filled,$(BENCH_COLOR))


multiarch-info :
	$(Q)$(call xprint_title,"Multi-Arch Builder Info",$(BENCH_TITLE_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)docker buildx version
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)docker buildx ls
	$(Q)$(call xprint_filled,$(BENCH_COLOR))



###############################################################################
# Multi-Architecture Builder Management

multiarch-create :
	$(Q)$(call xprint_title,"Create Multi-Arch Builder: $(BENCH_MULTIARCH_BUILDER)",$(BENCH_TITLE_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)docker buildx create --name $(BENCH_MULTIARCH_BUILDER) --driver docker-container --bootstrap --use 2>/dev/null || \
		(docker buildx create --name $(BENCH_MULTIARCH_BUILDER) --driver docker-container && \
		docker buildx use $(BENCH_MULTIARCH_BUILDER) && \
		docker buildx inspect --bootstrap)
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)$(call xprint_info,"Builder '$(BENCH_MULTIARCH_BUILDER)' is ready",$(BENCH_COLOR))


multiarch-remove :
	$(Q)$(call xprint_title,"Remove Multi-Arch Builder: $(BENCH_MULTIARCH_BUILDER)",$(BENCH_TITLE_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)docker buildx rm $(BENCH_MULTIARCH_BUILDER) 2>/dev/null || $(call xprint_info,"Builder not found or already removed",$(BENCH_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))


multiarch-use :
	$(Q)$(call xprint_title,"Switch to Multi-Arch Builder: $(BENCH_MULTIARCH_BUILDER)",$(BENCH_TITLE_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)docker buildx use $(BENCH_MULTIARCH_BUILDER)
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)$(call xprint_info,"Now using builder: $(BENCH_MULTIARCH_BUILDER)",$(BENCH_COLOR))


multiarch-default :
	$(Q)$(call xprint_title,"Switch to Default Builder",$(BENCH_TITLE_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)docker buildx use default
	$(Q)$(call xprint_filled,$(BENCH_COLOR))



###############################################################################
# Multi-Architecture Build Command

# bench_multiarch_build_cmd
# $(1) docker tag
define bench_multiarch_build_cmd
docker buildx build $(BENCH_CMD_ARGS) \
		--progress=plain \
		--ssh default \
		--platform $(BENCH_MULTIARCH_PLATFORMS) \
		$(BENCH_BUILD_OPTS) \
		$(foreach arg,$(DOCKER_FILE_ARGS),--build-arg $(arg) ) \
		--secret id=$(BENCH_AUTH_ID),src=$(BENCH_ROOT_PATH)/$(BENCH_AUTH_FILE) \
		--tag $(BENCH_NAME):$(1) \
		--file $(DOCKER_FILE_ROOT)/$(1)/Dockerfile \
		.
endef


# bench_multiarch_build_helper
# $(1) docker tag
define bench_multiarch_build_helper
	$(Q)$(call xprint_title,"Build Multi-Arch \"$(BENCH_NAME):$(1)\" Image",$(BENCH_TITLE_COLOR))
	$(Q)$(call xprint_info,"Platforms: $(BENCH_MULTIARCH_PLATFORMS)",$(BENCH_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)docker buildx use $(BENCH_MULTIARCH_BUILDER)
	$(Q)$(call bench_multiarch_build_cmd,$(1))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
endef


$(BENCH_MULTIARCH_TARGETS) : multiarch_% : bench_%
	$(Q)$(if $(call bench_image_id,$(subst multiarch_,,$@)),,$(call bench_multiarch_build_helper,$(subst multiarch_,,$@)))



###############################################################################
# Multi-Architecture Push Command

# bench_multiarch_push_helper
# $(1) docker tag
define bench_multiarch_push_helper
	$(Q)$(call xprint_title,"Push Multi-Arch \"$(BENCH_NAME):$(1)\" Image",$(BENCH_TITLE_COLOR))
	$(Q)$(call xprint_info,"Platforms: $(BENCH_MULTIARCH_PLATFORMS)",$(BENCH_COLOR))
	$(Q)$(call xprint_info,"Registry: $(BENCH_REPO_BASE)",$(BENCH_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)docker buildx use $(BENCH_MULTIARCH_BUILDER)
	docker buildx build $(BENCH_CMD_ARGS) \
		--progress=plain \
		--ssh default \
		--platform $(BENCH_MULTIARCH_PLATFORMS) \
		$(BENCH_BUILD_OPTS) \
		$(foreach arg,$(DOCKER_FILE_ARGS),--build-arg $(arg) ) \
		--secret id=$(BENCH_AUTH_ID),src=$(BENCH_ROOT_PATH)/$(BENCH_AUTH_FILE) \
		--tag $(BENCH_REPO_BASE)/$(BENCH_NAME):$(1) \
		--push \
		--file $(DOCKER_FILE_ROOT)/$(1)/Dockerfile \
		.
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
endef


$(BENCH_MULTIARCH_PUSH_TARGETS) : multiarch_push_% : bench_%
	$(Q)$(call bench_multiarch_push_helper,$(subst multiarch_push_,,$@))



###############################################################################
# Multi-Architecture Inspect Command

# bench_multiarch_inspect_helper
# $(1) docker tag
define bench_multiarch_inspect_helper
	$(Q)$(call xprint_title,"Inspect Multi-Arch \"$(BENCH_NAME):$(1)\" Manifest",$(BENCH_TITLE_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)docker buildx imagetools inspect $(BENCH_NAME):$(1)
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
endef


$(BENCH_MULTIARCH_INSPECT_TARGETS) : multiarch_inspect_% :
	$(Q)$(call bench_multiarch_inspect_helper,$(subst multiarch_inspect_,,$@))



###############################################################################
# Multi-Architecture Build and Push All

multiarch-build :
	$(Q)$(call xprint_title,"Build All Multi-Arch Images",$(BENCH_TITLE_COLOR))
	$(Q)$(call xprint_info,"Platforms: $(BENCH_MULTIARCH_PLATFORMS)",$(BENCH_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)docker buildx use $(BENCH_MULTIARCH_BUILDER)
	$(foreach tag,$(BENCH_IMAGE_TAG),$(call bench_multiarch_build_helper,$(tag)))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))


multiarch-push :
	$(Q)$(call xprint_title,"Build and Push All Multi-Arch Images",$(BENCH_TITLE_COLOR))
	$(Q)$(call xprint_info,"Platforms: $(BENCH_MULTIARCH_PLATFORMS)",$(BENCH_COLOR))
	$(Q)$(call xprint_info,"Registry: $(BENCH_REPO_BASE)",$(BENCH_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)docker buildx use $(BENCH_MULTIARCH_BUILDER)
	$(foreach tag,$(BENCH_IMAGE_TAG),docker buildx build $(BENCH_CMD_ARGS) \
		--progress=plain \
		--ssh default \
		--platform $(BENCH_MULTIARCH_PLATFORMS) \
		$(BENCH_BUILD_OPTS) \
		$(foreach arg,$(DOCKER_FILE_ARGS),--build-arg $(arg) ) \
		--secret id=$(BENCH_AUTH_ID),src=$(BENCH_ROOT_PATH)/$(BENCH_AUTH_FILE) \
		--tag $(BENCH_REPO_BASE)/$(BENCH_NAME):$(tag) \
		--push \
		--file $(DOCKER_FILE_ROOT)/$(tag)/Dockerfile \
		. && )
	$(Q)$(call xprint_filled,$(BENCH_COLOR))


###############################################################################
# Convenience Targets

.PHONY : multiarch-all multiarch-all-push multiarch-all-inspect

multiarch-all : multiarch-build
	$(Q)$(call xprint_title,"Multi-Arch Build Complete",$(BENCH_TITLE_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(foreach tag,$(BENCH_IMAGE_TAG),$(call bench_multiarch_inspect_helper,$(tag)))

multiarch-all-push : multiarch-push
	$(Q)$(call xprint_title,"Multi-Arch Push Complete",$(BENCH_TITLE_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)$(call xprint_info,"Images pushed to: $(BENCH_REPO_BASE)",$(BENCH_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))


###############################################################################
# CI/CD Support

.PHONY : multiarch-ci

multiarch-ci :
	$(Q)$(call xprint_title,"Multi-Arch CI Build",$(BENCH_TITLE_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)docker buildx use $(BENCH_MULTIARCH_BUILDER)
	docker buildx build $(BENCH_CMD_ARGS) \
		--progress=plain \
		--ssh default \
		--platform $(BENCH_MULTIARCH_PLATFORMS) \
		$(BENCH_BUILD_OPTS) \
		$(foreach arg,$(DOCKER_FILE_ARGS),--build-arg $(arg) ) \
		--secret id=$(BENCH_AUTH_ID),src=$(BENCH_ROOT_PATH)/$(BENCH_AUTH_FILE) \
		--tag $(BENCH_REPO_BASE)/$(BENCH_NAME):$(shell git describe --tags --always) \
		--tag $(BENCH_REPO_BASE)/$(BENCH_NAME):latest \
		--push \
		--cache-from type=gha \
		--cache-to type=gha,mode=max \
		--file $(DOCKER_FILE_ROOT)/$(firstword $(BENCH_IMAGE_TAG))/Dockerfile \
		.
	$(Q)$(call xprint_filled,$(BENCH_COLOR))

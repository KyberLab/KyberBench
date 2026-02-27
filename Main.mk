#                                 KyberBench
# Copyright (c) 2025-2026, Kyber Development Team, all right reserved.
#




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

bench_help : 
	$(Q)$(call xprint_title,"KyberBench Help",$(HB_GREEN))
	$(Q)$(call xprint_value,"Targets",	"\n"$(BENCH_TAG),$(HB_GREEN))
	$(Q)$(call xprint_filled,$(HB_GREEN))



###############################################################################
# Basic Rules

$(eval $(call rule_inc,$(BENCH_ROOT_PATH)/rules/Main.mk))

ifeq ($(call file_is_exist,$(WORKSPACE_ROOT_PATH)/WorkSpace.mk),)
$(eval $(call rule_inc,$(WORKSPACE_ROOT_PATH)/WorkSpace.mk))
endif

# Version Init
BENCH_VERSION_FULL			:= $(call git_version_full,$(BENCH_ROOT_PATH))
BENCH_VERSION_MAIN			:= $(call git_version_main,$(BENCH_VERSION_FULL))

BENCH_VERSION				:= $(call git_version,$(BENCH_VERSION_MAIN))
BENCH_SUBVERSION			:= $(call git_subversion,$(BENCH_VERSION_MAIN))
BENCH_REVISION				:= $(call git_revision,$(BENCH_VERSION_MAIN))

BENCH_SCMVERSION			:= $(call git_scmversion,$(BENCH_VERSION_FULL))



###############################################################################
# Default Config

# User Config
USER_HOST_WS				?= $(PWD)
USER_GUEST_WS				?= /ws
USER_MAP_WS					?= "$(USER_HOST_WS):$(USER_GUEST_WS)"
USER_RUN_CMD				?= bash


# Basic Config
BENCH_NAME					?= bench
BENCH_GROUP					?= $(BENCH_NAME)
BENCH_USER					?= $(BENCH_NAME)
BENCH_GID					?= $(shell id -g)
BENCH_UID					?= $(shell id -u)


# Repository Config
REPO_URL_IP					?= 127.0.0.1

REPO_URL_PROTO				?= ssh
REPO_URL_BASE				?= www.kyber.com
REPO_URL_PORT				?= 22
REPO_URL_GROUP				?= kyberbench
BENCH_REPO_BASE				?= $(REPO_URL_BASE)/docker

BENCH_USE_DNSMAP			?= 1


# Image Build Config
BENCH_IMG_DISTRO			?= ubuntu
BENCH_IMG_VERSION			?= 22.04

BENCH_IMG_FROM				?= local

BENCH_IMG_GROUP				?= $(BENCH_GROUP)
BENCH_IMG_USER				?= $(BENCH_USER)
BENCH_IMG_GID				?= 165535
BENCH_IMG_UID				?= 165535

ifneq ($(BENCH_USE_DNSMAP),0)
BENCH_BUILD_OPTS			?= --add-host "$(REPO_URL_BASE):$(REPO_URL_IP)"
endif


# Run Config
BENCH_RUN_DEBUG				?= 0

BENCH_RUN_GROUP				?= kyber
BENCH_RUN_USER				?= kyber
BENCH_RUN_GID				?= $(BENCH_GID)
BENCH_RUN_UID				?= $(BENCH_UID)

BENCH_INITRC_IGNORE			?= $(BENCH_IMG_DISTRO)
ifneq ($(strip $(foreach image,$(BENCH_INITRC_IGNORE),$(filter %_$(image),$(MAKECMDGOALS)) )),)
BENCH_INITRC_DISABLE		?= 1
endif

BENCH_SSH_MAP_KEY			?= 1
BENCH_SSH_MAP_GID			?= $(BENCH_IMG_GID)
BENCH_SSH_MAP_UID			?= $(BENCH_IMG_UID)



ifneq ($(BENCH_USE_DNSMAP),0)
BENCH_RUN_OPTS				?= --add-host "$(REPO_URL_BASE):$(REPO_URL_IP)"
endif

ifeq ($(CI_BUILDS_DIR),)
BENCH_TERM_OPTS				?= -it
else
BENCH_TERM_OPTS				?= -i
endif

BENCH_INITRC				?= /etc/benchrc
BENCH_INITCFG				?= /etc/benchcfg

BENCH_AUTH_ID				?= benchauth
BENCH_AUTH_FILE				?= .$(BENCH_AUTH_ID)

BENCH_TITLE_COLOR			?= $(HB_BLUE)
BENCH_COLOR					?= $(HB_GREEN)



###############################################################################
# Docker Rules

DOCKER_FILE_ROOT			:= $(BENCH_ROOT_PATH)/image/dockerfile
DOCKER_FILE_CONFIG			:= $(BENCH_ROOT_PATH)/image/config/KyberDocker.yaml
DOCKER_FILE_GENERATOR		:= $(BENCH_ROOT_PATH)/image/scripts/kyberdocker

DOCKER_FILE_ARGS			:= 	\
	http_proxy=$(http_proxy) \
	https_proxy=$(https_proxy) \
	BENCH_IMG_DISTRO=$(BENCH_IMG_DISTRO) \
	BENCH_IMG_VERSION=$(BENCH_IMG_VERSION) \
	BENCH_IMG_GROUP=$(BENCH_IMG_GROUP) \
	BENCH_IMG_USER=$(BENCH_IMG_USER) \
	BENCH_IMG_GID=$(BENCH_IMG_GID) \
	BENCH_IMG_UID=$(BENCH_IMG_UID) \
	BENCH_SSH_MAP_GID=$(BENCH_SSH_MAP_GID) \
	BENCH_SSH_MAP_UID=$(BENCH_SSH_MAP_UID) \
	BENCH_NAME=$(BENCH_NAME) \
	BENCH_AUTH_ID=$(BENCH_AUTH_ID) \
	BENCH_INITRC=$(BENCH_INITRC) \
	BENCH_INITCFG=$(BENCH_INITCFG) \
	REPO_URL_PROTO=$(REPO_URL_PROTO) \
	REPO_URL_BASE=$(REPO_URL_BASE) \
	REPO_URL_PORT=$(REPO_URL_PORT) \
	REPO_URL_GROUP=$(REPO_URL_GROUP) \

BENCH_TAG   				?= $(notdir $(shell find $(DOCKER_FILE_ROOT)/* -maxdepth 0 -type d -name "[a-zA-Z0-9]*"))


$(eval $(call rule_inc,$(BENCH_ROOT_PATH)/Build.mk))

$(eval $(call rule_inc,$(BENCH_ROOT_PATH)/Run.mk))


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


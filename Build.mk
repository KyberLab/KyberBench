#                                 KyberBench
# Copyright (c) 2025-2026, Kyber Development Team, all right reserved.
#




###############################################################################
# Image Targets

BENCH_DOCKGEN				:= $(patsubst %,dockgen_%,$(BENCH_TAG))
BENCH_DOCKPIN				:= $(patsubst %,dockpin_%,$(BENCH_TAG))
BENCH_DOCKCHECK				:= $(patsubst %,dockcheck_%,$(BENCH_TAG))
BENCH_BUILD					:= $(patsubst %,build_%,$(BENCH_TAG))
BENCH_SAVE					:= $(patsubst %,save_%,$(BENCH_TAG))
BENCH_LOAD					:= $(patsubst %,load_%,$(BENCH_TAG))
BENCH_PULL					:= $(patsubst %,pull_%,$(BENCH_TAG))
BENCH_PUSH					:= $(patsubst %,push_%,$(BENCH_TAG))

.PHONY : bench_depend $(BENCH_DOCKGEN) $(BENCH_DOCKPIN) $(BENCH_DOCKCHECK)
.PHONY : $(BENCH_BUILD) $(BENCH_SAVE) $(BENCH_LOAD) $(BENCH_PULL) $(BENCH_PUSH)



###############################################################################
# Dockerfile generator


DOCKER_TEMPLATE_LIST		:= $(wildcard $(DOCKER_FILE_ROOT)/*/Dockerfile.j2)
DOCKER_FILE_LIST			:= $(patsubst %.j2,%,$(DOCKER_TEMPLATE_LIST))


$(DOCKER_FILE_LIST) : % : %.j2
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)$(call xprint_title,"Generate $@",$(BENCH_TITLE_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)$(DOCKER_FILE_GENERATOR) -c $(DOCKER_FILE_CONFIG) -w $(DOCKER_FILE_ROOT)/$(shell echo $@ | awk -F / '{print $$(NF-1)}') $(foreach arg,$(DOCKER_FILE_ARGS),-e $(arg))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))


$(BENCH_DOCKGEN) : dockgen_% : $(DOCKER_FILE_ROOT)/%/Dockerfile



###############################################################################
# Dockerfile pinning


# Pinning Dockerfile
# $1: image name
define dockpin
	from_image=`cat $(DOCKER_FILE_ROOT)/$1/Dockerfile | grep "^FROM.*${BENCH_NAME}" | grep -v " AS " | awk -F ":" '{print $$2}'` && \
	make run_$${from_image} \
		USER_RUN_CMD="cd $(subst $(USER_HOST_WS),$(USER_GUEST_WS),$(DOCKER_FILE_ROOT))/$1 && \
			sudo dockpin apt pin -S --base-image ${BENCH_NAME}:$${from_image} && \
			if [ -f requirements.in ]; \
			then \
				which pip 2>/dev/null || sudo apt-get update && sudo apt-get install -y python3-pip; \
				which pip-compile 2>/dev/null || sudo pip install pip-tools; \
				pip-compile --allow-unsafe --strip-extras --generate-hashes requirements.in -o requirements.txt; \
			fi"
endef

$(BENCH_DOCKPIN) : dockpin_% : $(DOCKER_FILE_ROOT)/%/Dockerfile
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)$(call xprint_title,"Pin $@",$(BENCH_TITLE_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)$(call dockpin,$(subst dockpin_,,$@))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))


# Check Docker Image
# $1: image name
define dockcheck
	from_image=`cat $(DOCKER_FILE_ROOT)/$1/Dockerfile | grep "^FROM.*${BENCH_NAME}" | grep -v " AS " | awk -F ":" '{print $$2}'` && \
	make run_$${from_image} \
		USER_RUN_CMD="cd $(subst $(USER_HOST_WS),$(USER_GUEST_WS),$(DOCKER_FILE_ROOT))/$1 && \
			sudo ../../scripts/kyberinstall -c dockpin-apt.lock"
endef

$(BENCH_DOCKCHECK) : dockcheck_% : $(DOCKER_FILE_ROOT)/%/Dockerfile
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)$(call xprint_title,"Check $@",$(BENCH_TITLE_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)$(call dockcheck,$(subst dockcheck_,,$@))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))



###############################################################################
# Image Depends

ifneq ($(call is_in_docker),)
BENCH_DEPEND_FILE			:= $(DOCKER_FILE_ROOT)/.depend.host.$(BENCH_NAME)
else
BENCH_DEPEND_FILE			:= $(DOCKER_FILE_ROOT)/.depend.docker.$(BENCH_NAME)
endif

BENCH_CHECK_CMD			:= $(if $(call is_in_docker),,sudo )docker images --format \"table {{.ID}}\" 2>/dev/null

$(BENCH_DEPEND_FILE) : $(DOCKER_FILE_LIST)
	$(Q)cd $(DOCKER_FILE_ROOT) && echo $(BENCH_TAG) | tr " " "\n" | \
		xargs -i grep -H "^FROM.*${BENCH_NAME}" {}/Dockerfile | \
		sed 's/\.\///g' | \
		sed 's/\/Dockerfile:FROM ${BENCH_NAME}:/:/g' | \
		awk -F ":" '{print "build_" $$1 " : $$(if $$(shell $(BENCH_CHECK_CMD) $(BENCH_NAME):"$$1" | grep -v \"IMAGE ID\"),,build_"$$2")"}' | \
		grep -v "^build_$(BENCH_IMG_DISTRO)" > $(BENCH_DEPEND_FILE)

-include $(BENCH_DEPEND_FILE)

bench_depend : $(BENCH_DEPEND_FILE)



###############################################################################
# Image Build


# bench_image_build_cmd
# $(1) docker tag
define bench_image_build_cmd
BENCH_BUILDKIT=1 docker build $(BENCH_CMD_ARGS) \
		--progress=plain \
		--ssh default \
		$(BENCH_BUILD_OPTS) \
		$(foreach arg,$(DOCKER_FILE_ARGS),--build-arg $(arg) ) \
		--secret id=$(BENCH_AUTH_ID),src=$(BENCH_ROOT_PATH)/$(BENCH_AUTH_FILE) \
		-t $(BENCH_NAME):$(1) $(DOCKER_FILE_ROOT)/$(1)
endef


# bench_image_build_helper
# $(1) docker tag
define bench_image_build_helper
	$(Q)$(call xprint_title,"Build \"$(BENCH_NAME):$(1)\" Image",$(BENCH_TITLE_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)$(call bench_image_build_cmd,$(1))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
endef


$(BENCH_BUILD) : bench_depend
	$(if $(call bench_image_id,$(subst build_,,$@)),,$(call bench_image_build_helper,$(subst build_,,$@)))



###############################################################################
# Image helpers

# bench_image_id
# $(1) docker tag
define bench_image_id
$(shell docker images --format table | awk '$$1=="$(BENCH_NAME)" && $$2=="$(1)"{print $$3}')
endef



###############################################################################
# Image load and save

# bench_package_name
# $(1) docker tag
define bench_package_name
KyberBench_$(call string_to_upper,$(1))
endef

# bench_package_id
# $(1) docker tag
define bench_package_id
$(call string_to_upper,$(shell docker images --format "table {{.ID}}" $(BENCH_NAME):$(1) 2>/dev/null))
endef


# bench_package_path
# $(1) Docker Tag
define bench_package_path
$(BENCH_IMAGE_PATH)/$(call bench_package_name,$(1))_$(call bench_package_id,$(1))_$(shell date +"%Y-%m-%d")
endef


BENCH_IMAGE_PATH			?= $(BENCH_ROOT_PATH)

$(BENCH_SAVE) : save_% : build_%
	$(Q)$(call xprint_title,"Save $(BENCH_NAME):$< Image",$(BENCH_TITLE_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)docker save $(BENCH_NAME):$< | xz > $(call bench_package_path,$<).tar.xz
	$(Q)$(call xprint_filled,$(BENCH_COLOR))


$(BENCH_LOAD) : 
	$(Q)$(call xprint_line,$(BLUE))
	$(Q)$(call xprint_info,"Load $(BENCH_NAME):$(patsubst load_%,%,$@) Image",$(BENCH_TITLE_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)$(if $(call bench_image_id,$(patsubst load_%,%,$@)),,docker load < $(BENCH_IMAGE_PATH))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))



###############################################################################
# Image pull and push

# bench_pull_helper
# $(1) docker name
# $(2) docker tag
# $(3) docker repo base
define bench_pull_helper
	$(Q)$(call xprint_title,"Pull $(1):$(2) Image",$(BENCH_TITLE_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)docker pull $(3)/$(1):$(2)
	$(Q)docker tag $(3)/$(1):$(2) $(1):$(2)
	$(Q)docker rmi $(3)/$(1):$(2)
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
endef


# bench_pull
# $(1) docker name
# $(2) docker tag
# $(3) docker repo base
define bench_pull
$(if $(call bench_image_id,$(2)),,$(call bench_pull_helper,$(1),$(2),$(3)))
endef


$(BENCH_PULL) : 
	$(call bench_pull,$(BENCH_NAME),$(patsubst pull_%,%,$@),$(BENCH_REPO_BASE))


# bench_push
# $(1) docker name
# $(2) docker tag
# $(3) docker repo base
define bench_push
$(if $(call bench_image_id,$(2)),docker tag $(1):$(2) $(3)/$(1):$(2) && docker push $(3)/$(1):$(2) && docker rmi $(3)/$(1):$(2),,$(call xprint,$(RED),"Image Is Not Exist !"))
endef


$(BENCH_PUSH) : push_% : build_%
	$(Q)$(call xprint_info,"Push $(BENCH_NAME):$(patsubst push_%,%,$@) Image",$(BENCH_TITLE_COLOR))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))
	$(Q)$(call bench_push,$(BENCH_NAME),$(patsubst push_%,%,$@),$(BENCH_REPO_BASE))
	$(Q)$(call xprint_filled,$(BENCH_COLOR))


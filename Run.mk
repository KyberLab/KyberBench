#                                 KyberBench
# Copyright (c) 2025-2026, Kyber Development Team, all right reserved.
#



BENCH_IMAGE					:= $(patsubst %,image_%,$(BENCH_TAG))

BENCH_RUN					:= $(patsubst %,run_%,$(BENCH_TAG))
BENCH_RUND					:= $(patsubst %,rund_%,$(BENCH_TAG))
BENCH_EXEC					:= $(patsubst %,exec_%,$(BENCH_TAG))
BENCH_SSH					:= $(patsubst %,ssh_%,$(BENCH_TAG))

BENCH_START					:= $(patsubst %,start_%,$(BENCH_TAG))
BENCH_STOP					:= $(patsubst %,stop_%,$(BENCH_TAG))
BENCH_RM					:= $(patsubst %,rm_%,$(BENCH_TAG))
BENCH_RMI					:= $(patsubst %,rmi_%,$(BENCH_TAG))
BENCH_IP					:= $(patsubst %,ip_%,$(BENCH_TAG))


.PHONY : $(BENCH_IMAGE) $(BENCH_RUN) $(BENCH_RUND) $(BENCH_EXEC) $(BENCH_SSH) \
		$(BENCH_START) $(BENCH_STOP) $(BENCH_RM) $(BENCH_RMI) $(BENCH_IP)



###############################################################################


# bench_self_id
# return current container self id
define bench_self_id
$(shell cat /proc/self/mountinfo | awk '$$5=="/etc/resolv.conf" {print $$4}' | awk -F "/" '{print $$(NF-1)}')
endef


# bench_host_temp_root
# return current container temp root directory path in host
define bench_host_temp_root
$(shell docker inspect $(call bench_self_id) -f "{{.GraphDriver.Data.MergedDir}}")
endef


# bench_host_mount_root
# $(1) path in current container
# return mount path in host
define bench_host_mount_root
$(shell docker inspect $(call bench_self_id) -f '{{range .Mounts}}{{if eq .Destination "$(1)" }}{{printf "%s" .Source}}{{end}}{{end}}')
endef


# bench_host_map_root
# $(1) path in current container
# return map root in host
define bench_host_map_root
$(if $(call bench_host_mount_root,$(1)),$(call bench_host_mount_root,$(1)),$(call bench_host_temp_root)$(1))
endef


# bench_host_map_path
# $(1) path in current container
# return map path in host
define bench_host_map_path
$(if $(BENCH_CI_ENABLE),$(call bench_host_map_root,$(BENCH_CI_ENABLE))/$(patsubst $(BENCH_CI_ENABLE)%,%,$(1)),$(if $(call is_in_docker),$(1),$(call bench_host_map_root,$(1))))
endef


# bench_daemon_name
# $(1) docker image tag
define bench_daemon_name
$(BENCH_NAME)_$(1)_$(shell whoami)_$(shell echo $(BENCH_ROOT_PATH) | md5sum | cut -f1 -d " " | head -c6)
endef


# bench_daemon_id
# $(1) docker image tag
define bench_daemon_id
$(shell docker ps -a | awk '$$NF=="$(call bench_daemon_name,$(1))" {print $$1}' | head -n1)
endef


# bench_image_id
# $(1) docker image tag
define bench_image_id
$(shell docker images --format table | awk '$$1=="$(BENCH_NAME)" && $$2=="$(1)" {print $$3}')
endef

#$(shell docker images 2>/dev/null | awk '$$1=="$(BENCH_NAME):$(1)" {print $$2}')
#$(shell docker images | awk '$$1=="$(BENCH_NAME)" && $$2=="$(1)" {print $$3}')




###############################################################################
# Run Arguments

BENCH_RUN_ARGS				:= $(BENCH_RUN_OPTS)

# For device and kernel
BENCH_RUN_ARGS				+= --privileged
BENCH_RUN_ARGS				+= -v /dev:/dev

# Docker In Docker Arguments
BENCH_RUN_ARGS				+= -e BENCH_RUNNING_NESTED=1
BENCH_RUN_ARGS				+= -v /etc/localtime:/etc/localtime:ro
BENCH_RUN_ARGS				+= -v /var/run/docker.sock:/var/run/docker.sock

# X11 Forward Arguments
BENCH_RUN_ARGS				+= \
	-e DISPLAY=$${DISPLAY} \
    -v /tmp/.X11-unix:/tmp/.X11-unix

# Terminal Arguments
BENCH_RUN_ARGS				+= $(BENCH_TERM_OPTS)

# Debug Arguments
BENCH_RUN_ARGS				+= -e BENCH_RUN_DEBUG=$(BENCH_RUN_DEBUG)

# Image User Arguments
BENCH_RUN_ARGS				+= \
	-e BENCH_IMG_GROUP=$(BENCH_IMG_GROUP) \
	-e BENCH_IMG_USER=$(BENCH_IMG_USER) \
	-e BENCH_IMG_GID=$(BENCH_IMG_GID) \
	-e BENCH_IMG_UID=$(BENCH_IMG_UID)

ifneq ($(BENCH_INITRC_DISABLE),1)
BENCH_RUN_ARGS				+= \
	-u $(BENCH_IMG_UID):$(BENCH_IMG_GID)
endif

# Container User Arguments
BENCH_RUN_ARGS				+= \
	-e BENCH_RUN_GROUP=$(BENCH_RUN_GROUP) \
	-e BENCH_RUN_USER=$(BENCH_RUN_USER) \
	-e BENCH_RUN_GID=$(BENCH_RUN_GID) \
	-e BENCH_RUN_UID=$(BENCH_RUN_UID)

# Initrc Arguments
BENCH_RUN_ARGS				+= \
	-e BENCH_INITRC=$(BENCH_INITRC) \
	-e BENCH_INITCFG=$(BENCH_INITCFG)


# Authorization Arguments
ifeq ($(call is_in_docker),)

ifeq ($(BENCH_ROOT_PATH),$(call file_dst,$(USER_MAP_WS)))
ifneq ($(call file_is_exist,$(BENCH_ROOT_PATH)/$(BENCH_AUTH_FILE)),)
$(error Container Authorization File Not Exist !)
endif
endif # ($(BENCH_ROOT_PATH),$(call file_dst,$(USER_MAP_WS)))

else # ($(call is_in_docker),)

ifneq ($(call file_is_exist,$(BENCH_ROOT_PATH)/$(BENCH_AUTH_FILE)),)
$(warning Container Authorization File Not Exist !)
$(shell touch $(BENCH_ROOT_PATH)/$(BENCH_AUTH_FILE))
endif

endif # ($(call is_in_docker),)

BENCH_RUN_ARGS				+= \
		-e BENCH_AUTH_FILE=$(BENCH_AUTH_FILE)

# Mount Arguments
ifeq ($(BENCH_RUNNING_NESTED),1)
BENCH_RUN_ARGS				+= \
		--mount type=bind,source=$(call bench_host_map_path,/etc/$(BENCH_AUTH_FILE)),destination=/etc/$(BENCH_AUTH_FILE)
else # ($(BENCH_RUNNING_NESTED),1)
BENCH_RUN_ARGS				+= \
		--mount type=bind,source=$(call bench_host_map_path,$(BENCH_ROOT_PATH)/$(BENCH_AUTH_FILE)),destination=/etc/$(BENCH_AUTH_FILE)
endif # ($(BENCH_RUNNING_NESTED),1)


# Work Directory Arguments
BENCH_RUN_ARGS				+= \
		-e BENCH_WORK_PATH=$(call file_dst,$(USER_MAP_WS)) \
		--mount type=bind,source=$(call bench_host_map_path,$(call file_src,$(USER_MAP_WS))),destination=$(call file_dst,$(USER_MAP_WS))


# SSH Arguments
BENCH_RUN_ARGS				+= \
		-e BENCH_SSH_MAP_KEY=$(BENCH_SSH_MAP_KEY)

ifneq ($(BENCH_SSH_MAP_KEY),0)
BENCH_RUN_ARGS				+= \
		-v ~/.ssh/id_rsa:/home/$(BENCH_IMG_USER)/.ssh/id_rsa \
		-v ~/.ssh/id_rsa.pub:/home/$(BENCH_IMG_USER)/.ssh/id_rsa.pub
endif



###############################################################################
# Run targets

# define bench_run_plat
# $(1) docker image tag
# return platform
define bench_run_plat
$(shell x=$$(echo $(filter %$(1),$(BOARD_LONG_LIST)) | awk -F "_" '{print $$1}'); [ -z $$x ] && echo $(BUILD_PLATFORM_DEFAULT) || echo $${x})
endef


# define bench_run_board
# $(1) running platform
# $(2) docker image tag
# return board
define bench_run_board
$(shell [ $(1) = $(BUILD_PLATFORM_DEFAULT) ] && echo $(BUILD_BOARD_DEFAULT) || echo $(2))
endef


# define bench_run_env
# $(1) docker image tag
# return env set scripts
define bench_run_env
export BENCH_RUN_PLAT=$(call bench_run_plat,$(1)) && \
export BENCH_RUN_BOARD=$$([ $${BENCH_RUN_PLAT} = $(BUILD_PLATFORM_DEFAULT) ] && echo $(BUILD_BOARD_DEFAULT) || echo $(1))
endef


# define bench_run_cmd
# $(1) docker image tag
# $(2) run cmd
define bench_run_cmd
$(call bench_run_env,$(1)) && \
docker run --rm \
		-e BENCH_RUN_PLAT=$${BENCH_RUN_PLAT} \
		-e BENCH_RUN_BOARD=$${BENCH_RUN_BOARD} \
		$(BENCH_CMD_ARGS) \
		$(BENCH_RUN_ARGS) \
		$(BENCH_NAME):$(1) \
		$(if $(2), sh -c $(2)); \
exit 0
endef


# define bench_rund_cmd
# $(1) docker image tag
define bench_rund_cmd
$(call bench_run_env,$(1)) && \
docker run -d --restart=always \
		--name $(call bench_daemon_name,$(1)) \
		-e BENCH_RUN_PLAT=$${BENCH_RUN_PLAT} \
		-e BENCH_RUN_BOARD=$${BENCH_RUN_BOARD} \
		$(BENCH_CMD_ARGS) \
		$(BENCH_RUN_ARGS) \
		$(BENCH_NAME):$(1)
endef

ifneq ($(BENCH_INITRC_DISABLE),1)
BENCH_RUN_SCRIPT			:= "USER_RUN_CMD=$(if $(USER_RUN_CMD),\"$(USER_RUN_CMD)\") . $(BENCH_INITRC)"
else
BENCH_RUN_SCRIPT			:= "$(if $(USER_RUN_CMD),$(USER_RUN_CMD),/bin/bash)"
endif
#$(warning USER_RUN_CMD=$(USER_RUN_CMD))
#$(error BENCH_RUN_SCRIPT=$(BENCH_RUN_SCRIPT))

ifeq ($(BENCH_IMG_FROM),remote)
$(BENCH_IMAGE) : image_% : pull_%
else # ($(BENCH_IMG_FROM),remote)

ifeq ($(BENCH_IMG_FROM),local)
$(BENCH_IMAGE) : image_% : build_%

else # ($(BENCH_IMG_FROM),local)
$(error Invalid Image Type : $(BENCH_IMG_FROM))
endif # ($(BENCH_IMG_FROM),local)
endif # ($(BENCH_IMG_FROM),remote)


$(BENCH_RUN) : run_% : image_%
	$(Q)$(call bench_run_cmd,$(subst image_,,$<),$(BENCH_RUN_SCRIPT))


$(BENCH_RUND) : rund_% : image_%
	$(Q)if [ -z $(BENCH_RUNNING_NESTED) ]; then $(if $(call bench_daemon_id,$(subst image_,,$<)),$(call xprint,$(RED),Container \"$(BENCH_NAME)_$(subst image_,,$<)\" Has Been Started),$(call bench_rund_cmd,$(subst image_,,$<))); fi



###############################################################################

# bench_start
# $(1) docker image tag
define bench_start
$(if $(call bench_daemon_id,$(1)),docker start $(call bench_daemon_name,$(1)) > /dev/null && $(ECHO) "start $(call bench_daemon_name,$(1)) ok")
endef

$(BENCH_START) : start_% : image_%
	$(Q)$(call bench_start,$(subst image_,,$<))



###############################################################################

# bench_stop
# $(1) docker image tag
define bench_stop
$(if $(call bench_daemon_id,$(1)),ssh-keygen -f "$${HOME}/.ssh/known_hosts" -R "$(call bench_ip,$(1))" > /dev/null 2>&1;docker stop -t0 $(call bench_daemon_name,$(1)) > /dev/null && $(ECHO) "stop $(call bench_daemon_name,$(1)) ok";)
endef

$(BENCH_STOP) : 
	$(Q)$(call bench_stop,$(patsubst stop_%,%,$@))



###############################################################################

# bench_rm
# $(1) docker image tag
define bench_rm
$(if $(call bench_daemon_id,$(1)),docker rm $(call bench_daemon_name,$(1)) > /dev/null && $(ECHO) "remove $(call bench_daemon_name,$(1)) ok")
endef

$(BENCH_RM) : rm_% : stop_%
	$(Q)$(call bench_rm,$(patsubst rm_%,%,$@))



###############################################################################

# bench_rmi
# $(1) docker image tag
define bench_rmi
$(if $(call bench_image_id,$(1)),docker rmi $(BENCH_NAME):$(1) > /dev/null && $(ECHO) "remove $(BENCH_NAME):$(1) ok")
endef

$(BENCH_RMI) : rmi_% : rm_%
	$(Q)$(call bench_rmi,$(patsubst rmi_%,%,$@))



###############################################################################

# bench_ip
# $(1) docker image tag
define bench_ip
$(shell docker exec $(BENCH_TERM_OPTS) $(call bench_daemon_name,$(1)) ip addr show eth0 | tr "/" " " | awk '$$1=="inet" {print $$2}')
endef

$(BENCH_IP) : ip_% : image_%
	$(Q)echo -n $(call bench_ip,$(subst image_,,$<))



###############################################################################

$(BENCH_EXEC) : exec_% : image_%
	$(Q)-docker exec $(BENCH_TERM_OPTS) $(call bench_daemon_id,$(subst image_,,$<)) sh -c $(BENCH_RUN_SCRIPT); exit 0


$(BENCH_SSH) : ssh_% : image_%
	$(Q)-ssh -AY -t $(BENCH_RUN_USER)@$(call bench_ip,$(subst image_,,$<)) "LC_ALL=en_US.UTF-8 exec dbus-run-session -- bash -l"; exit 0


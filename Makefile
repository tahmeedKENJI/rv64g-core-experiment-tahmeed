#########################################################################################
##                                                                                     ##
##    Description : A single Makefile for Xilinx Vivado Simulation in this reposity    ##
##    Author      : Foez Ahmed                                                         ##
##    Email       : foez.official@gmail.com                                            ##
##                                                                                     ##
#########################################################################################

#########################################################################################
# HELP
#########################################################################################

.PHONY: help
help:
	@clear;
	@clear;
	@make -s print_logo
	@echo -e "\033[4;36mGNUmake options:\033[0m"
	@echo -e "\033[1;32mmake help\033[0m shows these message"
	@echo -e "\033[1;32mmake soft_clean\033[0m clears out builds"
	@echo -e "\033[1;32mmake clean\033[0m clears out builds and logs"
	@echo -e "\033[1;32mmake tb TOP=<top_module_name>\033[0m open new or existing testbench top"
	@echo -e "\033[1;32mmake rtl RTL=<module_name>\033[0m open new or existing rtl design"
	@echo -e "\033[1;32mmake simulate TOP=<top_module_name>\033[0m open new or existing rtl design"

#########################################################################################
# VARIABLES
#########################################################################################

ROOT := $(shell realpath .)
COMP_LIB := $(shell find $(ROOT)/source -name "*.sv")
INC_DIR := -i $(ROOT)/include

ifneq ($(TOP), )
  COMP_LIB += $(shell find $(ROOT)/test/$(TOP) -name "*.sv")
  INC_DIR += -i $(ROOT)/test/$(TOP)
endif

CONFIG?=default

USER_NAME = $(shell git config user.name)
USER_EMAIL = $(shell git config user.email)

#########################################################################################
# FILES
#########################################################################################

build:
	@mkdir -p build
	@echo "*" > build/.gitignore

log:
	@mkdir -p log
	@echo "*" > log/.gitignore

submodules/sv-genesis/tb_model.sv:
	@git submodule update --init --recursive --depth 1

submodules/sv-genesis/rtl_model.sv:
	@git submodule update --init --recursive --depth 1

.PHONY: tb
tb: test/$(TOP)/$(TOP).sv test/$(TOP) submodules/sv-genesis/tb_model.sv test/$(TOP)/xsim_$(CONFIG)_cfg
	@code test/$(TOP)/$(TOP).sv

test/$(TOP):
	@mkdir -p test/$(TOP)

test/$(TOP)/$(TOP).sv:
	@mkdir -p test/$(TOP)
	@cat submodules/sv-genesis/tb_model.sv \
	| sed "s/Author : name (email)/Author : $(USER_NAME) ($(USER_EMAIL))/g" \
	| sed "s/module tb_model;/module $(TOP);/g" \
	| sed "s/squared-studio/DSInnovators/g" \
	| sed "s/sv-genesis/rv64g-core/g" \
	> test/$(TOP)/$(TOP).sv

test/$(TOP)/xsim_$(CONFIG)_cfg:
	@touch test/$(TOP)/xsim_$(CONFIG)_cfg

.PHONY: rtl
rtl: source/$(RTL).sv submodules/sv-genesis/rtl_model.sv
	@code source/$(RTL).sv

source/$(RTL).sv:
	@cat submodules/sv-genesis/rtl_model.sv \
	| sed "s/Author : name (email)/Author : $(USER_NAME) ($(USER_EMAIL))/g" \
	| sed "s/module rtl_model/module $(RTL)/g" \
	| sed "s/squared-studio/DSInnovators/g" \
	| sed "s/sv-genesis/rv64g-core/g" \
	> source/$(RTL).sv

#########################################################################################
# VIVADO
#########################################################################################

.PHONY: simulate
simulate: print_logo soft_clean xvlog xelab xsim print_logo

define compile
  $(eval SUB_LIB := $(shell echo "$(wordlist 1, 25,$(COMPILE_LIB))"))
  cd build; xvlog $(INC_DIR) -sv $(SUB_LIB) --nolog  --define SIMULATION
  $(eval COMPILE_LIB := $(wordlist 26, $(words $(COMPILE_LIB)), $(COMPILE_LIB)))
  $(if $(COMPILE_LIB), $(call compile))
endef

.PHONY: xvlog
xvlog:
	@$(eval COMPILE_LIB := $(COMP_LIB))
	@$(call compile)

.PHONY: xelab
xelab:
ifeq ($(TOP), )
	@$(error TOP not set)
else
	@cd build; xelab $(TOP) -s $(TOP) --nolog
endif

.PHONY: xsim
xsim: test/$(TOP)/xsim_$(CONFIG)_cfg
ifeq ($(TOP), )
	@$(error TOP not set)
else
	@echo -n "$(TOP) $(CONFIG)" > build/config
	@cd build; xsim $(TOP) --runall --log ../log/$(TOP)_$(CONFIG).log
endif

#########################################################################################
# VERIBLE
#########################################################################################

.PHONY: verible_lint
verible_lint:
	@rm -rf temp_lint_error
	@$(eval list := $(shell find -name "*.sv"))
	@- $(foreach file, $(list), verible-verilog-lint.exe $(file) >> temp_lint_error 2>&1;)
	@cat temp_lint_error

#########################################################################################
# DOCUMENTER
#########################################################################################

.PHONY: gen_doc
gen_doc:
	@echo "Creating document for $(FILE)"
	@mkdir -p document/rtl
	@python submodules/documenter/sv_documenter.py $(FILE) document/rtl
	@sed -i "s/.*${LINE_1}.*/<br>**${LINE_1}**/g" ./document/rtl/$(shell basename $(FILE) | sed "s/\.sv/\.md/g")
	@sed -i "s/.*${LINE_2}.*/<br>**${LINE_2}**/g" ./document/rtl/$(shell basename $(FILE) | sed "s/\.sv/\.md/g")
	@sed -i "s/.*${LINE_3}.*/<br>**${LINE_3}**/g" ./document/rtl/$(shell basename $(FILE) | sed "s/\.sv/\.md/g")
	@sed -i "s/.*${LINE_4}.*/<br>**${LINE_4}**/g" ./document/rtl/$(shell basename $(FILE) | sed "s/\.sv/\.md/g")
	@echo "[\`$(shell basename $(FILE) | sed 's/\.sv//g')\`]($(shell basename $(FILE) | sed 's/\.sv//g').md)" >> document/rtl/modules.md

.PHONY: update_doc_list
update_doc_list: submodules/documenter/sv_documenter.py
	@rm -rf document/rtl/*.md
	@rm -rf document/rtl/*_top.svg
	@$(eval RTL_LIST = $(shell find source -name "*.sv"))
	@echo "# List of Modules" > document/rtl/modules.md
	@$(foreach file, $(RTL_LIST), make -s gen_doc FILE=$(file);)

submodules/documenter/sv_documenter.py:
	@git submodule update --init --recursive --depth 1

#########################################################################################
# MISCELLANEOUS
#########################################################################################

.PHONY: print_logo
print_logo:
	@echo "";
	@echo "";
	@echo -e "\033[1;34m  ____  ____ ___                             _      \033[0m\033[1;39m Since 2001 \033[0m";
	@echo -e "\033[1;34m |  _ \/ ___|_ _|_ __  _ __   _____   ____ _| |_ ___  _ __ ___  \033[0m";
	@echo -e "\033[1;34m | | | \___ \| || '_ \| '_ \ / _ \ \ / / _' | __/ _ \| '__/ __| \033[0m";
	@echo -e "\033[1;34m | |_| |___) | || | | | | | | (_) \ V / (_| | || (_) | |  \__ \ \033[0m";
	@echo -e "\033[1;34m |____/|____/___|_| |_|_| |_|\___/ \_/ \__,_|\__\___/|_|  |___/ \033[0m";
	@echo -e "\033[1;39m ______________ Dynamic Solution Innovators Ltd. ______________ \033[0m";
	@echo -e "";



.PHONY: soft_clean
soft_clean:
	@rm -rf build
	@make -s build

.PHONY: clean
clean: soft_clean
	@rm -rf log
	@make -s log
	@rm -rf $(shell find -name "temp_*")
	@$(foreach word, $(shell cat .gitignore), rm -rf $(shell find $(shell realpath .) -name "$(word)");)

LINE_1 := This file is part of DSInnovators:rv64g-core
LINE_2 := Copyright (c) $(shell date +%Y) DSInnovators
LINE_3 := Licensed under the MIT License
LINE_4 := See LICENSE file in the project root for full license information

.PHONY: copyright_check
copyright_check:
	@rm -rf temp_copyright_issues
	@$(eval LIST := $(shell find -name "*.svh" | sed "s/\/.*submodules\/.*//g"))
	@$(foreach file, $(LIST), $(call copyright_check_file,$(file));)
	@$(eval LIST := $(shell find -name "*.sv" | sed "s/\/.*submodules\/.*//g"))
	@$(foreach file, $(LIST), $(call copyright_check_file,$(file));)
	@touch temp_copyright_issues
	@cat temp_copyright_issues

define copyright_check_file
	(grep -ir "author" $(1) > /dev/null) || (echo "$(1) >> \"Author : Name (email)\"" >> temp_copyright_issues)
	(grep -r "$(LINE_1)" $(1) > /dev/null) || (echo "$(1) >> \"$(LINE_1)\"" >> temp_copyright_issues)
	(grep -r "$(LINE_2)" $(1) > /dev/null) || (echo "$(1) >> \"$(LINE_2)\"" >> temp_copyright_issues)
	(grep -r "$(LINE_3)" $(1) > /dev/null) || (echo "$(1) >> \"$(LINE_3)\"" >> temp_copyright_issues)
	(grep -r "$(LINE_4)" $(1) > /dev/null) || (echo "$(1) >> \"$(LINE_4)\"" >> temp_copyright_issues)
endef

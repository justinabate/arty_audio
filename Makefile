#!/usr/bin/make

XLNX_BIN=/opt/Xilinx/Vivado/2021.1/bin

.DEFAULT_GOAL := vivado_project

.ONESHELL:

.PHONY: clean vivado_project


# clean up
clean:
	@rm -rf arty_audio/ .Xil/
	@find . -maxdepth 1 -type f -name "*.jou" -delete
	@find . -maxdepth 1 -type f -name "*.log" -delete


vivado_project: clean
	@export PATH=$(XLNX_BIN):$$PATH
	@vivado -mode batch -source arty_audio.tcl
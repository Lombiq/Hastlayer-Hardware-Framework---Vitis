# Dumping help

.PHONY: help
help::
	@echo "Makefile Usage:"
	@echo "  make all TARGET=<hw/hw_emu> \\"
	@echo "           DEVICE=<FPGA platform> \\"
	@echo "           FREQUENCY=<60-300(default)> \\"
	@echo "           MEMTYPE=<default(default)/DDR/HBM/PLRAM> \\"
	@echo "           AXIDWIDTH=<32/64/128/256/512(default)/1024> \\"
	@echo "           CACHE=<0/1(default)>"
	@echo "      Command to generate the design for specified Target and Device with provided parameters."
	@echo ""
	@echo "  make configure AXIDWIDTH=<32/64/128/256/512(default)/1024> CACHE=<1(default)/0>"
	@echo "      Command to configure RTL Kernel source files for Vivado simulation."
	@echo ""
	@echo "  make memorytest"
	@echo "      Command to build host side memory tester application."
	@echo ""
	@echo "  make cleanall"
	@echo "      Command to remove all the generated files."
	@echo ""

# Building host side memorytest application

memorytest: ./src/memorytest/memorytest.cpp
	g++ -I$(XILINX_XRT)/include -I$(XILINX_VIVADO)/include -Wall -O0 -g -std=c++14 -fmessage-length=0 ./src/memorytest/memorytest.cpp -o memorytest -L$(XILINX_XRT)/lib -lOpenCL -lpthread -lrt -lstdc++

# Building kernel

FREQUENCY := 300
MEMTYPE:= default
AXIDWIDTH := 512
CACHE := 1

XCLBIN := ./xclbin
VIVADO := $(XILINX_VIVADO)/bin/vivado
VPP := $(XILINX_VITIS)/bin/v++
CLFLAGS += -g -R2 --save-temps -t $(TARGET) --platform $(DEVICE)
CLFLAGS += --dk chipscope:hastip_1:m_axi_gmem

ifeq ($(MEMTYPE),$(filter $(MEMTYPE),DDR HBM PLRAM))
CLFLAGS += --connectivity.sp hastip_1.buffer:$(MEMTYPE)[0:0]
endif

define func-configure =
@sed "s/###hastipAxiDWidth###/$(AXIDWIDTH)/g" ./src/xml/kernel.xml.template > ./src/xml/kernel.xml
@sed "s/###hastipAxiDWidth###/$(AXIDWIDTH)/g; s/###hastipCache###/$(CACHE)/g;" ./src/IP/hastip.v.template > ./src/IP/hastip.v
@sed "s/###hastipAxiDWidth###/$(AXIDWIDTH)/g" ./src/testbench/slv_m00_axi_vip_pkg.sv.template > ./src/testbench/slv_m00_axi_vip_pkg.sv
@sed "s/###hastipAxiDWidth###/$(AXIDWIDTH)/g" ./src/testbench/slv_m00_axi_vip.sv.template > ./src/testbench/slv_m00_axi_vip.sv
@sed "s/###hastipAxiDWidth###/$(AXIDWIDTH)/g" ./src/testbench/hastip_tb.sv.template > ./src/testbench/hastip_tb.sv
endef

.PHONY: configure
configure:
	$(func-configure)

./src/xml/kernel.xml ./src/IP/*.v:
	$(func-configure)

all: ./src/xml/kernel.xml ./src/scripts/package_kernel.tcl ./src/scripts/gen_xo.tcl ./src/IP/*.v ./src/IP/*.vhd ./src/IP/*.xdc
	$(func-configure)
	@mkdir -p $(XCLBIN)
	$(VIVADO) -mode batch -source ./src/scripts/gen_xo.tcl -tclargs $(XCLBIN)/hastip.$(TARGET).xo $(TARGET) $(DEVICE)
	$(VPP) $(CLFLAGS) $(LDCLFLAGS) --kernel_frequency $(FREQUENCY) -lo $(XCLBIN)/hastip.$(TARGET).xclbin $(XCLBIN)/hastip.$(TARGET).xo
	emconfigutil --platform $(DEVICE) --od $(XCLBIN)
	cp $(XCLBIN)/emconfig.json .

# Cleaning stuff

.PHONY: cleanall
cleanall: 
	rm -rf ./tmp_kernel_pack* ./packaged_kernel* ./x
	rm -rf ./.Xil ./.run
	rm -rf *.log *.jou memorytest emconfig.json
	rm -rf $(XCLBIN)

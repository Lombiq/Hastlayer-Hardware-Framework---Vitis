# Hastlayer Vitis RTL Kernel Framework

## Requirements

Requirements for building and simulating a kernel:

1. Install the Xilinx Vitis 2019.2 or 2020.1
2. Install the appropriate Xilinx Runtime Library (XRT)
3. Install at least one Alveo platform package

To find the specific steps follow the Xilinx guide: https://www.xilinx.com/products/boards-and-kits/alveo/u250.html#gettingStarted

Before using Vitis tools the environment must be initialized:

```
. /opt/xilinx/xrt/setup.sh
. /tools/Xilinx/Vitis/2019.2/settings64.sh
```

or

```
. /opt/xilinx/xrt/setup.sh
. /tools/Xilinx/Vitis/2020.1/settings64.sh 
```

## How to build hastip.hw.xclbin?

To build the final XCLBIN file use the provided Makefile. For e.g.:

```
make all TARGET=hw DEVICE=xilinx_u200_xdma_201830_2
```         

Available switches:

- `DEVICE` - The Alveo card platform name (`ls /opt/xilinx/platforms/`). Or the full path to exact .xpfm file.
- `FREQUENCY` - Optional. The default target kernel frequency is 300 MHz. It can be between 60 and 300.
- `MEMTYPE` - Optional. If left out then Vitis will chose the appropriate memory type for the kernel buffer. Available options: DDR/HBM/PLRAM
- `CACHE` - Optional. Default is 1. Set 0 to disable the internal cache (for debugging purposes).

## How to emulate hastip.hw_emu.xclbin?

The initial repo contains the MemoryTest Hast_IP.vhd and an apropriate host aplication which can be emulated through the XRT. 

To build the XCLBIN file for software emulation use the provided Makefile with hw_emu option. For e.g.:

```
make all TARGET=hw_emu DEVICE=xilinx_u200_xdma_201830_2
```         

Also build the host side memory tester application:

```
make memorytest
```         

To run the emulated tests:

```
XCL_EMULATION_MODE=hw_emu ./memorytest -s 1024 -a 2 -b 128 -l 10 -x ./xclbin/hastip.hw_emu.xclbin
```         

Available memorytest switches:
`-s` - Kernel buffer size in bytes.
`-a value` - cell[0] value - the firs cell to be incremented.
`-b value` - cell[1] value - number of cells to be incremented.
`-d` - Disable internal cache.
`-l N` - Repeat the tests N times.
`-r` - If set cell[0] and cell[1] will set to random range before each loop.
`-p` - Pause before invoking the kernel (for ChipScope debuging).
`-x filename` - Path to the XCLBIN file.

## How to simulate Hast_IP.vhd + AXI Verification IP testbench in Vivado?

To run simulation in command line mode (only text reports):

```
cd xsim
./compile.sh; ./elaborate.sh; ./simulate.sh --stats
```

To run simulation in GUI mode (text reports + waveforms) use --gui switch:

```
./simulate.sh --gui
```

To rerun the simulation after modyfing the source code:

```
rm -r xsim.dir; rm *.log; rm *.jou; ./compile.sh; ./elaborate.sh; ./simulate.sh --stats
```


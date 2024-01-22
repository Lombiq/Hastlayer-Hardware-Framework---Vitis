# Building Vitis XCLBIN files for Trenz TE0715-04-30-1C module

To generate the Vitis XCLBIN files containing the Hastlayer RTL kernel you need the XPFM platform generated in prevous step and the Hastlayer generated Hast_IP.vhd files (for details see the Hast.Samples.Consumer documentation). This document describes the makefile build flow.

Before using the Vitis tools you first have to set up the environment:
 
```
source /tools/Xilinx/Vitis/2020.2/settings64.sh
```

Execute the following commands to build the XCLBIN file:

```
cd ${HOME}/trenz_te0715_04_30_1c/rtl_kernel
make all TARGET=hw DEVICE=${HOME}/trenz_te0715_04_30_1c/vitis/trenz_te0715_04_30_1c/export/trenz_te0715_04_30_1c/trenz_te0715_04_30_1c.xpfm
```

After succesfull build you can found the generated output files required by the Hast.Samples.Consumer in the xclbin folder:

```
${HOME}/trenz_te0715_04_30_1c/rtl_kernel/xclbin
```

# Building PetaLinux SD card image for Hastlayer (Trenz TE0715-04-30-1C module)

To be able to run Hastlayer accelerated .NET applications on Trenz Electronics TE0715-04-30-1C Zynq 7030 SOM SoC module you have to build PetaLinux with certain features enabled. This document describes the required steps.

## Install Xilinx PetaLinux Tools 2020.2

Download PetaLinux 2020.2 installer from Xilinx website (https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/embedded-design-tools/2020-2.html) and install it. 

![Download PetaLinux Installer](Images/PetalinuxDownloadInstaller.png)

PetaLinux building requires a 64-bit Linux machine with supported RedHat 7-8, CentOS 7-8, or Ubuntu 16-18-20. The actual PetaLinux tools installation must be done as a regular user, but for installing the required packages you need root access too. For more details see the documentation (https://www.xilinx.com/content/dam/xilinx/support/documentation/sw_manuals/xilinx2021_1/ug1144-petalinux-tools-reference-guide.pdf).

```
./petalinux-v2020.2-final-installer.run --dir ${HOME}/petalinux20202 --platform "arm"
```

Before using the PetaLinux tools you first have to set up the environment:

```
source ${HOME}/petalinux20202/settings.sh
```

## Configuring and building PetaLinux images

Create an empty PetaLinux project based on Zynq template:

```
cd ${HOME}/trenz_te0715_04_30_1c
petalinux-create -t project --template zynq --name petalinux
```

Configure the hardware:

```
cd petalinux
petalinux-config --silentconfig  --get-hw-description=${HOME}/trenz_te0715_04_30_1c/vivado/test_board/vivado
```

Configure the kernel:

```
petalinux-config -c kernel
```

![Kernel Configuration](Images/PetalinuxKernelStagingXilinxPlClockEnabler.png)

Set "Kernel Configuration - Device Drivers - Staging drivers - Xilinx PL clock enabler" option to [*] built-in.
Press the ESC key and save the configuration before exit.

Replace ./project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi file with the following:

```
/include/ "system-conf.dtsi"
/ {
    fclk0: fclk0 {
    status = "okay";
    compatible = "xlnx,fclk";
    clocks = <&clkc 15>;
    };
};

&amba {
  zyxclmm_drm {
    compatible = "xlnx,zocl";
    status = "okay";
  };
};
```

Edit ./project-spec/meta-user/conf/petalinuxbsp.conf and add the following lines at the end:

```
EXTRA_IMAGE_FEATURES = "debug-tweaks"
IMAGE_AUTOLOGIN = "1"
```

Edit ./project-spec/meta-user/conf/user-rootfsconfig and add the following lines at the end:

```
CONFIG_opencl-clhpp-dev
CONFIG_opencl-headers-dev
CONFIG_xrt
CONFIG_zocl
```

Configure the root filesystem:

```
petalinux-config -c rootfs
```

![Rootfs Configuration](Images/PetalinuxRootfsUserPackages.png)

In "user packages" group choose [*] built-in option for all items.

Press the ESC key and save the configuration before exit.

Build the SD card images:

```
petalinux-build
petalinux-package --boot --force --fsbl --u-boot --fpga
```

## Preparing the SD card

Copy the following three files to the root folder in the first partition on the SD card (it should be less than 32 GB and FAT32 formatted):

```
./images/linux/BOOT.BIN
./images/linux/boot.scr
./images/linux/image.ub
```

The BOOT.BIN and the boot.scr contains the U-Boot and the initial FPGA image. The image.ub contains the kernel and the root file system.

If required you can put additional content on the SD card, and after booting PetaLinux you can access the SD card content in cd /media/sd-mmcblk0p1/ folder.

To run Hastlayer accelerated .NET applications you should log in as root (the default password is root).

![FPGA configuration done](Images/TE0715-04-30-LED.jpg)

To test the SD card image put the card into the Micro SD card slot on the carrier board. After switching on the power, the D2 LED becomes green, and if the FPGA is successfully programed from SD card it will goes off.
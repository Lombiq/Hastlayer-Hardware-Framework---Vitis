# Hastlayer Hardware Framework - Xilinx Vitis

## About

The hardware framework project to be used with the [Hastlayer SDK](https://github.com/Lombiq/Hastlayer-SDK) when targeting Xilinx devices using the Vitis development environment. You don't really have to take care of this manually, since the framework is included during Hastlayer operations automatically.


## Documentation

Contents:

- `opencl`: C++ OpenCL sample project.
- `platforms`: The custom hardware descriptions required to compile for specific devices (e.g. Trenz Electronic TE0715-04-30-1C).
- `rtl`: VHDL template project for building OpenCL binaries with Hastlayer.
- `Hast.Vitis.Abstractions.HardwareFramework.csproj`: A container project that helps importing the files from `rtl` into your .Net Core project. It's a dependency of `Hast.Vitis.Abstractions`.

When the project file is referenced the _rtl/src_ and the _platforms_ directories are copied into the build root's HardwareFramework directory.  

The _rtl_ directory contains Makefiles which you could feasibly use to build projects into a C++ application. More importantly we use them to track changes when translating a new version of the C++ prototype implementations into the C# build providers. In other words we don't actually use the _/rtl/Makefile_ and _/rtl/Makefile.Zynq_ in our code or build process directly. Consider it documentation if you know how to use make.

## Release notes

### v1.0 04.10.2021

First public release with support for Alveo Datacenter Accelerator Cards.


## Contributing and support

Bug reports, feature requests, comments, questions, code contributions, and love letters are warmly welcome, please do so via GitHub issues and pull requests. Please adhere to our [open-source guidelines](https://lombiq.com/open-source-guidelines) while doing so.

This project is developed by [Lombiq Technologies](https://lombiq.com/). Commercial-grade support is available through Lombiq.

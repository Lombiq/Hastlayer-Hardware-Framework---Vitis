# Hastlayer Hardware Framework - Xilinx Vitis

Contains:

- `opencl`: C++ OpenCL sample project.
- `platforms`: The custom hardware descriptions required to compile for specific devices (e.g. Trenz Electronic TE0715-04-30-1C).
- `rtl`: VHDL template project for building OpenCL binaries with Hastlayer.
- `Hast.Vitis.Abstractions.HardwareFramework.csproj`: A container project that helps importing the files from `rtl` into your .Net Core project. It's a dependency of `Hast.Vitis.Abstractions`.

When the project file is referenced the _rtl/src_ and the _platforms_ directories are copied into the build root's HardwareFramework directory.  

The _rtl_ directory contains Makefiles which you could feasibly use to build projects C++ style. More importantly we use them to track changes when translating a new version of the C++ prototype implementations into the C# build providers. 

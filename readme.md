# cmake-nRF5x

Cmake script for projects targeting Nordic Semiconductor nRF5x series devices using the GCC toolchain from ARM.

# Dependencies

The script makes use of the following dependencies which can be downloaded by the script:

- nRF5x SDK by Nordic Semiconductor - SoC specific drivers and libraries (also includes a lot of examples)
- nRF5x mesh SDK by Nordic Semiconductor - A mesh SDK which uses CMake, and is used for its CMake configuration

The script depends on the following external dependencies:

- [JLink](https://www.segger.com/downloads/jlink/#J-LinkSoftwareAndDocumentationPack) by Segger - interface software for the JLink familiy of programmers
- [Nordic command line tools](https://www.nordicsemi.com/Software-and-tools/Development-Tools/nRF-Command-Line-Tools/Download#infotabs) (`nrfjprog` and `mergehex`) by Nordic Semiconductor - Wrapper utility around JLink
- [Nordic nrfutil](https://infocenter.nordicsemi.com/index.jsp?topic=%2Fug_nrfutil%2FUG%2Fnrfutil%2Fnrfutil_intro.html) by Nordic Semiconductor - a utility for generating DFU packages. Currently requires installing with `pip install nrfutil --pre` to install the prerelease 6.0.0 version.  
- [ARM GNU Toolchain](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads) by ARM and the GCC Team - compiler toolchain for embedded (= bare metal) ARM chips. On a Mac, can be installed with homebrew:
    ```shell
    brew tap ArmMbed/homebrew-formulae
    brew install arm-none-eabi-gcc
    ```

# Setup

The script depends on the nRF5 SDK, and the nRF5 mesh SDK. It can download these dependencies for you.

After setting up your CMakeLists.txt as described below, or using the example project, to download the dependencies run:

```shell
cmake -Bcmake-build-download -G "Unix Makefiles"
cmake --build cmake-build-download/ --target download
cmake -Bcmake-build-debug -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Debug
```

This will download the dependencies and then re-run cmake ready for building

## Creating your own project

_Note_: You can also follow the tutorial on the [NRB Tech blog](hhttps://nrbtech.io/blog/2020/1/4/using-cmake-for-nordic-nrf52-projects).

1. Download this repo (or add as submodule) to the directory `cmake-nRF5x` in your project

1. It is recommended that you copy the example `CMakeLists.txt` and `src/CMakeLists.txt` into your project, but you can inspect these and change the structure or copy as you need

1. Search the SDK `example` directory for a `sdk_config.h`, `main.c` and a linker script (normally named `<project_name>_gcc_<chip familly>.ld`) that fits your chip and project needs

1. Copy the `sdk_config.h` and the project `main.c` into a new directory `src`. Modify them as required for your project

1. Copy the linker script from the example's `armgcc` directory into your project

1. Adjust the example `CMakeList.txt` files for your requirements, and to point at your source files

    _Note_: By default, C and assembly languages are enabled. You can add C++ with `enable_language(C ASM)`
	
1. Optionally add additional libraries:

    Many drivers and libraries are wrapped with macros to include them in your project, see `includes/libraries.cmake`. If you need one isn't implemented, please create an issue or pull request. 

    To include BLE services, use `nRF5x_addBLEService(<service name>)`.

# Build

After setup you can use cmake as usual:

1. Generate the build files:

	```shell
	cmake -Bcmake-build-debug -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Debug
	```

2. Build your app:

	```shell
	cmake --build cmake-build-debug --target <your target name>
	```

There are also other targets available:

- `merge_<your target name>`: Builds the application and merges the SoftDevice
- `secure_bootloader_<your target name>`: Builds the secure bootloader for this target
- `uECC`: Builds the uECC library
- `bl_merge_<your target name>`: Builds your application and the secure bootloader, merges these and the softdevice
- `pkg_<your target name>`: Builds and packages your application for DFU
- `pkg_bl_sd_<your target name>`: Builds and packages your application, the SoftDevice, and bootloader for DFU.


# Flash

In addition to the build targets the script adds some support targets:

- `FLASH_SOFTDEVICE`: Flashes the nRF softdevice to the SoC (typically done only once for each SoC if not using DFU flash target)
- `flash_<your target name>`: Builds and flashes your application
- `flash_bl_merge_<your target name>`: Builds the bootloader and application, and flashes both and the softdevice
- `FLASH_ERASE`: Erases the SoC flash

# JLink Applications

To start the gdb server and RTT terminal, build the target `START_JLINK_ALL`:

```shell
cmake --build "cmake-build" --target START_JLINK_ALL
```

There are also the targets `START_JLINK_RTT` and `START_JLINK_GDBSERVER` to start these independently.

# License

MIT for the `CMake_nRF5x.cmake` file. 

Please note that the nRF5x SDK and mesh SDK by Nordic Semiconductor are covered by their own licenses and shouldn't be re-distributed. 

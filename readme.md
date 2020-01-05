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
    ```commandline
    brew tap ArmMbed/homebrew-formulae
    brew install arm-none-eabi-gcc
    ```

# Setup

The script depends on the nRF5 SDK, and the nRF5 mesh SDK. It can download these dependencies for you.

After setting up your CMakeLists.txt as described below, or using the example project, to download the dependencies run:

```
cmake -Bcmake-build-download -G "Unix Makefiles"
cmake --build cmake-build-download/ --target download
cmake -Bcmake-build-debug -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Debug
```

This will download the dependencies and then re-run cmake ready for building

## Creating your own project

1. Download this repo (or add as submodule) to the directory `cmake-nRF5x` in your project

1. It is recommended that you copy the example `CMakeLists.txt` and `src/CMakeLists.txt` into your project, but you can inspect these and change the structure or copy as you need

1. Search the SDK `example` directory for a `sdk_config.h`, `main.c` and a linker script (normally named `<project_name>_gcc_<chip familly>.ld`) that fits your chip and project needs

1. Copy the `sdk_config.h` and the project `main.c` into a new directory `src`. Modify them as required for your project

1. Copy the linker script from the example's `armgcc` directory into your project

1. Adjust the example `CMakeList.txt` files for your requirements, and to point at your source files

_Note_: By default, C and assembly languages are enabled. You can add C++ with `enable_language(C ASM)`
	
1. Optionally add additional libraries:

Many drivers and libraries are wrapped with macros, but if you need to add one that isn't already defined please create a pull request on `includes/libraries.cmake`

To include BLE services, use `nRF5x_addBLEService(<service name>)`.

# Build

After setup you can use cmake as usual:

1. Generate the actual build files (out-of-source builds are strongly recomended):

	```commandline
	cmake -H. -B"cmake-build" -G "Unix Makefiles"
	```

2. Build your app:

	```commandline
	cmake --build "cmake-build" --target <your project name>
	```

# Flash

In addition to the build target (named like your project) the script adds some support targets:

`FLASH_SOFTDEVICE` To flash a nRF softdevice to the SoC (typically done only once for each SoC)

```commandline
cmake --build "cmake-build" --target FLASH_SOFTDEVICE
```

`FLASH_<your project name>` To flash your application (this will also rebuild your App first)

```commandline
cmake --build "cmake-build" --target FLASH_<your project name>
```

`FLASH_ERASE` To completely erase the SoC flash

```commandline
cmake --build "cmake-build" --target FLASH_ERASE
```

# JLink Applications

To start the gdb server and RTT terminal, build the target `START_JLINK`:

```commandline
cmake --build "cmake-build" --target START_JLINK
```

# License

MIT for the `CMake_nRF5x.cmake` file. 

Please note that the nRF5x SDK by Nordic Semiconductor is covered by it's own license and shouldn't be re-distributed. 

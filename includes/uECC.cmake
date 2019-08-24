cmake_minimum_required(VERSION 3.7.0)

set(cortex-m0_uECC "nf")
set(cortex-m4_uECC "nf")
set(cortex-m4f_uECC "hf")

if(NOT DEFINED ${ARCH}_uECC)
    message(FATAL_ERROR  "The uECC type is not found for the arch ${ARCH}, check uECC.cmake for missing arch defs")
endif()

string(SUBSTRING ${PLATFORM} 0 5 uECC_PREFIX)

include(${CMAKE_CURRENT_LIST_DIR}/makefile_vars.cmake)

include(ExternalProject)
ExternalProject_Add(uECC
    GIT_REPOSITORY    https://github.com/kmackay/micro-ecc
    GIT_TAG           master
    SOURCE_DIR        "${SDK_ROOT}/external/micro-ecc/micro-ecc"
    BINARY_DIR        "${CMAKE_BINARY_DIR}/uecc-build"
    BUILD_COMMAND     $(MAKE) -C ${SDK_ROOT}/external/micro-ecc/${uECC_PREFIX}${${ARCH}_uECC}_armgcc/armgcc/ ${MAKEFILE_VARS}
    CONFIGURE_COMMAND ""
    INSTALL_COMMAND   ""
    TEST_COMMAND      ""
)
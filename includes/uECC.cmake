cmake_minimum_required(VERSION 3.7.0)

set(cortex-m0_uECC "nf")
set(cortex-m4_uECC "nf")
set(cortex-m4f_uECC "hf")

if(NOT DEFINED ${ARCH}_uECC)
    message(FATAL_ERROR  "The uECC type is not found for the arch ${ARCH}, check uECC.cmake for missing arch defs")
endif()

string(SUBSTRING ${PLATFORM} 0 5 uECC_PREFIX)

include(${CMAKE_CURRENT_LIST_DIR}/makefile_vars.cmake)

set(uECC_PATH "${SDK_ROOT}/external/micro-ecc/${uECC_PREFIX}${${ARCH}_uECC}_armgcc/armgcc")
set(uECC_OP_FILE "${uECC_PATH}/micro_ecc_lib_${uECC_PREFIX}.a")
add_custom_target(uECC DEPENDS "${uECC_OP_FILE}")
add_custom_command(OUTPUT "${uECC_OP_FILE}"
        COMMAND $(MAKE) -C "${uECC_PATH}" ${MAKEFILE_VARS}
        VERBATIM)
set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_MAKE_CLEAN_FILES
        "${uECC_PATH}/_build"
        )
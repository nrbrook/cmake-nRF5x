cmake_minimum_required(VERSION 3.5.0)

include(${CMAKE_CURRENT_LIST_DIR}/uECC.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/makefile_vars.cmake)

# taken from https://github.com/NordicSemiconductor/pc-nrfutil

set(nRF51xxx_FAMILY NRF51)
set(nRF52832_FAMILY NRF52)
set(nRF52832-QFAB_FAMILY NRF52QFAB)
set(nRF52810_FAMILY NRF52810)
set(nRF52840_FAMILY NRF52840)

set(s112_6.0.0_FWID 0xA7)
set(s112_6.1.0_FWID 0xB0)
set(s112_6.1.1_FWID 0xB8)
set(s112_7.0.0_FWID 0xC4)
set(s113_7.0.0_FWID 0xC3)
set(s130_1.0.0_FWID 0x67)
set(s130_2.0.0_FWID 0x80)
set(s132_2.0.0_FWID 0x81)
set(s130_2.0.1_FWID 0x87)
set(s132_2.0.1_FWID 0x88)
set(s212_2.0.1_FWID 0x8D)
set(s332_2.0.1_FWID 0x8E)
set(s132_3.0.0_FWID 0x8C)
set(s132_3.1.0_FWID 0x91)
set(s132_4.0.0_FWID 0x95)
set(s132_4.0.2_FWID 0x98)
set(s132_4.0.3_FWID 0x99)
set(s132_4.0.4_FWID 0x9E)
set(s132_4.0.5_FWID 0x9F)
set(s212_4.0.5_FWID 0x93)
set(s332_4.0.5_FWID 0x94)
set(s132_5.0.0_FWID 0x9D)
set(s212_5.0.0_FWID 0x9C)
set(s332_5.0.0_FWID 0x9B)
set(s132_5.1.0_FWID 0xA5)
set(s132_6.0.0_FWID 0xA8)
set(s132_6.1.0_FWID 0xAF)
set(s132_6.1.1_FWID 0xB7)
set(s132_7.0.0_FWID 0xC2)
set(s140_6.0.0_FWID 0xA9)
set(s140_6.1.0_FWID 0xAE)
set(s140_6.1.1_FWID 0xB6)
set(s140_7.0.0_FWID 0xC1)
set(s212_6.1.1_FWID 0xBC)
set(s332_6.1.1_FWID 0xBA)
set(s340_6.1.1_FWID 0xB9)

set(SECURE_BOOTLOADER_SRC_DIR "${SDK_ROOT}/examples/dfu/secure_bootloader/${BOARD}_ble/armgcc")

if(NOT DEFINED ${IC}_FAMILY)
    message(FATAL_ERROR "The family is not found for the IC ${IC}, define a valid IC or check secure_bootloader.cmake for missing IC defs")
endif()
set(BL_OPT_FAMILY ${${IC}_FAMILY})
message("-- IC: ${IC}")
message("-- Previous softdevices: ${PREVIOUS_SOFTDEVICES}")

# set to hw version e.g. 52 for nrf52
string(SUBSTRING ${PLATFORM} 3 2 BL_OPT_HW_VERSION)

if(NOT DEFINED ${SOFTDEVICE}_FWID)
    message(FATAL_ERROR "The FWID is not found for the soft device ${SOFTDEVICE}, check secure_bootloader.cmake for missing softdevice defs")
endif()
set(BL_OPT_SD_ID ${${SOFTDEVICE}_FWID})

macro(nRF5x_get_BL_OPT_SD_REQ PREVIOUS_SOFTDEVICES)
    unset(BL_OPT_SD_REQ)
    set(ids_list ${BL_OPT_SD_ID})
    foreach(sd ${PREVIOUS_SOFTDEVICES})
        if(NOT DEFINED ${sd}_FWID)
            message(FATAL_ERROR "The FWID is not found for the previous soft device ${sd}, check secure_bootloader.cmake for missing softdevice defs")
        endif()
        list(APPEND ids_list ${${sd}_FWID})
    endforeach()
    list(REMOVE_DUPLICATES ids_list)

    list(JOIN ids_list "," BL_OPT_SD_REQ)
endmacro()

# add the secure bootloader target.
# also sets BL_OPT_FAMILY, BL_OPT_SD_ID, BL_OPT_SD_REQ for use with nrfutil params
function(nRF5x_addSecureBootloader EXECUTABLE_NAME PUBLIC_KEY_C_PATH BUILD_FLAGS)
    set(OP_FILE "${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_NAME}_bootloader.hex")
    add_custom_target(secure_bootloader_${EXECUTABLE_NAME} DEPENDS "${OP_FILE}")
    add_custom_command(OUTPUT "${OP_FILE}"
            COMMAND ${CMAKE_COMMAND} -E copy "${PUBLIC_KEY_C_PATH}" "${SDK_ROOT}/examples/dfu/dfu_public_key.c"
            COMMAND $(MAKE) -C "${SECURE_BOOTLOADER_SRC_DIR}" ${MAKEFILE_VARS} ${BUILD_FLAGS}
            COMMAND ${CMAKE_COMMAND} -E copy "${SECURE_BOOTLOADER_SRC_DIR}/_build/*.hex" "${OP_FILE}"
            DEPENDS uECC
            )
    set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_MAKE_CLEAN_FILES
            "${SECURE_BOOTLOADER_SRC_DIR}/_build"
            )
endfunction()
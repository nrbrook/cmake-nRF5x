cmake_minimum_required(VERSION 3.6)
set(nRF5_SDK_VERSION "nRF5_SDK_15.3.0_59ac345" CACHE STRING "nRF5 SDK")

# check if all the necessary tools paths have been provided.
if (NOT SDK_ROOT)
    message(FATAL_ERROR "The path to the nRF5 SDK (SDK_ROOT) must be set.")
endif ()

if (NOT NRFJPROG)
    message(FATAL_ERROR "The path to the nrfjprog utility (NRFJPROG) must be set.")
endif ()

if (NOT MERGEHEX)
    message(FATAL_ERROR "The path to the mergehex utility (MERGEHEX) must be set.")
endif ()

if (NOT NRFUTIL)
    message(FATAL_ERROR "The path to the nrfutil utility (NRFUTIL) must be set.")
endif ()

if(NOT CMAKE_CONFIG_DIR)
    message(FATAL_ERROR "The path to the CMake config (CMAKE_CONFIG_DIR) must be set.")
endif()

# must be set in file (not macro) scope (in macro would point to parent CMake directory)
set(DIR_OF_nRF5x_CMAKE ${CMAKE_CURRENT_LIST_DIR})

find_program(PATCH_EXECUTABLE patch
        DOC "Path to `patch` command line executable")

set(MESH_PATCH_COMMAND "")
if (PATCH_EXECUTABLE)
    set(MESH_PATCH_FILE "${DIR_OF_nRF5x_CMAKE}/sdk/nrf5SDKforMeshv320src.patch")
    if (EXISTS "${MESH_PATCH_FILE}")
        set(MESH_PATCH_COMMAND patch -p1 -d ${CMAKE_CONFIG_DIR}/../ -i ${MESH_PATCH_FILE})
    else ()
        set(MESH_PATCH_COMMAND "")
    endif()
else ()
    message(WARNING
            "Could not find `patch` executable. \
        Automatic patching of the nRF5 mesh SDK not supported. \
        See ${PATCH_FILE} for diff to apply.")
endif (PATCH_EXECUTABLE)

macro(add_download_target name)
    if(TARGET download)
        add_dependencies(download ${name})
    else()
        add_custom_target(download DEPENDS ${name})
    endif()
endmacro()

if(NOT EXISTS ${SDK_ROOT}/license.txt)
    include(ExternalProject)

    string(REGEX REPLACE "(nRF5)([1]?_SDK_)([0-9]*).*" "\\1\\2v\\3.x.x" SDK_DIR ${nRF5_SDK_VERSION})
    set(nRF5_SDK_URL "https://developer.nordicsemi.com/nRF5_SDK/${SDK_DIR}/${nRF5_SDK_VERSION}.zip")

    ExternalProject_Add(nRF5_SDK
            PREFIX "${nRF5_SDK_VERSION}"
            TMP_DIR "${CMAKE_CURRENT_BINARY_DIR}/${nRF5_SDK_VERSION}"
            SOURCE_DIR "${SDK_ROOT}/"
            DOWNLOAD_DIR "${SDK_ROOT}/zip"
            DOWNLOAD_NAME "${nRF5_SDK_VERSION}.zip"
            URL ${nRF5_SDK_URL}
            # No build or configure commands
            CONFIGURE_COMMAND ""
            BUILD_COMMAND ""
            INSTALL_COMMAND ""
            LOG_DOWNLOAD ON
            EXCLUDE_FROM_ALL ON)
    add_download_target(nRF5_SDK)
endif()

if(NOT EXISTS ${CMAKE_CONFIG_DIR}/Toolchain.cmake)
    include(ExternalProject)
    set(nRF5_MESH_SDK_URL "https://www.nordicsemi.com/-/media/Software-and-other-downloads/SDKs/nRF5-SDK-for-Mesh/nrf5SDKforMeshv320src.zip")

    ExternalProject_Add(nRF5_MESH_SDK
            PREFIX "nRF5_mesh_sdk"
            TMP_DIR "${CMAKE_CURRENT_BINARY_DIR}/nRF5_mesh_sdk"
            SOURCE_DIR "${CMAKE_CONFIG_DIR}/../"
            DOWNLOAD_DIR "${CMAKE_CURRENT_BINARY_DIR}/nRF5_mesh_sdk/zip"
            DOWNLOAD_NAME "meshsdk.zip"
            URL ${nRF5_MESH_SDK_URL}
            PATCH_COMMAND ${MESH_PATCH_COMMAND}
            # No build or configure commands
            CONFIGURE_COMMAND ""
            BUILD_COMMAND ""
            INSTALL_COMMAND ""
            LOG_DOWNLOAD ON
            EXCLUDE_FROM_ALL ON)
    add_download_target(nRF5_MESH_SDK)
endif()

if(TARGET download)
    message(WARNING "Run the 'download' target to download dependencies")
    return()
endif()

if (NOT BUILD_HOST)
    set(CMAKE_EXECUTABLE_SUFFIX ".elf")
    set(BUILD_SHARED_LIBS OFF)
    set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS "")
else ()
    message(STATUS "Building for HOST")
    include("${CMAKE_CONFIG_DIR}/UnitTest.cmake")
    include("${CMAKE_CONFIG_DIR}/Coverage.cmake")
    include("${CMAKE_CONFIG_DIR}/UBSAN.cmake")
endif ()

# Export compilation commands to .json file (used by clang-complete backends)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Needed tools for generating documentation and serial PyACI
find_package(PythonInterp)
find_package(Doxygen)
find_program(DOT_EXECUTABLE "dot" PATHS ENV PATH)
find_program(MSCGEN_EXECUTABLE "mscgen" PATHS ENV PATH)

if (NOT BUILD_HOST)
    include("${CMAKE_CONFIG_DIR}/Nrfjprog.cmake")
endif ()

macro(nRF5x_setup)
    if(nRF5x_setup_complete)
        return()
    endif()
    set(nRF5x_setup_complete TRUE)

    include("${CMAKE_CONFIG_DIR}/Toolchain.cmake")
    include("${CMAKE_CONFIG_DIR}/Platform.cmake")
    include("${CMAKE_CONFIG_DIR}/SoftDevice.cmake")
    include("${CMAKE_CONFIG_DIR}/FindDependency.cmake")
    include("${CMAKE_CONFIG_DIR}/FindSDK.cmake")

    include("${CMAKE_CONFIG_DIR}/BuildType.cmake")
    include("${CMAKE_CONFIG_DIR}/Board.cmake")
    include("${CMAKE_CONFIG_DIR}/PCLint.cmake")
    include("${CMAKE_CONFIG_DIR}/GenerateSESProject.cmake")

    include("${CMAKE_CONFIG_DIR}/sdk/${nRF5_SDK_VERSION}.cmake")
    include("${CMAKE_CONFIG_DIR}/platform/${PLATFORM}.cmake")
    include("${CMAKE_CONFIG_DIR}/softdevice/${SOFTDEVICE}.cmake")
    include("${CMAKE_CONFIG_DIR}/board/${BOARD}.cmake")

    message(STATUS "SDK: ${nRF5_SDK_VERSION}")
    message(STATUS "Platform: ${PLATFORM}")
    message(STATUS "Arch: ${${PLATFORM}_ARCH}")
    message(STATUS "SoftDevice: ${SOFTDEVICE}")
    message(STATUS "Board: ${BOARD}")

    set(ARCH ${${PLATFORM}_ARCH})

    enable_language(C ASM)

    add_compile_options(${${ARCH}_DEFINES})

    add_link_options(-u _printf_float)

    include(${DIR_OF_nRF5x_CMAKE}/includes/secure_bootloader.cmake)

    # adds target for erasing and flashing the board with a softdevice
    add_custom_target(FLASH_SOFTDEVICE ALL
            COMMAND ${NRFJPROG} --program ${${SOFTDEVICE}_HEX_FILE} -f nrf52 --sectorerase
            COMMAND sleep 0.5s
            COMMAND ${NRFJPROG} --reset -f nrf52
            COMMENT "flashing SoftDevice"
            )

    add_custom_target(FLASH_ERASE ALL
            COMMAND ${NRFJPROG} --eraseall -f nrf52
            COMMENT "erasing flashing"
            )

    if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Darwin")
        set(TERMINAL "open")
    elseif(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
        set(TERMINAL "sh")
    else()
        set(TERMINAL "gnome-terminal")
    endif()

    add_custom_target(START_JLINK ALL
            COMMAND ${TERMINAL} "${DIR_OF_nRF5x_CMAKE}/runJLinkGDBServer"
            COMMAND ${TERMINAL} "${DIR_OF_nRF5x_CMAKE}/runJLinkExe"
            COMMAND sleep 2s
            COMMAND ${TERMINAL} "${DIR_OF_nRF5x_CMAKE}/runJLinkRTTClient"
            COMMENT "started JLink commands"
            )

endmacro()

# adds a target for comiling and flashing an executable
macro(nRF5x_addExecutable EXECUTABLE_NAME SOURCE_FILES INCLUDE_DIRECTORIES)
    list(REMOVE_DUPLICATES SOURCE_FILES)
    list(REMOVE_DUPLICATES INCLUDE_DIRECTORIES)

    add_executable(${EXECUTABLE_NAME} ${SOURCE_FILES})

    target_include_directories(${EXECUTABLE_NAME} PUBLIC ${INCLUDE_DIRECTORIES})

    set_target_link_options(${EXECUTABLE_NAME}
            ${CMAKE_CURRENT_SOURCE_DIR}/linker/${PLATFORM}_${SOFTDEVICE})

    target_compile_definitions(${EXECUTABLE_NAME} PUBLIC
            ${USER_DEFINITIONS}
            -DUSE_APP_CONFIG
            ${${PLATFORM}_DEFINES}
            ${${SOFTDEVICE}_DEFINES}
            ${${BOARD}_DEFINES})

    create_hex(${EXECUTABLE_NAME})
    add_flash_target(${EXECUTABLE_NAME})

    add_ses_project(${EXECUTABLE_NAME})
endmacro()

function(nRF5x_addBootloaderMergeTarget EXECUTABLE_NAME VERSION_STRING PRIVATE_KEY PREVIOUS_SOFTDEVICES APP_VALIDATION SD_VALIDATION BOOTLOADER_VERSION)
    if(NOT TARGET secure_bootloader_${EXECUTABLE_NAME})
        message(FATAL_ERROR "You must call nRF5x_addSecureBootloader and provide the public key before calling nRF5x_addBootloaderMergeTarget")
    endif()
    nRF5x_get_BL_OPT_SD_REQ(${PREVIOUS_SOFTDEVICES})
    set(OP_FILE "${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_NAME}_bl_merged.hex")
    add_custom_target(bl_merge_${EXECUTABLE_NAME} DEPENDS "${OP_FILE}")
    add_custom_command(OUTPUT "${OP_FILE}"
            COMMAND ${NRFUTIL} settings generate --family ${BL_OPT_FAMILY} --application "${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_NAME}.hex" --application-version-string "${VERSION_STRING}" --app-boot-validation ${APP_VALIDATION} --bootloader-version ${BOOTLOADER_VERSION} --bl-settings-version 2 --softdevice "${${SOFTDEVICE}_HEX_FILE}" --sd-boot-validation ${SD_VALIDATION} --key-file "${PRIVATE_KEY}" "${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_NAME}_bootloader_setting.hex"
            COMMAND ${MERGEHEX} -m "${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_NAME}_bootloader.hex" "${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_NAME}_bootloader_setting.hex" "${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_NAME}_merged.hex" -o "${OP_FILE}"
            DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_NAME}_merged.hex"
            DEPENDS secure_bootloader_${EXECUTABLE_NAME}
            DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_NAME}_bootloader.hex"
            VERBATIM)
endfunction()

function(_addDFUPackageTarget INCLUDE_BL_SD EXECUTABLE_NAME VERSION_STRING PRIVATE_KEY PREVIOUS_SOFTDEVICES APP_VALIDATION SD_VALIDATION BOOTLOADER_VERSION)
    if(NOT TARGET secure_bootloader_${EXECUTABLE_NAME})
        message(FATAL_ERROR "You must call nRF5x_addSecureBootloader and provide the public key before calling _nRF5x_addDFUPackageTarget")
    endif()

    nRF5x_get_BL_OPT_SD_REQ(${PREVIOUS_SOFTDEVICES})
    set(PKG_OPT --sd-req ${BL_OPT_SD_REQ} --hw-version ${BL_OPT_HW_VERSION} --application "${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_NAME}.hex" --application-version-string "${VERSION_STRING}" --app-boot-validation ${APP_VALIDATION} --key-file "${PRIVATE_KEY}")
    set(DEPENDS ${EXECUTABLE_NAME})
    if(${INCLUDE_BL_SD})
        list(APPEND PKG_OPT --sd-id ${BL_OPT_SD_ID} --bootloader "${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_NAME}_bootloader.hex" --bootloader-version ${BOOTLOADER_VERSION} --softdevice "${${SOFTDEVICE}_HEX_FILE}" --sd-boot-validation ${SD_VALIDATION})
        list(APPEND DEPENDS secure_bootloader_${EXECUTABLE_NAME})
        set(TARGET_PREFIX pkg_bl_sd_)
        set(FILENAME_SUFFIX _bl_sd_app)
    else()
        set(TARGET_PREFIX pkg_)
        set(FILENAME_SUFFIX _app)
    endif()
    set(OP_FILE "${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_NAME}${FILENAME_SUFFIX}.zip")
    add_custom_target(${TARGET_PREFIX}${EXECUTABLE_NAME} DEPENDS "${OP_FILE}")
    add_custom_command(OUTPUT "${OP_FILE}"
            COMMAND ${NRFUTIL} pkg generate ${PKG_OPT} ${OP_FILE}
            DEPENDS ${DEPENDS}
            VERBATIM)
endfunction()

function(nRF5x_addDFU_BL_SD_APP_PkgTarget EXECUTABLE_NAME VERSION_STRING PRIVATE_KEY PREVIOUS_SOFTDEVICES APP_VALIDATION SD_VALIDATION BOOTLOADER_VERSION)
    _addDFUPackageTarget(TRUE ${EXECUTABLE_NAME} ${VERSION_STRING} ${PRIVATE_KEY} ${PREVIOUS_SOFTDEVICES} ${APP_VALIDATION} ${SD_VALIDATION} ${BOOTLOADER_VERSION})
endfunction()

function(nRF5x_addDFU_APP_PkgTarget EXECUTABLE_NAME VERSION_STRING PRIVATE_KEY PREVIOUS_SOFTDEVICES APP_VALIDATION)
    _addDFUPackageTarget(FALSE ${EXECUTABLE_NAME} ${VERSION_STRING} ${PRIVATE_KEY} ${PREVIOUS_SOFTDEVICES} ${APP_VALIDATION} "" "")
endfunction()

# adds mutex lib
macro(nRF5x_addMutex)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/mutex"
            )

endmacro()

# adds app error library
macro(nRF5x_addAppError)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/util"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/util/app_error.c"
            "${SDK_ROOT}/components/libraries/util/app_error_weak.c"
            )

endmacro()

# adds power management lib
macro(nRF5x_addPowerMgmt)
    nRF5x_addMutex()

    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/pwr_mgmt"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/pwr_mgmt/nrf_pwr_mgmt.c"
            )

endmacro()

# adds balloc lib
macro(nRF5x_addBalloc)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/balloc"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/balloc/nrf_balloc.c"
            )

endmacro()

# adds atomic fifo lib
macro(nRF5x_addAtomicFIFO)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/atomic_fifo"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/atomic_fifo/nrf_atfifo.c"
            )

endmacro()

# adds atomic flags lib
macro(nRF5x_addAtomicFlags)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/atomic_flags"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/atomic_flags/nrf_atflags.c"
            )

endmacro()

# adds memobj lib
macro(nRF5x_addMemobj)
    nRF5x_addBalloc()

    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/memobj"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/memobj/nrf_memobj.c"
            )

endmacro()

# adds dynamic memory manager
macro(nRF5x_addMemManager)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/mem_manager"
    )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/mem_manager/mem_manager.c"
    )

endmacro()

# adds app-level FDS (flash data storage) library
macro(nRF5x_addFDS)
    nRF5x_addAtomicFIFO()

    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/fds"
            "${SDK_ROOT}/components/libraries/fstorage"
            "${SDK_ROOT}/components/libraries/experimental_section_vars"
    )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/fds/fds.c"
            "${SDK_ROOT}/components/libraries/fstorage/nrf_fstorage.c"
            "${SDK_ROOT}/components/libraries/fstorage/nrf_fstorage_sd.c"
            "${SDK_ROOT}/components/libraries/fstorage/nrf_fstorage_nvmc.c"
    )
endmacro()

# adds ring buffer library
macro(nRF5x_addRingBuf)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/ringbuf"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/ringbuf/nrf_ringbuf.c"
            )
endmacro()

# adds strerror library
macro(nRF5x_addStrError)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/strerror"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/strerror/nrf_strerror.c"
            )
endmacro()

macro(nRF5x_addSeggerRTT)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/external/segger_rtt"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/external/segger_rtt/SEGGER_RTT.c"
            )
endmacro()

# adds log library
macro(nRF5x_addLog)
    nRF5x_addRingBuf()

    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/external/fprintf"
            "${SDK_ROOT}/components/libraries/log/include"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/external/fprintf/nrf_fprintf.c"
            "${SDK_ROOT}/external/fprintf/nrf_fprintf_format.c"
            "${SDK_ROOT}/components/libraries/log/src/nrf_log_str_formatter.c"
            "${SDK_ROOT}/components/libraries/log/src/nrf_log_frontend.c"
            "${SDK_ROOT}/components/libraries/log/src/nrf_log_default_backends.c"
            "${SDK_ROOT}/components/libraries/log/src/nrf_log_backend_flash.c"
            "${SDK_ROOT}/components/libraries/log/src/nrf_log_backend_rtt.c"
            "${SDK_ROOT}/components/libraries/log/src/nrf_log_backend_serial.c"
            "${SDK_ROOT}/components/libraries/log/src/nrf_log_backend_uart.c"
            )
endmacro()

# adds aSAADC driver
macro(nRF5x_addSAADC)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/modules/nrfx/drivers/include"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/modules/nrfx/drivers/src/nrfx_saadc.c"
            )
endmacro()

# adds PPI driver
macro(nRF5x_addPPI)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/modules/nrfx/drivers/include"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/modules/nrfx/drivers/src/nrfx_ppi.c"
            )
endmacro()

# adds timer driver
macro(nRF5x_addTimer)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/modules/nrfx/drivers/include"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/modules/nrfx/drivers/src/nrfx_timer.c"
            )
endmacro()

# adds gpiote driver
macro(nRF5x_addGPIOTE)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/modules/nrfx/drivers/include"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/modules/nrfx/drivers/src/nrfx_gpiote.c"
            )
endmacro()

# adds app-level scheduler library
macro(nRF5x_addAppScheduler)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/scheduler"
    )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/scheduler/app_scheduler.c"
            )

endmacro()

# adds app-level FIFO libraries
macro(nRF5x_addAppFIFO)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/fifo"
    )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/fifo/app_fifo.c"
            )

endmacro()

# adds app-level Timer libraries
macro(nRF5x_addAppTimer)
    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/timer/app_timer.c"
            )
endmacro()

# adds app-level UART libraries
macro(nRF5x_addAppUART)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/integration/nrfx/legacy"
            "${SDK_ROOT}/components/libraries/uart"
    )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/integration/nrfx/legacy/nrf_drv_uart.c"
            "${SDK_ROOT}/components/libraries/uart/app_uart_fifo.c"
            )

endmacro()

# adds app-level Button library
macro(nRF5x_addAppButton)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/button"
    )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/button/app_button.c"
            )

endmacro()

# adds BSP (board support package) library
macro(nRF5x_addBSP WITH_BLE_BTN WITH_ANT_BTN WITH_NFC)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/bsp"
    )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/bsp/bsp.c"
    )

    if (${WITH_BLE_BTN})
        list(APPEND SOURCE_FILES
                "${SDK_ROOT}/components/libraries/bsp/bsp_btn_ble.c"
        )
    endif ()

    if (${WITH_ANT_BTN})
        list(APPEND SOURCE_FILES
                "${SDK_ROOT}/components/libraries/bsp/bsp_btn_ant.c"
        )
    endif ()

    if (${WITH_NFC})
        list(APPEND SOURCE_FILES
                "${SDK_ROOT}/components/libraries/bsp/bsp_nfc.c"
        )
    endif ()

endmacro()

macro(nRF5x_addSoftDeviceSupport)
    nRF5x_addMemobj()
    nRF5x_addStrError()
    nRF5x_addAppError()

    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/ble/common"
            "${SDK_ROOT}/components/softdevice/common"
            "${SDK_ROOT}/components/libraries/strerror"
            "${SDK_ROOT}/components/libraries/atomic"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/util/app_util_platform.c"
            "${SDK_ROOT}/components/libraries/experimental_section_vars/nrf_section_iter.c"
            "${SDK_ROOT}/components/libraries/atomic/nrf_atomic.c"
            "${SDK_ROOT}/components/softdevice/common/nrf_sdh_soc.c"
            "${SDK_ROOT}/components/softdevice/common/nrf_sdh_ble.c"
            "${SDK_ROOT}/components/softdevice/common/nrf_sdh.c"
            "${SDK_ROOT}/components/ble/common/ble_conn_state.c"
            "${SDK_ROOT}/components/ble/common/ble_conn_params.c"
            "${SDK_ROOT}/components/ble/common/ble_advdata.c"
            "${SDK_ROOT}/components/ble/common/ble_srv_common.c"
            )
endmacro()

# adds Bluetooth Low Energy GATT support library
macro(nRF5x_addBLEGATT)
    nRF5x_addSoftDeviceSupport()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/ble/nrf_ble_gatt"
    )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/ble/nrf_ble_gatt/nrf_ble_gatt.c"
    )
endmacro()

# adds Bluetooth Low Energy advertising support library
macro(nRF5x_addBLEAdvertising)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/ble/ble_advertising"
    )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/ble/ble_advertising/ble_advertising.c"
    )
endmacro()

macro(nRF5x_addBLELinkCtxManager)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/ble/ble_link_ctx_manager"
    )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/ble/ble_link_ctx_manager/ble_link_ctx_manager.c"
    )
endmacro()

# adds Bluetooth Low Energy advertising support library
macro(nRF5x_addBLEPeerManager)
    nRF5x_addFDS()
    nRF5x_addAtomicFlags()

    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/ble/peer_manager"
    )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/ble/peer_manager/auth_status_tracker.c"
            "${SDK_ROOT}/components/ble/peer_manager/gatt_cache_manager.c"
            "${SDK_ROOT}/components/ble/peer_manager/gatts_cache_manager.c"
            "${SDK_ROOT}/components/ble/peer_manager/id_manager.c"
            "${SDK_ROOT}/components/ble/peer_manager/nrf_ble_lesc.c"
            "${SDK_ROOT}/components/ble/peer_manager/peer_data_storage.c"
            "${SDK_ROOT}/components/ble/peer_manager/peer_database.c"
            "${SDK_ROOT}/components/ble/peer_manager/peer_id.c"
            "${SDK_ROOT}/components/ble/peer_manager/peer_manager.c"
            "${SDK_ROOT}/components/ble/peer_manager/peer_manager_handler.c"
            "${SDK_ROOT}/components/ble/peer_manager/pm_buffer.c"
            "${SDK_ROOT}/components/ble/peer_manager/security_dispatcher.c"
            "${SDK_ROOT}/components/ble/peer_manager/security_manager.c"
    )

endmacro()

# adds NFC library
macro(nRF5x_addNFC)
    # NFC includes
    list(APPEND INCLUDE_DIRS
         "${SDK_ROOT}/components/nfc/ndef/conn_hand_parser"
         "${SDK_ROOT}/components/nfc/ndef/conn_hand_parser/ac_rec_parser"
         "${SDK_ROOT}/components/nfc/ndef/conn_hand_parser/ble_oob_advdata_parser"
         "${SDK_ROOT}/components/nfc/ndef/conn_hand_parser/le_oob_rec_parser"
         "${SDK_ROOT}/components/nfc/ndef/connection_handover/ac_rec"
         "${SDK_ROOT}/components/nfc/ndef/connection_handover/ble_oob_advdata"
         "${SDK_ROOT}/components/nfc/ndef/connection_handover/ble_pair_lib"
         "${SDK_ROOT}/components/nfc/ndef/connection_handover/ble_pair_msg"
         "${SDK_ROOT}/components/nfc/ndef/connection_handover/common"
         "${SDK_ROOT}/components/nfc/ndef/connection_handover/ep_oob_rec"
         "${SDK_ROOT}/components/nfc/ndef/connection_handover/hs_rec"
         "${SDK_ROOT}/components/nfc/ndef/connection_handover/le_oob_rec"
         "${SDK_ROOT}/components/nfc/ndef/generic/message"
         "${SDK_ROOT}/components/nfc/ndef/generic/record"
         "${SDK_ROOT}/components/nfc/ndef/launchapp"
         "${SDK_ROOT}/components/nfc/ndef/parser/message"
         "${SDK_ROOT}/components/nfc/ndef/parser/record"
         "${SDK_ROOT}/components/nfc/ndef/text"
         "${SDK_ROOT}/components/nfc/ndef/uri"
         "${SDK_ROOT}/components/nfc/platform"
         "${SDK_ROOT}/components/nfc/t2t_lib"
         "${SDK_ROOT}/components/nfc/t2t_parser"
         "${SDK_ROOT}/components/nfc/t4t_lib"
         "${SDK_ROOT}/components/nfc/t4t_parser/apdu"
         "${SDK_ROOT}/components/nfc/t4t_parser/cc_file"
         "${SDK_ROOT}/components/nfc/t4t_parser/hl_detection_procedure"
         "${SDK_ROOT}/components/nfc/t4t_parser/tlv"
    )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/nfc/ndef/conn_hand_parser/ac_rec_parser/nfc_ac_rec_parser.c"
            "${SDK_ROOT}/components/nfc/ndef/conn_hand_parser/ble_oob_advdata_parser/nfc_ble_oob_advdata_parser.c"
            "${SDK_ROOT}/components/nfc/ndef/conn_hand_parser/le_oob_rec_parser/nfc_le_oob_rec_parser.c"
            "${SDK_ROOT}/components/nfc/ndef/connection_handover/ac_rec/nfc_ac_rec.c"
            "${SDK_ROOT}/components/nfc/ndef/connection_handover/ble_oob_advdata/nfc_ble_oob_advdata.c"
            "${SDK_ROOT}/components/nfc/ndef/connection_handover/ble_pair_lib/nfc_ble_pair_lib.c"
            "${SDK_ROOT}/components/nfc/ndef/connection_handover/ble_pair_msg/nfc_ble_pair_msg.c"
            "${SDK_ROOT}/components/nfc/ndef/connection_handover/common/nfc_common.c"
            "${SDK_ROOT}/components/nfc/ndef/connection_handover/ep_oob_rec/nfc_ep_oob_rec.c"
            "${SDK_ROOT}/components/nfc/ndef/connection_handover/hs_rec/nfc_hs_rec.c"
            "${SDK_ROOT}/components/nfc/ndef/connection_handover/le_oob_rec/nfc_le_oob_rec.c"
            "${SDK_ROOT}/components/nfc/ndef/generic/message/nfc_ndef_msg.c"
            "${SDK_ROOT}/components/nfc/ndef/generic/record/nfc_ndef_record.c"
            "${SDK_ROOT}/components/nfc/ndef/launchapp/nfc_launchapp_msg.c"
            "${SDK_ROOT}/components/nfc/ndef/launchapp/nfc_launchapp_rec.c"
            "${SDK_ROOT}/components/nfc/ndef/parser/message/nfc_ndef_msg_parser.c"
            "${SDK_ROOT}/components/nfc/ndef/parser/message/nfc_ndef_msg_parser_local.c"
            "${SDK_ROOT}/components/nfc/ndef/parser/record/nfc_ndef_record_parser.c"
            "${SDK_ROOT}/components/nfc/ndef/text/nfc_text_rec.c"
            "${SDK_ROOT}/components/nfc/ndef/uri/nfc_uri_msg.c"
            "${SDK_ROOT}/components/nfc/ndef/uri/nfc_uri_rec.c"
            "${SDK_ROOT}/components/nfc/platform/nfc_platform.c"
            "${SDK_ROOT}/components/nfc/t2t_parser/nfc_t2t_parser.c"
            "${SDK_ROOT}/components/nfc/t4t_parser/apdu/nfc_t4t_apdu.c"
            "${SDK_ROOT}/components/nfc/t4t_parser/cc_file/nfc_t4t_cc_file.c"
            "${SDK_ROOT}/components/nfc/t4t_parser/hl_detection_procedure/nfc_t4t_hl_detection_procedures.c"
            "${SDK_ROOT}/components/nfc/t4t_parser/tlv/nfc_t4t_tlv_block.c"
         )
endmacro()

macro(nRF5x_addBLEService NAME)
    nRF5x_addBLEAdvertising()
    nRF5x_addBLELinkCtxManager()
    nRF5x_addBLEGATT()

    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/ble/ble_services/${NAME}"
    )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/ble/ble_services/${NAME}/${NAME}.c"
            )

endmacro()

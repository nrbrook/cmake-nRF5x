cmake_minimum_required(VERSION 3.6)
set(nRF5_SDK_VERSION "nRF5_SDK_16.0.0_98a08e2" CACHE STRING "nRF5 SDK")

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

if(NOT IC)
    message(FATAL_ERROR "The chip (IC) must be set, e.g. \"nrf52832\"")
endif()

if(NOT SOFTDEVICE_TYPE)
    message(FATAL_ERROR "The softdevice type (SOFTDEVICE_TYPE) must be set, e.g. \"s132\"")
endif()
if(NOT SOFTDEVICE_VERSION)
    message(FATAL_ERROR "The softdevice version (SOFTDEVICE_VERSION) must be set, e.g. \"7.0.1\"")
endif()
set(SOFTDEVICE "${SOFTDEVICE_TYPE}_${SOFTDEVICE_VERSION}" CACHE STRING "${IC} SoftDevice")

# must be set in file (not macro) scope (in macro would point to parent CMake directory)
set(DIR_OF_nRF5x_CMAKE ${CMAKE_CURRENT_LIST_DIR})

include(${DIR_OF_nRF5x_CMAKE}/includes/libraries.cmake)

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

function(nRF5x_addFlashTarget targetName hexFile)
    add_custom_target(flash_${targetName}
            COMMAND ${PYTHON_EXECUTABLE} ${CMAKE_CONFIG_DIR}/nrfjprog.py "${hexFile}"
            USES_TERMINAL
            DEPENDS ${targetName})
endfunction()

# adds a target for comiling and flashing an executable
macro(nRF5x_addExecutable EXECUTABLE_NAME SOURCE_FILES INCLUDE_DIRECTORIES LINKER_FILE)
    set(_SOURCE_FILES ${SOURCE_FILES})
    set(_INCLUDE_DIRECTORIES ${INCLUDE_DIRECTORIES})
    list(APPEND _SOURCE_FILES
        "${${PLATFORM}_SOURCE_FILES}"
        "${${nRF5_SDK_VERSION}_SOURCE_FILES}"
    )
    list(APPEND _INCLUDE_DIRECTORIES
        "${${SOFTDEVICE}_INCLUDE_DIRS}"
        "${${PLATFORM}_INCLUDE_DIRS}"
        "${${BOARD}_INCLUDE_DIRS}"
        "${${nRF5_SDK_VERSION}_INCLUDE_DIRS}"
    )

    list(REMOVE_DUPLICATES _SOURCE_FILES)
    list(REMOVE_DUPLICATES _INCLUDE_DIRECTORIES)

    add_executable(${EXECUTABLE_NAME} ${_SOURCE_FILES})

    target_include_directories(${EXECUTABLE_NAME} PUBLIC ${_INCLUDE_DIRECTORIES})

    set_target_link_options(${EXECUTABLE_NAME} "${LINKER_FILE}")

    target_compile_definitions(${EXECUTABLE_NAME} PUBLIC
            ${USER_DEFINITIONS}
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

function(nRF5x_print_size EXECUTABLE_NAME include_softdevice include_bootloader)
    set(target_depend ${EXECUTABLE_NAME})
    set(options "")
    if(${include_softdevice})
        set(target_depend merge_${EXECUTABLE_NAME})
        list(APPEND options -s "${CMAKE_CURRENT_SOURCE_DIR}/linker/${PLATFORM}_${SOFTDEVICE}.ld")
    endif()
    if(${include_bootloader})
        set(target_depend bl_merge_${EXECUTABLE_NAME})
        list(APPEND options -b "${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_NAME}_bootloader.out")
    endif()
    add_custom_command(TARGET ${target_depend} POST_BUILD
            COMMAND ${DIR_OF_nRF5x_CMAKE}/includes/getSizes -r 65536 -l 524288 -f ${CMAKE_CURRENT_BINARY_DIR}/${EXECUTABLE_NAME}.elf ${options}
            VERBATIM)
endfunction()

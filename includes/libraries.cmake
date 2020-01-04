# adds mutex lib
macro(nRF5x_addMutex)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/mutex"
            )

endmacro()

# adds app error library
macro(nRF5x_addAppError)
    nRF5x_addLog()
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

macro(nRF5x_addStackInfo)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/stack_info"
            )
endmacro()

macro(nRF5x_addSHA256)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/sha256"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/sha256/sha256.c"
            )
endmacro()

macro(nRF5x_addHWRNG)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/modules/nrfx/drivers/include"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/modules/nrfx/drivers/src/nrfx_rng.c"
            )
endmacro()

macro(nRF5x_addHWRNGLegacy)
    nRF5x_addHWRNG()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/integration/nrfx/legacy"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/integration/nrfx/legacy/nrf_drv_rng.c"
            )
endmacro()

macro(nRF5x_addMBEDTLS SDK_CONFIG_INCLUDE_DIR)
    if(TARGET mbedtls)
        return()
    endif()
    set(USE_STATIC_MBEDTLS_LIBRARY 1)
    set(ENABLE_TESTING OFF)
    set(ENABLE_PROGRAMS OFF)
    add_subdirectory("${SDK_ROOT}/external/mbedtls" mbedtls)
    # other targets link mbedcrypto and def needs to be public so only needs defining on this target
    target_compile_definitions(mbedcrypto PUBLIC MBEDTLS_CONFIG_FILE="${SDK_ROOT}/external/nrf_tls/mbedtls/nrf_crypto/config/nrf_crypto_mbedtls_config.h")
    foreach(target mbedtls mbedx509 mbedcrypto)
        target_include_directories(${target} PRIVATE ${SDK_CONFIG_INCLUDE_DIR})
    endforeach()
endmacro()

macro(nRF5x_addCryptoCommon)
    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/crypto/nrf_crypto_init.c"
            "${SDK_ROOT}/components/libraries/crypto/nrf_crypto_shared.c"
            )
endmacro()

macro(nRF5x_addAES BACKEND)
    nRF5x_addCryptoCommon()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/crypto"
            # must include all headers
            "${SDK_ROOT}/components/libraries/crypto/backend/cc310"
            "${SDK_ROOT}/components/libraries/crypto/backend/mbedtls"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/crypto/backend/${BACKEND}/${BACKEND}_backend_init.c"
            "${SDK_ROOT}/components/libraries/crypto/backend/${BACKEND}/${BACKEND}_backend_aes.c"
            "${SDK_ROOT}/components/libraries/crypto/nrf_crypto_aes_shared.c"
            "${SDK_ROOT}/components/libraries/crypto/nrf_crypto_aes.c"
            )
endmacro()

macro(nRF5x_addAEAD BACKEND)
    nRF5x_addCryptoCommon()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/crypto"
            # must include all headers
            "${SDK_ROOT}/components/libraries/crypto/backend/cc310"
            "${SDK_ROOT}/components/libraries/crypto/backend/cifra"
            "${SDK_ROOT}/components/libraries/crypto/backend/mbedtls"
            "${SDK_ROOT}/components/libraries/crypto/backend/oberon"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/crypto/backend/${BACKEND}/${BACKEND}_backend_init.c"
            "${SDK_ROOT}/components/libraries/crypto/backend/${BACKEND}/${BACKEND}_backend_aes_aead.c"
            "${SDK_ROOT}/components/libraries/crypto/nrf_crypto_aead.c"
            )
endmacro()

macro(nRF5x_addHash BACKEND)
    nRF5x_addCryptoCommon()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/crypto"
            # must include all headers
            "${SDK_ROOT}/components/libraries/crypto/backend/cc310"
            "${SDK_ROOT}/components/libraries/crypto/backend/mbedtls"
            "${SDK_ROOT}/components/libraries/crypto/backend/oberon"
            "${SDK_ROOT}/components/libraries/crypto/backend/cc310_bl"
            "${SDK_ROOT}/components/libraries/crypto/backend/nrf_sw"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/crypto/backend/${BACKEND}/${BACKEND}_backend_init.c"
            "${SDK_ROOT}/components/libraries/crypto/backend/${BACKEND}/${BACKEND}_backend_hash.c"
            "${SDK_ROOT}/components/libraries/crypto/nrf_crypto_hash.c"
            )
endmacro()

macro(nRF5x_addRNG BACKEND)
    nRF5x_addCryptoCommon()
    nRF5x_addStackInfo()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/crypto"
            # must include all headers
            "${SDK_ROOT}/components/libraries/crypto/backend/cc310"
            "${SDK_ROOT}/components/libraries/crypto/backend/optiga"
            "${SDK_ROOT}/components/libraries/crypto/backend/nrf_hw"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/crypto/nrf_crypto_rng.c"
            )
    if(${BACKEND} STREQUAL "nrf_hw_mbedtls")
        list(APPEND SOURCE_FILES
                "${SDK_ROOT}/components/libraries/crypto/backend/nrf_hw/nrf_hw_backend_rng_mbedtls.c"
                "${SDK_ROOT}/components/libraries/crypto/backend/nrf_hw/nrf_hw_backend_init.c"
                )
    else()
        list(APPEND SOURCE_FILES
                "${SDK_ROOT}/components/libraries/crypto/backend/${BACKEND}/${BACKEND}_backend_rng.c"
                )
    endif()
endmacro()

macro(nRF5x_addHMAC BACKEND)
    nRF5x_addCryptoCommon()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/crypto"
            # must include all headers
            "${SDK_ROOT}/components/libraries/crypto/backend/cc310"
            "${SDK_ROOT}/components/libraries/crypto/backend/mbedtls"
            "${SDK_ROOT}/components/libraries/crypto/backend/oberon"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/crypto/backend/${BACKEND}/${BACKEND}_backend_init.c"
            "${SDK_ROOT}/components/libraries/crypto/backend/${BACKEND}/${BACKEND}_backend_hmac.c"
            "${SDK_ROOT}/components/libraries/crypto/nrf_crypto_hmac.c"
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

# adds svc library
macro(nRF5x_addSVC)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/svc"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/svc/nrf_svc_handler.c"
            )
endmacro()

macro(nRF5x_addCRC32)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/crc32"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/crc32/crc32.c"
            )
endmacro()

# adds dfu buttonless bootloader libs
macro(nRF5x_addBootloaderButtonlessLibs)
    nRF5x_addSVC()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/bootloader"
            "${SDK_ROOT}/components/libraries/bootloader/dfu"
            "${SDK_ROOT}/components/libraries/bootloader/ble_dfu"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/bootloader/nrf_bootloader_info.c"
            "${SDK_ROOT}/components/libraries/bootloader/dfu/nrf_dfu_svci.c"
            )
endmacro()

macro(nRF5x_addBootloaderSettings)
    nRF5x_addCRC32()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/bootloader/dfu"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/bootloader/dfu/nrf_dfu_settings.c"
            )
endmacro()

# adds hardfault handler library
macro(nRF5x_addHardfaultHandler)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/hardfault"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/hardfault/hardfault_implementation.c"
            "${SDK_ROOT}/components/libraries/hardfault/nrf52/handler/hardfault_handler_gcc.c"
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

# adds rtc driver
macro(nRF5x_addRTC)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/modules/nrfx/drivers/include"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/modules/nrfx/drivers/src/nrfx_rtc.c"
            )
endmacro()

# adds peripheral resource sharing driver
macro(nRF5x_addPRS)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/modules/nrfx/drivers/src/prs"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/modules/nrfx/drivers/src/prs/nrfx_prs.c"
            )
endmacro()

# adds uart driver
macro(nRF5x_addUART)
    nRF5x_addPRS()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/modules/nrfx/drivers/include"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/modules/nrfx/drivers/src/nrfx_uart.c"
            "${SDK_ROOT}/modules/nrfx/drivers/src/nrfx_uarte.c"
            )
endmacro()

# adds legacy uart driver
macro(nRF5x_addLegacyUART)
    nRF5x_addUART()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/integration/nrfx/legacy"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/integration/nrfx/legacy/nrf_drv_uart.c"
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

# adds nvmc HAL
macro(nRF5x_addNVMC)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/modules/nrfx/hal"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/modules/nrfx/hal/nrf_nvmc.c"
            )
endmacro()

# adds queue library
macro(nRF5x_addQueue)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/queue"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/queue/nrf_queue.c"
            )
endmacro()

# adds serial library
macro(nRF5x_addSerial)
    nRF5x_addLegacyUART()
    nRF5x_addMutex()
    nRF5x_addQueue()
    nRF5x_addAppTimer()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/serial"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/serial/nrf_serial.c"
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

# adds app UART library
macro(nRF5x_addAppUART)
    nRF5x_addLegacyUART()
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/libraries/uart"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/libraries/uart/app_uart_fifo.c"
            )

endmacro()

# adds app-level Button library
macro(nRF5x_addAppButton)
    nRF5x_addGPIOTE()
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
            "${SDK_ROOT}/components/boards/boards.c"
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
    nRF5x_addAtomicFlags()

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

# adds Bluetooth Low Energy Queued Write library
macro(nRF5x_addBLEQWR)
    list(APPEND INCLUDE_DIRS
            "${SDK_ROOT}/components/ble/nrf_ble_qwr"
            )

    list(APPEND SOURCE_FILES
            "${SDK_ROOT}/components/ble/nrf_ble_qwr/nrf_ble_qwr.c"
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

    if("${NAME}" STREQUAL "ble_dfu")
        list(APPEND SOURCE_FILES
                "${SDK_ROOT}/components/ble/ble_services/${NAME}/${NAME}_bonded.c"
                "${SDK_ROOT}/components/ble/ble_services/${NAME}/${NAME}_unbonded.c"
                )
        nRF5x_addBootloaderButtonlessLibs()
        nRF5x_addBLEPeerManager()
    endif()
endmacro()

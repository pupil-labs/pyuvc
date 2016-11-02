'''
(*)~----------------------------------------------------------------------------------
 Pupil - eye tracking platform
 Copyright (C) 2012-2015  Pupil Labs

 Distributed under the terms of the CC BY-NC-SA License.
 License details are in the file license.txt, distributed as part of this software.
----------------------------------------------------------------------------------~(*)
'''


from libc.string cimport const_char

IF UNAME_SYSNAME == "Windows":
    from posix.types cimport suseconds_t, time_t
    cdef extern from "<time.h>":
        cdef struct timeval:
            time_t      tv_sec
            suseconds_t tv_usec

        cdef struct timespec:
            time_t tv_sec
            long tv_nsec
    cdef extern from "libusb/libusb.h":
        pass
ELSE:
    from posix.time cimport timeval,timespec
    cdef extern from "libusb-1.0/libusb.h":
        pass

cdef extern from "Python.h":
    void PyEval_InitThreads()

cdef enum ctrl_bit_mask_processing_unit:
    UVC_PU_BRIGHTNESS_CONTROL = 1 << 0
    UVC_PU_CONTRAST_CONTROL = 1 << 1
    UVC_PU_HUE_CONTROL = 1 << 2
    UVC_PU_SATURATION_CONTROL = 1 << 3
    UVC_PU_SHARPNESS_CONTROL = 1 << 4
    UVC_PU_GAMMA_CONTROL = 1 << 5
    UVC_PU_WHITE_BALANCE_TEMPERATURE_CONTROL = 1 << 6
    UVC_PU_WHITE_BALANCE_COMPONENT_CONTROL = 1 << 7
    UVC_PU_BACKLIGHT_COMPENSATION_CONTROL = 1 << 8
    UVC_PU_GAIN_CONTROL = 1 << 9
    UVC_PU_POWER_LINE_FREQUENCY_CONTROL = 1 << 10
    UVC_PU_HUE_AUTO_CONTROL = 1 << 11
    UVC_PU_WHITE_BALANCE_TEMPERATURE_AUTO_CONTROL = 1 << 12
    UVC_PU_WHITE_BALANCE_COMPONENT_AUTO_CONTROL = 1 << 13
    UVC_PU_DIGITAL_MULTIPLIER_CONTROL = 1 << 14
    UVC_PU_DIGITAL_MULTIPLIER_LIMIT_CONTROL = 1 << 15
    UVC_PU_ANALOG_VIDEO_STANDARD_CONTROL = 1 << 16
    UVC_PU_ANALOG_LOCK_STATUS_CONTROL = 1 << 17

cdef enum ctrl_bit_mask_input_terminal:
    UVC_CT_SCANNING_MODE_CONTROL = 1 << 0
    UVC_CT_AE_MODE_CONTROL = 1 << 1
    UVC_CT_AE_PRIORITY_CONTROL = 1 << 2
    UVC_CT_EXPOSURE_TIME_ABSOLUTE_CONTROL = 1 << 3
    UVC_CT_EXPOSURE_TIME_RELATIVE_CONTROL = 1 << 4
    UVC_CT_FOCUS_ABSOLUTE_CONTROL = 1 << 5
    UVC_CT_FOCUS_RELATIVE_CONTROL = 1 << 6
    UVC_CT_IRIS_ABSOLUTE_CONTROL = 1 << 7
    UVC_CT_IRIS_RELATIVE_CONTROL = 1 << 8
    UVC_CT_ZOOM_ABSOLUTE_CONTROL = 1 << 9
    UVC_CT_ZOOM_RELATIVE_CONTROL = 1 << 10
    UVC_CT_PANTILT_ABSOLUTE_CONTROL = 1 << 11
    UVC_CT_PANTILT_RELATIVE_CONTROL = 1 << 12
    UVC_CT_ROLL_ABSOLUTE_CONTROL = 1 << 13
    UVC_CT_ROLL_RELATIVE_CONTROL = 1 << 14
    UVC_CT_FOCUS_AUTO_CONTROL = 1 << 17
    UVC_CT_PRIVACY_CONTROL = 1 << 18



cdef extern from  "libuvc/libuvc.h":

    ctypedef int uint8_t
    ctypedef int uint16_t
    ctypedef int int16_t
    ctypedef int uint16_t
    ctypedef int uint32_t
    ctypedef int int32_t
    ctypedef int uint64_t

    cdef enum uvc_error:
        UVC_SUCCESS
        UVC_ERROR_IO
        UVC_ERROR_INVALID_PARAM
        UVC_ERROR_ACCESS
        UVC_ERROR_NO_DEVICE
        UVC_ERROR_NOT_FOUND
        UVC_ERROR_BUSY
        UVC_ERROR_TIMEOUT
        UVC_ERROR_OVERFLOW
        UVC_ERROR_PIPE
        UVC_ERROR_INTERRUPTED
        UVC_ERROR_NO_MEM
        UVC_ERROR_NOT_SUPPORTED
        UVC_ERROR_INVALID_DEVICE
        UVC_ERROR_INVALID_MODE
        UVC_ERROR_CALLBACK_EXISTS
        UVC_ERROR_OTHER
    ctypedef uvc_error uvc_error_t


    cdef enum uvc_frame_format:
        UVC_FRAME_FORMAT_UNKNOWN
        UVC_FRAME_FORMAT_ANY
        UVC_FRAME_FORMAT_UNCOMPRESSED
        UVC_FRAME_FORMAT_COMPRESSED
        UVC_FRAME_FORMAT_YUYV
        UVC_FRAME_FORMAT_UYVY
        UVC_FRAME_FORMAT_RGB
        UVC_FRAME_FORMAT_BGR
        UVC_FRAME_FORMAT_MJPEG
        UVC_FRAME_FORMAT_GRAY8
        UVC_FRAME_FORMAT_BY8
        UVC_FRAME_FORMAT_COUNT

    enum:
        UVC_COLOR_FORMAT_UNKNOWN
        UVC_COLOR_FORMAT_UNCOMPRESSED
        UVC_COLOR_FORMAT_COMPRESSED
        UVC_COLOR_FORMAT_YUYV
        UVC_COLOR_FORMAT_UYVY
        UVC_COLOR_FORMAT_RGB
        UVC_COLOR_FORMAT_BGR
        UVC_COLOR_FORMAT_MJPEG
        UVC_COLOR_FORMAT_GRAY8


    enum uvc_vs_desc_subtype:
        UVC_VS_UNDEFINED = 0x00
        UVC_VS_INPUT_HEADER = 0x01
        UVC_VS_OUTPUT_HEADER = 0x02
        UVC_VS_STILL_IMAGE_FRAME = 0x03
        UVC_VS_FORMAT_UNCOMPRESSED = 0x04
        UVC_VS_FRAME_UNCOMPRESSED = 0x05
        UVC_VS_FORMAT_MJPEG = 0x06
        UVC_VS_FRAME_MJPEG = 0x07
        UVC_VS_FORMAT_MPEG2TS = 0x0a
        UVC_VS_FORMAT_DV = 0x0c
        UVC_VS_COLORFORMAT = 0x0d
        UVC_VS_FORMAT_FRAME_BASED = 0x10
        UVC_VS_FRAME_FRAME_BASED = 0x11
        UVC_VS_FORMAT_STREAM_BASED = 0x12

    cdef struct uvc_frame_desc:
        uvc_format_desc *parent
        uvc_frame_desc *prev
        uvc_frame_desc *next
        uvc_vs_desc_subtype bDescriptorSubtype
        uint8_t bFrameIndex
        uint8_t bmCapabilities
        uint16_t wWidth
        uint16_t wHeight
        uint32_t dwMinBitRate
        uint32_t dwMaxBitRate
        uint32_t dwMaxVideoFrameBufferSize
        uint32_t dwDefaultFrameInterval
        uint32_t dwMinFrameInterval
        uint32_t dwMaxFrameInterval
        uint32_t dwFrameIntervalStep
        uint8_t bFrameIntervalType
        uint32_t dwBytesPerLine
        uint32_t *intervals
    ctypedef uvc_frame_desc uvc_frame_desc_t

    cdef struct uvc_format_desc:
        #uvc_streaming_interface *parent
        uvc_format_desc *prev
        uvc_format_desc *next
        uvc_vs_desc_subtype bDescriptorSubtype
        uint8_t bFormatIndex
        uint8_t bNumFrameDescriptors
        #union {
        #uint8_t guidFormat[16]
        #uint8_t fourccFormat[4]
        #}
        #/** Format-specific data */
        #union {
        #/** BPP for uncompressed stream */
        #uint8_t bBitsPerPixel
        #/** Flags for JPEG stream */
        #uint8_t bmFlags
        #}
        #/** Default {uvc_frame_desc} to choose given this format */
        uint8_t bDefaultFrameIndex
        uint8_t bAspectRatioX
        uint8_t bAspectRatioY
        uint8_t bmInterlaceFlags
        uint8_t bCopyProtect
        uint8_t bVariableSize
        uvc_frame_desc *frame_descs

    ctypedef uvc_format_desc uvc_format_desc_t


    cdef enum uvc_req_code:
        UVC_RC_UNDEFINED = 0x00
        UVC_SET_CUR = 0x01
        UVC_GET_CUR = 0x81
        UVC_GET_MIN = 0x82
        UVC_GET_MAX = 0x83
        UVC_GET_RES = 0x84
        UVC_GET_LEN = 0x85
        UVC_GET_INFO = 0x86
        UVC_GET_DEF = 0x87

    cdef enum uvc_device_power_mode:
        pass

    cdef enum uvc_ct_ctrl_selector:
        UVC_CT_CONTROL_UNDEFINED
        UVC_CT_SCANNING_MODE_CONTROL
        UVC_CT_AE_MODE_CONTROL
        UVC_CT_AE_PRIORITY_CONTROL
        UVC_CT_EXPOSURE_TIME_ABSOLUTE_CONTROL
        UVC_CT_EXPOSURE_TIME_RELATIVE_CONTROL
        UVC_CT_FOCUS_ABSOLUTE_CONTROL
        UVC_CT_FOCUS_RELATIVE_CONTROL
        UVC_CT_FOCUS_AUTO_CONTROL
        UVC_CT_IRIS_ABSOLUTE_CONTROL
        UVC_CT_IRIS_RELATIVE_CONTROL
        UVC_CT_ZOOM_ABSOLUTE_CONTROL
        UVC_CT_ZOOM_RELATIVE_CONTROL
        UVC_CT_PANTILT_ABSOLUTE_CONTROL
        UVC_CT_PANTILT_RELATIVE_CONTROL
        UVC_CT_ROLL_ABSOLUTE_CONTROL
        UVC_CT_ROLL_RELATIVE_CONTROL
        UVC_CT_PRIVACY_CONTROL
        UVC_CT_FOCUS_SIMPLE_CONTROL
        UVC_CT_DIGITAL_WINDOW_CONTROL
        UVC_CT_REGION_OF_INTEREST_CONTROL

    enum uvc_pu_ctrl_selector:
        UVC_PU_CONTROL_UNDEFINED
        UVC_PU_BACKLIGHT_COMPENSATION_CONTROL
        UVC_PU_BRIGHTNESS_CONTROL
        UVC_PU_CONTRAST_CONTROL
        UVC_PU_GAIN_CONTROL
        UVC_PU_POWER_LINE_FREQUENCY_CONTROL
        UVC_PU_HUE_CONTROL
        UVC_PU_SATURATION_CONTROL
        UVC_PU_SHARPNESS_CONTROL
        UVC_PU_GAMMA_CONTROL
        UVC_PU_WHITE_BALANCE_TEMPERATURE_CONTROL
        UVC_PU_WHITE_BALANCE_TEMPERATURE_AUTO_CONTROL
        UVC_PU_WHITE_BALANCE_COMPONENT_CONTROL
        UVC_PU_WHITE_BALANCE_COMPONENT_AUTO_CONTROL
        UVC_PU_DIGITAL_MULTIPLIER_CONTROL
        UVC_PU_DIGITAL_MULTIPLIER_LIMIT_CONTROL
        UVC_PU_HUE_AUTO_CONTROL
        UVC_PU_ANALOG_VIDEO_STANDARD_CONTROL
        UVC_PU_ANALOG_LOCK_STATUS_CONTROL
        UVC_PU_CONTRAST_AUTO_CONTROL



    cdef struct libusb_context:
        pass
    cdef struct uvc_context:
        pass
    ctypedef uvc_context uvc_context_t

    cdef struct uvc_device:
        pass
    ctypedef uvc_device uvc_device_t

    cdef struct uvc_device_handle:
        pass
    ctypedef uvc_device_handle uvc_device_handle_t

    cdef struct uvc_stream_handle:
        pass
    ctypedef uvc_stream_handle uvc_stream_handle_t

    cdef struct uvc_input_terminal:
        uvc_input_terminal *prev
        uvc_input_terminal *next
        uint8_t bTerminalID
        uint64_t bmControls

    ctypedef uvc_input_terminal uvc_input_terminal_t

    cdef struct uvc_output_terminal:
        pass
    ctypedef uvc_output_terminal uvc_output_terminal_t


    cdef struct uvc_processing_unit:
        uvc_processing_unit *prev
        uvc_processing_unit *next
        uint8_t bUnitID
        uint8_t bSourceID
        uint64_t bmControls
    ctypedef uvc_processing_unit uvc_processing_unit_t

    cdef struct uvc_extension_unit:
        uvc_extension_unit *prev
        uvc_extension_unit *next
        uint8_t bUnitID
        uint8_t guidExtensionCode[16]
        uint64_t bmControls
    ctypedef uvc_extension_unit uvc_extension_unit_t



    cdef enum uvc_status_class:
        UVC_STATUS_CLASS_CONTROL = 0x10
        UVC_STATUS_CLASS_CONTROL_CAMERA = 0x11
        UVC_STATUS_CLASS_CONTROL_PROCESSING = 0x12

    cdef enum uvc_status_attribute:
        UVC_STATUS_ATTRIBUTE_VALUE_CHANGE = 0x00,
        UVC_STATUS_ATTRIBUTE_INFO_CHANGE = 0x01,
        UVC_STATUS_ATTRIBUTE_FAILURE_CHANGE = 0x02,
        UVC_STATUS_ATTRIBUTE_UNKNOWN = 0xff

    ctypedef void(*uvc_status_callback_t)(uvc_status_class status_class,
                                        int event,
                                        int selector,
                                        uvc_status_attribute status_attribute,
                                        void *data,
                                        size_t data_len,
                                        void *user_ptr)


    cdef struct uvc_device_descriptor:
        int idVendor
        int idProduct
        int bcdUVC
        const_char *serialNumber
        const_char *manufacturer
        const_char *product
    ctypedef uvc_device_descriptor uvc_device_descriptor_t

    cdef struct uvc_frame:
        void *data
        int data_bytes
        int width
        int height
        uvc_frame_format frame_format
        int step
          #/** Frame number (may skip, but is strictly monotonically increasing) */
        int sequence
        #/** Estimate of system time when the device started capturing the image */
        timeval capture_time
        uvc_device_handle_t * source
        int library_owns_data
    ctypedef uvc_frame uvc_frame_t


    cdef struct uvc_stream_ctrl:
        pass
    ctypedef uvc_stream_ctrl uvc_stream_ctrl_t


    #fns
    uvc_error_t uvc_init(uvc_context_t **ctx, libusb_context *usb_ctx)
    void uvc_exit(uvc_context_t *ctx)


    uvc_error_t uvc_get_device_list(uvc_context_t *ctx, uvc_device_t ***list)
    void uvc_free_device_list(uvc_device_t **list, uint8_t unref_devices)

    uvc_error_t uvc_get_device_descriptor(uvc_device_t *dev,uvc_device_descriptor_t **desc)
    void uvc_free_device_descriptor(uvc_device_descriptor_t *desc)


    int uvc_get_bus_number(uvc_device_t *dev)
    int uvc_get_device_address(uvc_device_t *dev)

    uvc_error_t uvc_find_device( uvc_context_t *ctx, uvc_device_t **dev, int vid, int pid, const char *sn)

    void uvc_ref_device(uvc_device_t *dev)
    void uvc_unref_device(uvc_device_t *dev)


    uvc_error_t uvc_open(uvc_device_t *dev,uvc_device_handle_t **devh)
    void uvc_close(uvc_device_handle_t *devh)

    uvc_device_t *uvc_get_device(uvc_device_handle_t *devh)
    ctypedef void(*uvc_frame_callback_t)( uvc_frame *frame, void *user_ptr) # this is supposed to work wihtout a pointer?

    void uvc_set_status_callback(uvc_device_handle_t *devh, uvc_status_callback_t cb,void *user_ptr)


    const uvc_input_terminal_t *uvc_get_input_terminals(uvc_device_handle_t *devh)
    const uvc_output_terminal_t *uvc_get_output_terminals(uvc_device_handle_t *devh)
    const uvc_processing_unit_t *uvc_get_processing_units(uvc_device_handle_t *devh)
    const uvc_extension_unit_t *uvc_get_extension_units(uvc_device_handle_t *devh)


    uvc_error_t uvc_get_stream_ctrl_format_size( uvc_device_handle_t *devh, uvc_stream_ctrl_t *ctrl, uvc_frame_format format, int width, int height, int fps)

    uvc_format_desc_t *uvc_get_format_descs(uvc_device_handle_t* )

    uvc_error_t uvc_probe_stream_ctrl( uvc_device_handle_t *devh, uvc_stream_ctrl_t *ctrl)

    uvc_error_t uvc_start_streaming( uvc_device_handle_t *devh, uvc_stream_ctrl_t *ctrl, uvc_frame_callback_t *cb, void *user_ptr, uint8_t flags)

    void uvc_stop_streaming(uvc_device_handle_t *devh)

    uvc_error_t uvc_stream_open_ctrl(uvc_device_handle_t *devh, uvc_stream_handle_t **strmh, uvc_stream_ctrl_t *ctrl)
    uvc_error_t set_uvc_stream_ctrl"uvc_stream_ctrl"(uvc_stream_handle_t *strmh, uvc_stream_ctrl_t *ctrl)
    uvc_error_t uvc_stream_start(uvc_stream_handle_t *strmh,uvc_frame_callback_t *cb,void *user_ptr,float bandwidth_factor, uint8_t flags)
    #uvc_error_t uvc_stream_start_iso(uvc_stream_handle_t *strmh, uvc_frame_callback_t *cb, void *user_ptr)

    uvc_error_t uvc_stream_get_frame( uvc_stream_handle_t *strmh, uvc_frame_t **frame, int timeout_us) nogil
    uvc_error_t uvc_stream_stop(uvc_stream_handle_t *strmh)
    void uvc_stream_close(uvc_stream_handle_t *strmh)

    uvc_frame_t *uvc_allocate_frame(size_t data_bytes)
    void uvc_free_frame(uvc_frame_t *frame)
    uvc_error_t uvc_duplicate_frame(uvc_frame_t *in_frame, uvc_frame_t *out_frame)

    int uvc_get_ctrl_len(uvc_device_handle_t *devh, uint8_t unit, uint8_t ctrl)
    int uvc_get_ctrl(uvc_device_handle_t *devh, uint8_t unit, uint8_t ctrl, void *data, int len, uvc_req_code req_code)
    int uvc_set_ctrl(uvc_device_handle_t *devh, uint8_t unit, uint8_t ctrl, void *data, int len)



#/** Converts an unaligned four-byte little-endian integer into an int32 */
cdef inline int32_t DW_TO_INT(uint8_t *p):
    return (p)[0] | ((p)[1] << 8) | ((p)[2] << 16) | ((p)[3] << 24)
#/** Converts an unaligned two-byte little-endian integer into an int16 */
cdef inline int16_t SW_TO_SHORT(uint8_t *p):
    return (p)[0] | ((p)[1] << 8)
#/** Converts an int16 into an unaligned two-byte little-endian integer */
cdef inline void SHORT_TO_SW(int16_t s, uint8_t *p):
    p[0] = s
    p[1] = s >> 8
#/** Converts an int32 into an unaligned four-byte little-endian integer */
cdef inline void INT_TO_DW(int32_t i, uint8_t *p):
    p[0] = i
    p[1] = i >> 8
    p[2] = i >> 16
    p[3] = i >> 24



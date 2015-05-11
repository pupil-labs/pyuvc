
from posix.time cimport timeval,timespec
from libc.string cimport const_char

cdef extern from "libusb-1.0/libusb.h":
    pass

cdef extern from  "libuvc/libuvc.h":

    ctypedef int uint8_t
    ctypedef int uint32_t

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

    cdef struct uvc_frame_desc:
        pass
    ctypedef uvc_frame_desc uvc_frame_desc_t

    cdef struct uvc_format_desc:
        pass
    ctypedef uvc_format_desc uvc_format_desc_t


    cdef enum uvc_req_code:
        pass

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
        pass
    ctypedef uvc_input_terminal uvc_input_terminal_t

    cdef struct uvc_processing_unit:
        pass
    ctypedef uvc_processing_unit uvc_processing_unit_t

    cdef struct uvc_extension_unit:
        pass
    ctypedef uvc_extension_unit uvc_extension_unit_t

    cdef enum uvc_status_class:
        pass

    cdef enum uvc_status_attribute:
        pass

    #typedef void(uvc_status_callback_t)(enum uvc_status_class status_class,
    #                                    int event,
    #                                    int selector,
    #                                    enum uvc_status_attribute status_attribute,
    #                                    void *data, size_t data_len,
    #                                    void *user_ptr)


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

    uvc_error_t uvc_open(uvc_device_t *dev,uvc_device_handle_t **devh)
    void uvc_close(uvc_device_handle_t *devh)

    uvc_device_t *uvc_get_device(uvc_device_handle_t *devh)
    ctypedef void(*uvc_frame_callback_t)( uvc_frame *frame, void *user_ptr) # this is supposed to work wihtout a pointer?

    #void uvc_set_status_callback(uvc_device_handle_t *devh,uvc_status_callback_t cb,void *user_ptr)

    #const uvc_input_terminal_t *uvc_get_input_terminals(uvc_device_handle_t *devh)
    #const uvc_output_terminal_t *uvc_get_output_terminals(uvc_device_handle_t *devh)
    #const uvc_processing_unit_t *uvc_get_processing_units(uvc_device_handle_t *devh)
    #const uvc_extension_unit_t *uvc_get_extension_units(uvc_device_handle_t *devh)


    uvc_error_t uvc_get_stream_ctrl_format_size( uvc_device_handle_t *devh, uvc_stream_ctrl_t *ctrl, uvc_frame_format format, int width, int height, int fps)

    uvc_format_desc_t *uvc_get_format_descs(uvc_device_handle_t* )

    uvc_error_t uvc_probe_stream_ctrl( uvc_device_handle_t *devh, uvc_stream_ctrl_t *ctrl)

    uvc_error_t uvc_start_streaming( uvc_device_handle_t *devh, uvc_stream_ctrl_t *ctrl, uvc_frame_callback_t *cb, void *user_ptr, uint8_t flags)

    void uvc_stop_streaming(uvc_device_handle_t *devh)

    #uvc_error_t uvc_stream_open_ctrl(uvc_device_handle_t *devh, uvc_stream_handle_t **strmh, uvc_stream_ctrl_t *ctrl)
    #uvc_error_t uvc_stream_ctrl(uvc_stream_handle_t *strmh, uvc_stream_ctrl_t *ctrl)
    #uvc_error_t uvc_stream_start(uvc_stream_handle_t *strmh,
    #    uvc_frame_callback_t *cb,
    #    void *user_ptr,
    #    uint8_t flags)
    #uvc_error_t uvc_stream_start_iso(uvc_stream_handle_t *strmh,
    #    uvc_frame_callback_t *cb,
    #    void *user_ptr)

    uvc_error_t uvc_stream_get_frame( uvc_stream_handle_t *strmh, uvc_frame_t **frame, int timeout_us)
    #uvc_error_t uvc_stream_stop(uvc_stream_handle_t *strmh)
    #void uvc_stream_close(uvc_stream_handle_t *strmh)


    #int uvc_get_ctrl_len(uvc_device_handle_t *devh, uint8_t unit, uint8_t ctrl)
    #int uvc_get_ctrl(uvc_device_handle_t *devh, uint8_t unit, uint8_t ctrl, void *data, int len, enum uvc_req_code req_code)
    #int uvc_set_ctrl(uvc_device_handle_t *devh, uint8_t unit, uint8_t ctrl, void *data, int len)

    #uvc_error_t uvc_get_power_mode(uvc_device_handle_t *devh, enum uvc_device_power_mode *mode, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_power_mode(uvc_device_handle_t *devh, enum uvc_device_power_mode mode)

    #/* AUTO-GENERATED control accessors! Update them with the output of `ctrl-gen.py decl`. */
    #uvc_error_t uvc_get_scanning_mode(uvc_device_handle_t *devh, uint8_t* mode, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_scanning_mode(uvc_device_handle_t *devh, uint8_t mode)

    #uvc_error_t uvc_get_ae_mode(uvc_device_handle_t *devh, uint8_t* mode, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_ae_mode(uvc_device_handle_t *devh, uint8_t mode)

    #uvc_error_t uvc_get_ae_priority(uvc_device_handle_t *devh, uint8_t* priority, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_ae_priority(uvc_device_handle_t *devh, uint8_t priority)

    #uvc_error_t uvc_get_exposure_abs(uvc_device_handle_t *devh, uint32_t* time, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_exposure_abs(uvc_device_handle_t *devh, uint32_t time)

    #uvc_error_t uvc_get_exposure_rel(uvc_device_handle_t *devh, int8_t* step, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_exposure_rel(uvc_device_handle_t *devh, int8_t step)

    #uvc_error_t uvc_get_focus_abs(uvc_device_handle_t *devh, uint16_t* focus, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_focus_abs(uvc_device_handle_t *devh, uint16_t focus)

    #uvc_error_t uvc_get_focus_rel(uvc_device_handle_t *devh, int8_t* focus_rel, uint8_t* speed, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_focus_rel(uvc_device_handle_t *devh, int8_t focus_rel, uint8_t speed)

    #uvc_error_t uvc_get_focus_simple_range(uvc_device_handle_t *devh, uint8_t* focus, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_focus_simple_range(uvc_device_handle_t *devh, uint8_t focus)

    #uvc_error_t uvc_get_focus_auto(uvc_device_handle_t *devh, uint8_t* state, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_focus_auto(uvc_device_handle_t *devh, uint8_t state)

    #uvc_error_t uvc_get_iris_abs(uvc_device_handle_t *devh, uint16_t* iris, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_iris_abs(uvc_device_handle_t *devh, uint16_t iris)

    #uvc_error_t uvc_get_iris_rel(uvc_device_handle_t *devh, uint8_t* iris_rel, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_iris_rel(uvc_device_handle_t *devh, uint8_t iris_rel)

    #uvc_error_t uvc_get_zoom_abs(uvc_device_handle_t *devh, uint16_t* focal_length, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_zoom_abs(uvc_device_handle_t *devh, uint16_t focal_length)

    #uvc_error_t uvc_get_zoom_rel(uvc_device_handle_t *devh, int8_t* zoom_rel, uint8_t* digital_zoom, uint8_t* speed, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_zoom_rel(uvc_device_handle_t *devh, int8_t zoom_rel, uint8_t digital_zoom, uint8_t speed)

    #uvc_error_t uvc_get_pantilt_abs(uvc_device_handle_t *devh, int32_t* pan, int32_t* tilt, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_pantilt_abs(uvc_device_handle_t *devh, int32_t pan, int32_t tilt)

    #uvc_error_t uvc_get_pantilt_rel(uvc_device_handle_t *devh, int8_t* pan_rel, uint8_t* pan_speed, int8_t* tilt_rel, uint8_t* tilt_speed, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_pantilt_rel(uvc_device_handle_t *devh, int8_t pan_rel, uint8_t pan_speed, int8_t tilt_rel, uint8_t tilt_speed)

    #uvc_error_t uvc_get_roll_abs(uvc_device_handle_t *devh, int16_t* roll, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_roll_abs(uvc_device_handle_t *devh, int16_t roll)

    #uvc_error_t uvc_get_roll_rel(uvc_device_handle_t *devh, int8_t* roll_rel, uint8_t* speed, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_roll_rel(uvc_device_handle_t *devh, int8_t roll_rel, uint8_t speed)

    #uvc_error_t uvc_get_privacy(uvc_device_handle_t *devh, uint8_t* privacy, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_privacy(uvc_device_handle_t *devh, uint8_t privacy)

    #uvc_error_t uvc_get_digital_window(uvc_device_handle_t *devh, uint16_t* window_top, uint16_t* window_left, uint16_t* window_bottom, uint16_t* window_right, uint16_t* num_steps, uint16_t* num_steps_units, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_digital_window(uvc_device_handle_t *devh, uint16_t window_top, uint16_t window_left, uint16_t window_bottom, uint16_t window_right, uint16_t num_steps, uint16_t num_steps_units)

    #uvc_error_t uvc_get_digital_roi(uvc_device_handle_t *devh, uint16_t* roi_top, uint16_t* roi_left, uint16_t* roi_bottom, uint16_t* roi_right, uint16_t* auto_controls, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_digital_roi(uvc_device_handle_t *devh, uint16_t roi_top, uint16_t roi_left, uint16_t roi_bottom, uint16_t roi_right, uint16_t auto_controls)

    #uvc_error_t uvc_get_backlight_compensation(uvc_device_handle_t *devh, uint16_t* backlight_compensation, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_backlight_compensation(uvc_device_handle_t *devh, uint16_t backlight_compensation)

    #uvc_error_t uvc_get_brightness(uvc_device_handle_t *devh, int16_t* brightness, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_brightness(uvc_device_handle_t *devh, int16_t brightness)

    #uvc_error_t uvc_get_contrast(uvc_device_handle_t *devh, uint16_t* contrast, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_contrast(uvc_device_handle_t *devh, uint16_t contrast)

    #uvc_error_t uvc_get_contrast_auto(uvc_device_handle_t *devh, uint8_t* contrast_auto, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_contrast_auto(uvc_device_handle_t *devh, uint8_t contrast_auto)

    #uvc_error_t uvc_get_gain(uvc_device_handle_t *devh, uint16_t* gain, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_gain(uvc_device_handle_t *devh, uint16_t gain)

    #uvc_error_t uvc_get_power_line_frequency(uvc_device_handle_t *devh, uint8_t* power_line_frequency, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_power_line_frequency(uvc_device_handle_t *devh, uint8_t power_line_frequency)

    #uvc_error_t uvc_get_hue(uvc_device_handle_t *devh, int16_t* hue, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_hue(uvc_device_handle_t *devh, int16_t hue)

    #uvc_error_t uvc_get_hue_auto(uvc_device_handle_t *devh, uint8_t* hue_auto, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_hue_auto(uvc_device_handle_t *devh, uint8_t hue_auto)

    #uvc_error_t uvc_get_saturation(uvc_device_handle_t *devh, uint16_t* saturation, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_saturation(uvc_device_handle_t *devh, uint16_t saturation)

    #uvc_error_t uvc_get_sharpness(uvc_device_handle_t *devh, uint16_t* sharpness, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_sharpness(uvc_device_handle_t *devh, uint16_t sharpness)

    #uvc_error_t uvc_get_gamma(uvc_device_handle_t *devh, uint16_t* gamma, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_gamma(uvc_device_handle_t *devh, uint16_t gamma)

    #uvc_error_t uvc_get_white_balance_temperature(uvc_device_handle_t *devh, uint16_t* temperature, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_white_balance_temperature(uvc_device_handle_t *devh, uint16_t temperature)

    #uvc_error_t uvc_get_white_balance_temperature_auto(uvc_device_handle_t *devh, uint8_t* temperature_auto, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_white_balance_temperature_auto(uvc_device_handle_t *devh, uint8_t temperature_auto)

    #uvc_error_t uvc_get_white_balance_component(uvc_device_handle_t *devh, uint16_t* blue, uint16_t* red, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_white_balance_component(uvc_device_handle_t *devh, uint16_t blue, uint16_t red)

    #uvc_error_t uvc_get_white_balance_component_auto(uvc_device_handle_t *devh, uint8_t* white_balance_component_auto, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_white_balance_component_auto(uvc_device_handle_t *devh, uint8_t white_balance_component_auto)

    #uvc_error_t uvc_get_digital_multiplier(uvc_device_handle_t *devh, uint16_t* multiplier_step, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_digital_multiplier(uvc_device_handle_t *devh, uint16_t multiplier_step)

    #uvc_error_t uvc_get_digital_multiplier_limit(uvc_device_handle_t *devh, uint16_t* multiplier_step, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_digital_multiplier_limit(uvc_device_handle_t *devh, uint16_t multiplier_step)

    #uvc_error_t uvc_get_analog_video_standard(uvc_device_handle_t *devh, uint8_t* video_standard, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_analog_video_standard(uvc_device_handle_t *devh, uint8_t video_standard)

    #uvc_error_t uvc_get_analog_video_lock_status(uvc_device_handle_t *devh, uint8_t* status, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_analog_video_lock_status(uvc_device_handle_t *devh, uint8_t status)

    #uvc_error_t uvc_get_input_select(uvc_device_handle_t *devh, uint8_t* selector, enum uvc_req_code req_code)
    #uvc_error_t uvc_set_input_select(uvc_device_handle_t *devh, uint8_t selector)
    #/* end AUTO-GENERATED control accessors */

    #void uvc_perror(uvc_error_t err, const char *msg)
    #const char* uvc_strerror(uvc_error_t err)
    #void uvc_print_diag(uvc_device_handle_t *devh, FILE *stream)
    #void uvc_print_stream_ctrl(uvc_stream_ctrl_t *ctrl, FILE *stream)

    #uvc_frame_t *uvc_allocate_frame(size_t data_bytes)
    #void uvc_free_frame(uvc_frame_t *frame)

    #uvc_error_t uvc_duplicate_frame(uvc_frame_t *in, uvc_frame_t *out)

    #uvc_error_t uvc_yuyv2rgb(uvc_frame_t *in, uvc_frame_t *out)
    #uvc_error_t uvc_uyvy2rgb(uvc_frame_t *in, uvc_frame_t *out)
    #uvc_error_t uvc_any2rgb(uvc_frame_t *in, uvc_frame_t *out)

    #uvc_error_t uvc_yuyv2bgr(uvc_frame_t *in, uvc_frame_t *out)
    #uvc_error_t uvc_uyvy2bgr(uvc_frame_t *in, uvc_frame_t *out)
    #uvc_error_t uvc_any2bgr(uvc_frame_t *in, uvc_frame_t *out)

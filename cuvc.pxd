
from posix.time cimport timeval,timespec

cdef extern from  "libuvc/libuvc.h":
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

    cdef struct libusb_context

    cdef struct uvc_context
    ctypedef uvc_context uvc_context_t

    uvc_error_t uvc_init(uvc_context_t **ctx, libusb_context *usb_ctx)
    void uvc_exit(uvc_context_t *ctx)



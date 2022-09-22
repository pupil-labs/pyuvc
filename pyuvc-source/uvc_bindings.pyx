import logging
import platform
import warnings
from itertools import chain

import cython

from libc.string cimport memset

from typing import NamedTuple, Optional, Tuple

cimport numpy as np

import numpy as np

cimport cturbojpeg as turbojpeg
cimport cuvc as uvc
from cuvc cimport timeval, uvc_frame_t

__version__ = "0.15.0"

IF UNAME_SYSNAME == "Windows":
    include "windows_time.pxi"
ELIF UNAME_SYSNAME == "Darwin":
    include "darwin_time.pxi"
ELIF UNAME_SYSNAME == "Linux":
    include "linux_time.pxi"

from . import logger

# Until version 1.0.24, libusb did not support detaching kernel drivers on macOS. As a
# result, the cameras could only be accessed if no other driver was attached. In macOS
# Monterey, the OS attaches a driver by default. As a result, libusb needs to explicitly
# detach the driver before claiming the device. This is only implemented in newer
# versions of libusb and requires either root privileges or the
# "com.apple.vm.device-access" entitlement. The latter requires a special provisioning
# profile that is not publicly available. https://github.com/libusb/libusb/issues/1014

# To avoid requiring root privileges on every macOS version, the code below checks if
# it is running on macOS Big Sur or older and if so, disables the driver detachment
# which corresponds to libusb 1.0.24 behavior, even if libusb 1.0.25 or newer is being
# used.
_system_info = platform.uname()
if _system_info.system == "Darwin":
    logger.debug(f"Running on macOS (Kernel release {_system_info.release})")
    # https://en.wikipedia.org/wiki/Darwin_(operating_system)#Release_history
    # macOS Monterey uses Kernel version 21.*
    IS_MACOS_BIG_SUR_OR_OLDER = int(_system_info.release.split(".")[0]) < 21
    if IS_MACOS_BIG_SUR_OR_OLDER:
        logger.debug(
            "Running on macOS Big Sur or older. "
            "Will not attempt to detach kernel drivers."
        )
    else:
        logger.debug(
            "Running on macOS Monterey or newer. "
            "Requires root privileges to detach kernel drivers."
        )
else:
    logger.debug(f"Not running on macOS. Will attempt to detach kernel drivers.")
    IS_MACOS_BIG_SUR_OR_OLDER = False
cdef int SHOULD_DETACH_KERNEL_DRIVER = int(not IS_MACOS_BIG_SUR_OR_OLDER)

uvc_error_codes = {
    0:"Success (no error)",
    -1:"Input/output error",
    -2:"Invalid parameter",
    -3:"Access denied",
    -4:"No such device",
    -5:"Entity not found",
    -6:"Resource busy",
    -7:"Operation timed out",
    -8:"Overflow",
    -9:"Pipe error",
    -10:"System call interrupted",
    -11:"Insufficient memory",
    -12:"Operation not supported",
    -50:"Device is not UVC-compliant",
    -51:"Mode not supported",
    -52:"Resource has a callback (can't use polling and async)",
    -99:"Undefined error",
}


cdef str _to_str(object s):
    if type(s) is str:
        return <str>s
    else:
        return (<bytes>s).decode('utf-8')

class CaptureError(Exception):
    pass

class StreamError(CaptureError):
    pass

class InitError(CaptureError):
    pass

class OpenError(InitError):
    pass

class DeviceNotFoundError(InitError):
    def __init__(self, message):
        super().__init__(message)


CameraMode = NamedTuple(
    "CameraMode",
    [
        ("width", int),
        ("height", int),
        ("fps", int),
        ("format_native", int),
        ("format_name", str),
        ("supported", bool)
    ],
)

_supported_formats = (uvc.UVC_FRAME_FORMAT_GRAY8, uvc.UVC_FRAME_FORMAT_MJPEG)


cdef class Frame:
    cdef uvc.uvc_frame * _uvc_frame
    cdef bint owns_uvc_frame

    cdef public double timestamp

    cdef attach_uvcframe(self,uvc.uvc_frame *uvc_frame,copy=True):
        if copy:
            self._uvc_frame = uvc.uvc_allocate_frame(uvc_frame.data_bytes)
            uvc.uvc_duplicate_frame(uvc_frame,self._uvc_frame)
            self.owns_uvc_frame = True
        else:
            self._uvc_frame = uvc_frame
            self.owns_uvc_frame = False

    def __dealloc__(self):
        if self.owns_uvc_frame:
            uvc.uvc_free_frame(self._uvc_frame)

    @property
    def data_fully_received(self):
        return self._uvc_frame.width * self._uvc_frame.height == self._uvc_frame.data_bytes

    property width:
        def __get__(self):
            return self._uvc_frame.width

    property height:
        def __get__(self):
            return self._uvc_frame.height

    property index:
        def __get__(self):
            return self._uvc_frame.sequence

    property gray:
        def __get__(self):
            cdef np.uint8_t[::1] view
            if self._uvc_frame.width * self._uvc_frame.height > self._uvc_frame.data_bytes:
                logger.debug(
                    f"Received less data than expected ({self._uvc_frame.data_bytes} / "
                    f"{self._uvc_frame.width * self._uvc_frame.height})"
                )
                # less data transferred than expected, filling with zeros
                view = <np.uint8_t[:self._uvc_frame.data_bytes]>self._uvc_frame.data
                frame = 255 + np.zeros((self._uvc_frame.height * self._uvc_frame.width), dtype=np.uint8)
                frame[:self._uvc_frame.data_bytes] = view
            else:
                view = <np.uint8_t[:self._uvc_frame.height*self._uvc_frame.width]>self._uvc_frame.data
                frame = np.asarray(view)
            return frame.reshape((self._uvc_frame.height, self._uvc_frame.width))

    @property
    def bgr(self):
        return np.stack([self.gray] * 3, axis=2)

    @property
    def yuv_buffer(self):
        return None

    #for legacy reasons.
    @property
    def img(self):
        return self.bgr


cdef class MJPEGFrame(Frame):
    '''
    The Frame Object holds image data and image metadata.

    The Frame object is returned from Capture.get_frame()

    It will hold the data in the transport format the Capture is configured to grab.
    Usually this is mjpeg or yuyv

    Other formats can be requested and will be converted/decoded on the fly.
    Frame will use caching to avoid redunant work.
    Usually RGB8,YUYV or GRAY are requested formats.

    WARNING:
    When capture.get_frame() is called again previos instances of Frame will point to invalid memory.
    Specifically all image data in the capture transport format.
    Previously converted formats are still valid.
    '''

    cdef turbojpeg.tjhandle tj_context
    cdef unsigned char[:] _bgr_buffer, _gray_buffer,_yuv_buffer #we use numpy for memory management.
    cdef bint _yuv_converted, _bgr_converted
    cdef bint _data_fully_received
    cdef public yuv_subsampling

    def __cinit__(self):
        self._data_fully_received = True
        self._yuv_converted = False
        self._bgr_converted = False
        self.tj_context = NULL

    def __init__(self):
        pass

    property jpeg_buffer:
        def __get__(self):
            cdef np.uint8_t[::1] view = <np.uint8_t[:self._uvc_frame.data_bytes]>self._uvc_frame.data
            return view

    property yuv_buffer:
        def __get__(self):
            if self._yuv_converted is False:
                self.jpeg2yuv()
            cdef np.uint8_t[::1] view = <np.uint8_t[:self._yuv_buffer.shape[0]]>&self._yuv_buffer[0]
            return view

    property yuv420:
        def __get__(self):
            '''
            planar YUV420 returned in 3 numpy arrays:
            420 subsampling:
                Y(height,width) U(height/2,width/2), V(height/2,width/2)
            '''
            if self._yuv_converted is False:
                self.jpeg2yuv()

            cdef np.ndarray[np.uint8_t, ndim=2] Y,U,V
            y_plane_len = self.width*self.height
            Y = np.asarray(self._yuv_buffer[:y_plane_len]).reshape(self.height,self.width)

            if self.yuv_subsampling == turbojpeg.TJSAMP_422:
                uv_plane_len = y_plane_len//2
                offset = y_plane_len
                U = np.asarray(self._yuv_buffer[offset:offset+uv_plane_len]).reshape(self.height,self.width//2)
                offset += uv_plane_len
                V = np.asarray(self._yuv_buffer[offset:offset+uv_plane_len]).reshape(self.height,self.width//2)
                #hack solution to go from YUV422 to YUV420
                U = U[::2,:]
                V = V[::2,:]
            elif self.yuv_subsampling == turbojpeg.TJSAMP_420:
                uv_plane_len = y_plane_len//4
                offset = y_plane_len
                U = np.asarray(self._yuv_buffer[offset:offset+uv_plane_len]).reshape(self.height//2,self.width//2)
                offset += uv_plane_len
                V = np.asarray(self._yuv_buffer[offset:offset+uv_plane_len]).reshape(self.height//2,self.width//2)
            elif self.yuv_subsampling == turbojpeg.TJSAMP_444:
                uv_plane_len = y_plane_len
                offset = y_plane_len
                U = np.asarray(self._yuv_buffer[offset:offset+uv_plane_len]).reshape(self.height,self.width)
                offset += uv_plane_len
                V = np.asarray(self._yuv_buffer[offset:offset+uv_plane_len]).reshape(self.height,self.width)
                #hack solution to go from YUV444 to YUV420
                U = U[::2,::2]
                V = V[::2,::2]
            return Y,U,V

    property yuv422:
        def __get__(self):
            '''
            planar YUV420 returned in 3 numpy arrays:
            422 subsampling:
                Y(height,width) U(height,width/2), V(height,width/2)
            '''
            if self._yuv_converted is False:
                self.jpeg2yuv()

            cdef np.ndarray[np.uint8_t, ndim=2] Y,U,V
            y_plane_len = self.width*self.height
            Y = np.asarray(self._yuv_buffer[:y_plane_len]).reshape(self.height,self.width)

            if self.yuv_subsampling == turbojpeg.TJSAMP_422:
                uv_plane_len = y_plane_len//2
                offset = y_plane_len
                U = np.asarray(self._yuv_buffer[offset:offset+uv_plane_len]).reshape(self.height,self.width//2)
                offset += uv_plane_len
                V = np.asarray(self._yuv_buffer[offset:offset+uv_plane_len]).reshape(self.height,self.width//2)
            elif self.yuv_subsampling == turbojpeg.TJSAMP_420:
                raise Exception("can not convert from YUV420 to YUV422")
            elif self.yuv_subsampling == turbojpeg.TJSAMP_444:
                uv_plane_len = y_plane_len
                offset = y_plane_len
                U = np.asarray(self._yuv_buffer[offset:offset+uv_plane_len]).reshape(self.height,self.width)
                offset += uv_plane_len
                V = np.asarray(self._yuv_buffer[offset:offset+uv_plane_len]).reshape(self.height,self.width)
                #hack solution to go from YUV444 to YUV420
                U = U[:,::2]
                V = V[:,::2]
            return Y,U,V


    property gray:
        def __get__(self):
            # return gray aka luminace plane of YUV image.
            if self._yuv_converted is False:
                self.jpeg2yuv()
            cdef np.ndarray[np.uint8_t, ndim=2] Y
            Y = np.asarray(self._yuv_buffer[:self.width*self.height]).reshape(self.height,self.width)
            return Y


    property bgr:
        def __get__(self):
            if self._bgr_converted is False:
                if self._yuv_converted is False:
                    self.jpeg2yuv()
                self.yuv2bgr()

            cdef np.ndarray[np.uint8_t, ndim=3] BGR
            BGR = np.asarray(self._bgr_buffer).reshape(self.height,self.width,3)
            return BGR


    cdef yuv2bgr(self):
        #2.75 ms at 1080p
        cdef int channels = 3
        cdef int result
        self._bgr_buffer = np.empty(self.width*self.height*channels, dtype=np.uint8)
        result = turbojpeg.tjDecodeYUV(self.tj_context, &self._yuv_buffer[0], 4, self.yuv_subsampling,
                                        &self._bgr_buffer[0], self.width, 0, self.height, turbojpeg.TJPF_BGR, 0)
        if result == -1:
            logger.error('Turbojpeg yuv2bgr: %s'%turbojpeg.tjGetErrorStr() )
        self._bgr_converted = True


    cdef jpeg2yuv(self):
        # 7.55 ms on 1080p
        cdef int channels = 1
        cdef int jpegSubsamp, j_width,j_height
        cdef int result
        cdef long unsigned int buf_size
        result = turbojpeg.tjDecompressHeader2(self.tj_context,  <unsigned char *>self._uvc_frame.data,
                                               self._uvc_frame.data_bytes, &j_width, &j_height, &jpegSubsamp)

        if result == -1:
            logger.error('Turbojpeg could not read jpeg header: %s'%turbojpeg.tjGetErrorStr() )
            # hacky creation of dummy data, this will break if capture does work with different subsampling:
            j_width, j_height, jpegSubsamp = self.width, self.height, turbojpeg.TJSAMP_422

        buf_size = turbojpeg.tjBufSizeYUV(j_width, j_height, jpegSubsamp)
        self._yuv_buffer = np.empty(buf_size, dtype=np.uint8)
        if result !=-1:
            result =  turbojpeg.tjDecompressToYUV(self.tj_context,
                                             <unsigned char *>self._uvc_frame.data,
                                             self._uvc_frame.data_bytes,
                                             &self._yuv_buffer[0],
                                              0)
        if result == -1:
            self._data_fully_received = False
            logger.warning('Turbojpeg jpeg2yuv: %s'%turbojpeg.tjGetErrorStr() )
        self.yuv_subsampling = jpegSubsamp
        self._yuv_converted = True

    @property
    def data_fully_received(self):
        return self._data_fully_received

    def clear_caches(self):
        self._bgr_converted = False
        self._yuv_converted = False



cdef class Device_List(list):
    cdef uvc.uvc_context_t  * ctx


    def __cinit__(self):
        self.ctx = NULL
        cdef int ret = uvc.uvc_init(&self.ctx,NULL)
        if ret !=uvc.UVC_SUCCESS:
            raise InitError("Could not initialize uvc context.")

    def __init__(self):
        self.update()

    cpdef update(self):
        cdef uvc.uvc_device_t ** dev_list
        cdef uvc.uvc_device_t * dev
        cdef uvc.uvc_device_descriptor_t *desc

        if self.ctx == NULL:
            raise EnvironmentError("Device list uvc context is NULL.")

        ret = uvc.uvc_get_device_list(self.ctx,&dev_list)
        if ret !=uvc.UVC_SUCCESS:
            logger.error("could not get devices list.")
            return

        devices = []
        cdef int idx = 0
        while True:
            dev = dev_list[idx]
            if dev == NULL:
                break
            if (uvc.uvc_get_device_descriptor(dev, &desc) == uvc.UVC_SUCCESS):
                product = desc.product or "unknown"
                manufacturer = desc.manufacturer or "unknown"
                serialNumber = desc.serialNumber or "unknown"
                idProduct,idVendor = desc.idProduct,desc.idVendor
                device_address = uvc.uvc_get_device_address(dev)
                bus_number = uvc.uvc_get_bus_number(dev)
                devices.append({'name':_to_str(product),
                                'manufacturer':_to_str(manufacturer),
                                'serialNumber':_to_str(serialNumber),
                                'idProduct':idProduct,
                                'idVendor':idVendor,
                                'device_address':device_address,
                                'bus_number':bus_number,
                                'uid':'%s:%s'%(bus_number,device_address)})

            uvc.uvc_free_device_descriptor(desc)
            idx +=1

        uvc.uvc_free_device_list(dev_list, 1)

        self[:] = devices

    cpdef cleanup(self):
        if self.ctx !=NULL:
            uvc.uvc_exit(self.ctx)
            self.ctx = NULL

    def __dealloc__(self):
        self.cleanup()

def device_list():
    cdef uvc.uvc_context_t * ctx
    cdef int ret = uvc.uvc_init(&ctx,NULL)
    if ret !=uvc.UVC_SUCCESS:
        logger.error("could not initialize")
        return

    cdef uvc.uvc_device_t ** dev_list
    cdef uvc.uvc_device_t * dev
    cdef uvc.uvc_device_descriptor_t *desc

    ret = uvc.uvc_get_device_list(ctx,&dev_list)
    if ret !=uvc.UVC_SUCCESS:
        logger.error("could not get devices list.")
        return

    devices = []
    cdef int idx = 0
    while True:
        dev = dev_list[idx]
        if dev == NULL:
            break
        if (uvc.uvc_get_device_descriptor(dev, &desc) == uvc.UVC_SUCCESS):
            product = desc.product or "unknown"
            manufacturer = desc.manufacturer or "unknown"
            serialNumber = desc.serialNumber or "unknown"
            idProduct,idVendor = desc.idProduct,desc.idVendor
            device_address = uvc.uvc_get_device_address(dev)
            bus_number = uvc.uvc_get_bus_number(dev)
            devices.append({'name':_to_str(product),
                            'manufacturer':_to_str(manufacturer),
                            'serialNumber':_to_str(serialNumber),
                            'idProduct':idProduct,
                            'idVendor':idVendor,
                            'device_address':device_address,
                            'bus_number':bus_number,
                            'uid':'%s:%s'%(bus_number,device_address)})

        uvc.uvc_free_device_descriptor(desc)
        idx +=1

    uvc.uvc_free_device_list(dev_list, 1)
    uvc.uvc_exit(ctx)
    return devices

include 'controls.pxi'

cdef class Capture:
    """
    Video Capture class.
    A Class giving access to a capture UVC devices.
    The intent is to grab mjpeg frames and give access to the buffer using the Frame class.

    All controls are exposed and can be enumerated using the controls list.
    """

    cdef turbojpeg.tjhandle tj_context

    cdef uvc.uvc_context_t *ctx
    cdef uvc.uvc_device_t *dev
    cdef uvc.uvc_device_handle_t *devh
    cdef uvc.uvc_stream_ctrl_t ctrl
    cdef bint _stream_on,_configured
    cdef uvc.uvc_stream_handle_t *strmh
    cdef float _bandwidth_factor

    cdef object _active_mode
    cdef list _camera_modes
    cdef dict _info
    cdef public list controls

    def __cinit__(self,dev_uid):
        self.dev = NULL
        self.ctx = NULL
        self.devh = NULL
        self._stream_on = 0
        self._configured = 0
        self.strmh = NULL
        self._camera_modes = []
        self._active_mode = None
        self._info = {}
        self.controls = []
        self._bandwidth_factor = 2.0

    def __init__(self,dev_uid):

        #setup for jpeg converter
        self.tj_context = turbojpeg.tjInitDecompress()

        if uvc.uvc_init(&self.ctx, NULL) != uvc.UVC_SUCCESS:
            raise InitError('Could not init libuvc')

        self._init_device(dev_uid)
        self._enumerate_formats()
        self._enumerate_controls()

    cdef _init_device(self,dev_uid):

        ##first we find the appropriate dev handle
        cdef uvc.uvc_device_t ** dev_list
        cdef uvc.uvc_device_descriptor_t *desc
        cdef int idx = 0
        cdef int error
        if uvc.uvc_get_device_list(self.ctx,&dev_list) !=uvc.UVC_SUCCESS:
            uvc.uvc_exit(self.ctx)
            raise InitError("could not get devices list.")

        while True:
            dev = dev_list[idx]
            if dev == NULL:
                break
            device_address = uvc.uvc_get_device_address(dev)
            bus_number = uvc.uvc_get_bus_number(dev)
            dev_uid_found = f'{bus_number}:{device_address}'
            if dev_uid == dev_uid_found:
                logger.debug(f"Found device that mached uid: {dev_uid}")
                uvc.uvc_ref_device(dev)
                if (uvc.uvc_get_device_descriptor(dev, &desc) == uvc.UVC_SUCCESS):
                    product = desc.product or "unknown"
                    manufacturer = desc.manufacturer or "unknown"
                    serialNumber = desc.serialNumber or "unknown"
                    idProduct,idVendor = desc.idProduct,desc.idVendor
                    device_address = uvc.uvc_get_device_address(dev)
                    bus_number = uvc.uvc_get_bus_number(dev)
                    self._info = {
                        'name': _to_str(product),
                        'manufacturer': _to_str(manufacturer),
                        'serialNumber': _to_str(serialNumber),
                        'idProduct': idProduct,
                        'idVendor': idVendor,
                        'device_address': device_address,
                        'bus_number': bus_number,
                        'uid': dev_uid_found,
                    }
                    logger.debug(f"Device info: {self._info}")
                uvc.uvc_free_device_descriptor(desc)
                break
            idx +=1

        uvc.uvc_free_device_list(dev_list, 1)
        if dev == NULL:
            raise DeviceNotFoundError(f"Device with uid: `{dev_uid}` not found")


        #once found we open the device
        self.dev = dev
        error = uvc.uvc_open(self.dev, &self.devh, SHOULD_DETACH_KERNEL_DRIVER)
        if error != uvc.UVC_SUCCESS:
            raise OpenError(f"Could not open device. Error: {uvc_error_codes[error]}")
        logger.debug("Device '%s' opended."%dev_uid)

    cdef _de_init_device(self):
        uvc.uvc_close(self.devh)
        self.devh = NULL
        uvc.uvc_unref_device(self.dev)
        self.dev = NULL
        logger.debug('UVC device closed.')


    cdef _restart(self):
        self._stop()
        self._re_init_device()
        self._start()

    cdef _configure_stream(self, mode: Optional[CameraMode] = None):
        if mode is None:
            if self.available_modes:
                mode = self.available_modes[0]
            else:
                raise InitError(
                    f"Error: No supported mode found. Unsupported modes: "
                    f"{self.all_modes}"
                )

        if self._stream_on:
            self._stop()

        cdef int status
        status = uvc.uvc_get_stream_ctrl_format_size(
            self.devh,
            &self.ctrl,
            mode.format_native,
            mode.width,
            mode.height,
            mode.fps,
            SHOULD_DETACH_KERNEL_DRIVER,
        )
        if status != uvc.UVC_SUCCESS:
            raise InitError(
                f"Error: Can't get stream control: {uvc_error_codes[status]} "
                f"(requested {mode.format_native})"
            )
        else:
            logger.debug(f"Negotiated frame format: {self.ctrl}")

        self._configured = 1
        self._active_mode = mode

    cdef _start(self):
        cdef int status
        if not self._configured:
            self._configure_stream()
        status = uvc.uvc_stream_open_ctrl(self.devh, &self.strmh, &self.ctrl, SHOULD_DETACH_KERNEL_DRIVER)
        if status != uvc.UVC_SUCCESS:
            raise InitError("Can't open stream control: Error:'%s'."%uvc_error_codes[status])
        status = uvc.uvc_stream_start(self.strmh, NULL, NULL, self._bandwidth_factor, 0)
        if status != uvc.UVC_SUCCESS:
            raise InitError("Can't start isochronous stream: Error:'%s'."%uvc_error_codes[status])
        self._stream_on = 1
        logger.debug("Stream start.")

    def stop_stream(self):
        self._stop()

    cdef _stop(self):
        cdef int status = 0
        status = uvc.uvc_stream_stop(self.strmh)
        if status != uvc.UVC_SUCCESS:
            #raise Exception("Can't stop  stream: Error:'%s'."%uvc_error_codes[status])
            logger.error("Can't stop stream: Error:'%s'. Will ignore this and try to continue."%uvc_error_codes[status])
        else:
            logger.debug("Stream stopped")
        uvc.uvc_stream_close(self.strmh)
        logger.debug("Stream closed")
        self._stream_on = 0
        logger.debug("Stream stop.")

    def get_frame_robust(self):
        cdef int a,attempts = 3
        for a in range(attempts):
            try:
                frame = self.get_frame()
            except StreamError as e:
                logger.debug(
                    f"Could not get Frame of first try: '{e}'. Attempt: "
                    f"{a+1}/{attempts}"
                )
            else:
                return frame
        raise StreamError("Could not grab frame after 3 attempts. Giving up.")

    def get_frame(self,timeout=0):
        cdef int status, j_width, j_height, jpegSubsamp, header_ok
        cdef int  timeout_usec = int(timeout*1e6) #sec to usec
        if not self._stream_on:
            self._start()
        cdef uvc.uvc_frame *uvc_frame = NULL
        #when this is called we will overwrite the last jpeg buffer! This can be dangerous!
        with nogil:
            status = uvc.uvc_stream_get_frame(self.strmh, &uvc_frame, timeout_usec)
        if status == uvc.UVC_ERROR_TIMEOUT:
            raise TimeoutError
        elif status != uvc.UVC_SUCCESS:
            raise StreamError(uvc_error_codes[status])
        if uvc_frame is NULL:
            raise StreamError("Frame pointer is NULL")

        cdef Frame out_frame_gray
        cdef MJPEGFrame out_frame_mjpeg
        cdef object frame

        if uvc_frame.frame_format == uvc.UVC_COLOR_FORMAT_MJPEG:
            ##check jpeg header
            header_ok = turbojpeg.tjDecompressHeader2(
                self.tj_context,
                <unsigned char *>uvc_frame.data,
                uvc_frame.data_bytes,
                &j_width,
                &j_height,
                &jpegSubsamp
            )
            if not (
                header_ok >= 0 and
                uvc_frame.width == j_width and
                uvc_frame.height == j_height
            ):
                raise StreamError("JPEG header corrupt.")
            out_frame_mjpeg = MJPEGFrame()
            out_frame_mjpeg.tj_context = self.tj_context
            out_frame_mjpeg.attach_uvcframe(uvc_frame=uvc_frame, copy=True)
            frame = out_frame_mjpeg

        elif uvc_frame.frame_format == uvc.UVC_COLOR_FORMAT_GRAY8:
            # if uvc_frame.width * uvc_frame.height > uvc_frame.data_bytes:
            #     raise StreamError(
            #         f"Received too few bytes to fill {uvc_frame.width}x"
            #         f"{uvc_frame.height} GRAY8 image"
            #     )
            out_frame_gray = Frame()
            out_frame_gray.attach_uvcframe(uvc_frame=uvc_frame, copy=True)
            frame = out_frame_gray

        else:
            raise NotImplementedError(f"Unsupported frame format {uvc_frame.frame_format}")

        frame.timestamp = uvc_frame.capture_time.tv_sec + <double>uvc_frame.capture_time.tv_usec * 1e-6
        return frame


    cdef _enumerate_controls(self):

        cdef uvc.uvc_input_terminal_t *input_terminal = <uvc.uvc_input_terminal_t *>uvc.uvc_get_input_terminals(self.devh)
        cdef uvc.uvc_output_terminal_t *output_terminal = <uvc.uvc_output_terminal_t *>uvc.uvc_get_output_terminals(self.devh)
        cdef uvc.uvc_processing_unit_t *processing_unit = <uvc.uvc_processing_unit_t *>uvc.uvc_get_processing_units(self.devh)
        cdef uvc.uvc_extension_unit_t *extension_unit = <uvc.uvc_extension_unit_t *>uvc.uvc_get_extension_units(self.devh)

        cdef int x = 0
        avaible_controls_per_unit = {}
        id_per_unit = {}
        extension_units = {}
        while extension_unit !=NULL:
            guidExtensionCode = uint_array_to_GuidCode(extension_unit.guidExtensionCode)
            id_per_unit[guidExtensionCode] = extension_unit.bUnitID
            avaible_controls_per_unit[guidExtensionCode] = extension_unit.bmControls
            extension_unit = extension_unit.next


        while input_terminal !=NULL:
            avaible_controls_per_unit['input_terminal'] = input_terminal.bmControls
            id_per_unit['input_terminal'] = input_terminal.bTerminalID
            input_terminal = input_terminal.next

        while processing_unit !=NULL:
            avaible_controls_per_unit['processing_unit'] = processing_unit.bmControls
            id_per_unit['processing_unit'] = processing_unit.bUnitID
            processing_unit = processing_unit.next

        cdef Control control
        for std_ctl in standard_ctrl_units:
            if std_ctl['bit_mask'] & avaible_controls_per_unit[std_ctl['unit']]:

                logger.debug('Adding "%s" control.'%std_ctl['display_name'])

                std_ctl['unit_id'] = id_per_unit[std_ctl['unit']]
                try:
                    control= Control(cap = self,**std_ctl)
                except Exception as e:
                    import traceback

                    logger.debug(f"Could not init {std_ctl['display_name']} control!")
                    logger.debug(f"Control info: {std_ctl}")
                    logger.debug(traceback.format_exc())
                else:
                    self.controls.append(control)


        #uvc.PyEval_InitThreads()
        #uvc.uvc_set_status_callback(self.devh, on_status_update,<void*>self)


    cdef _enumerate_formats(self):
        cdef uvc.uvc_format_desc_t *format_desc = <uvc.uvc_format_desc_t *>uvc.uvc_get_format_descs(self.devh)
        cdef uvc.uvc_frame_desc *frame_desc
        cdef int i
        self._camera_modes = []
        cdef uvc.uvc_frame_format format_native
        cdef str format_name

        while format_desc is not NULL:
            frame_desc = format_desc.frame_descs

            format_native = uvc.uvc_frame_format_for_guid(format_desc.guidFormat)
            format_name = (<char*>format_desc.fourccFormat).decode('UTF-8')
            is_format_supported = (format_native in _supported_formats)
            while frame_desc is not NULL:
                i = 0
                while frame_desc.intervals[i]:
                    fps = interval_to_fps(frame_desc.intervals[i])
                    self._camera_modes.append(
                        CameraMode(
                            width=frame_desc.wWidth,
                            height=frame_desc.wHeight,
                            fps=fps,
                            format_native=format_native,
                            format_name=format_name,
                            supported=is_format_supported,
                        )
                    )
                    i+=1

                #go to next frame_desc
                frame_desc = frame_desc.next

            #go to next format_desc
            format_desc = format_desc.next

        logger.debug(f'{self} - all camera modes: {self._camera_modes}')

    def __str__(self):
        meta = " ".join((f'{k}={v!r}' for k,v in self._info.iteritems()))
        return f"Capture({meta})"


    def close(self):
        if self._stream_on:
            self._stop()
        if self.devh != NULL:
            self._de_init_device()
        if self.ctx != NULL:
            uvc.uvc_exit(self.ctx)
            self.ctx = NULL
            turbojpeg.tjDestroy(self.tj_context)
            self.tj_context = NULL

    def __dealloc__(self):
        self.close()


    @property
    def frame_size(self) -> Tuple[int, int]:
        if self._active_mode:
            return (self._active_mode.width, self._active_mode.height)

    @frame_size.setter
    def frame_size(self, size: Tuple[int, int]):
        for mode in self.available_modes:
            if size == (mode.width, mode.height):
                if self.frame_rate is not None:
                    #closest match for rate
                    rates = [abs(m.fps-self.frame_rate) for m in self.available_modes]
                    best_rate_idx = rates.index(min(rates))
                    mode = self.available_modes[best_rate_idx]
                self._configure_stream(mode)
                return
        raise ValueError("Frame size not suported.")

    property frame_rate:
        def __get__(self):
            if self._active_mode:
                return self._active_mode.fps

        def __set__(self, val):
            if self._active_mode and self._active_mode.fps == val:
                return
            elif self._active_mode:
                for mode in self.available_modes:
                    if (
                        mode.width == self._active_mode.width and
                        mode.height == self._active_mode.height and
                        mode.fps == val
                    ):
                        self.frame_mode = mode
                        return
                raise ValueError(
                    f"No available mode with target frame rate {val} Hz found: "
                    f"{self.available_modes}"
                )
            else:
                logger.warning("Could not set frame rate. Set frame size first.")

    property frame_sizes:
        def __get__(self):
            return [(m.width, m.height) for m in self._camera_modes]

    property frame_rates:
        def __get__(self):
            frame_rates = [
                m.fps for m in self._camera_modes
                if (m.width, m.height) == self.frame_size
            ]
            if not frame_rates:
                raise ValueError("Please set frame_size before asking for rates.")
            return frame_rates


    @property
    def frame_mode(self) -> CameraMode:
        return self._active_mode

    @frame_mode.setter
    def frame_mode(self, mode: CameraMode):
        logger.debug(f"Setting mode: {mode}")
        self._configure_stream(mode)

    @property
    def available_modes(self) -> Tuple[CameraMode,...]:
        return tuple(mode for mode in self._camera_modes if mode.supported)

    @property
    def all_modes(self) -> Tuple[CameraMode,...]:
        return tuple(self._camera_modes)
    property name:
        def __get__(self):
            return self._info['name']

    property bandwidth_factor:
        def __get__(self):
            return self._bandwidth_factor
        def __set__(self,bandwidth_factor):
            if self._bandwidth_factor != bandwidth_factor:
                self._bandwidth_factor = bandwidth_factor
                if self._stream_on:
                    self._stop()

cdef void on_status_update(uvc.uvc_status_class status_class,
                        int event,
                        int selector,
                        uvc.uvc_status_attribute status_attribute,
                        void *data,
                        size_t data_len,
                        void *user_ptr) with gil:
    pass
    #"Callback"
    #status_class, event,selector,status_attribute,data_len
    #<object>user_ptr

cdef inline int interval_to_fps(int interval):
    return int(10000000./interval)


cdef inline str uint_array_to_GuidCode(uvc.uint8_t * u):
    cdef str s = ''
    cdef int x
    for x in range(16):
        s += "{0:0{1}x}".format(u[x],2) # map int to rwo digit hex without "0x" prefix.
    return '%s%s%s%s%s%s%s%s-%s%s%s%s-%s%s%s%s-%s%s%s%s-%s%s%s%s%s%s%s%s%s%s%s%s'%tuple(s)

def get_time_monotonic():
    return get_sys_time_monotonic()

def is_accessible(dev_uid):
    cdef uvc.uvc_context_t * ctx
    cdef uvc.uvc_device_t ** dev_list
    cdef uvc.uvc_device_t * dev = NULL
    cdef uvc.uvc_device_handle_t *devh

    cdef int ret = uvc.uvc_init(&ctx,NULL)
    if ret !=uvc.UVC_SUCCESS:
        raise InitError("Could not initialize")

    ret = uvc.uvc_get_device_list(ctx,&dev_list)
    if ret !=uvc.UVC_SUCCESS:
        raise InitError("could not get devices list.")

    cdef int idx = 0
    while True:
        dev = dev_list[idx]
        if dev == NULL:
            break
        device_address = uvc.uvc_get_device_address(dev)
        bus_number = uvc.uvc_get_bus_number(dev)
        if dev_uid == '%s:%s'%(bus_number,device_address):
            logger.debug("Found device that mached uid:'%s'"%dev_uid)
            uvc.uvc_ref_device(dev)
            break
        idx +=1
    uvc.uvc_free_device_list(dev_list, 1)
    if dev == NULL:
        raise ValueError("Device with uid: '%s' not found"%dev_uid)

    #once found we open the device
    error = uvc.uvc_open(dev, &devh, SHOULD_DETACH_KERNEL_DRIVER)
    if error != uvc.UVC_SUCCESS:
        uvc.uvc_unref_device(dev)
        uvc.uvc_exit(ctx)
        return False
    else:
        uvc.uvc_close(devh)
        uvc.uvc_unref_device(dev)
        uvc.uvc_exit(ctx)
        return True

import cython
cimport cuvc as uvc
cimport cturbojpeg as turbojpeg
cimport numpy as np
import numpy as np


uvc_error_codes = {  0:"Success (no error)",
                    -1:"Input/output error.",
                    -2:"Invalid parameter.",
                    -3:"Access denied.",
                    -4:"No such device.",
                    -5:"Entity not found.",
                    -6:"Resource busy.",
                    -7:"Operation timed out.",
                    -8:"Overflow.",
                    -9:"Pipe error.",
                    -10:"System call interrupted.",
                    -11:"Insufficient memory.     ",
                    -12:"Operation not supported.",
                    -50:"Device is not UVC-compliant.",
                    -51:"Mode not supported.",
                    -52:"Resource has a callback (can't use polling and async)",
                    -99:"Undefined error."}



#logging
import logging
logger = logging.getLogger(__name__)

__version__ = '0.1' #make sure this is the same in setup.py


cdef class buffer_handle:
    cdef void *start
    cdef size_t length

    def __repr__(self):
        return  "Buffer pointing to %s. length: %s"%(<int>self.start,self.length)



cdef class Frame:
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
    Specifically the image format in the capture transport format.
    Previously converted formats are still valid.
    '''

    cdef turbojpeg.tjhandle tj_context
    cdef buffer_handle _jpeg_buffer
    cdef unsigned char[:] _bgr_buffer, _gray_buffer,_yuv_buffer #we use numpy for memory management.
    cdef bint _yuv_converted, _bgr_converted
    cdef public double timestamp
    cdef public int width,height, yuv_subsampling

    def __cinit__(self):
        # pass
        # self._jpeg_buffer.start = NULL doing this leads to the very strange behaivour of numpy slicing to break!
        self._yuv_converted = False
        self._bgr_converted = False
    def __init__(self):
        pass


    property jpeg_buffer:
        def __set__(self,buffer_handle buffer):
            self._jpeg_buffer = buffer

        def __get__(self):
            #retuns buffer handle to jpeg buffer
            if self._jpeg_buffer.start == NULL:
                raise Exception("jpeg buffer not used and not allocated.")
            return self._jpeg_buffer


    property yuv422_buffer:
        def __get__(self):
            #retuns buffer handle to yuv422 buffer
            if self._yuv_converted == False:
                if self._jpeg_buffer.start != NULL:
                    self.jpeg2yuv()
                else:
                    raise Exception("No source image data found to convert from.")
            if self.yuv_subsampling != turbojpeg.TJSAMP_422:
                raise Exception('YUV buffer avaible but not in yuv422.')
            cdef buffer_handle buf = buffer_handle()
            buf.start = <void*>(&self._yuv_buffer[0])
            buf.length = self._yuv_buffer.shape[0]
            return buf


    property yuv:
        def __get__(self):
            '''
            planar YUV420 returned in 3 numpy arrays:
            420 subsampling:
                Y(height,width) U(height/2,width/2), V(height/2,width/2)
            '''
            if self._yuv_converted is False:
                if self._jpeg_buffer.start != NULL:
                    self.jpeg2yuv()
                else:
                    raise Exception("No source image data found to convert from.")

            cdef np.ndarray[np.uint8_t, ndim=2] Y,U,V
            y_plane_len = self.width*self.height
            Y = np.asarray(self._yuv_buffer[:y_plane_len]).reshape(self.height,self.width)

            if self.yuv_subsampling == turbojpeg.TJSAMP_422:
                uv_plane_len = y_plane_len/2
                offset = y_plane_len
                U = np.asarray(self._yuv_buffer[offset:offset+uv_plane_len]).reshape(self.height,self.width/2)
                offset += uv_plane_len
                V = np.asarray(self._yuv_buffer[offset:offset+uv_plane_len]).reshape(self.height,self.width/2)
                #hack solution to go from YUV422 to YUV420
                U = U[::2,:]
                V = V[::2,:]
            elif self.yuv_subsampling == turbojpeg.TJSAMP_420:
                uv_plane_len = y_plane_len/4
                offset = y_plane_len
                U = np.asarray(self._yuv_buffer[offset:offset+uv_plane_len]).reshape(self.height/2,self.width/2)
                offset += uv_plane_len
                V = np.asarray(self._yuv_buffer[offset:offset+uv_plane_len]).reshape(self.height/2,self.width/2)
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

    property gray:
        def __get__(self):
            # return gray aka luminace plane of YUV image.
            if self._yuv_converted is False:
                if self._jpeg_buffer.start != NULL:
                    self.jpeg2yuv()
                else:
                    raise Exception("No source image data found to convert from.")
            cdef np.ndarray[np.uint8_t, ndim=2] Y
            Y = np.asarray(self._yuv_buffer[:self.width*self.height]).reshape(self.height,self.width)
            return Y



    property bgr:
        def __get__(self):
            if self._bgr_converted is False:
                #toggle conversion if needed
                _ = self.yuv
                self.yuv2bgr()

            cdef np.ndarray[np.uint8_t, ndim=3] BGR
            BGR = np.asarray(self._bgr_buffer).reshape(self.height,self.width,3)
            return BGR


    #for legacy reasons.
    property img:
        def __get__(self):
            return self.bgr

    cdef yuv2bgr(self):
        #2.75 ms at 1080p
        cdef int channels = 3
        cdef int result
        self._bgr_buffer = np.empty(self.width*self.height*channels, dtype=np.uint8)
        result = turbojpeg.tjDecodeYUV(self.tj_context, &self._yuv_buffer[0], 4, self.yuv_subsampling,
                                        &self._bgr_buffer[0], self.width, 0, self.height, turbojpeg.TJPF_BGR, 0)
        if result == -1:
            logger.error('Turbojpeg yuv2bgr error: %s'%turbojpeg.tjGetErrorStr() )
        self._bgr_converted = True


    cdef jpeg2yuv(self):
        # 7.55 ms on 1080p
        cdef int channels = 1
        cdef int jpegSubsamp, j_width,j_height
        cdef int result
        cdef long unsigned int buf_size
        result = turbojpeg.tjDecompressHeader2(self.tj_context,  <unsigned char *>self._jpeg_buffer.start,
                                        self._jpeg_buffer.length,
                                        &j_width, &j_height, &jpegSubsamp)

        if result == -1:
            logger.error('Turbojpeg could not read jpeg header: %s'%turbojpeg.tjGetErrorStr() )
            # hacky creation of dummy data, this will break if capture does work with different subsampling:
            j_width, j_height, jpegSubsamp = self.width, self.height, turbojpeg.TJSAMP_422

        buf_size = turbojpeg.tjBufSizeYUV(j_width, j_height, jpegSubsamp)
        self._yuv_buffer = np.empty(buf_size, dtype=np.uint8)
        if result !=-1:
            result =  turbojpeg.tjDecompressToYUV(self.tj_context,
                                             <unsigned char *>self._jpeg_buffer.start,
                                             self._jpeg_buffer.length,
                                             &self._yuv_buffer[0],
                                              0)
        if result == -1:
            logger.error('Turbojpeg jpeg2yuv error: %s'%turbojpeg.tjGetErrorStr() )
        self.yuv_subsampling = jpegSubsamp
        self._yuv_converted = True


    def clear_caches(self):
        self._bgr_converted = False
        self._yuv_converted = False


def test():
    cdef uvc.uvc_context_t * ctx
    print uvc.uvc_init(&ctx,NULL)
    uvc.uvc_exit(ctx)

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
            devices.append({'name':product,
                            'manufacturer':manufacturer,
                            'serialNumber':serialNumber,
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
    cdef bint _stream_on
    cdef uvc.uvc_stream_handle_t *strmh
    cdef uvc.uvc_frame *uvc_frame

    def __cinit__(self,dev_uid):
        self.dev = NULL
        self.ctx = NULL
        self.devh = NULL
        self._stream_on = 0
        self.strmh = NULL
        self.uvc_frame = NULL

    def __init__(self,dev_uid):

        #setup for jpeg converter
        self.tj_context = turbojpeg.tjInitDecompress()

        if uvc.uvc_init(&self.ctx, NULL) != uvc.UVC_SUCCESS:
            raise Exception('Could not init libuvc')

        self._init_device(dev_uid)



    cdef _init_device(self,dev_uid):

        ##first we find the appropriate dev handle
        cdef uvc.uvc_device_t ** dev_list
        cdef uvc.uvc_device_descriptor_t *desc
        cdef int idx = 0
        cdef int error
        if uvc.uvc_get_device_list(self.ctx,&dev_list) !=uvc.UVC_SUCCESS:
            uvc.uvc_exit(self.ctx)
            raise Exception("could not get devices list.")

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
            uvc.uvc_exit(self.ctx)
            raise Exception("Device with uid: '%s' not found"%dev_uid)


        #once found we open the device
        self.dev = dev
        error = uvc.uvc_open(self.dev,&self.devh)
        if error != uvc.UVC_SUCCESS:
            uvc.uvc_exit(self.ctx)
            raise Exception("could not open device. Error:%s"%uvc_error_codes[error])
        logger.debug("Device '%s' opended."%dev_uid)

    cdef _de_init_device(self):
        uvc.uvc_close(self.devh)
        self.devh = NULL
        uvc.uvc_unref_device(self.dev)
        self.dev = NULL
        logger.debug('UVC device closed.')


    def __dealloc__(self):
        if self._stream_on:
            self.stop()
        if self.devh != NULL:
            self._de_init_device()
        uvc.uvc_exit(self.ctx)
        turbojpeg.tjDestroy(self.tj_context)


    def restart(self):
        self.stop()
        self.start()

    def print_info(self):
        pass

    def get_frame_robust(self):
        cdef int a,r, attempts = 3,restarts = 2
        for r in range(restarts):
            for a in range(attempts)[::-1]:
                try:
                    frame = self.get_frame()
                except Exception as e:
                    logger.warning('Could not get Frame Error:"%s". Trying %s more times.'%(e,a))
                else:
                    return frame
            logger.warning("Could not grab frame. Restarting device")
            self.restart()
        raise Exception("Could not grab frame. Giving up.")



    def start(self):
        cdef int status
        status = uvc.uvc_get_stream_ctrl_format_size( self.devh, &self.ctrl,
                                                      uvc.UVC_FRAME_FORMAT_COMPRESSED,
                                                      640, 480, 120 )



        status = uvc.uvc_stream_open_ctrl(self.devh, &self.strmh, &self.ctrl)
        if status != uvc.UVC_SUCCESS:
            raise Exception("Can't open stream control: Error:'%s'."%uvc_error_codes[status])
        status = uvc.uvc_stream_start_iso(self.strmh, NULL, NULL)
        if status != uvc.UVC_SUCCESS:
            raise Exception("Can't start isochronous stream: Error:'%s'."%uvc_error_codes[status])
        self._stream_on = 1
        logger.debug("Stream start.")

    def stop(self):
        uvc.uvc_stop_streaming(self.devh)
        self._stream_on = 0
        logger.debug("Stream stop.")



    def get_frame(self):
        cdef int status, j_width,j_height,jpegSubsamp,header_ok
        cdef int  timeout_usec = 1000000 #1sec
        if not self._stream_on:
            self.start()
        cdef uvc.uvc_frame *uvc_frame = NULL
        status = uvc.uvc_stream_get_frame(self.strmh,&uvc_frame,timeout_usec)
        if status !=uvc.UVC_SUCCESS:
            raise Exception("Error:'%s'."%uvc_error_codes[status])
        if uvc_frame is NULL:
            raise Exception("Frame pointer is NULL")

        cdef Frame out_frame = Frame()
        out_frame.tj_context = self.tj_context

        out_frame.width,out_frame.height = uvc_frame.width,uvc_frame.height
        cdef buffer_handle buf = buffer_handle()
        buf.start = uvc_frame.data
        buf.length = uvc_frame.data_bytes


        ##check jpeg header
        header_ok = turbojpeg.tjDecompressHeader2(self.tj_context,  <unsigned char *>buf.start, buf.length, &j_width, &j_height, &jpegSubsamp)
        if header_ok >=0 and out_frame.width == j_width and out_frame.height == out_frame.height:
            out_frame.jpeg_buffer = buf
        else:
            raise Exception("JPEG header corrupted.")
        return out_frame



#    cdef set_format(self):
#        cdef v4l2.v4l2_format  format
#        format.type = v4l2.V4L2_BUF_TYPE_VIDEO_CAPTURE
#        format.fmt.pix.width       = self.frame_size[0]
#        format.fmt.pix.height      = self.frame_size[1]
#        format.fmt.pix.pixelformat = self._transport_format


#        format.fmt.pix.field       = v4l2.V4L2_FIELD_ANY
#        if self.xioctl(v4l2.VIDIOC_S_FMT, &format) == -1:
#            self.close()
#            raise Exception("Could not set v4l2 format")

#    cdef set_streamparm(self):
#        cdef v4l2.v4l2_streamparm streamparm
#        streamparm.type = v4l2.V4L2_BUF_TYPE_VIDEO_CAPTURE
#        streamparm.parm.capture.timeperframe.numerator = self.frame_rate[0]
#        streamparm.parm.capture.timeperframe.denominator = self.frame_rate[1]
#        if self.xioctl(v4l2.VIDIOC_S_PARM, &streamparm) == -1:
#            self.close()
#            raise Exception("Could not set v4l2 parameters")


#    cdef get_format(self):
#        cdef v4l2.v4l2_format format
#        format.type = v4l2.V4L2_BUF_TYPE_VIDEO_CAPTURE
#        if self.xioctl(v4l2.VIDIOC_G_FMT, &format) == -1:
#            self.close()
#            raise Exception("Could not get v4l2 format")
#        else:
#            self._frame_size = format.fmt.pix.width,format.fmt.pix.height
#            self._transport_format = format.fmt.pix.pixelformat

#    cdef get_streamparm(self):
#        cdef v4l2.v4l2_streamparm streamparm
#        streamparm.type = v4l2.V4L2_BUF_TYPE_VIDEO_CAPTURE
#        if self.xioctl(v4l2.VIDIOC_G_PARM, &streamparm) == -1:
#            self.close()
#            raise Exception("Could not get v4l2 parameters")
#        else:
#            self._frame_rate = streamparm.parm.capture.timeperframe.numerator,streamparm.parm.capture.timeperframe.denominator


#    property transport_formats:
#        def __get__(self):
#            cdef v4l2.v4l2_fmtdesc fmt
#            if self._transport_formats is None:
#                fmt.type =  v4l2.V4L2_BUF_TYPE_VIDEO_CAPTURE
#                fmt.index = 0
#                formats = []
#                while self.xioctl(v4l2.VIDIOC_ENUM_FMT,&fmt)>=0:
#                    formats.append( fourcc_string(fmt.pixelformat ) )
#                    fmt.index += 1
#                logger.debug("Reading Transport formats: %s"%formats)
#                self._transport_formats = formats
#            return self._transport_formats

#        def __set__(self,val):
#            raise Exception("Read Only")


#    property frame_sizes:
#        def __get__(self):
#            cdef  v4l2.v4l2_frmsizeenum frmsize
#            if self._frame_sizes is None:
#                frmsize.pixel_format = fourcc_u32(self.transport_format)
#                frmsize.index = 0
#                sizes = []
#                while self.xioctl(v4l2.VIDIOC_ENUM_FRAMESIZES, &frmsize) >= 0:
#                    if frmsize.type == v4l2.V4L2_FRMSIZE_TYPE_DISCRETE:
#                        sizes.append((frmsize.discrete.width,frmsize.discrete.height))
#                    elif frmsize.type == v4l2.V4L2_FRMSIZE_TYPE_STEPWISE:
#                        sizes.append( (frmsize.stepwise.max_width, frmsize.stepwise.max_height) )
#                    frmsize.index+=1
#                logger.debug("Reading frame sizes@'%s': %s"%(self.transport_format,sizes) )
#                self._frame_sizes = sizes

#            return self._frame_sizes

#        def __set__(self,val):
#            raise Exception("Read Only")


#    property frame_rates:
#        def __get__(self):
#            cdef v4l2.v4l2_frmivalenum interval

#            if self._frame_rates is None:
#                interval.pixel_format = fourcc_u32(self.transport_format)
#                interval.width,interval.height = self.frame_size
#                interval.index = 0
#                self.xioctl(v4l2.VIDIOC_ENUM_FRAMEINTERVALS,&interval)
#                rates = []
#                if interval.type == v4l2.V4L2_FRMIVAL_TYPE_DISCRETE:
#                    while self.xioctl(v4l2.VIDIOC_ENUM_FRAMEINTERVALS,&interval) >= 0:
#                        rates.append((interval.discrete.numerator,interval.discrete.denominator))
#                        interval.index += 1
#                #non-discreete rates are very seldom, the second and third case should never happen
#                elif interval.type == v4l2.V4L2_FRMIVAL_TYPE_STEPWISE or interval.type == v4l2.V4L2_FRMIVAL_TYPE_CONTINUOUS:
#                    minval = float(interval.stepwise.min.numerator)/interval.stepwise.min.denominator
#                    maxval = float(interval.stepwise.max.numerator)/interval.stepwise.max.denominator
#                    if interval.type == v4l2.V4L2_FRMIVAL_TYPE_CONTINUOUS:
#                        stepval = 1
#                    else:
#                        stepval = float(interval.stepwise.step.numerator)/interval.stepwise.step.denominator
#                    rates = range(minval,maxval,stepval)
#                logger.debug("Reading frame rates@'%s'@%s: %s"%(self.transport_format,self.frame_size,rates) )
#                self._frame_rates = rates

#            return self._frame_rates

#        def __set__(self,val):
#            raise Exception("Read Only")


#    property transport_format:
#        def __get__(self):
#            return fourcc_string(self._transport_format)

#        def __set__(self,val):
#            self._transport_format = fourcc_u32(val)
#            self.stop()
#            self.deinit_buffers()
#            self.set_format()
#            self.get_format()
#            self.set_streamparm()
#            self.get_streamparm()
#            self._frame_sizes = None
#            self._frame_rates = None


#    property frame_size:
#        def __get__(self):
#            return self._frame_size
#        def __set__(self,val):
#            self._frame_size = val
#            self._frame_rates = None
#            self.stop()
#            self.deinit_buffers()
#            self.set_format()
#            self.get_format()
#            self.set_streamparm()
#            self.get_streamparm()

#    property frame_rate:
#        def __get__(self):
#            return self._frame_rate
#        def __set__(self,val):
#            self._frame_rate = val
#            self.stop()
#            self.deinit_buffers()
#            self.set_streamparm()
#            self.get_streamparm()




#    def enum_controls(self):
#        cdef v4l2.v4l2_queryctrl queryctrl
#        queryctrl.id = v4l2.V4L2_CTRL_CLASS_USER | v4l2.V4L2_CTRL_FLAG_NEXT_CTRL
#        controls = []
#        control_type = {v4l2.V4L2_CTRL_TYPE_INTEGER:'int',
#                        v4l2.V4L2_CTRL_TYPE_BOOLEAN:'bool',
#                        v4l2.V4L2_CTRL_TYPE_MENU:'menu'}

#        while (0 == self.xioctl(v4l2.VIDIOC_QUERYCTRL, &queryctrl)):

#            if v4l2.V4L2_CTRL_ID2CLASS(queryctrl.id) != v4l2.V4L2_CTRL_CLASS_CAMERA:
#                #we ignore this conditon
#                pass
#            control = {}
#            control['name'] = queryctrl.name
#            control['type'] = control_type[queryctrl.type]
#            control['id'] = queryctrl.id
#            control['min'] = queryctrl.minimum
#            control['max'] = queryctrl.maximum
#            control['step'] = queryctrl.step
#            control['default'] = queryctrl.default_value
#            control['value'] = self.get_control(queryctrl.id)
#            if queryctrl.flags & v4l2.V4L2_CTRL_FLAG_DISABLED:
#                control['disabled'] = True
#            else:
#                control['disabled'] = False

#                if queryctrl.type == v4l2.V4L2_CTRL_TYPE_MENU:
#                    control['menu'] = self.enumerate_menu(queryctrl)

#            controls.append(control)

#            queryctrl.id |= v4l2.V4L2_CTRL_FLAG_NEXT_CTRL

#        if errno != EINVAL:
#            logger.error("VIDIOC_QUERYCTRL")
#            # raise Exception("VIDIOC_QUERYCTRL")
#        return controls

#    cdef enumerate_menu(self,v4l2.v4l2_queryctrl queryctrl):
#        cdef v4l2.v4l2_querymenu querymenu
#        querymenu.id = queryctrl.id
#        querymenu.index = queryctrl.minimum
#        menu = {}
#        while querymenu.index <= queryctrl.maximum:
#            if 0 == self.xioctl(v4l2.VIDIOC_QUERYMENU, &querymenu):
#                menu[querymenu.name] = querymenu.index
#            querymenu.index +=1
#        return menu


#    cpdef set_control(self, int control_id,value):
#        cdef v4l2.v4l2_control control
#        control.id = control_id
#        control.value = value
#        if self.xioctl(v4l2.VIDIOC_S_CTRL, &control) ==-1:
#            if errno == ERANGE:
#                logger.debug("Control out of range")
#            else:
#                logger.error("Could not set control")

#    cpdef get_control(self, int control_id):
#        cdef v4l2.v4l2_control control
#        control.id = control_id
#        if self.xioctl(v4l2.VIDIOC_G_CTRL, &control) ==-1:
#            if errno == EINVAL:
#                logger.debug("Control is not supported")
#            else:
#                logger.error("Could not set control")
#        return control.value





####Utiliy functions

#def list_devices():
#    file_names = [x for x in oslistdir("/dev") if x.startswith("video")]
#    file_names.sort()
#    devices = []
#    for file_name in file_names:
#        path = "/dev/" + file_name
#        try:
#            cap = Cap_Info(path)
#            devices.append(cap.get_info())
#            cap.close()
#        except IOError:
#            logger.error("Could not get device info for %s"%path)
#    return devices




#cdef class Cap_Info:
#    """
#    Video Capture class used to make device list.

#    """
#    cdef int dev_handle
#    cdef bytes dev_name

#    def __cinit__(self,dev_name):
#        pass

#    def __init__(self,dev_name):
#        self.dev_name = dev_name
#        self.dev_handle = self.open_device()


#    def close(self):
#        self.close_device()

#    def __dealloc__(self):
#        if self.dev_handle != -1:
#            self.close()

#    def get_info(self):
#        cdef v4l2.v4l2_capability caps
#        if self.xioctl(v4l2.VIDIOC_QUERYCAP,&caps) !=0:
#            raise Exception("VIDIOC_QUERYCAP error. Could not get devices info.")

#        return {'dev_path':self.dev_name,'driver':caps.driver,'dev_name':caps.card,'bus_info':caps.bus_info}

#    cdef xioctl(self, int request, void *arg):
#        cdef int r
#        while True:
#            r = ioctl(self.dev_handle, request, arg)
#            if -1 != r or EINTR != errno:
#                break
#        return r

#    cdef open_device(self):
#        cdef stat.struct_stat st
#        cdef int dev_handle = -1
#        if -1 == stat.stat(<char *>self.dev_name, &st):
#            raise Exception("Cannot find '%s'. Error: %d, %s\n"%(self.dev_name, errno, strerror(errno) ))
#        if not stat.S_ISCHR(st.st_mode):
#            raise Exception("%s is no device\n"%self.dev_name)

#        dev_handle = fcntl.open(<char *>self.dev_name, fcntl.O_RDWR | fcntl.O_NONBLOCK, 0)
#        if -1 == dev_handle:
#            raise Exception("Cannot open '%s'. Error: %d, %s\n"%(self.dev_name, errno, strerror(errno) ))
#        return dev_handle


#    cdef close_device(self):
#        if unistd.close(self.dev_handle) == -1:
#            raise Exception("Could not close device. Handle: '%s'. Error: %d, %s\n"%(self.dev_handle, errno, strerror(errno) ))
#        self.dev_handle = -1


#def get_sys_time_monotonic():
#    cdef time.timespec t
#    time.clock_gettime(time.CLOCK_MONOTONIC, &t)
#    return t.tv_sec + <double>t.tv_nsec * 1e-9



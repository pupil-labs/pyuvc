import cython
from libc.string cimport memset
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

uvc_vs_subtype = {
   0x00 : "UVC_VS_UNDEFINED",
   0x01 : "UVC_VS_INPUT_HEADER",
   0x02 : "UVC_VS_OUTPUT_HEADER",
   0x03 : "UVC_VS_STILL_IMAGE_FRAME",
   0x04 : "UVC_VS_FORMAT_UNCOMPRESSED",
   0x05 : "UVC_VS_FRAME_UNCOMPRESSED",
   0x06 : "UVC_VS_FORMAT_MJPEG",
   0x07 : "UVC_VS_FRAME_MJPEG",
   0x0a : "UVC_VS_FORMAT_MPEG2TS",
   0x0c : "UVC_VS_FORMAT_DV",
   0x0d : "UVC_VS_COLORFORMAT",
   0x10 : "UVC_VS_FORMAT_FRAME_BASED",
   0x11 : "UVC_VS_FRAME_FRAME_BASED",
   0x12 : "UVC_VS_FORMAT_STREAM_BASED"
}

class CaptureError(Exception):
    def __init__(self, message):
        super(CaptureError, self).__init__()
        self.message = message

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

    cdef tuple _active_mode
    cdef list _available_modes
    cdef dict _info
    cdef public list controls

    def __cinit__(self,dev_uid):
        self.dev = NULL
        self.ctx = NULL
        self.devh = NULL
        self._stream_on = 0
        self._configured = 0
        self.strmh = NULL
        self._available_modes = []
        self._active_mode = None,None,None
        self._info = {}
        self.controls = []

    def __init__(self,dev_uid):

        #setup for jpeg converter
        self.tj_context = turbojpeg.tjInitDecompress()

        if uvc.uvc_init(&self.ctx, NULL) != uvc.UVC_SUCCESS:
            raise Exception('Could not init libuvc')

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
                if (uvc.uvc_get_device_descriptor(dev, &desc) == uvc.UVC_SUCCESS):
                            product = desc.product or "unknown"
                            manufacturer = desc.manufacturer or "unknown"
                            serialNumber = desc.serialNumber or "unknown"
                            idProduct,idVendor = desc.idProduct,desc.idVendor
                            device_address = uvc.uvc_get_device_address(dev)
                            bus_number = uvc.uvc_get_bus_number(dev)
                            self._info = {'name':product,
                                            'manufacturer':manufacturer,
                                            'serialNumber':serialNumber,
                                            'idProduct':idProduct,
                                            'idVendor':idVendor,
                                            'device_address':device_address,
                                            'bus_number':bus_number,
                                            'uid':'%s:%s'%(bus_number,device_address)}
                uvc.uvc_free_device_descriptor(desc)
                break
            idx +=1

        uvc.uvc_free_device_list(dev_list, 1)
        if dev == NULL:
            raise Exception("Device with uid: '%s' not found"%dev_uid)


        #once found we open the device
        self.dev = dev
        error = uvc.uvc_open(self.dev,&self.devh)
        if error != uvc.UVC_SUCCESS:
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
            self._stop()
        if self.devh != NULL:
            self._de_init_device()
        if self.ctx != NULL:
            uvc.uvc_exit(self.ctx)
            turbojpeg.tjDestroy(self.tj_context)


    cdef _restart(self):
        self._stop()
        self._start()

    def print_info(self):
        print "Capture device"
        for k,v in self._info.iteritems():
            print '\t %s:%s'%(k,v)

    cdef _configure_stream(self,mode=(640,480,30)):
        cdef int status

        if self._stream_on:
            self._stop()

        status = uvc.uvc_get_stream_ctrl_format_size( self.devh, &self.ctrl,
                                                      uvc.UVC_FRAME_FORMAT_COMPRESSED,
                                                      mode[0],mode[1],mode[2] )
        if status != uvc.UVC_SUCCESS:
            raise Exception("Can't get stream control: Error:'%s'."%uvc_error_codes[status])
        self._configured = 1
        self._active_mode = mode


    cdef _start(self):
        cdef int status
        if not self._configured:
            self._configure_stream()
        status = uvc.uvc_stream_open_ctrl(self.devh, &self.strmh, &self.ctrl)
        if status != uvc.UVC_SUCCESS:
            raise Exception("Can't open stream control: Error:'%s'."%uvc_error_codes[status])
        status = uvc.uvc_stream_start(self.strmh, NULL, NULL,0)
        if status != uvc.UVC_SUCCESS:
            raise Exception("Can't start isochronous stream: Error:'%s'."%uvc_error_codes[status])
        self._stream_on = 1
        logger.debug("Stream start.")

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
        #uvc.uvc_stop_streaming(self.devh)
        self._stream_on = 0
        logger.debug("Stream stop.")

    def get_frame_robust(self):
        cdef int a,r, attempts = 4,restarts = 2
        for r in range(restarts):
            for a in range(attempts):
                try:
                    frame = self.get_frame()
                except CaptureError as e:
                    logger.debug('Could not get Frame. Error: "%s". Tried %s times.'%(e.message,a))
                else:
                    return frame
            logger.warning("Could not grab frame. Restarting device")
            self._restart()
        raise Exception("Could not grab frame. Giving up.")



    def get_frame(self):
        cdef int status, j_width,j_height,jpegSubsamp,header_ok
        cdef int  timeout_usec = 1000000 #1sec
        if not self._stream_on:
            self._start()
        cdef uvc.uvc_frame *uvc_frame = NULL
        status = uvc.uvc_stream_get_frame(self.strmh,&uvc_frame,timeout_usec)
        if status !=uvc.UVC_SUCCESS:
            raise CaptureError(uvc_error_codes[status])
        if uvc_frame is NULL:
            raise CaptureError("Frame pointer is NULL")

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


    cdef _enumerate_controls(self):

        cdef uvc.uvc_input_terminal_t  *input_terminal = uvc.uvc_get_input_terminals(self.devh)
        cdef uvc.uvc_output_terminal_t  *output_terminal = uvc.uvc_get_output_terminals(self.devh)
        cdef uvc.uvc_processing_unit_t  *processing_unit = uvc.uvc_get_processing_units(self.devh)
        cdef uvc.uvc_extension_unit_t  *extension_unit = uvc.uvc_get_extension_units(self.devh)

        cdef Control control
        #print 'ext units'
        #while extension_unit !=NULL:
        #    bUnitID = extension_unit.bUnitID
        #    print bUnitID,bin(extension_unit.bmControls)
        #    extension_unit = extension_unit.next

        avaible_controls_per_unit = {}
        id_per_unit = {}

        while input_terminal !=NULL:
            avaible_controls_per_unit['input_terminal'] = input_terminal.bmControls
            id_per_unit['input_terminal'] = input_terminal.bTerminalID
            input_terminal = input_terminal.next

        while processing_unit !=NULL:
            avaible_controls_per_unit['processing_unit'] = processing_unit.bmControls
            id_per_unit['processing_unit'] = processing_unit.bUnitID
            processing_unit = processing_unit.next


        for std_ctl in standard_ctrl_units:
            if std_ctl['bit_mask'] & avaible_controls_per_unit[std_ctl['unit']]:

                logger.debug('Adding "%s" as controll to Capture device'%std_ctl['display_name'])
                std_ctl['unit_id'] = id_per_unit[std_ctl['unit']]

                #we need to defer __init__ as we cannot pass the handle before
                control= Control(cap = self,**std_ctl)
                #control = Control.__new__(Control,**std_ctl)
                #control.devh = self.devh
                self.controls.append(control)


        #uvc.PyEval_InitThreads()
        #uvc.uvc_set_status_callback(self.devh, on_status_update,<void*>self)


    cdef _enumerate_formats(self):
        cdef uvc.uvc_format_desc_t *format_desc = uvc.uvc_get_format_descs(self.devh)
        cdef uvc.uvc_frame_desc *frame_desc
        cdef int i
        self._available_modes = []
        while format_desc is not NULL:
            frame_desc = format_desc.frame_descs
            while frame_desc is not NULL:
                if frame_desc.bDescriptorSubtype == uvc.UVC_VS_FRAME_MJPEG:
                    frame_index = frame_desc.bFrameIndex
                    width,height = frame_desc.wWidth,frame_desc.wHeight
                    mode = {'size':(width,height),'rates':[]}
                    i = 0
                    while frame_desc.intervals[i]:
                        mode['rates'].append(interval_to_fps(frame_desc.intervals[i]) )
                        i+=1
                    self._available_modes.append(mode)

                #go to next frame_desc
                frame_desc = frame_desc.next

            #go to next format_desc
            format_desc = format_desc.next

        logger.debug('avaible video modes: %s'%self._available_modes)


    property frame_size:
        def __get__(self):
            return self._active_mode[:2]
        def __set__(self,size):
            for m in self._available_modes:
                if size == m['size']:
                    if self.frame_rate is not None:
                        #closest match for rate
                        rates = [ abs(r-self.frame_rate) for r in m['rates'] ]
                        best_rate_idx = rates.index(min(rates))
                        rate = m['rates'][best_rate_idx]
                    else:
                        #fist one
                        rate = m['rates'][0]
                    mode = size + (rate,)
                    self._configure_stream(mode)
                    return
            raise Exception("Frame size not suported.")

    property frame_rate:
        def __get__(self):
            return self._active_mode[2]
        def __set__(self,val):
            if  self._configured:
                self.frame_mode = self._active_mode[:2]+(val,)
            else:
                raise Exception('set frame size first.')

    property frame_sizes:
        def __get__(self):
            return [m['size'] for m in self._available_modes]

    property frame_rates:
        def __get__(self):
            for m in self._available_modes:
                if m['size'] == self.frame_size:
                    return m['rates']
            raise Exception("Please set frame_size before asking for rates.")


    property frame_mode:
        def __get__(self):
            return self._active_mode
        def __set__(self,mode):
            logger.debug('Setting mode: %s,%s,%s'%mode)
            self._configure_stream(mode)

    property avaible_modes:
        def __get__(self):
            modes = []
            for idx,m in enumerate(self._available_modes):
                for r in m['rates']:
                    modes.append(m['size']+(r,))
            return modes

    property name:
        def __get__(self):
            return self._info['name']

cdef void on_status_update(uvc.uvc_status_class status_class,
                        int event,
                        int selector,
                        uvc.uvc_status_attribute status_attribute,
                        void *data,
                        size_t data_len,
                        void *user_ptr) with gil:
    print "Callback"
    print status_class, event,selector,status_attribute,data_len
    print <object>user_ptr

cdef inline int interval_to_fps(int interval):
    return int(10000000./interval)



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



#def get_sys_time_monotonic():
#    cdef time.timespec t
#    time.clock_gettime(time.CLOCK_MONOTONIC, &t)
#    return t.tv_sec + <double>t.tv_nsec * 1e-9



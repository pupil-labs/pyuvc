import cython
from posix cimport fcntl,unistd, stat, time
from posix.ioctl cimport ioctl
from libc.errno cimport errno,EINTR,EINVAL,EAGAIN,EIO,ERANGE
from libc.string cimport strerror
cimport cmman as mman
cimport cselect as select
cimport cuvc as uvc
cimport cturbojpeg as turbojpeg
cimport numpy as np
import numpy as np


from os import listdir as oslistdir


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
        def __set__(self,buffer_handle buffer):
            raise Exception('Read only')

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
        def __set__(self,val):
            raise Exception('read only')
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
        def __set__(self,val):
            raise Exception('read only')
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
        def __set__(self,val):
            raise Exception('read only')
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
        def __set__(self,val):
            raise Exception('read only')
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

    # cdef jpeg2bgr(self):
    #     #10.66ms on 1080p
    #     cdef int channels = 3
    #     cdef int jpegSubsamp, j_width,j_height
    #     cdef int result
    #     cdef np.ndarray[np.uint8_t, ndim=1] bgr_array = np.empty(self.width*self.height*channels, dtype=np.uint8)
    #     turbojpeg.tjDecompressHeader2(self.tj_context,  <unsigned char *>self._jpeg_buffer.start, self._jpeg_buffer.length, &j_width, &j_height, &jpegSubsamp)
    #     result = turbojpeg.tjDecompress2(self.tj_context, <unsigned char *>self._jpeg_buffer.start, self._jpeg_buffer.length,
    #                             <unsigned char *> bgr_array.data,
    #                             j_width, 0, j_height, turbojpeg.TJPF_BGR, 0)#turbojpeg.TJFLAG_FASTDCT
    #     if result == -1:
    #         logger.error('Turbojpeg jpeg2bgr error: %s'%turbojpeg.tjGetErrorStr() )
    #     self._bgr_array = bgr_array
    #     self._bgr_array.shape = self.height,self.width,channels


    # cdef jpeg2gray(self):
    #     #6.02ms on 1080p
    #     cdef int channels = 1
    #     cdef int jpegSubsamp, j_width,j_height
    #     cdef int result
    #     cdef np.ndarray[np.uint8_t, ndim=1] array = np.empty(self.width*self.height*channels, dtype=np.uint8)
    #     turbojpeg.tjDecompressHeader2(self.tj_context,  <unsigned char *>self._jpeg_buffer.start, self._jpeg_buffer.length, &j_width, &j_height, &jpegSubsamp)
    #     result = turbojpeg.tjDecompress2(self.tj_context, <unsigned char *>self._jpeg_buffer.start, self._jpeg_buffer.length,
    #                             <unsigned char *> array.data,
    #                             j_width, 0, j_height, turbojpeg.TJPF_GRAY, 0)#turbojpeg.TJFLAG_FASTDCT

    #     if result == -1:
    #         logger.error('Turbojpeg jpeg2gray error: %s'%turbojpeg.tjGetErrorStr() )
    #     self._gray_array = array
    #     self._gray_array.shape = self.height,self.width

    def clear_caches(self):
        self._bgr_converted = False
        self._yuv_converted = False


def init():
    cdef uvc.uvc_context_t * ctx
    print uvc.uvc_init(&ctx,NULL)
    uvc.uvc_exit(ctx)


#cdef class Capture:
#    """
#    Video Capture class.
#    A Class giving access to a capture devices using the v4l2 provides drivers and userspace API.
#    The intent is to always grab mjpeg frames and give access to theses buffer using the Frame class.

#    All controls are exposed and can be enumerated using the controls list.
#    """
#    cdef int dev_handle
#    cdef bytes dev_name
#    cdef bint _camera_streaming, _buffers_initialized
#    cdef object _transport_formats, _frame_rates,_frame_sizes
#    cdef object  _frame_rate, _frame_size # (rate_num,rate_den), (width,height)
#    cdef v4l2.__u32 _transport_format

#    cdef bint _buffer_active
#    cdef int _allocated_buf_n
#    cdef v4l2.v4l2_buffer _active_buffer
#    cdef list buffers

#    cdef turbojpeg.tjhandle tj_context

#    def __cinit__(self,dev_name):
#        pass

#    def __init__(self,dev_name):
#        self.dev_name = dev_name
#        self.dev_handle = self.open_device()
#        self.verify_device()
#        self.get_format()
#        self.get_streamparm()

#        self._transport_formats = None
#        self._frame_rates = None
#        self._frame_sizes = None

#        self._buffer_active = False
#        self._allocated_buf_n = 0

#        self._buffers_initialized = False
#        self._camera_streaming = False

#        #setup for jpeg converter
#        self.tj_context = turbojpeg.tjInitDecompress()

#        #set some sane defaults:
#        self.transport_format = 'MJPG'

#    def restart(self):
#        self.close()
#        self.dev_handle = self.open_device()
#        self.verify_device()
#        self.transport_format = 'MJPG' #this will set prev parms
#        logger.warning("restarted capture device")


#    def close(self):
#        try:
#            self.stop()
#            self.deinit_buffers()
#            self.close_device()
#        except:
#            logger.warning("Could not shut down Capture properly.")

#    def __dealloc__(self):
#        turbojpeg.tjDestroy(self.tj_context)

#        if self.dev_handle != -1:
#            self.close()

#    def get_info(self):
#        cdef v4l2.v4l2_capability caps
#        if self.xioctl(v4l2.VIDIOC_QUERYCAP,&caps) !=0:
#            raise Exception("VIDIOC_QUERYCAP error. Could not get devices info.")

#        return  {'dev_path':self.dev_name,'driver':caps.driver,'dev_name':caps.card,'bus_info':caps.bus_info}

#    def get_frame_robust(self, int attemps = 6):
#        for a in range(attemps)[::-1]:
#            try:
#                frame = self.get_frame()
#            except:
#                logger.warning('Could not get Frame on "%s". Trying %s more times.'%(self.dev_name,a))
#                self.restart()
#            else:
#                return frame
#        raise Exception("Could not grab frame from %s"%self.dev_name)

#    def get_frame(self):
#        cdef int j_width,j_height,jpegSubsamp,header_ok
#        if not self._camera_streaming:
#            self.init_buffers()
#            self.start()

#        if self._buffer_active:
#            if self.xioctl(v4l2.VIDIOC_QBUF,&self._active_buffer) == -1:
#                raise Exception("Could not queue buffer")
#            else:
#                self._buffer_active = False

#        self.wait_for_buffer_avaible()


#        #deque the buffer
#        self._active_buffer.type = v4l2.V4L2_BUF_TYPE_VIDEO_CAPTURE
#        self._active_buffer.memory = v4l2.V4L2_MEMORY_MMAP
#        if self.xioctl(v4l2.VIDIOC_DQBUF, &self._active_buffer) == -1:
#            if errno == EAGAIN: # no buffer available yet.
#                raise Exception("Fixme")

#            elif errno == EIO:
#                # Can ignore EIO, see spec.
#                pass
#            else:
#                raise Exception("VIDIOC_DQBUF")

#        self._buffer_active = True

#        # this is taken from the demo but it seams overly causious
#        assert(self._active_buffer.index < self._allocated_buf_n)

#        #now we hold a valid frame
#        # print self._active_buffer.timestamp.tv_sec,',',self._active_buffer.timestamp.tv_usec,self._active_buffer.bytesused,self._active_buffer.index
#        cdef Frame out_frame = Frame()
#        out_frame.tj_context = self.tj_context
#        out_frame.timestamp = <double>self._active_buffer.timestamp.tv_sec + (<double>self._active_buffer.timestamp.tv_usec) / 10e5
#        out_frame.width,out_frame.height = self._frame_size

#        cdef buffer_handle buf = buffer_handle()
#        buf.start = (<buffer_handle>self.buffers[self._active_buffer.index]).start
#        buf.length = self._active_buffer.bytesused


#        if self._transport_format == v4l2.V4L2_PIX_FMT_MJPEG:
#            ##check jpeg header
#            header_ok = turbojpeg.tjDecompressHeader2(self.tj_context,  <unsigned char *>buf.start, buf.length, &j_width, &j_height, &jpegSubsamp)
#            if header_ok >=0 and out_frame.width == j_width and out_frame.height == out_frame.height:
#                out_frame.jpeg_buffer  = buf
#            else:
#                raise Exception("JPEG header corrupted.")

#        elif self._transport_format == v4l2.V4L2_PIX_FMT_YUYV:
#            raise Exception("Transport format YUYV is not implemented")
#            # out_frame._yuyv_buffer = buf
#        else:
#            raise Exception("Tranport format data '%s' is not implemented."%self.transport_format)
#        return out_frame


#    cdef wait_for_buffer_avaible(self):
#        cdef select.fd_set fds
#        cdef time.timeval tv
#        cdef int r
#        while True:
#            select.FD_ZERO(&fds)
#            select.FD_SET(self.dev_handle, &fds)
#            tv.tv_sec = 2
#            tv.tv_usec = 0

#            r = select.select(self.dev_handle + 1, &fds, NULL, NULL, &tv)

#            if r == 0:
#                raise Exception("select timeout")
#            elif r == -1:
#                if errno != EINTR:
#                    raise Exception("Select Error")
#                else:
#                    #try again
#                    pass
#            else:
#                return


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
#        if not self.dev_handle == -1:
#            if unistd.close(self.dev_handle) == -1:
#                raise Exception("Could not close device. Handle: '%s'. Error: %d, %s\n"%(self.dev_handle, errno, strerror(errno) ))
#            self.dev_handle = -1


#    cdef verify_device(self):
#        cdef v4l2.v4l2_capability cap
#        if self.xioctl(v4l2.VIDIOC_QUERYCAP, &cap) ==-1:
#            if EINVAL == errno:
#                raise Exception("%s is no V4L2 device\n"%self.dev_name)
#            else:
#                raise Exception("Error during VIDIOC_QUERYCAP: %d, %s"%(errno, strerror(errno) ))

#        if not (cap.capabilities & v4l2.V4L2_CAP_VIDEO_CAPTURE):
#            raise Exception("%s is no video capture device"%self.dev_name)

#        if not (cap.capabilities & v4l2.V4L2_CAP_STREAMING):
#            raise Exception("%s does not support streaming i/o"%self.dev_name)


#    cdef stop(self):
#        cdef v4l2.v4l2_buf_type buf_type
#        if self._camera_streaming:
#            buf_type = v4l2.V4L2_BUF_TYPE_VIDEO_CAPTURE
#            if self.xioctl(v4l2.VIDIOC_STREAMOFF,&buf_type) == -1:
#                self.close_device()
#                raise Exception("Could not deinit buffers.")

#            self._camera_streaming = False
#            logger.debug("Capure stopped.")



#    cdef start(self):
#        cdef v4l2.v4l2_buffer buf
#        cdef v4l2.v4l2_buf_type buf_type
#        if not self._camera_streaming:
#            for i in range(len(self.buffers)):
#                buf.type = v4l2.V4L2_BUF_TYPE_VIDEO_CAPTURE
#                buf.memory = v4l2.V4L2_MEMORY_MMAP
#                buf.index = i
#                if self.xioctl(v4l2.VIDIOC_QBUF, &buf) == -1:
#                    raise Exception('VIDIOC_QBUF')

#            buf_type = v4l2.V4L2_BUF_TYPE_VIDEO_CAPTURE
#            if self.xioctl(v4l2.VIDIOC_STREAMON, &buf_type) ==-1:
#                raise Exception("VIDIOC_STREAMON")
#            self._camera_streaming = True
#            logger.debug("Capure started.")



#    cdef init_buffers(self):
#        cdef v4l2.v4l2_requestbuffers req
#        cdef v4l2.v4l2_buffer buf
#        if not self._buffers_initialized:
#            req.count = 4
#            req.type = v4l2.V4L2_BUF_TYPE_VIDEO_CAPTURE
#            req.memory = v4l2.V4L2_MEMORY_MMAP

#            if self.xioctl(v4l2.VIDIOC_REQBUFS, &req) == -1:
#                if EINVAL == errno:
#                    raise Exception("%s does not support memory mapping"%self.dev_name)
#                else:
#                    raise Exception("VIDIOC_REQBUFS failed")

#            if req.count < 2:
#                raise Exception("Insufficient buffer memory on %s\n"%self.dev_name)

#            self.buffers = []
#            self._allocated_buf_n = req.count

#            for buf_n in range(req.count):
#                buf.type        = v4l2.V4L2_BUF_TYPE_VIDEO_CAPTURE
#                buf.memory      = v4l2.V4L2_MEMORY_MMAP
#                buf.index       = buf_n
#                if self.xioctl(v4l2.VIDIOC_QUERYBUF, &buf) == -1:
#                    raise Exception("VIDIOC_QUERYBUF")

#                b = buffer_handle()
#                b.length = buf.length
#                b.start = mman.mmap(NULL,#start anywhere
#                                    buf.length,
#                                    mman.PROT_READ | mman.PROT_WRITE,#required
#                                    mman.MAP_SHARED,#recommended
#                                    self.dev_handle, buf.m.offset)
#                if <int>b.start == mman.MAP_FAILED:
#                    raise Exception("MMAP Error")
#                self.buffers.append(b)

#            self._buffers_initialized = True
#            logger.debug("Buffers initialized")


#    cdef deinit_buffers(self):
#        cdef buffer_handle b
#        if self._buffers_initialized:
#            for b in self.buffers:
#                if mman.munmap(b.start, b.length) ==-1:
#                    raise Exception("munmap error")
#            self.buffers = []
#            self._buffers_initialized = False
#            self._allocated_buf_n = 0
#            self._buffer_active = False
#            logger.debug("Buffers deinitialized")


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

def fourcc_string(i):
    s = chr(i & 255)
    for shift in (8,16,24):
        s += chr(i>>shift & 255)
    return s

#cpdef v4l2.__u32 fourcc_u32(char * fourcc):
#    return v4l2.v4l2_fourcc(fourcc[0],fourcc[1],fourcc[2],fourcc[3])
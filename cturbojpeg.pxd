cdef extern from "turbojpeg.h":
    cdef enum TJSAMP:
        TJSAMP_444
        TJSAMP_422
        TJSAMP_420
        TJSAMP_GRAY
        TJSAMP_440
        TJSAMP_411

    int tjMCUWidth[6]
    int tjMCUHeight[6]
    cdef enum TJPF:
        TJPF_RGB
        TJPF_BGR
        TJPF_RGBX
        TJPF_BGRX
        TJPF_XBGR
        TJPF_XRGB
        TJPF_GRAY
        TJPF_RGBA
        TJPF_BGRA
        TJPF_ABGR
        TJPF_ARGB
        TJPF_CMYK

    int tjRedOffset[12]
    int tjGreenOffset[12]
    int tjBlueOffset[12]
    int tjPixelSize[12]
    cdef enum TJCS:
        TJCS_RGB
        TJCS_YCbCr
        TJCS_GRAY
        TJCS_CMYK
        TJCS_YCCK

    cdef enum TJXOP:
        TJXOP_NONE
        TJXOP_HFLIP
        TJXOP_VFLIP
        TJXOP_TRANSPOSE
        TJXOP_TRANSVERSE
        TJXOP_ROT90
        TJXOP_ROT180
        TJXOP_ROT270

    cdef struct tjscalingfactor:
        int num
        int denom

    cdef struct tjregion:
        int x
        int y
        int w
        int h

    cdef struct tjtransform:
        tjregion r
        int op
        int options
        void *data
        int (*customFilter)(short int *, tjregion, tjregion, int, int, tjtransform *)

    ctypedef tjtransform tjtransform

    ctypedef void *tjhandle

    tjhandle tjInitCompress()

    int tjCompress2(tjhandle handle, unsigned char *srcBuf, int width, int pitch, int height, int pixelFormat, unsigned char **jpegBuf, long unsigned int *jpegSize, int jpegSubsamp, int jpegQual, int flags)

    int tjCompressFromYUV(tjhandle handle, unsigned char *srcBuf, int width, int pad, int height, int subsamp, unsigned char **jpegBuf, long unsigned int *jpegSize, int jpegQual, int flags)

    int tjCompressFromYUVPlanes(tjhandle handle, unsigned char **srcPlanes, int width, int *strides, int height, int subsamp, unsigned char **jpegBuf, long unsigned int *jpegSize, int jpegQual, int flags)

    long unsigned int tjBufSize(int width, int height, int jpegSubsamp)

    long unsigned int tjBufSizeYUV2(int width, int pad, int height, int subsamp)

    long unsigned int tjPlaneSizeYUV(int componentID, int width, int stride, int height, int subsamp)

    int tjPlaneWidth(int componentID, int width, int subsamp)

    int tjPlaneHeight(int componentID, int height, int subsamp)

    int tjEncodeYUV3(tjhandle handle, unsigned char *srcBuf, int width, int pitch, int height, int pixelFormat, unsigned char *dstBuf, int pad, int subsamp, int flags)

    int tjEncodeYUVPlanes(tjhandle handle, unsigned char *srcBuf, int width, int pitch, int height, int pixelFormat, unsigned char **dstPlanes, int *strides, int subsamp, int flags)

    tjhandle tjInitDecompress()

    int tjDecompressHeader3(tjhandle handle, unsigned char *jpegBuf, long unsigned int jpegSize, int *width, int *height, int *jpegSubsamp, int *jpegColorspace)

    tjscalingfactor *tjGetScalingFactors(int *numscalingfactors)
    # /**
    #  * Decompress a JPEG image to an RGB or grayscale image.
    #  *
    #  * @param handle a handle to a TurboJPEG decompressor or transformer instance
    #  * @param jpegBuf pointer to a buffer containing the JPEG image to decompress
    #  * @param jpegSize size of the JPEG image (in bytes)
    #  * @param dstBuf pointer to an image buffer that will receive the decompressed
    #  *        image.  This buffer should normally be <tt>pitch * scaledHeight</tt>
    #  *        bytes in size, where <tt>scaledHeight</tt> can be determined by
    #  *        calling #TJSCALED() with the JPEG image height and one of the scaling
    #  *        factors returned by #tjGetScalingFactors().  The dstBuf pointer may
    #  *        also be used to decompress into a specific region of a larger buffer.
    #  * @param width desired width (in pixels) of the destination image.  If this is
    #  *        smaller than the width of the JPEG image being decompressed, then
    #  *        TurboJPEG will use scaling in the JPEG decompressor to generate the
    #  *        largest possible image that will fit within the desired width.  If
    #  *        width is set to 0, then only the height will be considered when
    #  *        determining the scaled image size.
    #  * @param pitch bytes per line of the destination image.  Normally, this is
    #  *        <tt>scaledWidth * #tjPixelSize[pixelFormat]</tt> if the decompressed
    #  *        image is unpadded, else <tt>#TJPAD(scaledWidth *
    #  *        #tjPixelSize[pixelFormat])</tt> if each line of the decompressed
    #  *        image is padded to the nearest 32-bit boundary, as is the case for
    #  *        Windows bitmaps.  (NOTE: <tt>scaledWidth</tt> can be determined by
    #  *        calling #TJSCALED() with the JPEG image width and one of the scaling
    #  *        factors returned by #tjGetScalingFactors().)  You can also be clever
    #  *        and use the pitch parameter to skip lines, etc.  Setting this
    #  *        parameter to 0 is the equivalent of setting it to <tt>scaledWidth
    #  *        * #tjPixelSize[pixelFormat]</tt>.
    #  * @param height desired height (in pixels) of the destination image.  If this
    #  *        is smaller than the height of the JPEG image being decompressed, then
    #  *        TurboJPEG will use scaling in the JPEG decompressor to generate the
    #  *        largest possible image that will fit within the desired height.  If
    #  *        height is set to 0, then only the width will be considered when
    #  *        determining the scaled image size.
    #  * @param pixelFormat pixel format of the destination image (see @ref
    #  *        TJPF "Pixel formats".)
    #  * @param flags the bitwise OR of one or more of the @ref TJFLAG_BOTTOMUP
    #  *        "flags".
    #  *
    #  * @return 0 if successful, or -1 if an error occurred (see #tjGetErrorStr().)
    #  */
    int tjDecompress2(tjhandle handle, unsigned char *jpegBuf, long unsigned int jpegSize, unsigned char *dstBuf, int width, int pitch, int height, int pixelFormat, int flags)

    # /**
    #  * Decompress a JPEG image to a YUV planar image.  This function performs JPEG
    #  * decompression but leaves out the color conversion step, so a planar YUV
    #  * image is generated instead of an RGB image.
    #  *
    #  * @param handle a handle to a TurboJPEG decompressor or transformer instance
    #  *
    #  * @param jpegBuf pointer to a buffer containing the JPEG image to decompress
    #  *
    #  * @param jpegSize size of the JPEG image (in bytes)
    #  *
    #  * @param dstBuf pointer to an image buffer that will receive the YUV image.
    #  * Use #tjBufSizeYUV2() to determine the appropriate size for this buffer based
    #  * on the image width, height, padding, and level of subsampling.  The Y,
    #  * U (Cb), and V (Cr) image planes will be stored sequentially in the buffer
    #  * (refer to @ref YUVnotes "YUV Image Format Notes".)
    #  *
    #  * @param width desired width (in pixels) of the YUV image.  If this is
    #  * different than the width of the JPEG image being decompressed, then
    #  * TurboJPEG will use scaling in the JPEG decompressor to generate the largest
    #  * possible image that will fit within the desired width.  If <tt>width</tt> is
    #  * set to 0, then only the height will be considered when determining the
    #  * scaled image size.  If the scaled width is not an even multiple of the MCU
    #  * block width (see #tjMCUWidth), then an intermediate buffer copy will be
    #  * performed within TurboJPEG.
    #  *
    #  * @param pad the width of each line in each plane of the YUV image will be
    #  * padded to the nearest multiple of this number of bytes (must be a power of
    #  * 2.)  To generate images suitable for X Video, <tt>pad</tt> should be set to
    #  * 4.
    #  *
    #  * @param height desired height (in pixels) of the YUV image.  If this is
    #  * different than the height of the JPEG image being decompressed, then
    #  * TurboJPEG will use scaling in the JPEG decompressor to generate the largest
    #  * possible image that will fit within the desired height.  If <tt>height</tt>
    #  * is set to 0, then only the width will be considered when determining the
    #  * scaled image size.  If the scaled height is not an even multiple of the MCU
    #  * block height (see #tjMCUHeight), then an intermediate buffer copy will be
    #  * performed within TurboJPEG.
    #  *
    #  * @param flags the bitwise OR of one or more of the @ref TJFLAG_BOTTOMUP
    #  * "flags"
    #  *
    #  * @return 0 if successful, or -1 if an error occurred (see #tjGetErrorStr().)
    #  */

    int tjDecompressToYUV2(tjhandle handle, unsigned char *jpegBuf, long unsigned int jpegSize, unsigned char *dstBuf, int width, int pad, int height, int flags)

    int tjDecompressToYUVPlanes(tjhandle handle, unsigned char *jpegBuf, long unsigned int jpegSize, unsigned char **dstPlanes, int width, int *strides, int height, int flags)
    # /**
    #  * Decode a YUV planar image into an RGB or grayscale image.  This function
    #  * uses the accelerated color conversion routines in the underlying
    #  * codec but does not execute any of the other steps in the JPEG decompression
    #  * process.
    #  *
    #  * @param handle a handle to a TurboJPEG decompressor or transformer instance
    #  *
    #  * @param srcBuf pointer to an image buffer containing a YUV planar image to be
    #  * decoded.  The size of this buffer should match the value returned by
    #  * #tjBufSizeYUV2() for the given image width, height, padding, and level of
    #  * chrominance subsampling.  The Y, U (Cb), and V (Cr) image planes should be
    #  * stored sequentially in the source buffer (refer to @ref YUVnotes
    #  * "YUV Image Format Notes".)
    #  *
    #  * @param pad Use this parameter to specify that the width of each line in each
    #  * plane of the YUV source image is padded to the nearest multiple of this
    #  * number of bytes (must be a power of 2.)
    #  *
    #  * @param subsamp the level of chrominance subsampling used in the YUV source
    #  * image (see @ref TJSAMP "Chrominance subsampling options".)
    #  *
    #  * @param dstBuf pointer to an image buffer that will receive the decoded
    #  * image.  This buffer should normally be <tt>pitch * height</tt> bytes in
    #  * size, but the <tt>dstBuf</tt> pointer can also be used to decode into a
    #  * specific region of a larger buffer.
    #  *
    #  * @param width width (in pixels) of the source and destination images
    #  *
    #  * @param pitch bytes per line in the destination image.  Normally, this should
    #  * be <tt>width * #tjPixelSize[pixelFormat]</tt> if the destination image is
    #  * unpadded, or <tt>#TJPAD(width * #tjPixelSize[pixelFormat])</tt> if each line
    #  * of the destination image should be padded to the nearest 32-bit boundary, as
    #  * is the case for Windows bitmaps.  You can also be clever and use the pitch
    #  * parameter to skip lines, etc.  Setting this parameter to 0 is the equivalent
    #  * of setting it to <tt>width * #tjPixelSize[pixelFormat]</tt>.
    #  *
    #  * @param height height (in pixels) of the source and destination images
    #  *
    #  * @param pixelFormat pixel format of the destination image (see @ref TJPF
    #  * "Pixel formats".)
    #  *
    #  * @param flags the bitwise OR of one or more of the @ref TJFLAG_BOTTOMUP
    #  * "flags"
    #  *
    #  * @return 0 if successful, or -1 if an error occurred (see #tjGetErrorStr().)
    #  */
    int tjDecodeYUV(tjhandle handle, unsigned char *srcBuf, int pad, int subsamp, unsigned char *dstBuf, int width, int pitch, int height, int pixelFormat, int flags)

    int tjDecodeYUVPlanes(tjhandle handle, unsigned char **srcPlanes, int *strides, int subsamp, unsigned char *dstBuf, int width, int pitch, int height, int pixelFormat, int flags)

    tjhandle tjInitTransform()

    int tjTransform(tjhandle handle, unsigned char *jpegBuf, long unsigned int jpegSize, int n, unsigned char **dstBufs, long unsigned int *dstSizes, tjtransform *transforms, int flags)

    int tjDestroy(tjhandle handle)

    unsigned char *tjAlloc(int bytes)

    void tjFree(unsigned char *buffer)

    char *tjGetErrorStr()

    long unsigned int TJBUFSIZE(int width, int height)

    long unsigned int TJBUFSIZEYUV(int width, int height, int jpegSubsamp)

    long unsigned int tjBufSizeYUV(int width, int height, int subsamp)

    int tjCompress(tjhandle handle, unsigned char *srcBuf, int width, int pitch, int height, int pixelSize, unsigned char *dstBuf, long unsigned int *compressedSize, int jpegSubsamp, int jpegQual, int flags)

    int tjEncodeYUV(tjhandle handle, unsigned char *srcBuf, int width, int pitch, int height, int pixelSize, unsigned char *dstBuf, int subsamp, int flags)

    int tjEncodeYUV2(tjhandle handle, unsigned char *srcBuf, int width, int pitch, int height, int pixelFormat, unsigned char *dstBuf, int subsamp, int flags)

    int tjDecompressHeader(tjhandle handle, unsigned char *jpegBuf, long unsigned int jpegSize, int *width, int *height)

    int tjDecompressHeader2(tjhandle handle, unsigned char *jpegBuf, long unsigned int jpegSize, int *width, int *height, int *jpegSubsamp)

    int tjDecompress(tjhandle handle, unsigned char *jpegBuf, long unsigned int jpegSize, unsigned char *dstBuf, int width, int pitch, int height, int pixelSize, int flags)

    int tjDecompressToYUV(tjhandle handle, unsigned char *jpegBuf, long unsigned int jpegSize, unsigned char *dstBuf, int flags)



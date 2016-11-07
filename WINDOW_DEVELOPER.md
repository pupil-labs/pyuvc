# Windows Installation Instructions for developers

## Prerequisites

1. [Libusb with isochronous support] (http://github.com/pupil-labs/libusb)
2. [Libuvc] (http://github.com/pupil-labs/libuvc)
3. python 3 64-bit
4. MSVS 2015
5. numpy 
6. cython
7. wheel (make sure pip version is latest)


## Installation

1. Install turbojpeg VC 64 version: http://netassist.dl.sourceforge.net/project/libjpeg-turbo/1.5.1/libjpeg-turbo-1.5.1-vc64.exe
Make sure <jpeg_install_dir>\bin directory is added to the system path
2. Open setup.py and locate the code block branching from "elif platform.system() == 'Windows':". Edit the uvc_dir , tj_dir, and usb_dir 
top level directory locations, corresponding to the installation locations  of libuvc, libturbojpeg and libusb. If you built luibuvc with
binaries directory name different from "bin", and build type different from "Release" , you need to update  "uvc_lib" and "include_dirs" as
well. 
3. Open a new command prompt (to make sure PATH var is loaded)
4. If you wish to install directly run "python setup.py install"
5. If you'd like to create a wheel, run "pip wheel ."

'''
(*)~----------------------------------------------------------------------------------
 Pupil - eye tracking platform
 Copyright (C) 2012-2015  Pupil Labs

 Distributed under the terms of the CC BY-NC-SA License.
 License details are in the file license.txt, distributed as part of this software.
----------------------------------------------------------------------------------~(*)
'''
import os, platform
import numpy
import distutils.sysconfig
from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize
import glob

libs = []
extra_link_args = []
plat_data_files = []
extra_objects = []
libs = ['uvc.0.0.5']
if platform.system() == 'Darwin':
    try:
        tj_lib = glob.glob('/usr/local/opt/jpeg-turbo/lib/libturbojpeg.a')[0]
    except IndexError:
        raise Exception("Please install libturbojpeg")
    include_dirs = ['/usr/local/opt/jpeg-turbo/include/']
    extra_objects = [tj_lib]
elif platform.system() == 'Linux':
    try:
        # check for tubo jpeg offical lib and select appropriate lib32/lib64 path.
        tj_lib = glob.glob('/opt/libjpeg-turbo/lib*')[0]+'/libturbojpeg.a'
    except IndexError:
        raise Exception("Please install libturbojpeg")
    libs += ['rt']
    extra_link_args = []  # ['-Wl,-R/usr/local/lib/']
    include_dirs = ['/opt/libjpeg-turbo/include']
    extra_objects = [tj_lib]
elif platform.system() == 'Windows':
    pack_dir = ''
    uvc_dir = 'D:\\work\\github\\mylibuvc'
    tj_dir = 'D:\\work\\libjpeg-turbo-VC64'
    usb_dir = 'D:\\work\\github\\mylibusb\\libusb'
    pthread_dir = 'D:\\install\\pthreads-w32-2-9-1-release\\dll\\x64'

    tj_lib = tj_dir + '\\lib\\turbojpeg.lib'
    uvc_lib = uvc_dir + '\\bin\\Release\\uvc.lib'

    uvc_dll = uvc_dir + '\\bin\\Release\\uvc.dll'
    usb_dll = usb_dir + '\\x64\Release\\dll\\libusb-1.0.dll'
    tj_dll = tj_dir + '\\bin\\turbojpeg.dll'
    jpg_dll = tj_dir + '\\bin\\jpeg62.dll'
    pthr_dll = pthread_dir + '\\pthreadVC2.dll'

    extra_objects = [tj_lib, uvc_lib]
    libs = []
    extra_link_args = []
    include_dirs = [tj_dir + '\\include']
    include_dirs += [usb_dir] + [usb_dir + '\\libusb']
    include_dirs += [uvc_dir + '\\include'] + [uvc_dir + '\\bin\\include']

    plat_data_files = [(pack_dir,[uvc_dll]), (pack_dir,[usb_dll]),(pack_dir,[tj_dll]), (pack_dir, [jpg_dll]),(pack_dir, [pthr_dll])]

extensions = [
    Extension(name="uvc",
              sources=['uvc.pyx'],
              include_dirs=[numpy.get_include()]+include_dirs,
              libraries=libs,
              extra_link_args=extra_link_args,
              extra_objects=extra_objects,
              extra_compile_args=[]
             ),
             ]

setup(name="uvc",
      version="0.91",  # make sure this is the same in uvc.pxy
      description="Usb Video Class Device bindings with format conversion tool.",
      ext_modules=cythonize(extensions),
      data_files=plat_data_files
     )

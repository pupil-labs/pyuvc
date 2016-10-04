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

from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize
import glob

libs = []
extra_link_args = []
if platform.system() == 'Darwin':
    try:
        tj_lib = glob.glob('/usr/local/opt/jpeg-turbo/lib/libturbojpeg.a')[0]
    except IndexError:
       raise Exception("Please install libturbojpeg")
    include_dirs = ['/usr/local/opt/jpeg-turbo/include/']
elif platform.system() == 'Linux':
    try:
        #check for tubo jpeg offical lib and select appropriate lib32/lib64 path.
        tj_lib = glob.glob('/opt/libjpeg-turbo/lib*')[0]+'/libturbojpeg.a'
    except IndexError:
       raise Exception("Please install libturbojpeg")
    libs  = ['rt']
    extra_link_args = []#['-Wl,-R/usr/local/lib/']
    include_dirs = ['/opt/libjpeg-turbo/include']
elif platform.system() == 'Windows':
    raise NotImplementedError("please fix me.")


extensions = [
    Extension(  name="uvc",
                sources=['uvc.pyx'],
                include_dirs =  [numpy.get_include()]+include_dirs,
                libraries = ['uvc',]+libs,
                extra_link_args=extra_link_args,
                extra_objects = [tj_lib],
                extra_compile_args=[]
            ),
]

setup(  name="uvc",
        version="0.7.2", #make sure this is the same in v4l2.pxy
        description="Usb Video Class Device bindings with format conversion tool.",
        ext_modules=cythonize(extensions)
)

"""
(*)~----------------------------------------------------------------------------------
 Pupil - eye tracking platform
 Copyright (C) 2012-2015  Pupil Labs

 Distributed under the terms of the CC BY-NC-SA License.
 License details are in the file license.txt, distributed as part of this software.
----------------------------------------------------------------------------------~(*)
"""
import glob
import os
import platform

import numpy
from Cython.Build import cythonize
from setuptools import Extension, setup


def macos_homebrew_prefix(package: str) -> str:
    import subprocess

    with subprocess.Popen(
        ["brew", "--prefix", package], stdout=subprocess.PIPE, stderr=subprocess.PIPE
    ) as proc:
        out = proc.stdout.read()
        err = proc.stderr.read()
    if out:
        return out.decode("utf-8").strip()
    else:
        raise ValueError(err.decode("utf-8").strip())


extra_link_args = []
plat_data_files = []
extra_objects = []
library_dirs = []
include_dirs = [numpy.get_include()]
if platform.system() == "Darwin":
    jpeg_turbo_path = macos_homebrew_prefix("jpeg-turbo")
    libs = ["turbojpeg", "uvc.0.0.9"]
    include_dirs += [os.path.join(jpeg_turbo_path, "include")]
    library_dirs += [os.path.join(jpeg_turbo_path, "lib")]
elif platform.system() == "Linux":
    libs = ["rt", "uvc", "turbojpeg"]
elif platform.system() == "Windows":
    pack_dir = ""
    uvc_dir = "C:\\work\\libuvc"
    tj_dir = "C:\\work\\libjpeg-turbo-VC64"
    usb_dir = "C:\\work\\libusb"
    pthread_dir = "C:\\work\\pthreads-w32-2-9-1-release\\Pre-built.2\\dll\\x64"

    tj_lib = tj_dir + "\\lib\\turbojpeg.lib"
    uvc_lib = uvc_dir + "\\bin\\Release\\uvc.lib"

    uvc_dll = uvc_dir + "\\bin\\Release\\uvc.dll"
    usb_dll = usb_dir + "\\x64\Release\\dll\\libusb-1.0.dll"
    tj_dll = tj_dir + "\\bin\\turbojpeg.dll"
    jpg_dll = tj_dir + "\\bin\\jpeg62.dll"
    pthr_dll = pthread_dir + "\\pthreadVC2.dll"

    extra_objects = [tj_lib, uvc_lib]
    libs = ["winmm"]
    extra_link_args = []
    include_dirs += [tj_dir + "\\include"]
    include_dirs += [usb_dir] + [usb_dir + "\\libusb"]
    include_dirs += [uvc_dir + "\\include"] + [uvc_dir + "\\bin\\include"]

    plat_data_files = [
        (pack_dir, [uvc_dll]),
        (pack_dir, [usb_dll]),
        (pack_dir, [tj_dll]),
        (pack_dir, [jpg_dll]),
        (pack_dir, [pthr_dll]),
    ]


extensions = [
    Extension(
        name="uvc",
        sources=["uvc.pyx"],
        include_dirs=include_dirs,
        library_dirs=library_dirs,
        libraries=libs,
        extra_link_args=extra_link_args,
        extra_objects=extra_objects,
        extra_compile_args=[],
    )
]

setup(
    name="uvc",
    version="0.15.0",
    description="Usb Video Class Device bindings with format conversion tool.",
    install_requires=["numpy"],
    ext_modules=cythonize(extensions),
    data_files=plat_data_files,
)

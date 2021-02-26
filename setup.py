"""
(*)~----------------------------------------------------------------------------------
 Pupil - eye tracking platform
 Copyright (C) 2012-2015  Pupil Labs

 Distributed under the terms of the CC BY-NC-SA License.
 License details are in the file license.txt, distributed as part of this software.
----------------------------------------------------------------------------------~(*)
"""
from skbuild import setup

from uvc_version import __version__

setup(
    name="uvc",
    version=__version__,
    description="Usb Video Class Device bindings with format conversion tool.",
    install_requires=["numpy"],
)

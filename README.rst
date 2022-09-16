.. image:: https://img.shields.io/pypi/v/pupil-labs-uvc.svg
   :target: `PyPI link`_

.. image:: https://img.shields.io/pypi/pyversions/pupil-labs-uvc.svg
   :target: `PyPI link`_

.. _PyPI link: https://pypi.org/project/pupil-labs-uvc

.. image:: https://github.com/jaraco/pupil-labs/pyuvc/tests/badge.svg
   :target: https://github.com/pupil-labs/pyuvc/actions?query=workflow%3A%22tests%22
   :alt: tests

.. image:: https://img.shields.io/badge/code%20style-black-000000.svg
   :target: https://github.com/psf/black
   :alt: Code style: Black

.. .. image:: https://readthedocs.org/projects/skeleton/badge/?version=latest
..    :target: https://skeleton.readthedocs.io/en/latest/?badge=latest

.. image:: https://img.shields.io/badge/skeleton-2022-informational
   :target: https://blog.jaraco.com/skeleton

*****
pyuvc
*****

Python bindings for the Pupil Labs fork of `libuvc <https://github.com/pupil-labs/libuvc>`__
with super fast jpeg decompression using `libjpegturbo <http://libjpeg-turbo.virtualgl.org/>`__
(utilizing the tubojpeg api).

* cross platform access to UVC capture devices.
* Full access to all uvc settings (Zoom,Focus,Brightness,etc.)
* Full access to all stream and format parameters (rates,sizes,etc.)
* Enumerate all capture devices with device_list()
* Capture instance will always grab mjpeg conpressed frames from cameras.

Image data is returned as `Frame` object. This object will decompress and convert on the
fly when image data is requested. This gives the user the full flexiblity: Grab just the
jpeg buffers or have them converted to YUV or Gray or RGB and only when you need.

The `Frame` class has caching build in to avoid double decompression or conversion.


Example
#######

See `examples/` for code examples.

Dependencies Linux
##################

TODO: Update

udev rules for running as normal user
*************************************

.. code-block::

   echo 'SUBSYSTEM=="usb",  ENV{DEVTYPE}=="usb_device", GROUP="plugdev", MODE="0664"' | sudo tee /etc/udev/rules.d/10-libuvc.rules > /dev/null
   sudo udevadm trigger

Dependencies Mac
################

TODO: Update

WINDOWS
#######

TODO: Update

Please have a look at WINDOWS_USER.md for install instructions if you want to use PYUVC.
Please have a look at WINDOWS_DEVELOER.md for install instructions if you want to modify PYUVC.

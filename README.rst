.. image:: https://img.shields.io/pypi/v/pupil-labs-uvc.svg
   :target: `PyPI link`_

.. image:: https://img.shields.io/pypi/pyversions/pupil-labs-uvc.svg
   :target: `PyPI link`_

.. _PyPI link: https://pypi.org/project/pupil-labs-uvc

.. image:: https://github.com/pupil-labs/pyuvc/actions/workflows/main.yml/badge.svg
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

Install via PyPI
################

.. code-block::

   pip install pupil-labs-uvc

Example
#######

See `examples/` for code examples.

Install from source
###################

pyuvc requires the following dependencies:

- `libusb <https://github.com/libusb/libusb/>`__
- `libturbo-jpeg <https://libjpeg-turbo.org/>`__
- `POSIX Threads for Windows <https://sourceforge.net/projects/pthreads4w/>`__ (Windows
  only, supplied via the `pupil-pthreads-win <https://pypi.org/project/pupil-pthreads-win/>`__
  Python module)

Once the dependencies are installed, you can pip install the source tree::

   git clone https://github.com/pupil-labs/pyuvc --recursive
   pip install ./pyuvc

Linux
*****

Ubuntu/Debian::

   apt-get update -y
   apt-get install -y libusb-1.0-0-dev libturbojpeg-dev

Running as a non-root user
==========================

One needs to setup udev rules and add the target user to the ``plugdev`` group to avoid
the privileged access requirement.

.. code-block:: bash

   echo 'SUBSYSTEM=="usb",  ENV{DEVTYPE}=="usb_device", GROUP="plugdev", MODE="0664"' | sudo tee /etc/udev/rules.d/10-libuvc.rules > /dev/null
   sudo udevadm trigger
   sudo usermod -a -G plugdev $USER
   # logout and back in

macOS
*****

Homebrew::

   brew update
   brew install libusb jpeg-turbo

Running as a non-root user
==========================

Unfortunately, this is currently not possible. See
`this libusb issue thread <https://github.com/libusb/libusb/issues/1014>`__ for details.

WINDOWS
*******

Run the following code in a powershell to install the dependencies (requires
`7z <https://www.7-zip.org/>`__ to be installed)

.. code-block:: powershell

   pip install build delvewheel
   git clone https://github.com/pupil-labs/pyuvc --recursive
   cd pyuvc
   scripts/download-deps-win.ps1 -DEPS_TMP_PATH tmp
   $Env:DEPS_PATHS_LOC = "tmp/dep_paths.json"
   python -m build -w   # will create a wheel in dist/ folder; insert the wheel path below
   python scripts/repair-wheels-win.py $Env:DEPS_PATHS_LOC <wheel location> wheelhouse
   pip install wheelhouse/<wheel name>


Manual driver installation
==========================

pyuvc requires the libUSBk driver to be installed for your corresponding camera.
Otherwise, metadata like the product name will be set to ``"unknown"``.

Please see `these instructions <https://github.com/pupil-labs/pyuvc/blob/master/WINDOWS_USER.md>`__
on how to manually install libUSBk drivers for your specific camera.

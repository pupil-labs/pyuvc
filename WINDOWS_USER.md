## How to prepare your system for uvc on Windows (8 and later)

PYUVC will only work with Python3.5+ 64bit!


1. Download and install [libusbk 3.0.7.0] (https://sourceforge.net/projects/libusbk/files/libusbK-release/3.0.7.0/libusbK-3.0.7.0-setup.exe/download)

2. Download and install [Zadig] (http://zadig.akeo.ie/downloads/zadig_2.2.exe)

3. Plug in your web camera

4. Start ZadiG. From options menu uncheck "hide composite devices", and check "display all devices"

5. Locate your web camera composite device. It is crucial you select the composite parent and not one of the interfaces, otherwise libusb will not work

6. Set the driver replacement to libusbK (v3.0.7.0) and click "Replace driver"

7. Verify in device manager it is correctly replaced. Should be listed under a new category libusbK USB Devices

8. download the whell file from the releases page and do `pip install uvc-0.7.2-cp35-cp35m-win_amd64.whl`

At this point the uvc extension should be able to locate and stream from your web camera.

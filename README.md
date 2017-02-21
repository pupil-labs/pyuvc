pyuvc
=======

Python bindings for [libuvc](https://github.com/ktossell/libuvc) with super fast jpeg decompression using [libjpegturbo](http://libjpeg-turbo.virtualgl.org/) (utilizing the tubojpeg api).

* cross platform access to UVC capture devices.
* Full access to all uvc settings (Zoom,Focus,Brightness,etc.)
* Full access to all stream and format parameters (rates,sizes,etc.)
* Enumerate all capture devices with device_list()
* Capture instance will always grab mjpeg conpressed frames from cameras.

Image data is returned as `Frame` object. This object will decompress and convert on the fly when image data is requested.
This gives the user the full flexiblity: Grab just the jpeg buffers or have them converted to YUV or Gray or RGB and only when you need.

The `Frame` class has caching build in to avoid double decompression or conversion.


# Example
```python
import uvc
import logging
logging.basicConfig(level=logging.INFO)

dev_list =  uvc.device_list()
print dev_list
cap = uvc.Capture(dev_list[0]['uid'])
print cap.avaible_modes
cap.print_info()
for x in range(10):
	print x
	cap.frame_mode = (640,480,30)
	for x in range(100):
		frame = cap.get_frame_robust()
		print frame.img.shape
		#cv2.imshow("img",frame.gray)
		#cv2.waitKey(1)
cap = None
```

#Dependencies Linux

###libuvc
```
git clone https://github.com/pupil-labs/libuvc
cd libuvc
mkdir build
cd build
cmake ..
make && sudo make install
sudo ldconfig
```

### libjpeg-turbo
```
wget -O libjpeg-turbo.tar.gz https://sourceforge.net/projects/libjpeg-turbo/files/1.5.1/libjpeg-turbo-1.5.1.tar.gz/download
tar xvzf libjpeg-turbo.tar.gz
cd libjpeg-turbo-1.5.1
./configure --with-pic --prefix=/usr/local
sudo make install
sudo ldconfig
```

### cython
```
sudo pip install cython
```

###udev rules for running as normal user:
```
echo 'SUBSYSTEM=="usb",  ENV{DEVTYPE}=="usb_device", GROUP="plugdev", MODE="0664"' | sudo tee /etc/udev/rules.d/10-libuvc.rules > /dev/null 
sudo udevadm trigger
```

#Dependencies Mac

###libuvc
```
git clone https://github.com/pupil-labs/libuvc
cd libuvc
mkdir build
cd build
cmake ..
make && sudo make install
```

### libjpeg-turbo

```
brew install libjpeg-turbo
```

### cython,numpy
```
pip install cython
pip install numpy
```

## just build locally
```
python setup.py build_ext -i
```

## or install system wide
```
python setup.py install
```

# WINDOWS

Please have a look at WINDOWS_USER.md for install instructions if you want to use PYUVC.
Please have a look at WINDOWS_DEVELOER.md for install instructions if you want to modify PYUVC.

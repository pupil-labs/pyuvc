pyuvc
=======

Python bindings for Video4Linux2 API using [libjpegturbo](http://libjpeg-turbo.virtualgl.org/) (utilizing the tubojpeg api).


* Full access to all uvc settings (Zoom,Focus,Brightness,etc.)
* Full access to all stream and format parameters (rates,sizes,etc.)
* Enumerate all capture devices with list_devices()
* Capture instance will always grab mjpeg conpressed frames from cameras.

Image data is returned as `Frame` object. This object will decompress and convert on the fly when image data is requested.
This gives the user the full flexiblity: Grab just the jpeg buffers or have them converted to YUV or Gray or RGB and only when you need.

The `Frame` class has caching build in to avoid double decompression or conversion.


## Example
```python
import uvc
cap = uvc.Capture("/video/dev0")
print cap.frame_rates
frame = cap.get_frame()

gray_numpy_array = frame.gray
bgr_numpy_array = frame.bgr
jpeg_buffer_handle = frame.jpeg_buffer

cap = None
```

##Dependencies Linux

### libjpeg-turbo
Needs to be build with fpic!
Will be installed to `/opt/libjpeg-turbo`.

```
sudo apt-get install nasm
wget -O libjpeg-turbo-1.3.90.tar.gz http://sourceforge.net/projects/libjpeg-turbo/files/1.3.90%20%281.4%20beta1%29/libjpeg-turbo-1.3.90.tar.gz/download
tar xvzf libjpeg-turbo-1.3.90.tar.gz
cd libjpeg-turbo-1.3.90
./configure --with-pic
sudo make install
```

### cython
```
sudo pip install cython
```

###udev rules for sunning as normal user:
```
echo 'SUBSYSTEM=="usb",  ENV{DEVTYPE}=="usb_device", GROUP="plugdev", MODE="0664"' | sudo tee /etc/udev/rules.d/10-libuvc.rules > /dev/null 
sudo udevadm trigger
```

##Dependencies Mac

### libjpeg-turbo

```
brew install libjpeg-turbo
```

### cython
```
pip install cython
```

## just build locally
```
python setup.py build_ext -i
```

## or install system wide
```
python setup.py install
```

import uvc
import logging
import cv2

logging.basicConfig(level=logging.DEBUG)
from time import time,sleep

import numpy as np






print uvc.device_list()
exit()


cap = v4l2.Capture("/dev/video0")
print cap.get_info()
cap.transport_formats
print cap.frame_rate
print cap.frame_size
print cap.transport_format,cap.transport_formats

cap.frame_size = (1920, 1080)
cap.frame_rate= (1,120)
controls =  cap.enum_controls()
print controls
cap.set_control(controls[0]['id'],controls[0]['default'])
print cap.get_control(controls[0]['id'])
print 'Will capture at:',cap.transport_format,cap.frame_size,cap.frame_rate
for x in range(20):
	try:
		frame = cap.get_frame_robust()
	except IOError:
		print "could not grab frame"
		break
	# print frame.width,frame.height
	# print frame.d
	# y= frame.gray
	# print v.shape
	img = frame.yuv
	y,u,v = img
	# y = frame.bgr
	# print y.data
	# y = np.ones((1080,1920b,1))
	# print y[].shape
	# print u[]s.shape
	# cv2.imshow("img",y)
	# cv2.imshow("u",u)
	# cv2.imshow("v",v)

	# cv2.waitKey(1)
	# print img
cap.close()
cap = None


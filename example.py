import uvc
import logging
import cv2
from time import sleep
logging.basicConfig(level=logging.DEBUG)
from time import time,sleep

import numpy as np


dev_list =  uvc.device_list()
print dev_list
cap = uvc.Capture(dev_list[0]['uid'])
print cap.name
# print cap.avaible_modes
cap.print_info()
# for x in range(10):
# 	print x
# 	# cap.frame_mode = (640,480,90)
# 	cap.frame_mode = (640,480,30)
# 	for x in range(3):
# 		frame = cap.get_frame_robust()
# 		frame.img
# 		cv2.imshow("img",frame.gray)
# 		# cv2.imshow("u",u)
# 		# cv2.imshow("v",v)
# 		# sleep(.1)
# 		cv2.waitKey(1)
# 		# print frame.img.shape,x
# 	cap.frame_mode = (1280,720,30)
# 	for x in range(3):
# 		frame = cap.get_frame_robust()
# 		frame.img
# 		cv2.imshow("img",frame.gray)
# 		# cv2.imshow("u",u)
# 		# cv2.imshow("v",v)
# 		# sleep(.1)
# 		cv2.waitKey(1)
# 		# print frame.img.shape,x

# cap = None
# exit()


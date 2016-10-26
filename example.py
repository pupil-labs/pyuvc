from __future__ import print_function
import uvc
import logging
# import cv2
from time import sleep
logging.basicConfig(level=logging.DEBUG)
from time import time,sleep

import numpy as np


dev_list =  uvc.device_list()
print(dev_list)
cap = uvc.Capture(dev_list[0]['uid'])
for c in cap.controls:
    print(getattr(c,'value'))
    if 'Focus' in c.display_name:
        c.value = 0
print(cap.name)
# print cap.avaible_modes
print(cap)
for x in range(500):

    frame = cap.get_frame_robust()
    cv2.imshow("img",frame.gray)
    y,u,v = frame.yuv422
    cv2.imshow("u",u)
    cv2.imshow("v",v)
    cv2.waitKey(1)
#       # print frame.img.shape,x
    # cap.frame_mode = (1280,720,30)
#   for x in range(3):
#       frame = cap.get_frame_robust()
#       frame.img
#       cv2.imshow("img",frame.gray)
#       # cv2.imshow("u",u)
#       # cv2.imshow("v",v)
#       # sleep(.1)
#       cv2.waitKey(1)
#       # print frame.img.shape,x

cap = None
# exit()


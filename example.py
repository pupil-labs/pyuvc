from __future__ import print_function

import uvc
# import cv2
from time import time,sleep

try:
    from multiprocessing import Process,forking_enable,freeze_support
except ImportError:
    try:
        # python3
        from multiprocessing import Process,set_start_method,freeze_support
        def forking_enable(_):
            set_start_method('spawn')
    except ImportError:
        # python2 macos
        from billiard import Process,forking_enable,freeze_support


import numpy as np
dev_list =  uvc.device_list()

def test_cap(i,mode=(640,480,30),format='bgr',bandwidth_factor=1.3):
    print("started cap: %s\n" %i)
    cap = uvc.Capture(dev_list[i]['uid'])
    # cap.print_info()
    cap.bandwidth_factor = bandwidth_factor
    cap.frame_mode = mode

    title = cap.name + ' - ' + str(mode) + ' - ' + format
    ts = time()
    while True:
        frame = cap.get_frame_robust()
        print("%s - %s" %(title,time() - ts))
        ts = time()

        # uncomment below lines for opencv preview

        # if format == 'bgr':
        #     data = frame.bgr
        # elif format == 'gray':
        #     data = frame.gray

        # cv2.imshow(title,data)
        # k = cv2.waitKey(1)
        # if k == 27:
        #     break

    cap = None


if __name__ == '__main__':
    freeze_support()
    forking_enable(0)
    p0 = Process(target=test_cap,args=(0,(1280,720,60),'bgr'))
    p1 = Process(target=test_cap,args=(1,(640,480,120),'gray'))
    p2 = Process(target=test_cap,args=(2,(640,480,120),'gray'))

    p0.start()
    p1.start()
    p2.start()

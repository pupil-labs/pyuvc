import uvc
import logging
import time
logging.basicConfig(level=logging.INFO)

dev_list =  uvc.device_list()
print(dev_list)
cap = uvc.Capture(dev_list[0]['uid'])
for c in cap.controls:
    print(getattr(c,'value'))
    if 'Focus' in c.display_name:
        print("Setting focus");
        c.value = 0
print(cap.name)
#print(cap.avaible_modes)
print(cap)
cap.frame_mode = (640,480,30)
for x in range(100):
    frame = cap.get_frame_robust()
    print(frame.img.shape)

time.sleep(1)
cap.close()
cap = None

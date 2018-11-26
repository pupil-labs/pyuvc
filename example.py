from __future__ import print_function
import uvc
import logging

logging.basicConfig(level=logging.INFO)

dev_list = uvc.device_list()
print(dev_list)
cap = uvc.Capture(dev_list[0]["uid"])

# Uncomment the following lines to configure the Pupil 200Hz IR cameras:
# controls_dict = dict([(c.display_name, c) for c in cap.controls])
# controls_dict['Auto Exposure Mode'].value = 1
# controls_dict['Gamma'].value = 200

print(cap.avaible_modes)
for x in range(10):
    print(x)
    cap.frame_mode = (640, 480, 30)
    for x in range(100):
        frame = cap.get_frame_robust()
        print(frame.img.shape)
        # cv2.imshow("img",frame.gray)
        # cv2.waitKey(1)
cap = None

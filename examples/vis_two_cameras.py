import logging
import os
import time
from typing import Iterable, NamedTuple, Optional

import cv2
import uvc.uvc_bindings as uvc
from rich.logging import RichHandler
from rich.traceback import install as install_rich_traceback


class CameraSpec(NamedTuple):
    name: str
    width: int
    height: int
    fps: int
    bandwidth_factor: float = 2.0


def main(camera_specs: Iterable[CameraSpec]):
    devices = uvc.device_list()
    cameras = {spec: init_camera_from_list(devices, spec) for spec in camera_specs}
    if not all(cameras.values()):
        raise RuntimeError(
            "Could not initialize all specified cameras. Available: "
            f"{[dev['name'] for dev in devices]}"
        )

    try:
        keep_running = True
        last_update = time.perf_counter()

        while keep_running:
            for spec, cam in cameras.items():
                try:
                    frame = cam.get_frame(timeout=0.001)
                except TimeoutError:
                    pass
                    # keep_running = False
                    # break
                except uvc.InitError as err:
                    logging.debug(f"Failed to init {spec}: {err}")
                    keep_running = False
                    break
                except uvc.StreamError as err:
                    logging.debug(f"Failed to get a frame for {spec}: {err}")
                else:
                    data = frame.bgr if hasattr(frame, "bgr") else frame.gray
                    if frame.data_fully_received:
                        cv2.imshow(spec.name, data)

            if (time.perf_counter() - last_update) > 1 / 60:
                if cv2.waitKey(1) & 0xFF == 27:
                    break
                last_update = time.perf_counter()

    except KeyboardInterrupt:
        pass

    for cam in cameras.values():
        cam.close()


def init_camera_from_list(devices, camera: CameraSpec) -> Optional[uvc.Capture]:
    logging.debug(f"Searching {camera}...")
    for device in devices:
        if device["name"] == camera.name:
            logging.debug(f"Found match by name")
            capture = uvc.Capture(device["uid"])
            capture.bandwidth_factor = camera.bandwidth_factor
            for mode in capture.available_modes:
                if mode[:3] == camera[1:4]:  # compare width, height, fps
                    capture.frame_mode = mode
                    return capture
            else:
                logging.warning(
                    f"None of the available modes matched: {capture.available_modes}"
                )
            capture.close()
    else:
        logging.warning(f"No matching camera with name {camera.name!r} found")


if __name__ == "__main__":
    os.environ["LIBUSB_DEBUG"] = "3"
    install_rich_traceback()
    logging.basicConfig(
        level=logging.NOTSET,
        handlers=[RichHandler(level="DEBUG")],
        format="%(message)s",
        datefmt="[%X]",
    )
    # logging.getLogger("uvc").setLevel("INFO")
    main(
        [
            CameraSpec(
                name=os.environ["CAM1"],
                width=1600,
                height=1200,
                fps=30,
                bandwidth_factor=1.6,
            ),
            CameraSpec(
                name=os.environ["CAM2"],
                width=384,
                height=192,
                fps=200,
                bandwidth_factor=0,
            ),
        ]
    )

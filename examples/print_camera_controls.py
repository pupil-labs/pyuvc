import logging

from rich import print
from rich.logging import RichHandler


def main():
    import uvc

    devices = uvc.device_list()
    print("Available devices", devices)

    for device in devices:

        try:
            cap = uvc.Capture(device["uid"])
        except uvc.DeviceNotFoundError:
            continue

        print(f"{cap.name}")

        print("Available modes:")
        for mode in cap.available_modes:
            print(
                f"MODE: {mode.width} x {mode.height} @ {mode.fps} ({mode.format_name})"
            )

        print("Iterating over frame sizes and rates")
        for res in cap.frame_sizes:
            cap.frame_size = res
            for rate in cap.frame_rates:
                cap.frame_rate = rate
                print(f"RES/RATE: {res[0]} x {res[1]} @ {rate} Hz")

        cap.close()


if __name__ == "__main__":
    # import os
    # os.environ["LIBUSB_DEBUG"] = "0"

    logging.basicConfig(
        level=logging.NOTSET,
        handlers=[RichHandler(level="WARNING")],
        format="%(message)s",
        datefmt="[%X]",
    )
    main()

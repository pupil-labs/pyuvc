import logging

try:
    from importlib.metadata import PackageNotFoundError, version
except ImportError:
    from importlib_metadata import PackageNotFoundError, version

# .uvc_bindings expects `logger` to be present
logger = logging.getLogger(__name__)

from .uvc_bindings import (  # noqa: E402
    Capture,
    Device_List,
    InitError,
    OpenError,
    StreamError,
    device_list,
    get_time_monotonic,
    is_accessible,
)

try:
    __version__ = version("pupil-labs-uvc")
except PackageNotFoundError:
    # package is not installed
    pass

__all__ = [
    "__version__",
    "Capture",
    "device_list",
    "Device_List",
    "get_time_monotonic",
    "InitError",
    "is_accessible",
    "OpenError",
    "StreamError",
]

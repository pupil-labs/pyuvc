import logging

try:
    from importlib.metadata import PackageNotFoundError, version
except ImportError:
    from importlib_metadata import PackageNotFoundError, version

try:
    __version__ = version("pupil-labs-uvc")
except PackageNotFoundError:
    # package is not installed
    pass

__all__ = ["__version__"]

logger = logging.getLogger(__name__)

from .uvc_bindings import *

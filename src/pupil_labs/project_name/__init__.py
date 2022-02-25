"""Top-level entry-point for the <project_name> package"""

try:
    from importlib.metadata import PackageNotFoundError, version
except ImportError:
    from importlib_metadata import PackageNotFoundError, version

try:
    __version__ = version("pupil_labs.project_name")
except PackageNotFoundError:
    # package is not installed
    pass

__all__ = ["__version__"]

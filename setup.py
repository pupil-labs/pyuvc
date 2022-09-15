import platform

from setuptools import find_packages
from skbuild import setup

cmake_args = []
if platform.system() == "Windows":
    import os
    import pupil_pthreads_win as ptw

    cmake_args.append(f"-DPTHREADS_WIN_INCLUDE_DIR='{ptw.include_path}'")
    cmake_args.append(f"-DPTHREADS_WIN_IMPORT_LIB_PATH='{ptw.import_lib_path}'")

    for var_name in ("LIBUSB_WIN_INCLUDE_DIR", "LIBUSB_WIN_IMPORT_LIB_PATH"):
        var = os.environ.get(var_name)
        if var is not None:
            cmake_args.append(f"-D{var_name}='{var}'")

    # The Ninja cmake generator will use mingw (gcc) on windows travis instances, but we
    # need to use msvc for compatibility. The easiest solution I found was to just use
    # the vs cmake generator as it defaults to msvc.
    cmake_args.append("-GVisual Studio 15 2017 Win64")
    cmake_args.append("-DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=True")

pyuvc_source_folder = "pyuvc-source"

setup(
    packages=find_packages(where=pyuvc_source_folder),
    package_dir={"": pyuvc_source_folder},
    include_package_data=False,
    cmake_source_dir=pyuvc_source_folder,
    cmake_install_dir=pyuvc_source_folder + "/uvc",
    cmake_args=cmake_args,
)

import json
import os
import pathlib
import platform

from setuptools import find_packages
from skbuild import setup

cmake_args = []
cmake_args.append(f"-DUVC_DEBUGGING={os.environ.get('UVC_DEBUGGING', 'OFF')}")
cmake_args.append(
    f"-DFORCE_LOCAL_LIBUVC_BUILD={os.environ.get('FORCE_LOCAL_LIBUVC_BUILD', 'ON')}"
)

if platform.system() == "Windows":
    import os

    import pupil_pthreads_win as ptw

    cmake_args.append(f"-DPTHREADS_WIN_INCLUDE_DIR='{ptw.include_path}'")
    cmake_args.append(f"-DPTHREADS_WIN_IMPORT_LIB_PATH='{ptw.import_lib_path}'")

    paths = {}
    paths_loc = os.environ.get("DEPS_PATHS_LOC")

    if paths_loc:
        paths = json.loads(pathlib.Path(paths_loc).read_text())

    for path_name, path_value in paths.items():
        path_value = pathlib.Path(path_value).resolve()
        cmake_args.append(f"-D{path_name}='{path_value}'")


    # The Ninja cmake generator will use mingw (gcc) on windows travis instances, but we
    # need to use msvc for compatibility. The easiest solution I found was to just use
    # the vs cmake generator as it defaults to msvc.
    cmake_args.append("-GVisual Studio 17 2022")
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

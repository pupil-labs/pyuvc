from setuptools import find_packages
from skbuild import setup

pyuvc_source_folder = "pyuvc-source"

setup(
    packages=find_packages(where=pyuvc_source_folder),
    package_dir={"": pyuvc_source_folder},
    include_package_data=False,
    cmake_source_dir=pyuvc_source_folder,
    cmake_install_dir=pyuvc_source_folder + "/uvc",
)

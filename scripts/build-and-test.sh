#!/bin/bash -xe
git clean -dxf -e .venv/
export PKG_CONFIG_PATH=/opt/homebrew/opt/jpeg-turbo/lib/pkgconfig

BUILD_WHEEL=true
if [ "$BUILD_WHEEL" = true ]
then
    py -m build . --wheel
    delocate-wheel -v dist/*.whl
    pip install -vv dist/*.whl --force-reinstall
else
    py -m build . --sdist -n
    pip install -vv dist/*.tar.gz --force-reinstall
fi
python examples/access_100_frames.py
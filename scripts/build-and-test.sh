#!/bin/bash -xe

if [ "$1" == "clean" ]
then
    git clean -dxf -e .venv/ -e .venv-dbg/
fi

export PKG_CONFIG_PATH=/opt/homebrew/opt/jpeg-turbo/lib/pkgconfig:$PKG_CONFIG_PATH

DIRECT_INSTALL=true
BUILD_WHEEL=true

if [ "$DIRECT_INSTALL" = true ]
then
    python -m pip install -v ".[example]" --no-build-isolation
elif [ "$BUILD_WHEEL" = true ]
then
    python -m build . --wheel -n
    delocate-wheel -v dist/*.whl
    pip install -v "dist/*.whl[example]" --force-reinstall
else
    python -m build . --sdist -n
    pip install -vv "dist/*.tar.gz[example]" --force-reinstall
fi
python examples/access_100_frames.py
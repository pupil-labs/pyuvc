import uvc as this_project


def test_package_metadata() -> None:
    assert hasattr(this_project, "__version__")

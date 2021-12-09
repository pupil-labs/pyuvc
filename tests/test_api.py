import pupil_labs.project_name as this_project


def test_package_metadata() -> None:
    assert hasattr(this_project, "__version__")
    assert hasattr(this_project, "__version_info__")

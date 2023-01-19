import argparse
import json
import pathlib
import shutil
import subprocess


def repair(deps_paths_loc, wheel, dest_dir):
    import pupil_pthreads_win

    deps_paths = json.loads(pathlib.Path(deps_paths_loc).read_text())
    dll_search_paths = ";".join(
        map(
            str,
            [
                pupil_pthreads_win.dll_path.parent,
                *(
                    p
                    for key, p in deps_paths.items()
                    if key.endswith("DLL_SEARCH_PATH")
                ),
            ],
        )
    )
    cmd = [
        "delvewheel.exe",
        "repair",
        "-w",
        dest_dir,
        wheel,
        "--add-path",
        dll_search_paths,
    ]
    out = subprocess.check_output(cmd).decode()
    print(f"+ {cmd}")
    print(f"+ delvewheel.exe output:\n{out}")
    last_line = out.splitlines()[-1]

    # cibuildwheels expects the wheel to be in dest_dir but delvewheel does not copy the
    # wheel to dest_dir if there is nothing to repair
    if last_line.startswith("no external dependencies are needed"):
        print(f"+ Manually copying {wheel} to {dest_dir}")
        pathlib.Path(dest_dir).mkdir(exist_ok=True)
        shutil.copy2(wheel, dest_dir)
    else:
        print(f"+ No need for a manual copy")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("deps_paths_loc")
    parser.add_argument("wheel")
    parser.add_argument("dest_dir")
    args = parser.parse_args()
    repair(args.deps_paths_loc, args.wheel, args.dest_dir)

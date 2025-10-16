import subprocess
import sys
from pathlib import Path
import os


def main():
    if sys.platform == "win32":
        # TODO: windows cleanup
        print("Nothing has changed on Windows")
        return 0
    else:
        script_dir = Path(__file__).resolve().parent
        cleanup_script = os.path.join(script_dir, "cleanup.sh")
        cmd = (cleanup_script, *sys.argv[1:])
    return subprocess.call(cmd)


if __name__ == "__main__":
    exit(main())

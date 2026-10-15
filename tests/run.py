#!/usr/bin/env python3
"""Build/run real SDL virtual-pad tests and a temporary, instrumented game.

Run under xvfb-run on headless hosts. No changes to the user's settings.
"""
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

repo = Path(__file__).resolve().parents[1]
bmk = sys.argv[1] if len(sys.argv) > 1 else "bmk"
with tempfile.TemporaryDirectory(prefix="gridwars-input-") as temporary:
    temp = Path(temporary)
    profile = temp / "profile"
    profile.mkdir()
    (profile / "Config.txt").write_text(
        "[Windowed]\nTrue\n[Control Type]\nDual Analog\n[Key Move Left]\n81\n"
        "[Used Port]\n3\n[Joy Port]\n99\n[Joy Move X]\n15\n[Joy Move X Scale]\n255\n"
    )
    env = dict(os.environ, GRIDWARS_CONFIG_DIR=str(profile))
    # Match production asset lookup (BlitzMax starts in the executable directory).
    for name in ("gfx", "sounds", "music"):
        (temp / name).symlink_to(repo / name, target_is_directory=True)

    source = (repo / "gridwars.bmx").read_text()
    source = re.sub(r'Import "([^"\n]+\.bmx)"',
                    lambda m: f'Import "{os.path.relpath(repo / m[1], temp)}"', source)
    source = source.replace('Import BRL.Random',
                            'Import BRL.Random\nImport "' +
                            os.path.relpath(repo / "tests/virtualpad.bmx", temp) + '"', 1)
    assert source.count("\nMain()\n") == 1
    source = source.replace("\nMain()\n", "\nTry\nRunGameInputTests()\n"
                            "Catch failure:Object\nPrint failure.ToString()\nexit_(1)\nEnd Try\n", 1)
    source += "\n" + (repo / "tests/game_integration.bmx").read_text()
    integration = temp / "integration.bmx"
    integration.write_text(source)
    for name, entry in (("input", repo / "tests/input_test.bmx"),
                        ("integration", integration)):
        binary = temp / name
        log = temp / f"{name}-build.log"
        with log.open("w") as output:
            result = subprocess.run(
                [bmk, "makeapp", "-t", "console", "-g", "x64", "-d", "-w",
                 "-o", str(binary), str(entry)], stdout=output, stderr=subprocess.STDOUT)
        if result.returncode:
            sys.exit("\n".join(log.read_text().splitlines()[-25:]))
        subprocess.run([str(binary)], input="q\n", text=True, env=env, check=True, timeout=60)
    saved = (profile / "Config.txt").read_text()
    assert "[Key Move Left]\n81\n" in saved
    assert "[Control Type]\nHybrid\n" in saved
    assert "[Gamepad Deadzone]\n19\n" in saved
    assert "[Joy Port]" not in saved
    assert (profile / "Colours.txt").stat().st_size > 0
    assert (profile / "hiscores.dat").stat().st_size > 0
    print("PASS: isolated profile migration and normal-exit settings/high-score persistence")

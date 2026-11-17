#!/usr/bin/env python3
"""Make the patch from the built disc, and check it.

    python3 tools/patch.py

Writes dist/ys-iii-enhanced-0.2.0.xdelta, a VCDIFF patch (tools/vcdiff.py) from your
Track 02 file (.local/disc.cue) to the one tools/mkdisc.py built (dist/disc/). Its
added data holds only bytes that differ from your file at their place. It then
applies the patch with xdelta3 to the same file, compares the result with the build,
and puts apply.py, README.md, LICENSE, CREDITS.md (and, when present, the
second-step manifest, edc130.py and pregen/) beside the patch. Needs xdelta3 on the PATH.
"""
import hashlib
import json
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import disc  # noqa: E402
import vcdiff  # noqa: E402


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def main():
    base = disc.data_track(disc.parse_cue(ROOT / ".local/disc.cue"))["file"]
    dist = ROOT / "dist"
    patched = dist / "disc" / base.name
    if not patched.exists():
        sys.exit(f"{patched} not found: run tools/mkdisc.py first")
    cfg = json.loads((ROOT / "src/modules.json").read_text())
    want = cfg["release_track_sha256"]
    if sha(patched) != want:
        sys.exit(f"{patched.name}: not the expected build (sha256 {want}); no patch written")
    out = dist / "ys-iii-enhanced-0.2.0.xdelta"
    out.write_bytes(vcdiff.encode(base.read_bytes(), patched.read_bytes()))
    check = dist / "roundtrip.tmp"
    subprocess.run(["xdelta3", "-d", "-f", "-s", str(base), str(out), str(check)], check=True)
    same = sha(check) == sha(patched)
    check.unlink()
    print(f"{out}: {out.stat().st_size} bytes; source sha256 {sha(base)}; round trip {'byte-identical' if same else 'DIFFERS'}")
    if not same:
        sys.exit(1)
    for name in ("apply.py", "README.md", "LICENSE", "CREDITS.md"):
        shutil.copyfile(ROOT / name, dist / name)
    manifest = dist / "disc.store.json"
    if manifest.is_file():
        want_m = cfg.get("manifest_sha256")
        if want_m and sha(manifest) != want_m:
            sys.exit(f"{manifest.name}: sha256 {sha(manifest)} differs from {want_m}")
        shutil.copyfile(manifest, out.with_suffix(".store.json"))
        shutil.copyfile(ROOT / "tools/edc130.py", dist / "edc130.py")
        pre = dist / "pregen"
        shutil.rmtree(pre, ignore_errors=True)
        pre.mkdir(parents=True, exist_ok=True)
        for p in sorted((ROOT / "tools/pregen").glob("*.py")):
            shutil.copyfile(p, pre / p.name)


if __name__ == "__main__":
    main()

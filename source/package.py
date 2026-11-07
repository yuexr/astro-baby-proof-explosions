import argparse
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
from zipfile import ZIP_DEFLATED, ZipFile

parser = argparse.ArgumentParser()
parser.add_argument("--repak", required=True, type=Path)
parser.add_argument("--mod", type=Path, help="Override the BabyProofDynamites source folder")
args = parser.parse_args()
root = Path(__file__).resolve().parent.parent
if args.mod is None:
    args.mod = root / "BabyProofDynamites"
metadata_path = root / "metadata.json"
metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
mod_id, version = metadata["mod_id"], metadata["version"]
assert metadata["schema_version"] == 2 and metadata["enable_ue4ss"] is True
assert re.fullmatch(r"[A-Za-z0-9.]+", mod_id)
assert re.fullmatch(r"\d+\.\d+\.\d+", version)
assert metadata["name"] and metadata["author"]
build = root / "build"
build.mkdir(exist_ok=True)
pak = build / f"000-{mod_id}-{version}_P.pak"
dist = root / "dist"
dist.mkdir(exist_ok=True)
archive = dist / f"Baby-Proof-Explosions-{version}.zip"
files = (
    "config.ini",
    "Scripts/main.lua",
    "Scripts/BabyProofDynamitesNative.dll",
)
with tempfile.TemporaryDirectory(dir=build) as temp:
    work = Path(temp)
    payload = work / "payload"
    payload.mkdir()
    (payload / "metadata.json").write_text(
        json.dumps(metadata, indent=2) + "\n", encoding="utf-8"
    )
    for name in files:
        target = payload / "UE4SS" / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(args.mod / name, target)
    subprocess.run(
        [str(args.repak), "pack", "--version", "V8B", "--mount-point", "../../../",
         str(payload), str(pak)], check=True
    )
    unpacked = work / "unpacked"
    subprocess.run(
        [str(args.repak), "unpack", str(pak), "--output", str(unpacked)], check=True
    )
    expected = {p.relative_to(payload).as_posix(): p.read_bytes()
                for p in payload.rglob("*") if p.is_file()}
    actual = {p.relative_to(unpacked).as_posix(): p.read_bytes()
              for p in unpacked.rglob("*") if p.is_file()}
    assert actual == expected, "PAK round-trip mismatch"
    assert not actual["metadata.json"].startswith(b"\xef\xbb\xbf")
    extracted_mod = work / "amlc-extraction" / mod_id
    for name, data in actual.items():
        if name.startswith("UE4SS/"):
            target = extracted_mod / name[6:]
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
    for name in files:
        assert (extracted_mod / name).read_bytes() == (args.mod / name).read_bytes()

with ZipFile(archive, "w", compression=ZIP_DEFLATED) as package:
    package.write(pak, pak.name)
with ZipFile(archive) as package:
    assert package.testzip() is None
    assert package.namelist() == [pak.name]
    assert package.read(pak.name) == pak.read_bytes()
print("Verified metadata, PAK round-trip, extracted Lua/DLL/config layout and ZIP.")
print(archive)

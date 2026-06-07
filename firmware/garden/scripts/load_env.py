Import("env")
from pathlib import Path

ENV_FILE = Path(env["PROJECT_DIR"]) / ".env"
OUT_FILE = Path(env["PROJECT_DIR"]) / "include" / "secrets.h"

lines = ENV_FILE.read_text().splitlines()
defines = []

for line in lines:
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    key, _, value = line.partition("=")
    defines.append(f'#define {key.strip()} "{value.strip()}"')

OUT_FILE.write_text("\n".join([
    "#pragma once",
    "// Auto-generated from .env — do not commit",
    *defines,
    "",
]))

print("Generated secrets.h from .env")



#!/usr/bin/env python3
"""Actualizador inicial del catálogo de Bacus Hub Universe."""

from pathlib import Path
import json
import sys
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parent.parent
CATALOG_DIR = ROOT / "catalog"
OUTPUT_FILE = CATALOG_DIR / "index.json"


def main():
    CATALOG_DIR.mkdir(parents=True, exist_ok=True)

    packages = []

    # Leer los manifiestos JSON existentes.
    for manifest in sorted(CATALOG_DIR.glob("*/package.json")):
        try:
            with manifest.open("r", encoding="utf-8") as file:
                package = json.load(file)

            if not isinstance(package, dict):
                raise ValueError("El manifiesto debe contener un objeto JSON.")

            packages.append(package)

        except (OSError, json.JSONDecodeError, ValueError) as error:
            print(f"ERROR: {manifest}: {error}", file=sys.stderr)
            return 1

    catalog = {
        "schema_version": "1.0",
        "hub": "Bacus Hub Universe",
        "updated_at": datetime.now(timezone.utc).isoformat(),
        "package_count": len(packages),
        "packages": packages,
    }

    temporary_file = OUTPUT_FILE.with_suffix(".json.tmp")

    with temporary_file.open("w", encoding="utf-8") as file:
        json.dump(catalog, file, indent=2, ensure_ascii=False)
        file.write("\n")

    temporary_file.replace(OUTPUT_FILE)

    print(f"Catálogo actualizado: {len(packages)} paquetes.")
    print(f"Archivo generado: {OUTPUT_FILE.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())


#!/bin/sh
# Construye un paquete .bp inicial.
set -eu

usage() {
    echo "Uso: sh tools/bacus-build.sh DIRECTORIO_FUENTE SALIDA.bp" >&2
    exit 2
}

[ "$#" -eq 2 ] || usage

src=$1
out=$2

[ -d "$src" ] || {
    echo "Error: no existe el directorio fuente: $src" >&2
    exit 1
}

command -v tar >/dev/null 2>&1 || {
    echo "Error: falta tar" >&2
    exit 1
}

for f in package.conf install.sh; do
    [ -f "$src/$f" ] || {
        echo "Error: falta $src/$f" >&2
        exit 1
    }
done

getval() {
    awk -F= -v key="$1" \
        '$1 == key {sub(/^[^=]*=/,""); print; exit}' \
        "$src/package.conf"
}

id=$(getval ID)
name=$(getval NAME)
version=$(getval VERSION)
description=$(getval DESCRIPTION)
arch=$(getval ARCHITECTURE)
entry=$(getval ENTRYPOINT)

for pair in \
    "ID:$id" \
    "NAME:$name" \
    "VERSION:$version" \
    "DESCRIPTION:$description" \
    "ARCHITECTURE:$arch" \
    "ENTRYPOINT:$entry"
do
    val=${pair#*:}
    [ -n "$val" ] || {
        echo "Error: campo vacío ($pair)" >&2
        exit 1
    }

    case "$val" in
        *"	"*|*"
"*)
            echo "Error: metadatos con tabuladores o saltos de línea" >&2
            exit 1
            ;;
    esac
done

case "$id" in
    *[!a-zA-Z0-9._+-]*|'')
        echo "Error: ID inválido: $id" >&2
        exit 1
        ;;
esac

case "$version" in
    *[!a-zA-Z0-9._+-]*|'')
        echo "Error: versión inválida: $version" >&2
        exit 1
        ;;
esac

case "$entry" in
    /*|*..*)
        echo "Error: ENTRYPOINT debe ser una ruta relativa segura" >&2
        exit 1
        ;;
esac

tmp=${TMPDIR:-/tmp}/bacus-build.$$
stage=$tmp/stage
mkdir -p "$stage/payload"

trap 'rm -rf "$tmp"' EXIT HUP INT TERM

find "$src" -mindepth 1 -maxdepth 1 \
    ! -name package.conf \
    ! -name install.sh \
    -exec cp -R {} "$stage/payload/" \;

[ -e "$stage/payload/$entry" ] || {
    echo "Error: ENTRYPOINT '$entry' no existe en el payload" >&2
    exit 1
}

cp "$src/install.sh" "$stage/install.sh"
chmod 755 "$stage/install.sh"

{
    printf 'id\tname\tversion\tdescription\tarchitecture\tentrypoint\n'
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$id" "$name" "$version" "$description" "$arch" "$entry"
} > "$stage/manifest.tsv"

outdir=$(dirname "$out")
mkdir -p "$outdir"

case "$out" in
    /*) out_abs=$out ;;
    *) out_abs="$(pwd)/$out" ;;
esac

tar -czf "$out_abs" \
    -C "$stage" manifest.tsv install.sh payload

echo "Paquete creado: $out_abs"

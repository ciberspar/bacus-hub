
#!/bin/sh
set -eu

prefix=$1
entry=$2

[ -f "$prefix/$entry" ] || {
    echo "No se encontró el ejecutable instalado" >&2
    exit 1
}

chmod 755 "$prefix/$entry"
echo "Hola Bacus: instalado en $prefix/$entry"


#!/bin/sh
# Instalador inicial de paquetes .bp.
set -eu

[ "$#" -ge 1 ] && [ "$#" -le 2 ] || {
    echo "Uso: sh tools/bacus-install.sh ARCHIVO.bp [PREFIJO]" >&2
    exit 2
}

pkg=$1
prefix=${2:-"$HOME/.local"}

[ -f "$pkg" ] || {
    echo "Error: no existe $pkg" >&2
    exit 1
}

command -v tar >/dev/null 2>&1 || {
    echo "Error: falta tar" >&2
    exit 1
}

tmp=${TMPDIR:-/tmp}/bacus-install.$$
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

tar -tzf "$pkg" > "$tmp/list"

awk '
    /^\// { bad=1 }
    {
        n=split($0,a,"/")
        for (i=1;i<=n;i++)
            if (a[i]=="..") bad=1
    }
    END { exit bad ? 1 : 0 }
' "$tmp/list" || {
    echo "Error: el paquete contiene rutas inseguras" >&2
    exit 1
}

tar -xzf "$pkg" -C "$tmp"

[ -f "$tmp/manifest.tsv" ] && [ -d "$tmp/payload" ] || {
    echo "Error: formato .bp inválido" >&2
    exit 1
}

entry=$(awk -F '\t' 'NR==2 {print $6}' "$tmp/manifest.tsv")

[ -n "$entry" ] || {
    echo "Error: manifest.tsv inválido" >&2
    exit 1
}

case "$entry" in
    /*|*..*)
        echo "Error: entrypoint inseguro" >&2
        exit 1
        ;;
esac

[ -e "$tmp/payload/$entry" ] || {
    echo "Error: entrypoint no encontrado" >&2
    exit 1
}

echo "ATENCIÓN: install.sh ejecutará código incluido en el paquete."
echo "Revisa el instalador con:"
echo "tar -xOf '$pkg' install.sh"
echo "Destino: $prefix"

mkdir -p "$prefix"
cp -R "$tmp/payload/." "$prefix/"

sh "$tmp/install.sh" "$prefix" "$entry"

echo "Instalación terminada."

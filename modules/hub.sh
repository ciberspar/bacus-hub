
#!/bin/sh
set -eu

REPO_TSV=${BACUS_HUB_TSV:-https://raw.githubusercontent.com/ciberspar/bacus-hub/main/catalog/packages.tsv}

cmd=${1:-help}
[ "$#" -eq 0 ] || shift

case "$cmd" in
    help|-h|--help)
        cat <<'EOF'
Bacus Hub (catálogo; no instala paquetes)

  hub list
  hub search TEXTO
  hub info ID

Para probar un catálogo local:
  BACUS_HUB_TSV=/ruta/packages.tsv hub list
EOF
        ;;

    list|search|info)
        tmp=${TMPDIR:-/tmp}/bacus-hub.$$
        trap 'rm -f "$tmp"' EXIT HUP INT TERM

        case "$REPO_TSV" in
            http://*|https://*)
                if command -v curl >/dev/null 2>&1; then
                    curl -fsSL "$REPO_TSV" -o "$tmp"
                elif command -v wget >/dev/null 2>&1; then
                    wget -qO "$tmp" "$REPO_TSV"
                else
                    echo "Error: necesitas curl o wget" >&2
                    exit 1
                fi
                ;;
            *)
                cp "$REPO_TSV" "$tmp"
                ;;
        esac

        case "$cmd" in
            list)
                awk -F '\t' '
                    NF>=7 && $1 !~ /^#/ && NR>1 {
                        printf "%-20s %-12s %-10s %s\n",
                            $1,$2,$3,$4
                    }
                ' "$tmp"
                ;;

            search)
                q=${1:-}
                [ -n "$q" ] || {
                    echo "Uso: hub search TEXTO" >&2
                    exit 2
                }

                awk -F '\t' -v q="$q" '
                    NF>=7 && $1 !~ /^#/ && NR>1 &&
                    index(tolower($0),tolower(q)) {
                        print
                    }
                ' "$tmp"
                ;;

            info)
                id=${1:-}
                [ -n "$id" ] || {
                    echo "Uso: hub info ID" >&2
                    exit 2
                }

                awk -F '\t' -v id="$id" '
                    NF>=7 && $1==id {
                        print
                        found=1
                    }
                    END { if (!found) exit 1 }
                ' "$tmp" || {
                    echo "No encontrado: $id" >&2
                    exit 1
                }
                ;;
        esac
        ;;

    *)
        echo "Comando desconocido: $cmd" >&2
        exit 2
        ;;
esac

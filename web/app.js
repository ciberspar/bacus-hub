
const root = document.querySelector("#packages");
const status = document.querySelector("#status");
const q = document.querySelector("#q");

let packages = [];

function safeURL(value) {
    try {
        const url = new URL(value);

        if (url.protocol === "https:") {
            return url.href;
        }

        return null;
    } catch {
        return null;
    }
}

function render() {
    const term = q.value.trim().toLowerCase();

    const shown = packages.filter((p) => {
        const fields = [
            p.id,
            p.name,
            p.description,
            p.version,
            (p.platforms || []).join(" ")
        ];

        return fields.join(" ").toLowerCase().includes(term);
    });

    root.replaceChildren();

    for (const p of shown) {
        const card = document.createElement("article");
        card.className = "package";

        const heading = document.createElement("h2");
        heading.textContent = p.name || p.id;

        const meta = document.createElement("p");
        meta.className = "muted";
        meta.textContent =
            `${p.version || "sin versión"} · ` +
            `${(p.platforms || []).join(", ") || "plataforma no indicada"}`;

        const desc = document.createElement("p");
        desc.textContent = p.description || "Sin descripción";

        card.append(heading, meta, desc);

        const url = safeURL(p.url);

        if (url) {
            const link = document.createElement("a");
            link.href = url;
            link.rel = "noopener noreferrer";
            link.textContent = "Ver paquete";
            card.append(link);
        }

        root.append(card);
    }

    status.textContent = `${shown.length} paquete(s) encontrado(s).`;
}

q.addEventListener("input", render);

fetch("./catalog/packages.json")
    .then((response) => {
        if (!response.ok) {
            throw new Error("No se pudo cargar el catálogo");
        }

        return response.json();
    })
    .then((data) => {
        packages = Array.isArray(data.packages) ? data.packages : [];
        render();
    })
    .catch(() => {
        status.textContent =
            "No se pudo cargar el catálogo. Comprueba catalog/packages.json.";
    });

#!/bin/bash
set -e

# === 0) Variables de infraestructura ===
if [ ! -f "infraestructura-info.txt" ]; then
  echo "❌ Falta infraestructura-info.txt"; exit 1
fi
source infraestructura-info.txt
: "${PUBLIC_IP:?Falta PUBLIC_IP}"
: "${KEY_PEM:?Falta KEY_PEM}"
EC2_USER="${EC2_USER:-ec2-user}"

echo "🚀 Destino: $EC2_USER@$PUBLIC_IP"

# === 1) Instalar/levantar Apache ===
ssh -i "$KEY_PEM" -o StrictHostKeyChecking=no "$EC2_USER@$PUBLIC_IP" \
  "sudo dnf -y install httpd && sudo systemctl enable --now httpd"

# === 2) Subir proyectos.json ===
scp -i "$KEY_PEM" -o StrictHostKeyChecking=no proyectos.json "$EC2_USER@$PUBLIC_IP":/tmp/proyectos.json
ssh -i "$KEY_PEM" -o StrictHostKeyChecking=no "$EC2_USER@$PUBLIC_IP" \
  "sudo mv /tmp/proyectos.json /var/www/html/proyectos.json && sudo chown apache:apache /var/www/html/proyectos.json && sudo chmod 644 /var/www/html/proyectos.json"

# === 3) (Opcional) Subir página de ejemplo que consume el JSON ===
cat > index_proyectos.html <<'HTML'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Proyectos</title>
  <style>
    body { font-family: system-ui, Arial, sans-serif; margin: 24px; }
    header { display: flex; gap: 12px; flex-wrap: wrap; align-items: center; margin-bottom: 16px; }
    input, button { padding: 8px 10px; font-size: 14px; }
    .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 16px; }
    .card { border: 1px solid #ddd; border-radius: 12px; padding: 16px; }
    .title { font-weight: 700; margin-bottom: 6px; }
    .meta { font-size: 14px; color: #444; margin-top: 8px; }
    .badge { display:inline-block; background:#f0f0f0; padding:2px 8px; border-radius: 999px; margin-right:6px; margin-top:4px;}
  </style>
</head>
<body>
  <h1>Proyectos</h1>
  <header>
    <input id="q" type="text" placeholder="Buscar por nombre/descripcion"/>
    <input id="max_funding" type="number" min="0" placeholder="Funding máx."/>
    <input id="integrante" type="text" placeholder="Integrante"/>
    <button id="btn">Filtrar</button>
    <span id="total"></span>
  </header>
  <div class="grid" id="list"></div>

  <script>
    const $q = document.getElementById('q');
    const $max = document.getElementById('max_funding');
    const $int = document.getElementById('integrante');
    const $btn = document.getElementById('btn');
    const $list = document.getElementById('list');
    const $total = document.getElementById('total');

    let base = [];

    async function load() {
      const res = await fetch('./proyectos.json');
      base = await res.json();
      render();
    }

    function render() {
      let data = [...base];
      const q = ($q.value||'').toLowerCase().trim();
      const max = parseInt($max.value, 10);
      const integrante = ($int.value||'').toLowerCase().trim();

      if (q) {
        data = data.filter(p =>
          (p.nombre_proyecto||'').toLowerCase().includes(q) ||
          (p.descripcion||'').toLowerCase().includes(q)
        );
      }
      if (!Number.isNaN(max)) {
        data = data.filter(p => Number(p.funding_necesario) <= max);
      }
      if (integrante) {
        data = data.filter(p =>
          (p.integrantes||[]).some(n => (n||'').toLowerCase().includes(integrante))
        );
      }

      $total.textContent = `Total: ${data.length}`;
      $list.innerHTML = data.map(p => `
        <div class="card">
          <div class="title">${p.nombre_proyecto}</div>
          <div>${p.descripcion}</div>
          <div class="meta">Funding necesario: $${p.funding_necesario.toLocaleString()}</div>
          <div class="meta">Integrantes: ${p.integrantes.map(n=>`<span class="badge">${n}</span>`).join('')}</div>
        </div>
      `).join('');
    }

    $btn.addEventListener('click', render);
    [$q,$max,$int].forEach(el => el.addEventListener('keydown', e => { if(e.key==='Enter') render(); }));

    load();
  </script>
</body>
</html>
HTML

scp -i "$KEY_PEM" -o StrictHostKeyChecking=no index_proyectos.html "$EC2_USER@$PUBLIC_IP":/tmp/index_proyectos.html
ssh -i "$KEY_PEM" -o StrictHostKeyChecking=no "$EC2_USER@$PUBLIC_IP" \
  "sudo mv /tmp/index_proyectos.html /var/www/html/index_proyectos.html && sudo chown apache:apache /var/www/html/index_proyectos.html && sudo chmod 644 /var/www/html/index_proyectos.html"
rm -f index_proyectos.html

echo "✅ Listo:"
echo "   • JSON:   http://$PUBLIC_IP/proyectos.json"
echo "   • Demo:   http://$PUBLIC_IP/index_proyectos.html"
echo "ℹ️ Asegúrate de tener abierto el puerto 80 (HTTP) en tu Security Group."

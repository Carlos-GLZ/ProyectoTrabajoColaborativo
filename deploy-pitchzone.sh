#!/bin/bash

# Actualizar sistema y preparar Apache
# (Amazon Linux 2/2023: yum/dnf; mantenemos yum por compatibilidad)
sudo yum update -y
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd

# Mover logo si está presente en /tmp/
if [ -f /tmp/logo_pitchzone.png ]; then
    sudo mv /tmp/logo_pitchzone.png /var/www/html/logo_pitchzone.png
    sudo chown apache:apache /var/www/html/logo_pitchzone.png
    LOGO_HTML='<img src="logo_pitchzone.png" alt="PitchZone Logo" style="height:58px; margin-bottom:12px; border-radius:12px; box-shadow:0 0 10px #1B768E;">'
else
    LOGO_HTML='<span style="font-size:3rem;color:#FB9833;font-weight:800;">P</span>'
fi

# Mover base de datos si está presente en /tmp/
DB_BADGE=""
if [ -f /tmp/proyectos.json ]; then
    sudo mv /tmp/proyectos.json /var/www/html/proyectos.json
    sudo chown apache:apache /var/www/html/proyectos.json
    sudo chmod 644 /var/www/html/proyectos.json
    DB_BADGE='<span id="dbBadge" style="display:inline-block;background:#FB9833;color:#012538;padding:6px 10px;border-radius:999px;font-weight:800;margin-left:8px;">DB Cargada</span>'
fi

# Crear landing page PitchZone
sudo bash -c "cat > /var/www/html/index.html" <<HTMLEOF
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PitchZone - Súbelo. Preséntalo. Véndelo.</title>
    <link href='https://fonts.googleapis.com/css?family=Montserrat:700,400' rel='stylesheet'>
    <style>
        :root {
            --primary-orange: #FB9833;
            --primary-light: #FCEFEF;
            --primary-teal: #1B768E;
            --primary-dark: #012538;
            --primary-gray: #4D555B;
        }
        body {
            margin:0; font-family: 'Montserrat', Arial, sans-serif;
            background: linear-gradient(135deg, var(--primary-dark) 70%, var(--primary-teal) 100%);
            color: var(--primary-light);
            min-height:100vh;
        }
        header {
            background:rgba(1,37,56,0.96);
            padding:22px 40px 10px 40px;
            display:flex; align-items:center; justify-content:space-between;
            border-bottom:2px solid var(--primary-teal);
            position:sticky; top:0; z-index:20;
        }
        .logo-zone {display:flex;align-items:center;gap:14px;}
        .logo-zone span {font-weight:800;font-size:1.55em;letter-spacing:2px;}
        nav a {
            color: var(--primary-light); text-decoration:none; margin:0 18px;
            font-weight:bold; letter-spacing:1px; transition:color 0.2s;
        }
        nav a:hover {color:var(--primary-orange);}
        .hero {
            display:flex; flex-direction:column; align-items:center;
            padding:60px 10px 44px 10px; text-align:center;
        }
        .hero h1 {font-size:2.8em;font-weight:800;letter-spacing:1.7px;margin-bottom:9px;}
        .hero p {font-size:1.3em;color:var(--primary-orange);font-weight:600;margin-bottom:33px;letter-spacing:2px;}
        .hero-btn {
            background:var(--primary-orange);color:var(--primary-dark);font-weight:800;font-size:1.19em;
            border:none; padding:16px 42px; border-radius:28px; cursor:pointer;
            box-shadow:0 4px 30px #01253899;transition:background 0.2s,color 0.2s;
            margin-bottom:34px; letter-spacing:1.4px;
        }
        .hero-btn:hover {background:var(--primary-light);color:var(--primary-orange);}
        .main-content {
            background:var(--primary-light);color:var(--primary-dark);padding:48px 0 36px 0;margin-top:24px;
            border-radius:36px 36px 0 0;box-shadow:0 -4px 40px #01253844;
        }
        .features {display:flex;flex-wrap:wrap;justify-content:center;gap:30px;margin-top:16px;}
        .feature-card {
            background:var(--primary-gray);color:var(--primary-light);border-radius:20px;box-shadow:0 2px 14px #1B768E66;
            width:270px;padding:26px 18px;text-align:center;transition:transform 0.13s;
        }
        .feature-card:hover {transform:scale(1.05);box-shadow:0 7px 28px #FB983388;}
        .feature-icon {font-size:2.3rem;margin-bottom:13px;}
        .feature-title {font-weight:700;color:var(--primary-orange);font-size:1.13em;margin-bottom:7px;}
        footer {
            background:var(--primary-dark);color:var(--primary-light);
            text-align:center;padding:28px 10px 20px 10px;font-size:1em;
            margin-top:36px;border-top:2px solid var(--primary-teal);
        }
        @media (max-width:900px){
            .main-content,.features{flex-direction:column;align-items:center;}
            .feature-card{width:90%;}
            header{padding:18px 8px 8px 8px;}
        }
        .badge {display:inline-block;background:#f0f0f0;color:#012538;padding:6px 10px;border-radius:999px;font-weight:800;margin-left:8px;}
    </style>
</head>
<body>
    <header>
        <div class='logo-zone'>
            ${LOGO_HTML}
            <span>PITCHZONE</span>
            ${DB_BADGE}
        </div>
        <nav>
            <a href="#">Inicio</a>
            <a href="#caracteristicas">Características</a>
            <a href="#alianzas">Alianzas</a>
            <a href="#eventos">Eventos</a>
            <a href="#contacto">Contacto</a>
        </nav>
    </header>
    <section class='hero'>
        ${LOGO_HTML}
        <h1>PITCHZONE</h1>
        <p>"Súbelo. Preséntalo. Véndelo."</p>
        <button class='hero-btn' onclick="alert('Pronto podrás subir tu pitch')">¡Sube tu proyecto ahora!</button>
        <div id="dbInfo" style="margin-top:10px;font-weight:700;"></div>
    </section>
    <div class="main-content" id="caracteristicas">
        <h2 style="text-align:center;font-size:2em;color:var(--primary-dark);margin-bottom:28px;">¿Qué puedes hacer en PitchZone?</h2>
        <div class="features">
            <div class="feature-card">
                <div class="feature-icon">🎬</div>
                <div class="feature-title">Reels de Proyectos</div>
                <div>Muestra tu pitch en video y destaca ante inversores.</div>
            </div>
            <div class="feature-card">
                <div class="feature-icon">🏫</div>
                <div class="feature-title">Alianzas Universitarias</div>
                <div>Difunde tu proyecto con el apoyo de universidades e incubadoras.</div>
            </div>
            <div class="feature-card">
                <div class="feature-icon">🚀</div>
                <div class="feature-title">Demo Day y Eventos</div>
                <div>Participa en concursos y presentaciones virtuales.</div>
            </div>
            <div class="feature-card">
                <div class="feature-icon">💡</div>
                <div class="feature-title">Proyectos Olvidados</div>
                <div>Revive y publica ideas que merecen una segunda oportunidad.</div>
            </div>
        </div>
    </div>
    <footer>
        <div>
            ${LOGO_HTML}
            <br>
            PitchZone — Súbelo. Preséntalo. Véndelo.<br>
            <span style="color:var(--primary-orange);">contacto@pitchzone.com</span>
        </div>
        <div style="margin-top:13px;">
            <a href="#" style="color:var(--primary-orange);margin:0 10px;">Instagram</a>
            <a href="#" style="color:var(--primary-orange);margin:0 10px;">LinkedIn</a>
            <a href="#" style="color:var(--primary-orange);margin:0 10px;">YouTube</a>
        </div>
        <div style="margin-top:7px;font-size:0.9em;color:#FCEFEF88;">
            © 2025 PitchZone. Todos los derechos reservados.
        </div>
    </footer>

    <script>
      // Si existe /proyectos.json, mostramos el total en la hero y pintamos una mini lista en consola
      fetch('./proyectos.json', {cache:'no-store'})
        .then(r => r.ok ? r.json() : Promise.reject(r.status))
        .then(data => {
          const info = document.getElementById('dbInfo');
          info.innerHTML = 'Proyectos cargados: <span class="badge">'+data.length+'</span>';
          console.log('Proyectos.json ->', data);
          const badge = document.getElementById('dbBadge');
          if (badge) badge.textContent = 'DB OK ('+data.length+')';
        })
        .catch(() => {
          const info = document.getElementById('dbInfo');
          info.textContent = 'Sin base de datos (proyectos.json no encontrado)';
        });
    </script>
</body>
</html>
HTMLEOF

# Ajustar permisos
sudo chown -R apache:apache /var/www/html
sudo chmod -R 755 /var/www/html
sudo systemctl restart httpd

echo "✅ PitchZone desplegado exitosamente en la EC2."

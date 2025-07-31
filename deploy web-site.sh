# ============================================================================
# SCRIPT 2: deploy-website.sh
# Despliega la página web de PitchZone en la instancia EC2
# ============================================================================

#!/bin/bash

# Cargar información de infraestructura
if [ ! -f "infrastructure-info.txt" ]; then
    echo "❌ No se encontró infrastructure-info.txt"
    echo "📝 Ejecuta primero create-infrastructure.sh"
    exit 1
fi

source infrastructure-info.txt

echo "🚀 Iniciando despliegue de PitchZone..."

# Crear script de datos de usuario para configurar el servidor web
cat > deploy-pitchzone.sh << 'EOF'
#!/bin/bash

# Actualizar el sistema
sudo yum update -y

# Instalar Apache
sudo yum install -y httpd

# Iniciar y habilitar Apache
sudo systemctl start httpd
sudo systemctl enable httpd

# Crear directorio para el sitio web
sudo mkdir -p /var/www/html

# Crear la página web de PitchZone
sudo cat > /var/www/html/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PitchZone - Subelo.Presentalo.Vendelo</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        :root {
            --primary-orange: #FB9833;
            --primary-light: #FCEFEF;
            --primary-teal: #1B768E;
            --primary-dark: #012538;
            --primary-gray: #4D555B;
            --accent-cyan: #00D4FF;
        }

        body {
            font-family: 'Arial', sans-serif;
            background: linear-gradient(135deg, var(--primary-dark) 0%, var(--primary-teal) 50%, var(--primary-dark) 100%);
            color: #333;
            overflow-x: hidden;
        }

        .header {
            background: rgba(1, 37, 56, 0.95);
            backdrop-filter: blur(15px);
            padding: 1rem 2rem;
            position: fixed;
            width: 100%;
            top: 0;
            z-index: 100;
            box-shadow: 0 4px 20px rgba(0,0,0,0.3);
            border-bottom: 2px solid var(--accent-cyan);
        }

        .nav {
            display: flex;
            justify-content: space-between;
            align-items: center;
            max-width: 1200px;
            margin: 0 auto;
        }

        .logo {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            color: white;
            font-size: 1.8rem;
            font-weight: bold;
        }

        .logo-icon {
            width: 40px;
            height: 40px;
            position: relative;
        }

        .logo-triangle {
            width: 35px;
            height: 35px;
            border: 2px solid var(--accent-cyan);
            border-radius: 4px;
            transform: rotate(45deg);
            position: relative;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: transform 0.5s ease;
        }

        .logo-triangle::before {
            content: 'P';
            color: var(--accent-cyan);
            font-weight: bold;
            font-size: 1.2rem;
            transform: rotate(-45deg);
        }

        .nav-links {
            display: flex;
            gap: 2rem;
            list-style: none;
        }

        .nav-links a {
            text-decoration: none;
            color: white;
            font-weight: 500;
            transition: all 0.3s;
            position: relative;
        }

        .nav-links a:hover {
            color: var(--accent-cyan);
        }

        .nav-links a::after {
            content: '';
            position: absolute;
            bottom: -5px;
            left: 0;
            width: 0;
            height: 2px;
            background: var(--accent-cyan);
            transition: width 0.3s;
        }

        .nav-links a:hover::after {
            width: 100%;
        }

        .cta-button {
            background: linear-gradient(45deg, var(--primary-orange), var(--primary-teal));
            color: white;
            padding: 0.8rem 1.5rem;
            border: none;
            border-radius: 25px;
            font-weight: bold;
            cursor: pointer;
            transition: all 0.3s;
            box-shadow: 0 4px 15px rgba(251, 152, 51, 0.3);
        }

        .cta-button:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(251, 152, 51, 0.4);
        }

        .hero {
            padding: 8rem 2rem 4rem;
            text-align: center;
            color: white;
            position: relative;
            overflow: hidden;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .hero::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><defs><pattern id="triangle" x="0" y="0" width="10" height="10" patternUnits="userSpaceOnUse"><polygon points="5,0 10,8.66 0,8.66" fill="rgba(0,212,255,0.1)"/></pattern></defs><rect width="100" height="100" fill="url(%23triangle)"/></svg>');
            opacity: 0.3;
        }

        .hero-content {
            max-width: 800px;
            margin: 0 auto;
            position: relative;
            z-index: 2;
        }

        .hero h1 {
            font-size: 4rem;
            margin-bottom: 1rem;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.5);
            background: linear-gradient(45deg, white, var(--accent-cyan));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            animation: fadeInUp 1s ease-out;
        }

        .slogan {
            font-size: 1.8rem;
            margin-bottom: 2rem;
            color: var(--primary-orange);
            font-weight: bold;
            text-shadow: 1px 1px 2px rgba(0,0,0,0.3);
            animation: fadeInUp 1s ease-out 0.3s both;
        }

        .hero-description {
            font-size: 1.2rem;
            margin-bottom: 2rem;
            opacity: 0.9;
            animation: fadeInUp 1s ease-out 0.6s both;
        }

        .hero-cta {
            animation: fadeInUp 1s ease-out 0.9s both;
        }

        .main-content {
            background: var(--primary-light);
            margin-top: 2rem;
            position: relative;
        }

        .section {
            padding: 4rem 2rem;
            max-width: 1200px;
            margin: 0 auto;
        }

        .section-title {
            text-align: center;
            font-size: 2.8rem;
            margin-bottom: 3rem;
            color: var(--primary-dark);
            position: relative;
        }

        .section-title::after {
            content: '';
            position: absolute;
            bottom: -10px;
            left: 50%;
            transform: translateX(-50%);
            width: 100px;
            height: 4px;
            background: linear-gradient(45deg, var(--primary-orange), var(--primary-teal));
            border-radius: 2px;
        }

        .feature-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 2rem;
            margin-bottom: 3rem;
        }

        .feature-card {
            background: white;
            border-radius: 20px;
            padding: 2rem;
            box-shadow: 0 15px 35px rgba(1, 37, 56, 0.1);
            transition: all 0.3s;
            border: 2px solid transparent;
            text-align: center;
        }

        .feature-card:hover {
            transform: translateY(-8px);
            box-shadow: 0 25px 50px rgba(1, 37, 56, 0.15);
            border-color: var(--accent-cyan);
        }

        .feature-icon {
            font-size: 3rem;
            margin-bottom: 1rem;
            display: block;
        }

        .feature-card h3 {
            color: var(--primary-dark);
            margin-bottom: 1rem;
            font-size: 1.5rem;
        }

        .feature-card p {
            color: var(--primary-gray);
            line-height: 1.6;
        }

        .stats-section {
            background: linear-gradient(135deg, var(--primary-teal), var(--primary-dark));
            color: white;
        }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 2rem;
            text-align: center;
        }

        .stat-item {
            padding: 2rem;
        }

        .stat-number {
            font-size: 3rem;
            font-weight: bold;
            color: var(--accent-cyan);
            display: block;
            margin-bottom: 0.5rem;
        }

        .stat-label {
            font-size: 1.1rem;
            opacity: 0.9;
        }

        .cta-section {
            background: var(--primary-dark);
            color: white;
            text-align: center;
            padding: 5rem 2rem;
        }

        .cta-section h2 {
            font-size: 2.5rem;
            margin-bottom: 1rem;
            color: var(--accent-cyan);
        }

        .cta-section p {
            font-size: 1.2rem;
            margin-bottom: 2rem;
            opacity: 0.9;
        }

        .cta-large {
            background: linear-gradient(45deg, var(--primary-orange), var(--primary-teal));
            color: white;
            padding: 1.2rem 2.5rem;
            border: none;
            border-radius: 30px;
            font-weight: bold;
            font-size: 1.2rem;
            cursor: pointer;
            transition: all 0.3s;
            box-shadow: 0 8px 25px rgba(251, 152, 51, 0.3);
        }

        .cta-large:hover {
            transform: translateY(-3px) scale(1.05);
            box-shadow: 0 15px 35px rgba(251, 152, 51, 0.4);
        }

        .footer {
            background: var(--primary-dark);
            color: white;
            text-align: center;
            padding: 3rem 2rem;
            border-top: 3px solid var(--accent-cyan);
        }

        .footer p {
            margin-bottom: 0.5rem;
            opacity: 0.8;
        }

        .floating-elements {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            pointer-events: none;
            overflow: hidden;
        }

        .floating-triangle {
            position: absolute;
            width: 20px;
            height: 20px;
            border: 2px solid var(--accent-cyan);
            transform: rotate(45deg);
            animation: float 6s ease-in-out infinite;
            opacity: 0.3;
        }

        .floating-triangle:nth-child(1) { top: 20%; left: 10%; animation-delay: 0s; }
        .floating-triangle:nth-child(2) { top: 60%; right: 15%; animation-delay: 2s; }
        .floating-triangle:nth-child(3) { top: 80%; left: 70%; animation-delay: 4s; }

        .pulse {
            animation: pulse 2s infinite;
        }

        @keyframes pulse {
            0% { transform: scale(1); }
            50% { transform: scale(1.05); }
            100% { transform: scale(1); }
        }

        @keyframes float {
            0%, 100% { transform: rotate(45deg) translateY(0px); }
            50% { transform: rotate(45deg) translateY(-20px); }
        }

        @keyframes fadeInUp {
            from { 
                opacity: 0; 
                transform: translateY(30px); 
            }
            to { 
                opacity: 1; 
                transform: translateY(0); 
            }
        }

        .success-message {
            background: linear-gradient(45deg, #00b894, #00cec9);
            color: white;
            padding: 1rem 2rem;
            border-radius: 10px;
            margin: 2rem auto;
            max-width: 600px;
            text-align: center;
            font-weight: bold;
            box-shadow: 0 4px 15px rgba(0, 184, 148, 0.3);
        }

        @media (max-width: 768px) {
            .hero h1 { font-size: 2.8rem; }
            .slogan { font-size: 1.3rem; }
            .nav-links { display: none; }
            .section { padding: 3rem 1rem; }
            .feature-grid, .stats-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="floating-elements">
        <div class="floating-triangle"></div>
        <div class="floating-triangle"></div>
        <div class="floating-triangle"></div>
    </div>

    <header class="header">
        <nav class="nav">
            <div class="logo">
                <div class="logo-icon">
                    <div class="logo-triangle"></div>
                </div>
                PITCHZONE
            </div>
            <ul class="nav-links">
                <li><a href="#inicio">Inicio</a></li>
                <li><a href="#caracteristicas">Características</a></li>
                <li><a href="#estadisticas">Stats</a></li>
                <li><a href="#contacto">Contacto</a></li>
            </ul>
            <button class="cta-button pulse">Sube tu Pitch</button>
        </nav>
    </header>

    <section id="inicio" class="hero">
        <div class="hero-content">
            <h1>PITCHZONE</h1>
            <p class="slogan">"SUBELO.PRESENTALO.VENDELO"</p>
            <p class="hero-description">La plataforma donde tus ideas cobran vida y encuentran inversión. Conectando el talento universitario con oportunidades reales.</p>
            <div class="hero-cta">
                <button class="cta-large">Comenzar Ahora</button>
            </div>
        </div>
    </section>

    <div class="success-message">
        🎉 ¡PitchZone se ha desplegado exitosamente en AWS EC2 Free Tier!
    </div>

    <main class="main-content">
        <section id="caracteristicas" class="section">
            <h2 class="section-title">¿Qué Ofrecemos?</h2>
            
            <div class="feature-grid">
                <div class="feature-card">
                    <span class="feature-icon">🎬</span>
                    <h3>Reels de Proyectos</h3>
                    <p>Muestra tu proyecto en formato video corto y atractivo. Conecta con inversores a través de contenido visual impactante que cuenta tu historia.</p>
                </div>

                <div class="feature-card">
                    <span class="feature-icon">🎓</span>
                    <h3>Alianzas Universitarias</h3>
                    <p>Trabajamos directamente con universidades e incubadoras para destacar los mejores proyectos finales y tesis de grado.</p>
                </div>

                <div class="feature-card">
                    <span class="feature-icon">🚀</span>
                    <h3>Eventos de Lanzamiento</h3>
                    <p>Demo Days virtuales, concursos de pitch y activaciones en campus universitarios para maximizar tu visibilidad.</p>
                </div>

                <div class="feature-card">
                    <span class="feature-icon">💡</span>
                    <h3>Proyectos Olvidados</h3>
                    <p>Revive proyectos universitarios que merecen una segunda oportunidad. Historias inspiradoras de éxito y transformación.</p>
                </div>

                <div class="feature-card">
                    <span class="feature-icon">🎯</span>
                    <h3>Mentorías Personalizadas</h3>
                    <p>Conecta con mentores especializados en tu industria. Recibe feedback valioso para perfeccionar tu propuesta de valor.</p>
                </div>

                <div class="feature-card">
                    <span class="feature-icon">📱</span>
                    <h3>Acceso Móvil</h3>
                    <p>Descarga la app mediante códigos QR en eventos universitarios. Lleva tu pitch siempre contigo, listo para presentar.</p>
                </div>
            </div>
        </section>

        <section id="estadisticas" class="section stats-section">
            <h2 class="section-title">Números que Hablan</h2>
            
            <div class="stats-grid">
                <div class="stat-item">
                    <span class="stat-number">500+</span>
                    <span class="stat-label">Proyectos Publicados</span>
                </div>
                <div class="stat-item">
                    <span class="stat-number">50+</span>
                    <span class="stat-label">Universidades Aliadas</span>
                </div>
                <div class="stat-item">
                    <span class="stat-number">1M+</span>
                    <span class="stat-label">Visualizaciones</span>
                </div>
                <div class="stat-item">
                    <span class="stat-number">150K</span>
                    <span class="stat-label">Inversión Conectada</span>
                </div>
            </div>
        </section>

        <section id="contacto" class="cta-section">
            <h2>¿Listo para Lanzar tu Idea?</h2>
            <p>Únete a la comunidad de emprendedores más innovadora de México. Tu próximo gran éxito comienza aquí.</p>
            <button class="cta-large">Crear Mi Pitch Ahora</button>
        </section>
    </main>

    <footer class="footer">
        <div style="max-width: 1200px; margin: 0 auto;">
            <p style="font-size: 1.1rem; margin-bottom: 1rem;">&copy; 2025 PitchZone - "Subelo.Presentalo.Vendelo"</p>
            <p>Desplegado exitosamente en AWS EC2 Free Tier</p>
            <p style="margin-top: 1rem; font-size: 0.9rem;">Transformando el ecosistema emprendedor universitario de México</p>
        </div>
    </footer>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // Smooth scrolling
            document.querySelectorAll('a[href^="#"]').forEach(anchor => {
                anchor.addEventListener('click', function (e) {
                    e.preventDefault();
                    const target = document.querySelector(this.getAttribute('href'));
                    if (target) {
                        target.scrollIntoView({
                            behavior: 'smooth',
                            block: 'start'
                        });
                    }
                });
            });

            // Animación de contadores
            function animateCounters() {
                const counters = document.querySelectorAll('.stat-number');
                counters.forEach(counter => {
                    const target = parseInt(counter.innerText.replace(/[^0-9]/g, ''));
                    let current = 0;
                    const increment = target / 50;
                    const timer = setInterval(() => {
                        current += increment;
                        if (current >= target) {
                            current = target;
                            clearInterval(timer);
                        }
                        const suffix = counter.innerText.replace(/[0-9]/g, '');
                        counter.innerText = Math.floor(current) + suffix;
                    }, 40);
                });
            }

            // Observer para animaciones
            const observer = new IntersectionObserver((entries) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        if (entry.target.classList.contains('stats-section')) {
                            animateCounters();
                        }
                        entry.target.style.opacity = '1';
                        entry.target.style.transform = 'translateY(0)';
                    }
                });
            });

            // Observar elementos
            document.querySelectorAll('.feature-card, .stats-section').forEach(el => {
                el.style.opacity = '0';
                el.style.transform = 'translateY(30px)';
                el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
                observer.observe(el);
            });

            // Efecto hover para botones
            document.querySelectorAll('.cta-button, .cta-large').forEach(button => {
                button.addEventListener('mouseenter', function() {
                    this.style.transform = 'translateY(-3px) scale(1.05)';
                });
                
                button.addEventListener('mouseleave', function() {
                    this.style.transform = 'translateY(0) scale(1)';
                });
            });

            // Rotación del logo
            const logoTriangle = document.querySelector('.logo-triangle');
            if (logoTriangle) {
                setInterval(() => {
                    logoTriangle.style.transform = 'rotate(405deg)';
                    setTimeout(() => {
                        logoTriangle.style.transform = 'rotate(45deg)';
                    }, 500);
                }, 5000);
            }

            // Parallax effect
            window.addEventListener('scroll', () => {
                const scrolled = window.pageYOffset;
                const hero = document.querySelector('.hero');
                if (hero) {
                    hero.style.transform = `translateY(${scrolled * 0.5}px)`;
                }
            });
        });
    </script>
</body>
</html>
HTMLEOF

# Configurar permisos
sudo chown -R apache:apache /var/www/html
sudo chmod -R 755 /var/www/html

# Configurar Apache para servir el sitio
sudo systemctl restart httpd

# Configurar firewall si está habilitado
sudo firewall-cmd --permanent --add-service=http 2>/dev/null || true
sudo firewall-cmd --permanent --add-service=https 2>/dev/null || true
sudo firewall-cmd --reload 2>/dev/null || true

echo "✅ PitchZone ha sido desplegado exitosamente!"
echo "🌐 El sitio está disponible en la IP pública de la instancia"
EOF

# Hacer el script ejecutable
chmod +x deploy-pitchzone.sh

# Crear script de datos de usuario para la instancia
cat > user-data.sh << 'EOF'
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

# Crear página temporal mientras se despliega el sitio completo
cat > /var/www/html/index.html << 'TEMPHTML'
<!DOCTYPE html>
<html>
<head>
    <title>PitchZone - Cargando...</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            text-align: center; 
            padding: 50px;
            background: linear-gradient(135deg, #012538, #1B768E);
            color: white;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-direction: column;
        }
        .logo { 
            font-size: 3rem; 
            margin-bottom: 1rem;
            background: linear-gradient(45deg, white, #00D4FF);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .slogan { 
            color: #FB9833; 
            font-size: 1.5rem;
            margin-bottom: 2rem;
        }
        .spinner {
            border: 4px solid #f3f3f3;
            border-top: 4px solid #00D4FF;
            border-radius: 50%;
            width: 50px;
            height: 50px;
            animation: spin 1s linear infinite;
            margin: 2rem auto;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div>
        <h1 class="logo">PITCHZONE</h1>
        <p class="slogan">"SUBELO.PRESENTALO.VENDELO"</p>
        <div class="spinner"></div>
        <p>Configurando tu plataforma de emprendimiento...</p>
        <p><small>AWS EC2 Free Tier | Estado: Inicializando</small></p>
    </div>
</body>
</html>
TEMPHTML

chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html
EOF

echo "⏳ Esperando a que la instancia esté completamente lista..."
sleep 60

# Conectar y ejecutar el script de despliegue
echo "🚀 Desplegando PitchZone en la instancia..."
scp -i ${KEY_NAME}.pem -o StrictHostKeyChecking=no deploy-pitchzone.sh ec2-user@$PUBLIC_IP:/tmp/
ssh -i ${KEY_NAME}.pem -o StrictHostKeyChecking=no ec2-user@$PUBLIC_IP "chmod +x /tmp/deploy-pitchzone.sh && sudo /tmp/deploy-pitchzone.sh"

echo ""
echo "🎉 ¡PitchZone desplegado exitosamente!"
echo "🌐 Tu sitio web está disponible en: http://$PUBLIC_IP"
echo "📱 Accede desde cualquier dispositivo"
echo ""
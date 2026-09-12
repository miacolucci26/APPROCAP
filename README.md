# APPROCAP — Sitio web corporativo

Sitio web corporativo de la **Cooperativa Agraria APPROCAP Ltda.**, cooperativa
cacaotera de San Juan de Bigote, provincia de Morropón, región Piura, Perú.

HTML, CSS y JavaScript estáticos, sin frameworks ni build step.

## Estructura

```
index.html        Inicio
nosotros.html      Nosotros (misión, visión, reconocimientos)
productos.html      Productos (cacao en grano y línea INTENSSO)
trabajo.html        Nuestro trabajo (cultivo → comercialización)
compromiso.html      Compromiso (prácticas actuales y objetivos 2023-2027)
galeria.html        Galería fotográfica
contacto.html        Contacto

css/styles.css     Estilos (variables de marca, componentes, responsive)
js/main.js         Menú móvil y visor de imágenes (lightbox), sin dependencias

assets/img/        Fotografías e imágenes optimizadas usadas por el sitio
assets/img/reconocimientos/  Certificados de premios y reconocimientos

scripts/resize-images.ps1   Script (PowerShell) usado para generar las copias
                             optimizadas en assets/img/ a partir de los
                             originales en COOP.APPROCAP/

PENDIENTES.md       Información no publicada por falta de verificación,
                     y decisiones sobre datos personales
```

La carpeta `COOP.APPROCAP/` contiene los materiales originales (Plan Estratégico
Institucional, fotografías sin optimizar, certificados en resolución completa).
Se conserva en el equipo local pero está excluida del repositorio (`.gitignore`),
porque incluye información interna y datos personales que no deben publicarse.

## Cómo verlo localmente

Al ser un sitio 100% estático, basta con abrir `index.html` en el navegador, o
servirlo con cualquier servidor estático, por ejemplo:

```
npx serve .
```

## Paleta de marca

Definida como variables CSS en `css/styles.css`:

```css
--color-primary: #004F2D;   /* verde oscuro */
--color-accent: #FFEB00;    /* amarillo */
--color-white: #FFFFFF;
--color-secondary: #84DCC6; /* verde agua */
--color-blue: #0089D0;
```

## Antes de publicar

Ver [`PENDIENTES.md`](PENDIENTES.md) para la lista completa de datos por confirmar
(correo, dirección exacta, redes sociales) y las decisiones tomadas sobre datos
personales (Consejo Directivo, certificados individuales de socios/as).

Antes de asignar dominio y hosting definitivos, agregar `<link rel="canonical">` y
`og:url` en el `<head>` de cada página (se omitieron a propósito para no publicar un
dominio ficticio).

## Estado del repositorio

Repositorio Git inicializado localmente, sin remoto configurado y sin despliegue.
No se ha hecho ningún `git push` ni publicación.

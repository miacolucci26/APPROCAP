# APPROCAP — Sitio web corporativo

Sitio web corporativo de la **Cooperativa Agraria APPROCAP Ltda.**, cooperativa
cacaotera de San Juan de Bigote, provincia de Morropón, región Piura, Perú.

HTML, CSS y JavaScript estáticos, sin frameworks ni build step.

## Estructura

```
index.html          Inicio (hero de imagen completa, cifras animadas)
nosotros.html       Nosotros (misión/visión, equidad de género, gobernanza,
                    reconocimientos)
nuestro-cacao.html  Nuestro Cacao (genética premium, 215 ha, cacao blanco y
                    criollo, variedades por piso ecológico)
sostenibilidad.html Sostenibilidad (certificación orgánica, resiliencia
                    climática, objetivos 2023-2027)
intensso.html       Marca INTENSSO (cacao en grano, proceso, línea de derivados)
contacto.html       Contacto

css/styles.css     Estilos (variables de marca, componentes, responsive)
js/main.js         Menú móvil, desplegables de navegación, cifras animadas,
                    header transparente y visor de imágenes (lightbox);
                    sin dependencias externas

assets/img/        Fotografías e imágenes optimizadas usadas por el sitio
assets/img/reconocimientos/  Certificados de premios y reconocimientos
assets/img/logo-approcap-white.png  Versión monocromática del logo, para el
                    header transparente de Inicio

scripts/resize-images.ps1    Genera las copias optimizadas en assets/img/ a
                              partir de los originales en COOP.APPROCAP/
scripts/make-white-logo.ps1  Genera la versión monocromática del logo
scripts/cdp-check.ps1        Herramienta de verificación: abre el sitio en
                              Chrome headless (vía CDP) para revisar overflow,
                              errores de consola e interacciones reales
scripts/contrast-check.ps1   Calcula el contraste WCAG de los pares de color

PENDIENTES.md       Información no publicada por falta de verificación,
                     y decisiones sobre datos personales
```

La navegación principal es plana, con cinco enlaces directos: **Nosotros**,
**Nuestro Cacao**, **Sostenibilidad**, **Marca INTENSSO** y **Contáctanos** (este
último con estilo de botón). Las páginas `galeria.html` y `trabajo.html` de la
primera versión ya no existen: su contenido se fusionó dentro de `intensso.html`
(proceso de trabajo) o se retiró (galería). Ver `PENDIENTES.md` para el detalle.

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

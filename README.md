# CONTROL DE CURSOS — Herramientas de poder y Equipos de poder

- **index.html**: el capacitador ingresa su DNI. Si está autorizado, registra el curso dictado, la fecha, la cantidad de integrantes, el DNI y nombre de cada participante, y sube su certificado de capacitador (PDF).
- **admin.html**: panel del administrador.
  - *Cursos registrados*: ver cada registro, sus participantes y el PDF; dar **recibido** cuando entreguen la documentación física; exportar a Excel (CSV).
  - *Capacitadores autorizados*: agregar, bloquear o autorizar DNIs.
  - *Lista de cursos*: agregar u ocultar cursos.
- **config.js**: conexión con Supabase.
- **supabase.sql**: estructura de la base de datos, reglas de seguridad y almacenamiento de certificados (ya aplicado).

Publicado en Netlify; cada cambio en este repositorio actualiza la página automáticamente.

Nota: Supabase en plan gratis pausa el proyecto tras 7 días sin uso; se reactiva con "Restore" desde su panel.

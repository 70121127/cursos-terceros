# Cursos Terceros — Registro y recepción de documentos

- **index.html**: página pública. El tercero registra DNI, nombre y empresa, y puede consultar si ya le dieron "recibido".
- **admin.html**: panel del administrador. Inicia sesión y da clic en **Dar recibido** cuando entreguen los documentos en físico. Permite buscar, filtrar y exportar a Excel (CSV).
- **config.js**: conexión con la base de datos Supabase.
- **supabase.sql**: estructura de la base de datos y reglas de seguridad (ya aplicado).

Publicado en Netlify. Cada cambio en este repositorio actualiza la página automáticamente.

Para agregar otro administrador: Supabase > Authentication > Users > Add user.

Nota: Supabase en plan gratis pausa el proyecto tras 7 días sin uso; se reactiva con un clic desde su panel.

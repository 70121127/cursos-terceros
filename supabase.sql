-- =========================================================
--  CONTROL DE CURSOS - Herramientas de poder y Equipos de poder
--  Base de datos v2 (pegar en Supabase > SQL Editor > Run)
-- =========================================================

-- Limpieza de la versión 1 (registro individual)
drop function if exists public.consultar_estado(text);
drop table if exists public.registros;

-- ---------- TABLAS ----------
create table if not exists public.cursos (
  id         bigint generated always as identity primary key,
  nombre     text not null unique check (char_length(nombre) between 2 and 150),
  activo     boolean not null default true,
  creado_en  timestamptz not null default now()
);

create table if not exists public.capacitadores (
  dni        text primary key check (dni ~ '^[0-9]{8}$'),
  nombre     text not null check (char_length(nombre) between 3 and 150),
  activo     boolean not null default true,
  creado_en  timestamptz not null default now()
);

create table if not exists public.capacitaciones (
  id                bigint generated always as identity primary key,
  dni_capacitador   text not null references public.capacitadores(dni),
  curso_id          bigint not null references public.cursos(id),
  curso_nombre      text not null,
  fecha             date not null,
  cantidad          int  not null check (cantidad between 1 and 100),
  certificado_path  text not null,
  creado_en         timestamptz not null default now(),
  recibido          boolean not null default false,
  recibido_en       timestamptz,
  recibido_por      text,
  observacion       text
);

create table if not exists public.participantes (
  id                bigint generated always as identity primary key,
  capacitacion_id   bigint not null references public.capacitaciones(id) on delete cascade,
  dni               text not null check (dni ~ '^[0-9]{8}$'),
  nombre            text not null check (char_length(nombre) between 3 and 150)
);
create index if not exists participantes_dni_idx on public.participantes(dni);
create index if not exists participantes_cap_idx on public.participantes(capacitacion_id);

-- ---------- SEGURIDAD (RLS) ----------
alter table public.cursos          enable row level security;
alter table public.capacitadores   enable row level security;
alter table public.capacitaciones  enable row level security;
alter table public.participantes   enable row level security;

-- Público: solo puede ver la lista de cursos activos (para el desplegable)
drop policy if exists "publico_ve_cursos" on public.cursos;
create policy "publico_ve_cursos" on public.cursos for select to anon using (activo);
grant select on public.cursos to anon;

-- Administrador (con login): acceso total a todo
do $$
declare t text;
begin
  foreach t in array array['cursos','capacitadores','capacitaciones','participantes'] loop
    execute format('drop policy if exists "admin_todo" on public.%I', t);
    execute format('create policy "admin_todo" on public.%I for all to authenticated using (true) with check (true)', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;

-- ---------- FUNCIONES PÚBLICAS ----------
-- 1) Verificar si un DNI es capacitador autorizado (devuelve solo su nombre)
create or replace function public.verificar_capacitador(p_dni text)
returns table (nombre text)
language sql security definer set search_path = public
as $$
  select c.nombre from public.capacitadores c where c.dni = p_dni and c.activo;
$$;

-- 2) Registrar una capacitación con sus participantes (todo o nada)
create or replace function public.registrar_capacitacion(
  p_dni text, p_curso_id bigint, p_fecha date, p_participantes jsonb, p_certificado text)
returns bigint
language plpgsql security definer set search_path = public
as $$
declare
  v_curso text;
  v_id bigint;
  v_n int;
  p jsonb;
begin
  if not exists (select 1 from capacitadores where dni = p_dni and activo) then
    raise exception 'DNI no autorizado';
  end if;
  select nombre into v_curso from cursos where id = p_curso_id and activo;
  if v_curso is null then raise exception 'Curso no válido'; end if;
  if p_fecha is null or p_fecha > current_date or p_fecha < current_date - 365 then
    raise exception 'Fecha no válida';
  end if;
  if jsonb_typeof(p_participantes) <> 'array' then raise exception 'Participantes no válidos'; end if;
  v_n := jsonb_array_length(p_participantes);
  if v_n < 1 or v_n > 100 then raise exception 'Cantidad de participantes no válida'; end if;
  if p_certificado is null or p_certificado not like ('cert/' || p_dni || '/%')
     or not exists (select 1 from storage.objects where bucket_id = 'certificados' and name = p_certificado) then
    raise exception 'Certificado no encontrado';
  end if;

  insert into capacitaciones (dni_capacitador, curso_id, curso_nombre, fecha, cantidad, certificado_path)
  values (p_dni, p_curso_id, v_curso, p_fecha, v_n, p_certificado)
  returning id into v_id;

  for p in select * from jsonb_array_elements(p_participantes) loop
    insert into participantes (capacitacion_id, dni, nombre)
    values (v_id, p->>'dni', upper(trim(p->>'nombre')));
  end loop;

  return v_id;
end;
$$;

grant execute on function public.verificar_capacitador(text) to anon, authenticated;
grant execute on function public.registrar_capacitacion(text, bigint, date, jsonb, text) to anon, authenticated;

-- ---------- ALMACENAMIENTO DE CERTIFICADOS (solo PDF, máx 5 MB, privado) ----------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('certificados', 'certificados', false, 5242880, array['application/pdf'])
on conflict (id) do update set public = false, file_size_limit = 5242880, allowed_mime_types = array['application/pdf'];

drop policy if exists "cert_publico_sube" on storage.objects;
create policy "cert_publico_sube" on storage.objects for insert to anon
  with check (bucket_id = 'certificados' and name like 'cert/%');

drop policy if exists "cert_admin_todo" on storage.objects;
create policy "cert_admin_todo" on storage.objects for all to authenticated
  using (bucket_id = 'certificados') with check (bucket_id = 'certificados');

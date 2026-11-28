-- =====================================================================
-- Tahap 12: turnamen (fitur Kompetisi) disimpan di Supabase supaya ikut
-- akun dan bisa dibuka dari perangkat lain.
-- Jalankan SEKALI di Supabase > SQL Editor.
-- =====================================================================

create table if not exists public.tournaments (
  -- id dibuat oleh aplikasi (mis. 't1764312345678901'), jadi bertipe text.
  id         text primary key,
  user_id    uuid not null default auth.uid()
             references auth.users (id) on delete cascade,
  name       text not null,
  format     text not null default 'americano'
             check (format in ('americano', 'mexicano', 'knockout')),
  finished   boolean not null default false,
  -- Seluruh isi turnamen (pemain, jadwal, skor) = Tournament.toJson().
  data       jsonb not null
             check (octet_length(data::text) <= 1000000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists tournaments_user_idx
  on public.tournaments (user_id, created_at desc);

-- updated_at diisi otomatis setiap baris dibuat/diubah.
create or replace function public.tournaments_touch()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists tournaments_touch_trg on public.tournaments;
create trigger tournaments_touch_trg
  before insert or update on public.tournaments
  for each row execute function public.tournaments_touch();

-- ---------- Keamanan: tiap akun hanya mengakses turnamennya sendiri ----------
alter table public.tournaments enable row level security;

revoke all on public.tournaments from anon, authenticated;
grant select, insert, update, delete on public.tournaments to authenticated;

drop policy if exists "turnamen: baca milik sendiri" on public.tournaments;
create policy "turnamen: baca milik sendiri"
  on public.tournaments for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists "turnamen: buat milik sendiri" on public.tournaments;
create policy "turnamen: buat milik sendiri"
  on public.tournaments for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "turnamen: ubah milik sendiri" on public.tournaments;
create policy "turnamen: ubah milik sendiri"
  on public.tournaments for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "turnamen: hapus milik sendiri" on public.tournaments;
create policy "turnamen: hapus milik sendiri"
  on public.tournaments for delete to authenticated
  using (auth.uid() = user_id);
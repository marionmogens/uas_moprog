alter table public.venues
  add column if not exists latitude  double precision,
  add column if not exists longitude double precision;

alter table public.venues drop constraint if exists venues_coords_check;
alter table public.venues
  add constraint venues_coords_check check (
    (latitude is null and longitude is null)
    or (latitude between -90 and 90 and longitude between -180 and 180)
  );

grant insert (latitude, longitude) on public.venues to authenticated;
grant update (latitude, longitude) on public.venues to authenticated;

update public.venues set latitude = -6.1080, longitude = 106.7400 where name in ('Smash Padel Club', 'Kelas Padel Pemula')     and latitude is null;
update public.venues set latitude = -6.3010, longitude = 106.6530 where name = 'Arena Padel BSD'                               and latitude is null;
update public.venues set latitude = -6.2745, longitude = 106.8130 where name in ('Padel House Kemang', 'Kelas Padel Menengah') and latitude is null;
update public.venues set latitude = -6.1580, longitude = 106.9050 where name = 'Padel Point Kelapa Gading'                     and latitude is null;
update public.venues set latitude = -6.2740, longitude = 106.7100 where name = 'Elite Padel Center'                            and latitude is null;
update public.venues set latitude = -6.2185, longitude = 106.8020 where name = 'GOR Padel Senayan'                             and latitude is null;
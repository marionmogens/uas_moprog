alter table public.venues
  add column if not exists rating_avg   numeric(2,1) not null default 0,
  add column if not exists review_count int          not null default 0;

create table if not exists public.reviews (
  id         uuid primary key default gen_random_uuid(),
  venue_id   uuid not null references public.venues (id) on delete cascade,
  user_id    uuid not null default auth.uid()
             references public.profiles (id) on delete cascade,
  user_name  text not null default '',
  rating     int  not null check (rating between 1 and 5),
  comment    text not null default '' check (char_length(comment) <= 500),
  created_at timestamptz not null default now(),
  unique (venue_id, user_id)
);

create index if not exists reviews_venue_idx
  on public.reviews (venue_id, created_at desc);
create index if not exists reviews_created_idx
  on public.reviews (created_at desc);

create or replace function public.reviews_fill_name()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  new.user_name := coalesce(
    (select nullif(btrim(p.full_name), '') from public.profiles p where p.id = new.user_id),
    'Pengguna'
  );
  return new;
end;
$$;

drop trigger if exists reviews_fill_name_trg on public.reviews;
create trigger reviews_fill_name_trg
  before insert or update on public.reviews
  for each row execute function public.reviews_fill_name();

create or replace function public.refresh_venue_rating(p_venue uuid)
returns void
language sql
security definer set search_path = ''
as $$
  update public.venues v
     set rating_avg = coalesce(
           (select round(avg(r.rating)::numeric, 1)
              from public.reviews r where r.venue_id = p_venue), 0),
         review_count = (select count(*) from public.reviews r where r.venue_id = p_venue)
   where v.id = p_venue;
$$;

revoke execute on function public.refresh_venue_rating(uuid) from public, anon, authenticated;

create or replace function public.reviews_after_change()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  if tg_op in ('INSERT', 'UPDATE') then
    perform public.refresh_venue_rating(new.venue_id);
  end if;
  if tg_op = 'DELETE'
     or (tg_op = 'UPDATE' and old.venue_id is distinct from new.venue_id) then
    perform public.refresh_venue_rating(old.venue_id);
  end if;
  return null;
end;
$$;

drop trigger if exists reviews_after_change_trg on public.reviews;
create trigger reviews_after_change_trg
  after insert or update or delete on public.reviews
  for each row execute function public.reviews_after_change();

alter table public.reviews enable row level security;

revoke all on public.reviews from anon, authenticated;
grant select, insert on public.reviews to authenticated;
grant update (venue_id, rating, comment) on public.reviews to authenticated;

drop policy if exists "review: baca" on public.reviews;
create policy "review: baca"
  on public.reviews for select to authenticated
  using (true);

drop policy if exists "review: tulis" on public.reviews;
create policy "review: tulis"
  on public.reviews for insert to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.bookings b
      where b.user_id = auth.uid()
        and b.court_id = venue_id::text
        and b.status <> 'dibatalkan'
    )
  );

drop policy if exists "review: ubah milik sendiri" on public.reviews;
create policy "review: ubah milik sendiri"
  on public.reviews for update to authenticated
  using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.bookings b
      where b.user_id = auth.uid()
        and b.court_id = venue_id::text
        and b.status <> 'dibatalkan'
    )
  );
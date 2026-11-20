-- Monte Carlo Forecast – wspólne zapisane scenariusze (zespoły Alpha i Beta)
-- Uruchom raz w Supabase: SQL Editor -> New query -> wklej -> Run.
-- Dostęp: każdy z linkiem do strony może czytać, dodawać, zmieniać i usuwać scenariusze (rola anon).

create table if not exists public.mc_scenarios (
  id          uuid primary key default gen_random_uuid(),
  team        text not null check (team in ('alpha', 'beta')),
  name        text not null check (char_length(btrim(name)) between 1 and 80),
  params      jsonb not null check (jsonb_typeof(params) = 'object' and octet_length(params::text) <= 20000),
  author      text check (author is null or char_length(author) <= 60),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (team, name)
);

create or replace function public.mc_scenarios_touch()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists mc_scenarios_touch on public.mc_scenarios;
create trigger mc_scenarios_touch before update on public.mc_scenarios
  for each row execute function public.mc_scenarios_touch();

alter table public.mc_scenarios enable row level security;

drop policy if exists "mc_scenarios read"   on public.mc_scenarios;
drop policy if exists "mc_scenarios insert" on public.mc_scenarios;
drop policy if exists "mc_scenarios update" on public.mc_scenarios;
drop policy if exists "mc_scenarios delete" on public.mc_scenarios;
create policy "mc_scenarios read"   on public.mc_scenarios for select to anon, authenticated using (true);
create policy "mc_scenarios insert" on public.mc_scenarios for insert to anon, authenticated with check (true);
create policy "mc_scenarios update" on public.mc_scenarios for update to anon, authenticated using (true) with check (true);
create policy "mc_scenarios delete" on public.mc_scenarios for delete to anon, authenticated using (true);

grant select, insert, update, delete on public.mc_scenarios to anon, authenticated;

-- Realtime: zmiany widoczne na żywo u innych osób
do $$
begin
  if not exists (select 1 from pg_publication_tables
                 where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'mc_scenarios') then
    alter publication supabase_realtime add table public.mc_scenarios;
  end if;
end $$;

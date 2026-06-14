-- Initial schema for Real Estate Portfolio MVP

create extension if not exists "pgcrypto";

-- Profiles (extends auth.users)
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now()
);

-- Properties
create table public.properties (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  property_address text not null,
  city text not null,
  state text not null,
  zip_code text not null,
  unit_number text,
  normalized_address text,
  created_at timestamptz not null default now()
);

create index properties_user_match_idx
  on public.properties (user_id, normalized_address, city, state, zip_code);

-- Leases
create table public.leases (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties (id) on delete cascade,
  lease_start_date date,
  lease_end_date date,
  monthly_rent numeric(12, 2),
  security_deposit numeric(12, 2),
  late_fee numeric(12, 2),
  tenant_names jsonb not null default '[]'::jsonb,
  landlord_name text,
  raw_extraction_json jsonb,
  created_at timestamptz not null default now()
);

create index leases_property_id_idx on public.leases (property_id);

-- Documents
create table public.documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  property_id uuid references public.properties (id) on delete set null,
  lease_id uuid references public.leases (id) on delete set null,
  file_name text not null,
  storage_path text not null,
  uploaded_at timestamptz not null default now()
);

create index documents_property_id_idx on public.documents (property_id);
create index documents_lease_id_idx on public.documents (lease_id);

-- Address normalization helper
create or replace function public.normalize_address(input text)
returns text
language plpgsql
immutable
as $$
declare
  normalized text;
begin
  if input is null then
    return '';
  end if;

  normalized := lower(trim(input));
  normalized := regexp_replace(normalized, '[^a-z0-9# ]', ' ', 'g');
  normalized := regexp_replace(normalized, '\s+', ' ', 'g');

  normalized := regexp_replace(normalized, '\mst\M', 'street', 'g');
  normalized := regexp_replace(normalized, '\mstr\M', 'street', 'g');
  normalized := regexp_replace(normalized, '\mave\M', 'avenue', 'g');
  normalized := regexp_replace(normalized, '\mblvd\M', 'boulevard', 'g');
  normalized := regexp_replace(normalized, '\mrd\M', 'road', 'g');
  normalized := regexp_replace(normalized, '\mdr\M', 'drive', 'g');
  normalized := regexp_replace(normalized, '\mln\M', 'lane', 'g');
  normalized := regexp_replace(normalized, '\mct\M', 'court', 'g');
  normalized := regexp_replace(normalized, '\mapt\M', 'unit', 'g');
  normalized := regexp_replace(normalized, '\mste\M', 'unit', 'g');

  return trim(normalized);
end;
$$;

create or replace function public.set_property_normalized_address()
returns trigger
language plpgsql
as $$
begin
  new.normalized_address := public.normalize_address(new.property_address);
  return new;
end;
$$;

create trigger properties_set_normalized_address
before insert or update on public.properties
for each row
execute function public.set_property_normalized_address();

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', new.email))
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();

-- Row Level Security
alter table public.profiles enable row level security;
alter table public.properties enable row level security;
alter table public.leases enable row level security;
alter table public.documents enable row level security;

create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Users can select own properties"
  on public.properties for select
  using (auth.uid() = user_id);

create policy "Users can insert own properties"
  on public.properties for insert
  with check (auth.uid() = user_id);

create policy "Users can update own properties"
  on public.properties for update
  using (auth.uid() = user_id);

create policy "Users can delete own properties"
  on public.properties for delete
  using (auth.uid() = user_id);

create policy "Users can select own leases"
  on public.leases for select
  using (
    exists (
      select 1
      from public.properties p
      where p.id = leases.property_id
        and p.user_id = auth.uid()
    )
  );

create policy "Users can insert own leases"
  on public.leases for insert
  with check (
    exists (
      select 1
      from public.properties p
      where p.id = leases.property_id
        and p.user_id = auth.uid()
    )
  );

create policy "Users can update own leases"
  on public.leases for update
  using (
    exists (
      select 1
      from public.properties p
      where p.id = leases.property_id
        and p.user_id = auth.uid()
    )
  );

create policy "Users can delete own leases"
  on public.leases for delete
  using (
    exists (
      select 1
      from public.properties p
      where p.id = leases.property_id
        and p.user_id = auth.uid()
    )
  );

create policy "Users can select own documents"
  on public.documents for select
  using (auth.uid() = user_id);

create policy "Users can insert own documents"
  on public.documents for insert
  with check (auth.uid() = user_id);

create policy "Users can update own documents"
  on public.documents for update
  using (auth.uid() = user_id);

create policy "Users can delete own documents"
  on public.documents for delete
  using (auth.uid() = user_id);

-- Storage bucket for lease PDFs
insert into storage.buckets (id, name, public)
values ('lease-documents', 'lease-documents', false)
on conflict (id) do nothing;

create policy "Users can read own lease documents"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'lease-documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users can upload own lease documents"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'lease-documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users can update own lease documents"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'lease-documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users can delete own lease documents"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'lease-documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

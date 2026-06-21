-- Phase 2: Action items / Needs Attention feed

create table public.action_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  property_id uuid references public.properties (id) on delete cascade,
  document_id uuid references public.documents (id) on delete set null,
  item_type text not null,
  title text not null,
  description text,
  due_date date,
  severity text not null default 'info'
    check (severity in ('info', 'warning', 'critical')),
  status text not null default 'open'
    check (status in ('open', 'done', 'dismissed')),
  source_key text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index action_items_user_status_idx
  on public.action_items (user_id, status, due_date);

create index action_items_property_id_idx
  on public.action_items (property_id);

create unique index action_items_source_key_open_idx
  on public.action_items (user_id, source_key)
  where status = 'open';

alter table public.action_items enable row level security;

create policy "Users can select own action items"
  on public.action_items for select
  using (auth.uid() = user_id);

create policy "Users can insert own action items"
  on public.action_items for insert
  with check (auth.uid() = user_id);

create policy "Users can update own action items"
  on public.action_items for update
  using (auth.uid() = user_id);

create policy "Users can delete own action items"
  on public.action_items for delete
  using (auth.uid() = user_id);

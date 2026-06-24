-- User Story 1: property onboarding from closing documents
alter table public.properties
  add column if not exists property_type text,
  add column if not exists bedrooms integer,
  add column if not exists bathrooms numeric(4, 1),
  add column if not exists onboarding_status text not null default 'none',
  add column if not exists onboarding_checklist jsonb not null default '{}'::jsonb;

alter table public.properties
  add constraint properties_property_type_check
  check (property_type is null or property_type in ('single_family', 'multi_family'));

alter table public.properties
  add constraint properties_onboarding_status_check
  check (onboarding_status in ('none', 'in_progress', 'complete'));

comment on column public.properties.onboarding_checklist is
  'Expected/received closing docs: settlement, mortgage, hoa, lease, insurance';

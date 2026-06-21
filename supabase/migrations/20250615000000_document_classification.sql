-- Document classification and metadata
alter table public.documents
  add column if not exists document_type text,
  add column if not exists classification_confidence numeric(4, 3),
  add column if not exists extracted_metadata jsonb not null default '{}'::jsonb;

create index if not exists documents_property_type_idx
  on public.documents (property_id, document_type);

comment on column public.documents.document_type is
  'lease, deed, insurance, utility, tax, hoa, permit, other';

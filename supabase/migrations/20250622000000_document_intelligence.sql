-- Phase 1: AI summaries, key points, and flags on documents
alter table public.documents
  add column if not exists summary text,
  add column if not exists key_points jsonb not null default '[]'::jsonb,
  add column if not exists flags jsonb not null default '[]'::jsonb;

comment on column public.documents.summary is 'AI-generated document overview';
comment on column public.documents.key_points is 'Array of extracted bullet points';
comment on column public.documents.flags is 'Array of {severity, title, description} warnings';

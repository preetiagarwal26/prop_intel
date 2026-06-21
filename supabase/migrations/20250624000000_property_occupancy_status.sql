-- Phase 3: optional manual occupancy flag on properties
alter table public.properties
  add column if not exists occupancy_status text;

alter table public.properties
  add constraint properties_occupancy_status_check
  check (occupancy_status is null or occupancy_status in ('rented', 'vacant'));

-- Hostel Complaint Tracker schema for Supabase PostgreSQL.
create extension if not exists pgcrypto;

create table if not exists public.users (
  id uuid primary key default gen_random_uuid(),
  full_name varchar(80) not null check (char_length(trim(full_name)) between 2 and 80),
  email varchar(254) not null unique,
  password_hash text not null,
  hostel varchar(80) not null,
  room_number varchar(20) not null,
  role varchar(10) not null default 'student' check (role in ('student', 'admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.complaints (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  title varchar(100) not null check (char_length(trim(title)) between 5 and 100),
  description varchar(2000) not null check (char_length(trim(description)) between 10 and 2000),
  category varchar(30) not null check (category in ('Maintenance','Cleanliness','Water Supply','Electricity','Wi-Fi','Food','Security','Other')),
  priority varchar(10) not null default 'Medium' check (priority in ('Low','Medium','High')),
  status varchar(20) not null default 'Submitted' check (status in ('Submitted','In Progress','Resolved','Rejected')),
  admin_note varchar(500),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists complaints_user_id_idx on public.complaints(user_id);
create index if not exists complaints_status_idx on public.complaints(status);
create index if not exists complaints_category_idx on public.complaints(category);
create index if not exists complaints_created_at_idx on public.complaints(created_at desc);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;
drop trigger if exists complaints_set_updated_at on public.complaints;
create trigger complaints_set_updated_at before update on public.complaints
for each row execute function public.set_updated_at();

-- API access uses the server-only service-role key, and every private route performs
-- JWT authentication plus ownership/admin checks. RLS is enabled as defence-in-depth.
alter table public.users enable row level security;
alter table public.complaints enable row level security;
-- Do not add anon/public policies. Browser clients must never connect using service-role credentials.

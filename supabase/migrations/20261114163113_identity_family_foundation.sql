-- G0 / #22. No application data or credentials. All mutation grants start closed.
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to authenticated;
alter default privileges in schema public revoke execute on functions from public, anon, authenticated;
alter default privileges in schema private revoke execute on functions from public, anon, authenticated;

create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  public_id text not null unique default replace(gen_random_uuid()::text, '-', ''),
  full_name text not null check (char_length(btrim(full_name)) between 2 and 120),
  version integer not null default 1 check (version > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.private_profiles (
  user_id uuid primary key references public.profiles(user_id) on delete cascade,
  blood_type text check (blood_type in ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
  identity_card text not null check (char_length(btrim(identity_card)) between 3 and 30),
  birth_date date not null check (birth_date between date '1900-01-01' and current_date),
  address text not null check (char_length(btrim(address)) between 3 and 250)
);
create table public.families (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(btrim(name)) between 2 and 100),
  version integer not null default 1 check (version > 0),
  created_by uuid references public.profiles(user_id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.memberships (
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid not null references public.profiles(user_id) on delete restrict,
  is_admin boolean not null default false,
  active boolean not null default true,
  joined_at timestamptz not null default now(),
  primary key (family_id, user_id),
  check (active or not is_admin)
);
create index families_creator_idx on public.families(created_by);
create index memberships_user_active_idx on public.memberships(user_id, family_id) where active;
create index memberships_admin_idx on public.memberships(family_id) where active and is_admin;
create table public.profile_shares (
  family_id uuid not null,
  user_id uuid not null,
  selected_fields jsonb not null default '{}'::jsonb check (jsonb_typeof(selected_fields) = 'object'),
  consented_at timestamptz not null default now(),
  version integer not null default 1 check (version > 0),
  primary key (family_id,user_id),
  foreign key (family_id,user_id) references public.memberships(family_id,user_id) on delete cascade
);
create table private.audit_events (
  id bigint generated always as identity primary key,
  actor_id uuid,
  family_id uuid,
  operation text not null,
  resource_id uuid,
  created_at timestamptz not null default now()
);
create index audit_family_time_idx on private.audit_events(family_id,created_at);
create table private.request_dedup (
  actor_id uuid not null references auth.users(id) on delete cascade,
  operation text not null,
  request_id uuid not null,
  request_body jsonb not null,
  result jsonb not null,
  created_at timestamptz not null default now(),
  primary key (actor_id,operation,request_id)
);
create index request_dedup_expiry_idx on private.request_dedup(created_at);

-- Restricted definer: auth.sessions is never granted to a client. A live S2 must
-- not make the token of deleted S1 live again. Missing/malformed claims fail closed.
create function private.has_live_session() returns boolean
language plpgsql stable security definer set search_path = '' as $$
declare sid text := auth.jwt()->>'session_id';
begin
  if auth.uid() is null or sid is null or
     sid !~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
  then return false; end if;
  return exists (
    select 1 from auth.sessions s join auth.users u on u.id=s.user_id
    where s.id=sid::uuid and s.user_id=auth.uid()
      and (s.not_after is null or s.not_after > now())
      and u.email_confirmed_at is not null and not coalesce(u.is_anonymous,false)
      and (u.banned_until is null or u.banned_until < now())
  );
end;
$$;
create function private.require_actor() returns uuid
language plpgsql stable security definer set search_path = '' as $$
begin
  if not private.has_live_session() then raise exception using message='forbidden',errcode='42501'; end if;
  return auth.uid();
end;
$$;
-- Definers are necessary to avoid recursive membership RLS; predicates still
-- derive the actor from Auth, never from an actor_id supplied by Flutter.
create function private.is_active_member(p_family_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select private.has_live_session() and exists (
    select 1 from public.memberships m where m.family_id=p_family_id and m.user_id=auth.uid() and m.active
  );
$$;
create function private.is_family_admin(p_family_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select private.has_live_session() and exists (
    select 1 from public.memberships m where m.family_id=p_family_id and m.user_id=auth.uid() and m.active and m.is_admin
  );
$$;
create function private.shares_family_with(p_user_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select private.has_live_session() and exists (
    select 1 from public.memberships mine join public.memberships theirs on theirs.family_id=mine.family_id
    where mine.user_id=auth.uid() and mine.active and theirs.user_id=p_user_id and theirs.active
  );
$$;

alter table public.profiles enable row level security;
alter table public.private_profiles enable row level security;
alter table public.families enable row level security;
alter table public.memberships enable row level security;
alter table public.profile_shares enable row level security;
alter table private.audit_events enable row level security;
alter table private.request_dedup enable row level security;
revoke all on public.profiles, public.private_profiles, public.families, public.memberships, public.profile_shares from public, anon, authenticated;
revoke all on private.audit_events, private.request_dedup from public, anon, authenticated;
grant select on public.profiles, public.private_profiles, public.families, public.memberships, public.profile_shares to authenticated;
revoke all on all functions in schema private from public, anon, authenticated;
grant execute on function private.has_live_session(), private.require_actor(), private.is_active_member(uuid), private.is_family_admin(uuid), private.shares_family_with(uuid) to authenticated;

create policy profiles_read on public.profiles for select to authenticated
using ((select private.has_live_session()) and (user_id=(select auth.uid()) or private.shares_family_with(user_id)));
create policy private_profiles_read on public.private_profiles for select to authenticated
using ((select private.has_live_session()) and user_id=(select auth.uid()));
create policy families_read on public.families for select to authenticated using (private.is_active_member(id));
create policy memberships_read on public.memberships for select to authenticated using (active and private.is_active_member(family_id));
create policy profile_shares_read on public.profile_shares for select to authenticated
using (private.is_active_member(family_id) and exists (
  select 1 from public.memberships m where m.family_id=profile_shares.family_id and m.user_id=profile_shares.user_id and m.active
));

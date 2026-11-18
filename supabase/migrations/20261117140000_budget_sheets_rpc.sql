-- HU-11 / #12. A sheet belongs to its creator. Family admin does not grant access.
create table public.budget_sheets (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  owner_id uuid not null references public.profiles(user_id) on delete restrict,
  name text not null check (char_length(btrim(name)) between 2 and 100),
  version integer not null default 1 check (version > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index budget_sheets_owner_idx on public.budget_sheets(owner_id, family_id) where deleted_at is null;
alter table public.budget_sheets enable row level security;
revoke all on public.budget_sheets from public, anon, authenticated;
grant select on public.budget_sheets to authenticated;
create policy budget_sheets_read on public.budget_sheets for select to authenticated
using (
  deleted_at is null
  and owner_id = (select auth.uid())
  and private.is_active_member(family_id)
);

create function private.create_budget_sheet(p_family_id uuid, p_name text, p_request_id uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  actor uuid := private.require_actor();
  body jsonb;
  result jsonb;
begin
  perform 1 from public.families where id = p_family_id and deleted_at is null for update;
  if not private.is_active_member(p_family_id) then
    raise exception using message = 'forbidden', errcode = '42501';
  end if;
  if p_name is null or char_length(btrim(p_name)) not between 2 and 100 then
    raise exception 'validation_error';
  end if;
  body := jsonb_build_object('family_id', p_family_id, 'name', btrim(p_name));
  result := private.begin_request('create_budget_sheet', p_request_id, body);
  if result is not null then
    if not exists (
      select 1 from public.budget_sheets s
      where s.id = (result->>'id')::uuid and s.owner_id = actor and s.deleted_at is null
        and private.is_active_member(s.family_id)
    ) then
      raise exception using message = 'forbidden', errcode = '42501';
    end if;
    return result;
  end if;
  insert into public.budget_sheets(family_id, owner_id, name)
    values (p_family_id, actor, btrim(p_name))
    returning to_jsonb(budget_sheets.*) into result;
  insert into private.audit_events(actor_id, family_id, operation, resource_id)
    values (actor, p_family_id, 'create_budget_sheet', (result->>'id')::uuid);
  return private.finish_request('create_budget_sheet', p_request_id, body, result);
end;
$$;

create function private.update_budget_sheet(p_sheet_id uuid, p_name text, p_expected_version integer) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  actor uuid := private.require_actor();
  sheet public.budget_sheets;
  result jsonb;
begin
  select * into sheet from public.budget_sheets where id = p_sheet_id and deleted_at is null for update;
  if not found or sheet.owner_id <> actor or not private.is_active_member(sheet.family_id) then
    raise exception using message = 'forbidden', errcode = '42501';
  end if;
  perform 1 from public.families where id = sheet.family_id and deleted_at is null for update;
  if p_expected_version is null or p_expected_version <> sheet.version then
    raise exception 'version_conflict';
  end if;
  if p_name is null or char_length(btrim(p_name)) not between 2 and 100 then
    raise exception 'validation_error';
  end if;
  update public.budget_sheets
    set name = btrim(p_name), version = version + 1, updated_at = now()
    where id = p_sheet_id
    returning to_jsonb(budget_sheets.*) into result;
  insert into private.audit_events(actor_id, family_id, operation, resource_id)
    values (actor, sheet.family_id, 'update_budget_sheet', p_sheet_id);
  return result;
end;
$$;

create function private.delete_budget_sheet(p_sheet_id uuid, p_expected_version integer, p_confirmation text) returns void
language plpgsql security definer set search_path = '' as $$
declare
  actor uuid := private.require_actor();
  sheet public.budget_sheets;
begin
  select * into sheet from public.budget_sheets where id = p_sheet_id and deleted_at is null for update;
  if not found or sheet.owner_id <> actor or not private.is_active_member(sheet.family_id) then
    raise exception using message = 'forbidden', errcode = '42501';
  end if;
  perform 1 from public.families where id = sheet.family_id for update;
  if p_expected_version is null or p_expected_version <> sheet.version then
    raise exception 'version_conflict';
  end if;
  if p_confirmation is null or p_confirmation <> sheet.name then
    raise exception 'validation_error';
  end if;
  update public.budget_sheets
    set deleted_at = now(), version = version + 1, updated_at = now()
    where id = p_sheet_id;
  insert into private.audit_events(actor_id, family_id, operation, resource_id)
    values (actor, sheet.family_id, 'delete_budget_sheet', p_sheet_id);
end;
$$;

create function public.create_budget_sheet(p_family_id uuid, p_name text, p_request_id uuid) returns jsonb
language sql security invoker set search_path = '' as $$
  select private.create_budget_sheet(p_family_id, p_name, p_request_id);
$$;
create function public.update_budget_sheet(p_sheet_id uuid, p_name text, p_expected_version integer) returns jsonb
language sql security invoker set search_path = '' as $$
  select private.update_budget_sheet(p_sheet_id, p_name, p_expected_version);
$$;
create function public.delete_budget_sheet(p_sheet_id uuid, p_expected_version integer, p_confirmation text) returns void
language sql security invoker set search_path = '' as $$
  select private.delete_budget_sheet(p_sheet_id, p_expected_version, p_confirmation);
$$;

revoke all on function private.create_budget_sheet(uuid, text, uuid), private.update_budget_sheet(uuid, text, integer), private.delete_budget_sheet(uuid, integer, text) from public, anon, authenticated;
revoke all on function public.create_budget_sheet(uuid, text, uuid), public.update_budget_sheet(uuid, text, integer), public.delete_budget_sheet(uuid, integer, text) from public, anon, authenticated;
grant execute on function private.create_budget_sheet(uuid, text, uuid), private.update_budget_sheet(uuid, text, integer), private.delete_budget_sheet(uuid, integer, text) to authenticated;
grant execute on function public.create_budget_sheet(uuid, text, uuid), public.update_budget_sheet(uuid, text, integer), public.delete_budget_sheet(uuid, integer, text) to authenticated;

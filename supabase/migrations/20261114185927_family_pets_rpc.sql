-- HU-07 / #8. Pets belong to a family and never create Auth accounts.
create table public.pets (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  name text not null check(char_length(btrim(name)) between 1 and 100),
  species text not null check(char_length(btrim(species)) between 1 and 60),
  birth_date date check(birth_date between date '1900-01-01' and current_date),
  notes text not null default '' check(char_length(notes)<=1000),
  version integer not null default 1 check(version>0),
  created_by uuid references public.profiles(user_id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique(family_id,id)
);
create index pets_creator_idx on public.pets(created_by);
alter table public.pets enable row level security;
revoke all on public.pets from public,anon,authenticated;
grant select on public.pets to authenticated;
create policy pets_read on public.pets for select to authenticated using(deleted_at is null and private.is_active_member(family_id));
create function private.save_pet(p_family_id uuid,p_pet_id uuid,p_name text,p_species text,p_birth_date date,p_notes text,p_expected_version integer,p_request_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); old public.pets;body jsonb;result jsonb;
begin
  perform 1 from public.families where id=p_family_id for update;
  if not private.is_family_admin(p_family_id) then raise exception using message='forbidden',errcode='42501'; end if;
  if p_name is null or char_length(btrim(p_name)) not between 1 and 100 or p_species is null or char_length(btrim(p_species)) not between 1 and 60
    or char_length(coalesce(p_notes,''))>1000 or (p_birth_date is not null and (p_birth_date<date '1900-01-01' or p_birth_date>current_date))
  then raise exception 'validation_error'; end if;
  body:=jsonb_build_object('family_id',p_family_id,'id',p_pet_id,'name',btrim(p_name),'species',btrim(p_species),'birth_date',p_birth_date,'notes',coalesce(p_notes,''),'version',p_expected_version);
  result:=private.begin_request('save_pet',p_request_id,body);
  if result is not null then return result; end if;
  if p_pet_id is null then
    insert into public.pets(family_id,name,species,birth_date,notes,created_by) values(p_family_id,btrim(p_name),btrim(p_species),p_birth_date,coalesce(p_notes,''),actor) returning to_jsonb(pets.*) into result;
  else
    select * into old from public.pets where id=p_pet_id and family_id=p_family_id and deleted_at is null for update;
    if not found then raise exception 'pet_unavailable'; end if;
    if p_expected_version is null or p_expected_version<>old.version then raise exception 'version_conflict'; end if;
    update public.pets set name=btrim(p_name),species=btrim(p_species),birth_date=p_birth_date,notes=coalesce(p_notes,''),version=version+1,updated_at=now() where id=p_pet_id returning to_jsonb(pets.*) into result;
  end if;
  insert into private.audit_events(actor_id,family_id,operation,resource_id) values(actor,p_family_id,'save_pet',(result->>'id')::uuid);
  return private.finish_request('save_pet',p_request_id,body,result);
end;
$$;
create function private.delete_pet(p_pet_id uuid,p_expected_version integer) returns void
language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); fid uuid;old public.pets;
begin
  select family_id into fid from public.pets where id=p_pet_id;
  perform 1 from public.families where id=fid for update;
  if not private.is_family_admin(fid) then raise exception using message='forbidden',errcode='42501'; end if;
  select * into old from public.pets where id=p_pet_id and deleted_at is null for update;
  if not found then raise exception 'pet_unavailable'; end if;
  if p_expected_version is null or p_expected_version<>old.version then raise exception 'version_conflict'; end if;
  update public.pets set deleted_at=now(),version=version+1,updated_at=now() where id=p_pet_id;
  insert into private.cleanup_jobs(operation,family_id,resource_id) values('delete_pet',fid,p_pet_id) on conflict do nothing;
  insert into private.audit_events(actor_id,family_id,operation,resource_id) values(actor,fid,'delete_pet',p_pet_id);
end;
$$;
create function public.save_pet(p_family_id uuid,p_pet_id uuid,p_name text,p_species text,p_birth_date date,p_notes text,p_expected_version integer,p_request_id uuid) returns jsonb
language sql security invoker set search_path='' as $$ select private.save_pet(p_family_id,p_pet_id,p_name,p_species,p_birth_date,p_notes,p_expected_version,p_request_id); $$;
create function public.delete_pet(p_pet_id uuid,p_expected_version integer) returns void
language sql security invoker set search_path='' as $$ select private.delete_pet(p_pet_id,p_expected_version); $$;
revoke all on function private.save_pet(uuid,uuid,text,text,date,text,integer,uuid),private.delete_pet(uuid,integer) from public,anon,authenticated;
revoke all on function public.save_pet(uuid,uuid,text,text,date,text,integer,uuid),public.delete_pet(uuid,integer) from public,anon,authenticated;
grant execute on function private.save_pet(uuid,uuid,text,text,date,text,integer,uuid),private.delete_pet(uuid,integer) to authenticated;
grant execute on function public.save_pet(uuid,uuid,text,text,date,text,integer,uuid),public.delete_pet(uuid,integer) to authenticated;

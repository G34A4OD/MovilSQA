"""HU-04: multi-user HTTP attacks against the disposable local stack and Edge."""
import json
import time
import urllib.error
import uuid
from local_supabase import LocalSupabase


def main():
    passed=[]
    def check(condition,label):
        if not condition:
            raise AssertionError(label)
        passed.append(label)
    with LocalSupabase() as db:
        # Wait for the separately started local Edge runtime, without dumping logs/keys.
        ready=False
        for _ in range(90):
            try:
                status,_=db.request('/functions/v1/lookup-user',{})
                if status==401:
                    ready=True
                    break
            except (urllib.error.URLError,TimeoutError):
                pass
            time.sleep(1)
        check(ready,'TC-SEC-03 HU-04: Edge local sin JWT deniega')
        admin=db.actor('Persona Admin HTTP')
        target=db.actor('Persona Receptora HTTP')
        stranger=db.actor('Persona Ajena HTTP')
        family=db.family(admin,'Grupo Invitación HTTP')
        body={'family_id':family['id'],'public_id':target['public_id']}
        status,_=db.request('/functions/v1/lookup-user',body,token=stranger['token'])
        check(status==403,'TC-FAM-02 HU-04: ajeno no usa búsqueda Edge')
        status,found=db.request('/functions/v1/lookup-user',body,token=admin['token'])
        check(status==200 and set(found)=={'full_name','public_id'} and found['public_id']==target['public_id'],'TC-FAM-02 HU-04: admin obtiene solo nombre/ID por Edge real')
        status,rows=db.request('/rest/v1/profiles?select=user_id',token=admin['token'])
        check(status==200 and len(rows)==1,'TC-SEC-01 HU-04: buscar no abre perfiles ajenos por REST')
        params={'p_family_id':family['id'],'p_target_public_id':target['public_id'],'p_request_id':str(uuid.uuid4())}
        status,_=db.rpc('invite_member',params,stranger)
        check(status==403,'TC-FAM-02 HU-04: ajeno no invita por RPC directa')
        status,invite=db.rpc('invite_member',params,admin)
        check(status==200 and invite['status']=='pending','TC-FAM-02 HU-04: invitación real admin')
        status,retry=db.rpc('invite_member',params,admin)
        check(status==200 and retry['id']==invite['id'],'TC-FAM-02 HU-04: reintento no duplica')
        status,rows=db.request('/rest/v1/invitations?select=id,family_name,target_name,status,expires_at',token=target['token'])
        check(status==200 and len(rows)==1 and rows[0]['family_name']==family['name'],'TC-FAM-03 HU-04: receptor ve invitación mínima')
        status,rows=db.request('/rest/v1/families?select=id',token=target['token'])
        check(status==200 and rows==[],'TC-SEC-02 HU-04: invitado pendiente sin datos familiares')
        response={'p_invitation_id':invite['id'],'p_decision':'accept','p_request_id':str(uuid.uuid4())}
        status,_=db.rpc('respond_invitation',response,stranger)
        check(status==400,'TC-FAM-03 HU-04: tercero no acepta')
        status,accepted=db.rpc('respond_invitation',response,target)
        check(status==200 and accepted['status']=='accepted','TC-FAM-03 HU-04: receptor acepta por HTTP')
        status,rows=db.request('/rest/v1/memberships?select=user_id,is_admin',token=target['token'])
        check(status==200 and len(rows)==2 and not next(r['is_admin'] for r in rows if r['user_id']==target['user_id']),'TC-FAM-03 HU-04: miembro aceptado sin privilegio admin')
        status,_=db.rpc('lookup_family_user',{'p_family_id':family['id'],'p_public_id':stranger['public_id']},target)
        check(status==403,'TC-FAM-02 HU-04: miembro normal tampoco elude Edge por SQL RPC')
        relation={'p_family_id':family['id'],'p_relationship_id':None,'p_from_user_id':admin['user_id'],'p_to_user_id':target['user_id'],'p_kind':'parent','p_expected_version':None,'p_request_id':str(uuid.uuid4())}
        status,_=db.rpc('save_relationship',relation,target)
        check(status==403,'TC-FAM-05 HU-06: miembro no asigna parentesco')
        status,edge=db.rpc('save_relationship',relation,admin)
        check(status==200 and edge['kind']=='parent','TC-FAM-05 HU-06: admin vincula padre/hijo real')
        status,rows=db.request('/rest/v1/relationships?select=id,from_user_id,to_user_id,kind,version',token=target['token'])
        check(status==200 and len(rows)==1,'TC-FAM-05 HU-06: familiar lee grafo autorizado')
        status,error=db.rpc('save_relationship',{**relation,'p_from_user_id':target['user_id'],'p_to_user_id':admin['user_id'],'p_request_id':str(uuid.uuid4())},admin)
        check(status==400 and error.get('message')=='invalid_relationship','TC-FAM-05 HU-06: ciclo inverso HTTP denegado')
        status,edited=db.rpc('save_relationship',{**relation,'p_relationship_id':edge['id'],'p_kind':'grandparent','p_expected_version':1,'p_request_id':str(uuid.uuid4())},admin)
        check(status==200 and edited['version']==2,'TC-FAM-05 HU-06: editar rol versionado')
        deletion={'p_family_id':family['id'],'p_relationship_id':edge['id'],'p_expected_version':1}
        status,_=db.rpc('delete_relationship',deletion,admin)
        check(status==400,'TC-FAM-05 HU-06: borrar versión obsoleta denegado')
        status,_=db.rpc('delete_relationship',{**deletion,'p_expected_version':2},admin)
        check(status in (200,204),'TC-FAM-05 HU-06: borrar vínculo actual')
        pet_params={'p_family_id':family['id'],'p_pet_id':None,'p_name':'Luna HTTP ficticia','p_species':'Perro','p_birth_date':None,'p_notes':'Demo ficticia','p_expected_version':None,'p_request_id':str(uuid.uuid4())}
        status,_=db.rpc('save_pet',pet_params,target)
        check(status==403,'TC-FAM-06 HU-07: miembro no crea mascota')
        status,pet=db.rpc('save_pet',pet_params,admin)
        check(status==200 and pet['name']=='Luna HTTP ficticia','TC-FAM-06 HU-07: admin crea mascota familiar')
        status,retry=db.rpc('save_pet',pet_params,admin)
        check(status==200 and retry['id']==pet['id'],'TC-FAM-06 HU-07: reintento sin mascota duplicada')
        status,rows=db.request('/rest/v1/pets?select=id,name,species,birth_date,notes,version',token=target['token'])
        check(status==200 and len(rows)==1,'TC-FAM-06 HU-07: miembro ve ficha separada')
        status,rows=db.request('/rest/v1/pets?select=id',token=stranger['token'])
        check(status==200 and rows==[],'TC-SEC-02 HU-07: ajeno sin mascota')
        status,edited_pet=db.rpc('save_pet',{**pet_params,'p_pet_id':pet['id'],'p_name':'Luna HTTP editada','p_expected_version':1,'p_request_id':str(uuid.uuid4())},admin)
        check(status==200 and edited_pet['version']==2,'TC-FAM-06 HU-07: mascota editada por versión')
        status,_=db.rpc('delete_pet',{'p_pet_id':pet['id'],'p_expected_version':1},admin)
        check(status==400,'TC-FAM-06 HU-07: versión vieja no borra mascota')
        status,_=db.rpc('delete_pet',{'p_pet_id':pet['id'],'p_expected_version':2},target)
        check(status==403,'TC-FAM-06 HU-07: miembro no borra mascota')
        status,_=db.rpc('delete_pet',{'p_pet_id':pet['id'],'p_expected_version':2},admin)
        check(status in (200,204),'TC-FAM-06 HU-07: admin borra mascota')
        status,rows=db.request('/rest/v1/pets?select=id',token=target['token'])
        check(status==200 and rows==[],'TC-SEC-02 HU-07: mascota borrada ya no se publica')
        status,error=db.rpc('leave_family',{'p_family_id':family['id']},admin)
        check(status==400 and error.get('message')=='last_admin','TC-FAM-04 HU-05: último admin no sale por HTTP')
        status,_=db.rpc('set_member_admin',{'p_family_id':family['id'],'p_target_user_id':target['user_id'],'p_is_admin':True},target)
        check(status==403,'TC-FAM-04 HU-05: no auto promoción desde cliente adverso')
        status,_=db.rpc('set_member_admin',{'p_family_id':family['id'],'p_target_user_id':target['user_id'],'p_is_admin':True},admin)
        check(status==200,'TC-FAM-04 HU-05: admin delega administración')
        status,_=db.rpc('set_member_admin',{'p_family_id':family['id'],'p_target_user_id':target['user_id'],'p_is_admin':False},target)
        check(status==200,'TC-FAM-04 HU-05: renuncia propia con otro admin')
        status,_=db.rpc('set_member_admin',{'p_family_id':family['id'],'p_target_user_id':target['user_id'],'p_is_admin':True},admin)
        check(status==200,'TC-FAM-04 HU-05: dos admins de nuevo')
        status,_=db.rpc('remove_member',{'p_family_id':family['id'],'p_target_user_id':target['user_id']},admin)
        check(status==200,'TC-FAM-04 HU-05: expulsión de admin con otro restante')
        status,rows=db.request('/rest/v1/families?select=id',token=target['token'])
        check(status==200 and rows==[],'TC-SEC-02 HU-05: expulsado sin acceso con el mismo JWT')
        status,reinvite=db.rpc('invite_member',{**params,'p_request_id':str(uuid.uuid4())},admin)
        check(status==200 and reinvite['status']=='pending','TC-FAM-04 HU-05: reinvitación explícita tras expulsión')
        status,_=db.rpc('respond_invitation',{'p_invitation_id':reinvite['id'],'p_decision':'accept','p_request_id':str(uuid.uuid4())},target)
        check(status==200,'TC-FAM-04 HU-05: reingreso por nueva aceptación')
        status,rows=db.request('/rest/v1/memberships?select=user_id,is_admin',token=target['token'])
        check(status==200 and not next(r['is_admin'] for r in rows if r['user_id']==target['user_id']),'TC-FAM-04 HU-05: reingreso no restaura admin antiguo')
        status,_=db.rpc('leave_family',{'p_family_id':family['id']},target)
        check(status==200,'TC-FAM-04 HU-05: miembro sale voluntariamente')
        status,rows=db.request('/rest/v1/families?select=id',token=target['token'])
        check(status==200 and rows==[],'TC-SEC-02 HU-05: salida voluntaria revoca acceso vigente')
        status,_=db.request('/auth/v1/logout?scope=local',token=admin['token'],method='POST')
        check(status==204,'TC-SEC-03 HU-04: sesión del admin terminada')
        status,_=db.request('/functions/v1/lookup-user',body,token=admin['token'])
        check(status in (401,403),'TC-SEC-03 HU-04: Edge con JWT anterior denegado')
    print(json.dumps({'status':'PASS','tests':len(passed),'cases':passed},ensure_ascii=False,indent=2))


if __name__=='__main__':
    main()

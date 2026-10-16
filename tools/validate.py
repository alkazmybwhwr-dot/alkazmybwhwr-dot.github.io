#!/usr/bin/env python3
"""يتحقق من صحة أي مفتاح/رابط على الشبكة الحقيقية. يُستدعى: validate.py <type> <value>"""
import sys,json,re,urllib.request,urllib.error
UA={'User-Agent':'Mozilla/5.0 (CineHub3099)','Accept':'application/json'}
def get(u,h=None):
    rq=urllib.request.Request(u,headers=h or UA)
    return urllib.request.urlopen(rq,timeout=25)
def post(u,data,h=None):
    hh={'Content-Type':'application/json'}; hh.update(h or {})
    rq=urllib.request.Request(u,data=json.dumps(data).encode(),headers=hh)
    return urllib.request.urlopen(rq,timeout=25)
t=sys.argv[1]; v=sys.argv[2].strip()
try:
  if t=='github_token':
    r=get('https://api.github.com/user',{'Authorization':'token '+v,'User-Agent':'x'})
    sc=r.headers.get('x-oauth-scopes','') or ''
    j=json.loads(r.read().decode())
    miss=[s for s in ('repo','workflow') if s not in sc]
    print(json.dumps({'ok':not miss,'login':j.get('login'),'scopes':sc,'missing':miss}))
  elif t=='adsterra_key':
    r=get('https://api3.adsterratools.com/publisher/stats.json?start_date=2024-01-01&finish_date=2030-01-01&group_by=date',
          {'X-API-Key':v,'Accept':'application/json'})
    print(json.dumps({'ok':r.status==200,'code':r.status}))
  elif t=='supabase':
    r=get(v.rstrip('/')+'/rest/v1/',{'apikey':sys.argv[3] if len(sys.argv)>3 else '','Authorization':'Bearer '+(sys.argv[3] if len(sys.argv)>3 else '')})
    print(json.dumps({'ok':r.status<400,'code':r.status}))
  elif t=='apps_script':
    r=post(v,{'type':'verify','token':'probe','provider':'test'})
    body=r.read().decode()[:200]
    print(json.dumps({'ok':'ok' in body.lower() or r.status==200,'code':r.status,'body':body[:80]}))
  elif t=='url':  print(json.dumps({'ok':bool(re.match(r'^https://',v))}))
  elif t=='phone':
    d=re.sub(r'\D','',v); print(json.dumps({'ok':8<=len(d)<=15,'digits':d}))
  elif t=='turnstile_site':
    print(json.dumps({'ok':bool(re.match(r'^(0x4AAAAA|1x0|2x0|3x0)',v)) or len(v)>20}))
  elif t=='turnstile_secret':
    print(json.dumps({'ok':bool(re.match(r'^(0x4AAAAA|1x0|2x0|3x0)',v)) or len(v)>20}))
  elif t=='adsterra_pubid': print(json.dumps({'ok':bool(re.match(r'^\d{4,}$',v))}))
  elif t=='uid': print(json.dumps({'ok':bool(re.match(r'^[A-Za-z0-9._-]{3,64}$',v))}))
  elif t=='email': print(json.dumps({'ok':bool(re.match(r'^[^@\s]+@[^@\s]+\.[a-z]{2,}$',v,re.I))}))
  elif t=='pin': print(json.dumps({'ok':len(v)>=4}))
  else: print(json.dumps({'ok':True}))
except Exception as e:
  print(json.dumps({'ok':False,'err':'%s: %s'%(type(e).__name__,str(e)[:70])}))

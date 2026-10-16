#!/usr/bin/env python3
"""TMDB: آلاف الأفلام بملصقات حقيقية + تريلرات قابلة للتشغيل داخل التطبيق"""
import json,os,urllib.request,urllib.parse,datetime
from concurrent.futures import ThreadPoolExecutor
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.makedirs(os.path.join(R,'data','catalog'),exist_ok=True)
K={}
if os.path.exists(os.path.join(R,'keys.env')):
    for l in open(os.path.join(R,'keys.env'),encoding='utf-8'):
        if '=' in l and not l.strip().startswith('#'):
            a,b=l.split('=',1); K[a.strip()]=b.strip()
key=K.get('TMDB_KEY','')
if not key: print('  ! لا TMDB_KEY — تخطّي'); raise SystemExit
def get(p,extra=None):
    q={'api_key':key}; q.update(extra or {})
    u='https://api.themoviedb.org/3/'+p+'?'+urllib.parse.urlencode(q)
    return json.loads(urllib.request.urlopen(urllib.request.Request(u,headers={'User-Agent':'ch','Accept':'application/json'}),timeout=30).read().decode())
MOV=[]
for path,pages in (('movie/popular',range(1,6)),('movie/top_rated',range(1,6)),('movie/now_playing',range(1,4)),
                   ('movie/upcoming',range(1,4)),('trending/movie/week',[None])):
    for pg in pages:
        try:
            j=get(path,{'page':pg} if pg else None)
            MOV+=j.get('results') or []
        except Exception: pass
GEN=['28','12','16','35','80','99','18','10751','14','36','27','10402','9648','10749','878','53','10752','37']
for g in GEN:
    for pg in (1,2,3):
        try: MOV+=get('discover/movie',{'with_genres':g,'page':pg,'sort_by':'popularity.desc'}).get('results') or []
        except Exception: pass
seen={};out=[]
for m in MOV:
    i=m.get('id')
    if not i or i in seen: continue
    seen[i]=1
    out.append({'id':str(i),'t':(m.get('title') or m.get('original_title') or '')[:110],
      'img':'https://image.tmdb.org/t/p/w300'+m['poster_path'] if m.get('poster_path') else '',
      'emb':'','kind':'iframe','dur':0,'y':(m.get('release_date') or '')[:4],
      'rate':m.get('vote_average') or 0,'c':'tmdb'})
print('  TMDB أفلام:',len(out))
top=out[:600]
def vids(x):
    try:
        j=get('movie/%s/videos'%x['id'])
        for v in (j.get('results') or []):
            if v.get('site')=='YouTube' and v.get('type') in ('Trailer','Teaser'):
                return x['id'],'https://www.youtube.com/embed/'+v['key']; break
    except Exception: pass
    return x['id'],''
with ThreadPoolExecutor(10) as ex:
    for pid,emb in ex.map(vids,top):
        if emb:
            for x in out:
                if x['id']==pid: x['emb']=emb; break
have=len([x for x in out if x['emb']])
json.dump({'src':'tmdb','name':'TMDB أفلام وتريلرات','items':out},open(os.path.join(R,'data','catalog','tmdb.json'),'w',encoding='utf-8'),ensure_ascii=False,indent=0)
print('  TMDB: %d فيلم · %d بتريلر يعمل'%(len(out),have))

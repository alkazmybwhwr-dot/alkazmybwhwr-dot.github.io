#!/usr/bin/env python3
"""archive.org بالاستعلام بالنوع والتنزيلات (لا يعتمد على أسماء مجموعات) + إعادة محاولة"""
import json,os,urllib.request,urllib.parse,datetime,time
from concurrent.futures import ThreadPoolExecutor
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.makedirs(os.path.join(R,'data','catalog'),exist_ok=True)
UA={'User-Agent':'Mozilla/5.0 (CineHub3099)','Accept':'application/json','Accept-Encoding':'identity'}
def raw(u,t=90):
    return urllib.request.urlopen(urllib.request.Request(u,headers=UA),timeout=t).read().decode('utf-8','ignore')
def q(med,page,rows=400):
    p={'q':'mediatype:%s AND downloads:[300 TO null]'%med,'fl[]':['identifier','title','year','downloads','mediatype'],
       'rows':rows,'page':page,'sort[]':'downloads desc','output':'json'}
    u='https://archive.org/advancedsearch.php?'+urllib.parse.urlencode(p,doseq=True)
    return ((json.loads(raw(u)).get('response') or {}).get('docs') or [])
def scrape(med,count=400):
    u='https://archive.org/services/search/v1/scrape?'+urllib.parse.urlencode(
      {'q':'mediatype:%s AND downloads:[300 TO null]'%med,'fields':'identifier,title,year,downloads,mediatype',
       'count':count,'sorts':'downloads desc'})
    return (json.loads(raw(u)).get('items') or [])
items=[];errs={}
def add(docs,kind):
    for d in docs:
        i=d.get('identifier')
        if not i: continue
        items.append({'id':i,'t':(d.get('title') or i)[:110],'y':d.get('year') or '','dl':d.get('downloads') or 0,
          'c':kind,'img':'https://archive.org/services/img/'+i,'emb':'https://archive.org/embed/'+i,'kind':'iframe'})
def job(args):
    med,kind,page=args
    for attempt in (1,2):
        try:
            d=q(med,page)
            if d: return kind,d
        except Exception as e: errs['%s_p%d'%(med,page)]=type(e).__name__
        time.sleep(2)
    return kind,[]
tasks=[('movies','movie',p) for p in range(1,13)]+[('audio','audio',p) for p in range(1,7)]+[('texts','book',p) for p in range(1,5)]
with ThreadPoolExecutor(6) as ex:
    for kind,d in ex.map(job,tasks):
        if d: add(d,kind)
seen=set();out=[]
for x in items:
    if x['id'] in seen: continue
    seen.add(x['id']); out.append(x)
mov=[x for x in out if x['c']=='movie']
aud=[x for x in out if x['c']=='audio']; bok=[x for x in out if x['c']=='book']
json.dump({'t':datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None).strftime('%FT%TZ'),
 'total':len(out),'movies':len(mov),'errors':errs,
 'cols':{'أفلام':mov[:400],'feature_films':mov[:400],'صوت':aud[:300],'كتب':bok[:300]}},
 open(os.path.join(R,'data','archive.json'),'w',encoding='utf-8'),ensure_ascii=False,indent=0)
json.dump({'src':'archive','name':'Archive.org','items':out},open(os.path.join(R,'data','catalog','archive.json'),'w',encoding='utf-8'),ensure_ascii=False,indent=0)
print('  archive: %d عنصر (%d فيلم · %d صوت · %d كتاب) · أخطاء %d'%(len(out),len(mov),len(aud),len(bok),len(errs)))

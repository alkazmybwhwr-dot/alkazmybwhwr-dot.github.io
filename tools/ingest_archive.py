#!/usr/bin/env python3
"""يجلب أفلامًا مجانية (ملك عام) من archive.org — محتوى حقيقي قانوني بلا رخصة"""
import json,os,urllib.request,datetime,urllib.parse
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UA={'User-Agent':'Mozilla/5.0 (CineHub3099)'}
COLS=['feature_films','moviesandfilms','classic_cartoons','film_noir','silent_films','sci-fi_horror','short_films']
out={}
for c in COLS:
    q=urllib.parse.quote('collection:%s AND mediatype:movies'%c)
    u=('https://archive.org/advancedsearch.php?q=%s&fl%%5B%%5D=identifier&fl%%5B%%5D=title&fl%%5B%%5D=year'
       '&fl%%5B%%5D=downloads&fl%%5B%%5D=description&rows=120&page=1&sort%%5B%%5D=downloads+desc&output=json')%q
    try:
        j=json.load(urllib.request.urlopen(urllib.request.Request(u,headers=UA),timeout=45))
        docs=((j.get('response') or {}).get('docs') or [])
    except Exception as e:
        print('  !',c,type(e).__name__); docs=[]
    items=[]
    for d in docs:
        i=d.get('identifier')
        if not i: continue
        items.append({'id':i,'t':(d.get('title') or i)[:90],'y':d.get('year') or '',
          'dl':d.get('downloads') or 0,'c':c,'embed':'https://archive.org/embed/'+i})
    out[c]=items
    print('  ✓ %s: %d'%(c,len(items)))
tot=sum(len(v) for v in out.values())
json.dump({'t':datetime.datetime.utcnow().strftime('%FT%TZ'),'total':tot,'cols':out},
 open(os.path.join(R,'data','archive.json'),'w',encoding='utf-8'),ensure_ascii=False,indent=0)
print('  المجموع',tot,'فيلمًا مجانيًا')

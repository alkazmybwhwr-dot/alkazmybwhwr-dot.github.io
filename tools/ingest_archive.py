#!/usr/bin/env python3
"""3 طبقات: scrape API → advancedsearch → HTML. يطبع كود الخطأ الحقيقي."""
import json,os,re,urllib.request,urllib.parse,datetime
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UA={'User-Agent':'Mozilla/5.0 (CineHub3099)','Accept':'application/json','Accept-Encoding':'identity'}
COLS=['feature_films','moviesandfilms','classic_cartoons','film_noir','silent_films','sci-fi_horror','short_films','animation']
def raw(u,t=45):
    return urllib.request.urlopen(urllib.request.Request(u,headers=UA),timeout=t).read().decode('utf-8','ignore')
def layer1(c,n=100):
    u='https://archive.org/services/search/v1/scrape?'+urllib.parse.urlencode(
      {'q':'collection:%s AND mediatype:movies'%c,'fields':'identifier,title,year,downloads','count':n,'sorts':'downloads desc'})
    j=json.loads(raw(u)); return (j.get('items') or [])
def layer2(c,n=100):
    p={'q':'collection:%s AND mediatype:movies'%c,'fl[]':['identifier','title','year','downloads'],
       'rows':n,'page':1,'sort[]':'downloads desc','output':'json'}
    u='https://archive.org/advancedsearch.php?'+urllib.parse.urlencode(p,doseq=True)
    j=json.loads(raw(u)); return ((j.get('response') or {}).get('docs') or [])
def layer3(c,n=60):
    h=raw('https://archive.org/details/%s'%c,40)
    ids=re.findall(r'href="/details/([A-Za-z0-9._\-]{4,})"',h)
    seen=[];out=[]
    for i in ids:
        if i in seen or i==c: continue
        seen.append(i); out.append({'identifier':i,'title':i,'downloads':0})
        if len(out)>=n: break
    return out
out={}; log={}
for c in COLS:
    docs=[];how=''
    for i,fn in enumerate((layer1,layer2,layer3),1):
        try:
            docs=fn(c)
            if docs: how='layer%d'%i; break
        except Exception as e: log['%s_L%d'%(c,i)]='%s:%s'%(type(e).__name__,str(e)[:60])
    items=[{'id':d.get('identifier'),'t':(d.get('title') or d.get('identifier') or '')[:90],
            'y':d.get('year') or '','dl':d.get('downloads') or 0,'c':c,
            'embed':'https://archive.org/embed/'+str(d.get('identifier'))} for d in docs if d.get('identifier')]
    out[c]=items; print('  %-18s %3d عبر %s'%(c,len(items),how or 'فشل'))
tot=sum(len(v) for v in out.values())
json.dump({'t':datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None).strftime('%FT%TZ'),
 'total':tot,'cols':out,'errors':log},open(os.path.join(R,'data','archive.json'),'w',encoding='utf-8'),ensure_ascii=False,indent=0)
print('  المجموع',tot,'· أخطاء',len(log))
if tot==0: raise SystemExit('  ✗ لم يُجلب شيء — راجع data/archive.json')

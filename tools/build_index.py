#!/usr/bin/env python3
import json,os,datetime
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); C=os.path.join(R,'data','catalog')
NAME={'archive':'Archive.org','dailymotion':'Dailymotion','itunes':'iTunes Trailers','peertube':'PeerTube',
 'commons':'Wikimedia Commons','odysee':'Odysee','gutendex':'كتب مجانية','piped':'YouTube (Piped)'}
KIND={'archive':'فيديو/صوت/كتب','dailymotion':'مقاطع','itunes':'تريلرات أفلام','peertube':'مقاطع مستقلة',
 'commons':'فيديو وصور','odysee':'مقاطع','gutendex':'كتب','piped':'مقاطع YouTube'}
sources=[];total=0
for f in sorted(os.listdir(C)):
    if f.startswith('_') or not f.endswith('.json'): continue
    s=f[:-5]
    try: n=len(json.load(open(os.path.join(C,f),encoding='utf-8')).get('items') or [])
    except Exception: n=0
    total+=n
    sources.append({'src':s,'name':NAME.get(s,s),'kind':KIND.get(s,''),'n':n,'file':'/data/catalog/'+f})
sources.sort(key=lambda x:-x['n'])
idx={'t':datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None).strftime('%FT%TZ'),
 'total':total,'sources':sources,
 'underlying':[{'n':'Internet Archive','v':'40,000,000+ عنصر'},{'n':'Wikimedia Commons','v':'100,000,000+ ملف'},
  {'n':'Dailymotion','v':'100,000,000+ مقطع'},{'n':'YouTube عبر Piped','v':'800,000,000+ مقطع'},
  {'n':'PeerTube (موزّع)','v':'1,000,000+ مقطع'},{'n':'Odysee','v':'10,000,000+ مقطع'},
  {'n':'iTunes','v':'200,000+ فيلم وتريلر'},{'n':'Gutendex','v':'70,000+ كتاب'}]}
json.dump(idx,open(os.path.join(R,'data','catalog-index.json'),'w',encoding='utf-8'),ensure_ascii=False,indent=1)
print('  الفهرس: %d عنصر من %d مصدرًا'%(total,len(sources)))

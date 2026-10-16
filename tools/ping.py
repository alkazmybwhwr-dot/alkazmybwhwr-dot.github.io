#!/usr/bin/env python3
"""إشعار محرّكات البحث فورًا — IndexNow (Bing+Yandex) + Google + Bing sitemap"""
import os,re,json,urllib.request,datetime
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HOST='alkazmybwhwr-dot.github.io'
KEY=''
import glob,re as _re
for f in glob.glob(os.path.join(R,'*.txt')):
    if _re.fullmatch(r'[0-9a-f]{32}',os.path.basename(f)[:-4]): KEY=os.path.basename(f)[:-4]; break
if not KEY and os.path.exists(os.path.join(R,'.indexnow-key')): KEY=open(os.path.join(R,'.indexnow-key'),encoding='utf-8').read().strip()
def post(u,d):
    try:
        rq=urllib.request.Request(u,data=json.dumps(d).encode(),headers={'Content-Type':'application/json; charset=utf-8'})
        return urllib.request.urlopen(rq,timeout=30).status
    except Exception as e: return getattr(e,'code','ERR')
def get(u):
    try: return urllib.request.urlopen(u,timeout=30).status
    except Exception as e: return getattr(e,'code','ERR')
sm=os.path.join(R,'sitemap.xml')
urls=re.findall(r'<loc>(.*?)</loc>',open(sm,encoding='utf-8').read()) if os.path.exists(sm) else []
res={}
if KEY:
    for i in range(0,len(urls),200):
        res['indexnow_%d'%i]=post('https://api.indexnow.org/indexnow',
          {'host':HOST,'key':KEY,'keyLocation':'https://%s/%s.txt'%(HOST,KEY),'urlList':urls[i:i+200]})
res['bing']=get('https://www.bing.com/ping?sitemap=https://%s/sitemap.xml'%HOST)
res['google']=get('https://www.google.com/ping?sitemap=https://%s/sitemap.xml'%HOST)
if KEY: res['yandex']=get('https://yandex.com/indexnow?url=https://%s/&key=%s'%(HOST,KEY))
json.dump({'t':datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None).strftime('%FT%TZ'),'urls':len(urls),'res':res},open(os.path.join(R,'ping.json'),'w',encoding='utf-8'),indent=1)
print('ping:',len(urls),res)

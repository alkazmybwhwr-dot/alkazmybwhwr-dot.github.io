#!/usr/bin/env python3
"""يقرأ keys.env ويربط كل مفتاح في مكانه الصحيح. تلقائي بالكامل."""
import os,json,re
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def rd(p,d):
    try:return json.load(open(os.path.join(R,p),encoding='utf-8'))
    except Exception:return d
def wr(p,o):json.dump(o,open(os.path.join(R,p),'w',encoding='utf-8'),ensure_ascii=False,indent=1)
K={}
f=os.path.join(R,'keys.env')
if os.path.exists(f):
    for l in open(f,encoding='utf-8'):
        l=l.strip()
        if not l or l.startswith('#') or '=' not in l: continue
        a,b=l.split('=',1); K[a.strip()]=b.strip()
ALIAS={'ADSTERRA':'ADSTERRA_API_KEY','EXOCLICK':'EXOCLICK_API_KEY','TMDB_KEY':'TMDB_KEY',
 'WORKER':'WORKER_URL','CCBILL':'CCBILL_ACCOUNT','SEGPAY':'SEGPAY_ACCOUNT','ADSENSE':'ADSENSE_CLIENT',
 'MONETAG':'MONETAG_MULTITAG','PROPELLER':'PROPELLER_API_KEY','POPADS':'POPADS_API_KEY',
 'LINKVERTISE':'LINKVERTISE_UID','WORKINK':'WORKINK_UID','SHRINKME':'SHRINKME_UID'}
for a,b in ALIAS.items():
    if K.get(a) and not K.get(b):
        v=K[a]
        if a=='ADSTERRA' and v.isdigit() and len(v)<12: K['ADSTERRA_PUB_ID']=v
        else: K[b]=v
EXTRA={k:v for k,v in K.items() if k not in ALIAS and k not in ('ADSTERRA_PUB_ID',)}
def g(k):return K.get(k,'')
n=0
cfg=rd('ads-config.json',{}) or {}
if g('ADSENSE_CLIENT'):cfg['adsense_client']=g('ADSENSE_CLIENT');n+=1
if g('MONETAG_MULTITAG'):cfg['monetag_src']=g('MONETAG_MULTITAG');n+=1
if g('MONETAG_REWARDED_ZONE'):cfg['monetag_rewarded_zone']=g('MONETAG_REWARDED_ZONE');n+=1
b=cfg.setdefault('banners',{})
for k,z in (('ADSTERRA_BANNER_TOP','top'),('ADSTERRA_BANNER_MID','mid'),('ADSTERRA_BANNER_SIDE','side'),('ADSTERRA_BANNER_MOBILE','mobile')):
    if g(k): b.setdefault(z,{}); b[z]['key']=g(k); n+=1
wr('ads-config.json',cfg)
net=rd('networks.json',{'networks':[]})
for x in net.get('networks',[]):
    if x['id']=='adsterra':
        for k,z in (('ADSTERRA_BANNER_TOP','banner_top'),('ADSTERRA_BANNER_MID','banner_mid'),('ADSTERRA_BANNER_SIDE','banner_side'),('ADSTERRA_BANNER_MOBILE','banner_mobile'),('ADSTERRA_POPUNDER','popunder'),('ADSTERRA_SOCIALBAR','socialbar'),('ADSTERRA_INPAGE','inpage')):
            if g(k): x['keys'][z]=g(k); n+=1
        if any(x['keys'].values()): x['enabled']=True
    if x['id']=='monetag':
        if g('MONETAG_MULTITAG'): x['keys']['multitag']=g('MONETAG_MULTITAG'); x['enabled']=True; n+=1
        if g('MONETAG_REWARDED_ZONE'): x['keys']['rewarded']=g('MONETAG_REWARDED_ZONE'); x['enabled']=True
    if x['id']=='propeller' and g('PROPELLER_API_KEY'): x['enabled']=True
    if x['id']=='popads' and g('POPADS_API_KEY'): x['enabled']=True
    if x['id']=='adsense' and g('ADSENSE_CLIENT'): x['enabled']=True
wr('networks.json',net)
sh=rd('shorteners.json',{'shorteners':[]})
M={'LINKVERTISE_UID':'linkvertise','WORKINK_UID':'workink','SHRINKME_UID':'shrinkme','SHRINKERN_UID':'shrinkearn','CLKSH_UID':'clksh','GPLINKS_UID':'gplinks'}
for x in sh.get('shorteners',[]):
    k=[a for a,b in M.items() if b==x['id']]
    if k and g(k[0]): x['uid']=g(k[0]); x['enabled']=True; n+=1
sl=sh.setdefault('smartlinks',{})
if g('CPAGRIP_SMARTLINK'):sl['cpagrip']=g('CPAGRIP_SMARTLINK');n+=1
if g('OGADS_SMARTLINK'):sl['ogads']=g('OGADS_SMARTLINK');n+=1
wr('shorteners.json',sh)
o=rd('owner.json',{})
for k,fld in (('OWNER_WHATSAPP','whatsapp'),('OWNER_TELEGRAM','telegram'),('OWNER_EMAIL','email'),('KURAIMI_NAME','kuraimi_name'),('KURAIMI_ACCOUNT','kuraimi_account'),('KURAIMI_PHONE','kuraimi_phone'),('USDT_TRC20','usdt_trc20'),('APPS_SCRIPT_URL','endpoint'),('SUPABASE_URL','supabase_url'),('SUPABASE_ANON','supabase_anon')):
    if g(k): o[fld]=g(k); n+=1
c=o.setdefault('captcha',{})
if g('TURNSTILE_SITE'):c['turnstile_site']=g('TURNSTILE_SITE');n+=1
if g('TURNSTILE_SECRET'):c['turnstile_secret']=g('TURNSTILE_SECRET');n+=1
wr('owner.json',o)
k2=rd('kuraimi.json',{})
for a,b2 in (('KURAIMI_NAME','holder'),('KURAIMI_ACCOUNT','account'),('KURAIMI_PHONE','phone')):
    if g(a):k2[b2]=g(a)
wr('kuraimi.json',k2)
cl=rd('cloud-config.json',{})
if g('SUPABASE_URL'):cl['supabase_url']=g('SUPABASE_URL')
if g('SUPABASE_ANON'):cl['supabase_anon']=g('SUPABASE_ANON')
wr('cloud-config.json',cl)
o2=rd('owner.json',{}); o2.setdefault('extra',{}).update({k:v for k,v in K.items() if v and k not in ('ADSTERRA_API_KEY','ADSTERRA_PUB_ID','LINKVERTISE_UID')}); wr('owner.json',o2)
if g('ADSTERRA_PUB_ID'):
    a=open(os.path.join(R,'ads.txt'),encoding='utf-8').read() if os.path.exists(os.path.join(R,'ads.txt')) else ''
    if 'adsterra.com, %s'%g('ADSTERRA_PUB_ID') not in a:
        open(os.path.join(R,'ads.txt'),'a',encoding='utf-8').write('\nadsterra.com, %s, DIRECT\n'%g('ADSTERRA_PUB_ID'))
print('  ✓ رُبط %d مفتاحًا تلقائيًا'%n)

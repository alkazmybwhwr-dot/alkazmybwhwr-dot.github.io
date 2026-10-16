#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")" || exit 1
ask(){ printf '%s' "$2"; read -r v; [ -n "$v" ] && echo "$v" || echo "$1"; }
echo "— اترك الفراغ ليبقى الحالي —"
P=$(ask "" "معرّف ناشر Adsterra (ads.txt) [فارغ=تخطّي]: ")
for z in top mid side mobile bottom; do K=$(ask "" "مفتاح بانر $z [فارغ=تخطّي]: "); [ -n "$K" ] && eval "K_$z=\$K"; done
PU=$(ask "" "رابط سكربت Popunder: "); SB=$(ask "" "رابط سكربت Social Bar: "); IP=$(ask "" "رابط In-Page Push: ")
MT=$(ask "" "رابط Monetag MultiTag: "); AC=$(ask "" "AdSense client (ca-pub-...): "); AS=$(ask "" "AdSense slot: ")
HN=$(ask "" "اسمك كما في الهوية (الكريمي): "); HA=$(ask "" "رقم حسابك في الكريمي: ")
HP=$(ask "" "رقم هاتفك (967...): "); HB=$(ask "" "الفرع: ")
WA=$(ask "" "واتساب للطلبات (967...): "); TG=$(ask "" "تيليجرام (username): "); EM=$(ask "" "بريدك: ")
UT=$(ask "" "عنوان USDT TRC20: "); EP=$(ask "" "رابط Google Apps Script Web App: ")
TSS=$(ask "" "Turnstile sitekey: "); TSK=$(ask "" "Turnstile secret: ")
export P PU SB IP MT AC AS HN HA HP HB WA TG EM UT EP TSS TSK K_top K_mid K_side K_mobile K_bottom
python3 - <<'PY'
import json,os
c=json.load(open('ads-config.json',encoding='utf-8'))
for k in ('K_top','K_mid','K_side','K_mobile','K_bottom'):
    z=k.split('_')[1]; v=os.environ.get(k,'')
    if v: c['banners'][z]['key']=v
for env,key in (('PU','popunder_src'),('SB','socialbar_src'),('IP','inpage_src'),('MT','monetag_src'),('AC','adsense_client'),('AS','adsense_slot')):
    if os.environ.get(env): c[key]=os.environ[env]
json.dump(c,open('ads-config.json','w',encoding='utf-8'),ensure_ascii=False,indent=2)
k=json.load(open('kuraimi.json',encoding='utf-8'))
for env,key in (('HN','holder'),('HA','account'),('HP','phone'),('HB','branch')):
    if os.environ.get(env): k[key]=os.environ[env]
json.dump(k,open('kuraimi.json','w',encoding='utf-8'),ensure_ascii=False,indent=2)
o=json.load(open('owner.json',encoding='utf-8'))
for env,key in (('WA','whatsapp'),('TG','telegram'),('EM','email'),('UT','usdt_trc20'),('EP','endpoint'),('TSS','turnstile_site'),('TSK','turnstile_secret')):
    if os.environ.get(env): o[key]=os.environ[env]
json.dump(o,open('owner.json','w',encoding='utf-8'),ensure_ascii=False,indent=2)
if os.environ.get('P'): open('ads.txt','a',encoding='utf-8').write('\nadsterra.com, %s, DIRECT\n'%os.environ['P'])
print('  ✓ حُدِّثت الملفات')
PY
bash deploy.sh main "activate $(date -u +%FT%TZ)"

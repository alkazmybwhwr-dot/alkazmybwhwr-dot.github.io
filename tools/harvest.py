#!/usr/bin/env python3
"""يجمع جهات حقيقية: عناوين شركات من قوائم/تصنيفات ويكيبيديا، ثم موقعها الرسمي عبر extlinks
   تحقّق: action=parse&prop=links  ✓   action=query&prop=extlinks  ✓   list=categorymembers ✓"""
import json,os,re,urllib.request,urllib.parse,sys,time
from concurrent.futures import ThreadPoolExecutor
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TARGET=int(os.environ.get('HARVEST_TARGET','9000'))
API='https://en.wikipedia.org/w/api.php'
UA={'User-Agent':'Mozilla/5.0 (CineHub3099 harvest; +https://%s/)'%'alkazmybwhwr-dot.github.io',
    'Accept':'application/json','Accept-Encoding':'identity'}
def jget(params,timeout=35):
    u=API+'?'+urllib.parse.urlencode(params)
    return json.loads(urllib.request.urlopen(urllib.request.Request(u,headers=UA),timeout=timeout).read().decode('utf-8','ignore'))
PAGES="""List_of_largest_companies_by_revenue List_of_largest_companies_in_the_United_States
List_of_largest_companies_in_China List_of_largest_companies_in_India List_of_largest_companies_in_Europe
List_of_largest_companies_in_Africa List_of_largest_companies_in_Asia List_of_largest_companies_in_South_America
List_of_largest_banks List_of_largest_financial_services_companies_by_revenue List_of_stock_exchanges
List_of_insurance_companies List_of_largest_employers List_of_public_corporations_by_market_capitalization
List_of_most_valuable_brands List_of_largest_Internet_companies List_of_largest_software_companies
List_of_largest_technology_companies_by_revenue List_of_largest_manufacturing_companies_by_revenue
List_of_streaming_media_services List_of_music_streaming_services List_of_record_labels
List_of_book_publishing_companies List_of_newspapers List_of_magazines List_of_television_networks
List_of_film_production_companies List_of_animation_studios List_of_video_game_publishers
List_of_video_game_developers List_of_news_agencies List_of_search_engines
List_of_social_networking_services List_of_online_marketplaces List_of_web_hosting_services
List_of_domain_registrars List_of_cloud_computing_providers List_of_content_delivery_networks
List_of_CRM_software List_of_project_management_software List_of_accounting_software
List_of_email_marketing_software List_of_web_analytics_software List_of_graphic_design_software
List_of_video_editing_software List_of_cryptocurrencies List_of_cryptocurrency_exchanges
List_of_financial_technology_companies List_of_antivirus_software List_of_password_managers
List_of_cloud_storage_services List_of_virtual_private_network_services List_of_web_browsers
List_of_airlines List_of_hotel_chains List_of_largest_hotel_companies List_of_low-cost_airlines
List_of_cruise_lines List_of_railway_companies List_of_shipping_companies List_of_airports
List_of_retailers List_of_supermarket_chains List_of_fashion_brands List_of_food_companies
List_of_beverage_companies List_of_restaurant_chains List_of_fast_food_restaurant_chains
List_of_coffee_companies List_of_pharmaceutical_companies List_of_cosmetics_companies
List_of_automobile_manufacturers List_of_computer_hardware_companies List_of_semiconductor_manufacturers
List_of_telecommunications_companies List_of_mobile_network_operators List_of_energy_companies
List_of_largest_oil_and_gas_companies List_of_mining_companies List_of_construction_companies
List_of_companies_of_Yemen List_of_companies_of_Saudi_Arabia List_of_companies_of_the_United_Arab_Emirates
List_of_companies_of_Egypt List_of_companies_of_Jordan List_of_companies_of_Turkey
List_of_companies_of_India List_of_companies_of_Indonesia List_of_companies_of_Nigeria
List_of_companies_of_Brazil List_of_companies_of_Pakistan List_of_companies_of_Malaysia
List_of_companies_of_Kenya List_of_companies_of_Morocco List_of_companies_of_Qatar
List_of_companies_of_Kuwait List_of_companies_of_Bahrain List_of_companies_of_Oman
List_of_courier_companies List_of_logistics_companies List_of_software_companies
List_of_advertising_agencies List_of_public_relations_firms""".split()
CATS="""Category:Advertising_agencies Category:Online_advertising Category:Web_hosting Category:Domain_registrars
Category:Cloud_computing_providers Category:Payment_systems Category:Cryptocurrencies Category:Payment_gateways
Category:Online_retailers Category:Online_marketplaces Category:Cashback_websites Category:Survey_research_companies
Category:Stock_photography Category:Print_on_demand Category:Music_distribution Category:Video_on_demand
Category:Freelance_marketplaces Category:Employment_websites Category:Crowdfunding_platforms
Category:Virtual_private_network_services Category:Content_management_systems Category:Email_marketing
Category:Web_analytics Category:Password_managers Category:Banks_of_Yemen Category:Companies_of_Yemen
Category:Travel_websites Category:Travel_technology_companies Category:Airline_ticket_booking_websites
Category:Hotel_chains Category:Software_companies Category:Internet_technology_companies""".split()
BLOCK=set("""wikipedia wikimedia wikidata wiktionary commons doi jstor worldcat openlibrary archive
books.google scholar.google google web.archive ghostarchive api.semanticscholar semanticscholar
opencorporates sec.gov annualreports nasdaq nyse similarweb alexa crunchbase bloomberg reuters
britannica forbes fortune cnbc cnn bbc nytimes theguardian wsj washingtonpost techcrunch theverge
hbr.org time.com variety.com hollywoodreporter musicbrainz viaf isni id.loc.gov opensecrets
geohack.toolforge toolforge.org bgp.tools baxtel pacermonitor businesswire prnewswire
glassdoor indeed linkedin facebook twitter instagram youtube tiktok pinterest reddit
about.fb.com investor.fb.com ir.aboutamazon press.aboutamazon newsroom.fb.com""".split())
def slug(s):
    s=re.sub(r'\s*\([^)]*\)','',s)
    return re.sub(r'[^a-z0-9]','',s.lower())
def dom(u):
    try: h=urllib.parse.urlparse(u).netloc.lower().split(':')[0]
    except Exception: return None
    if h.startswith('www.'): h=h[4:]
    return h or None
def core(h):
    p=h.split('.')
    return p[-2] if len(p)>=2 else p[0]
def blocked(h):
    return any(h==b or h.endswith('.'+b) for b in BLOCK)
titles=set(); errs={}
def add_titles(lst,src):
    n=0
    for t in lst:
        if t and t not in titles: titles.add(t); n+=1
    return n
for p in PAGES:
    try:
        j=jget({'action':'parse','page':p,'prop':'links','format':'json','redirects':'1'})
        ls=[x['*'] for x in ((j.get('parse') or {}).get('links') or []) if x.get('ns')==0]
        add_titles(ls,p)
    except Exception as e: errs[p]=type(e).__name__
print('  عناوين من القوائم:',len(titles),'· فشل:',len(errs))
if len(titles)<TARGET:
    for c in CATS:
        try:
            j=jget({'action':'query','list':'categorymembers','cmtitle':c,'cmlimit':'500','cmnamespace':'0','format':'json'})
            add_titles([x['title'] for x in ((j.get('query') or {}).get('categorymembers') or [])],c)
        except Exception as e: errs[c]=type(e).__name__
    print('  بعد التصنيفات:',len(titles))
TL=sorted(titles)
def links_of(batch):
    try:
        j=jget({'action':'query','prop':'extlinks','titles':'|'.join(batch),'ellimit':'500','format':'json'})
        out={}
        for k,v in ((j.get('query') or {}).get('pages') or {}).items():
            t=v.get('title') or ''
            out[t]=[x['*'] for x in (v.get('extlinks') or [])]
        return out
    except Exception: return {}
batches=[TL[i:i+50] for i in range(0,len(TL),50)]
res={}
with ThreadPoolExecutor(12) as ex:
    for r in ex.map(links_of,batches): res.update(r)
print('  صفحات لها روابط:',len(res))
found={}
for t,us in res.items():
    s=slug(t)
    if len(s)<3: continue
    best=None
    for u in us:
        h=dom(u)
        if not h or blocked(h) or '.' not in h: continue
        c=core(h)
        if len(c)<3: continue
        if c==s or (len(c)>=4 and c in s) or (len(s)>=5 and s in c):
            best=h; break
    if best: found[best]=t
print('  جهات مؤكَّدة:',len(found))
j=json.load(open(os.path.join(R,'platforms.json'),encoding='utf-8'))
have={x['u'].rstrip('/').lower() for x in j['platforms']}
hadom={dom(x['u']) for x in j['platforms'] if dom(x['u'])}
add=0
for h,t in sorted(found.items()):
    if h in hadom or ('https://'+h) in have: continue
    hadom.add(h)
    j['platforms'].append({'id':re.sub(r'[^a-z0-9]+','-',h).strip('-'),'n':t[:60],'c':'entity',
      'min':0,'p':['PayPal','Wire'],'ye':'mid','u':'https://'+h+'/','note':'موقع رسمي · ويكيبيديا',
      'model':'unknown','ref':True,'done':False,'ref_code':''})
    add+=1
j['cats'].setdefault('entity','شركات ومؤسسات (مرجع عام)')
j['total']=len(j['platforms']); j['harvested_at']=__import__('datetime').datetime.now(__import__('datetime').timezone.utc).replace(tzinfo=None).strftime('%FT%TZ')
json.dump(j,open(os.path.join(R,'platforms.json'),'w',encoding='utf-8'),ensure_ascii=False,indent=1)
json.dump({'t':j['harvested_at'],'titles':len(titles),'matched':len(found),'added':add,'errors':errs},
 open(os.path.join(R,'data','harvest-report.json'),'w',encoding='utf-8'),ensure_ascii=False,indent=1)
print('  ✓ أُضيف %d · الإجمالي %d (الهدف %d)'%(add,j['total'],TARGET))

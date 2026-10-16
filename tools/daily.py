#!/usr/bin/env python3
import os,datetime,json
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); base='https://alkazmybwhwr-dot.github.io'
urls=[]
for root,dirs,files in os.walk(R):
    if '/.git' in root: continue
    for f in files:
        if f.endswith('.html'):
            rel=os.path.relpath(os.path.join(root,f),R).replace('\\','/')
            urls.append(base+'/'+('' if rel=='index.html' else rel))
urls=sorted(set(urls)); today=datetime.date.today().isoformat()
open(os.path.join(R,'sitemap.xml'),'w',encoding='utf-8').write(
 '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
 +''.join('<url><loc>%s</loc><lastmod>%s</lastmod><changefreq>daily</changefreq></url>\n'%(u,today) for u in urls)
 +'</urlset>\n')
open(os.path.join(R,'rss.xml'),'w',encoding='utf-8').write(
 '<?xml version="1.0" encoding="UTF-8"?>\n<rss version="2.0"><channel><title>CineHub 3099</title><link>%s/</link>'
 '<description>أفلام + أرباح إعلانات حقيقية</description>'%base
 +''.join('<item><title>%s</title><link>%s</link><pubDate>%s</pubDate></item>'%(u.split('/')[-1] or 'home',u,today) for u in urls[:60])
 +'</channel></rss>\n')
print('sitemap+rss:',len(urls))

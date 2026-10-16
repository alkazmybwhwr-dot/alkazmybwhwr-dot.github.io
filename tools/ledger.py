#!/usr/bin/env python3
"""سجل مالي غير قابل للتلاعب: كل سطر يُوقّع بسلسلة هاش من السطر السابق"""
import os,json,hashlib,datetime,glob
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
D=os.path.join(R,'ledger'); os.makedirs(D,exist_ok=True)
def last(m):
    f=os.path.join(D,m+'.jsonl')
    if not os.path.exists(f): return 'GENESIS',0
    lines=[l for l in open(f,encoding='utf-8').read().split('\n') if l.strip()]
    if not lines: return 'GENESIS',0
    o=json.loads(lines[-1]); return o.get('hash','GENESIS'),len(lines)
def add(kind,amount,src='',meta=None):
    m=datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None).strftime('%Y-%m')
    prev,n=last(m)
    rec={'i':n+1,'at':datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None).strftime('%FT%TZ'),'kind':kind,
     'amount':round(float(amount),6),'src':src,'meta':meta or {},'prev':prev}
    rec['hash']=hashlib.sha256((prev+json.dumps(rec,sort_keys=True,ensure_ascii=False)).encode()).hexdigest()
    open(os.path.join(D,m+'.jsonl'),'a',encoding='utf-8').write(json.dumps(rec,ensure_ascii=False)+'\n')
    return rec
def verify():
    bad=0;tot=0
    for f in sorted(glob.glob(os.path.join(D,'*.jsonl'))):
        prev='GENESIS'
        for line in open(f,encoding='utf-8'):
            if not line.strip(): continue
            o=json.loads(line);tot+=1
            h=o.pop('hash',None)
            calc=hashlib.sha256((prev+json.dumps(o,sort_keys=True,ensure_ascii=False)).encode()).hexdigest()
            if calc!=h or o.get('prev')!=prev: bad+=1
            prev=h
    return tot,bad
if __name__=='__main__':
    t=json.load(open(os.path.join(R,'treasury.json'),encoding='utf-8')) if os.path.exists(os.path.join(R,'treasury.json')) else {}
    if t.get('total_30d'):
        add('revenue_30d',t['total_30d'],'networks',{'by_network':list((t.get('by_network') or {}).keys())})
    r=json.load(open(os.path.join(R,'revenue.json'),encoding='utf-8')) if os.path.exists(os.path.join(R,'revenue.json')) else {}
    for k,v in (r.get('networks') or {}).items():
        if v.get('revenue'): add('net_'+k,v['revenue'],k,{'imp':v.get('impressions',0)})
    tot,bad=verify()
    json.dump({'t':datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None).strftime('%FT%TZ'),'entries':tot,'broken':bad,
     'chain':'sha256'},open(os.path.join(R,'ledger-index.json'),'w',encoding='utf-8'),indent=1)
    print('ledger: %d قيد · %d مكسور'%(tot,bad))

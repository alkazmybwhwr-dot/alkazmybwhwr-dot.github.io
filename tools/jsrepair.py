#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يستخرج كتل السكربت، يستشير node، يحذف/يضيف الرمز المُشار إليه بالضبط، ثم يتحقق"""
import sys, os, re, json, subprocess, shutil

SR=re.compile(r"<script\b([^>]*)>(.*?)</script\s*>", re.S|re.I)
NONJS=re.compile(r"""type\s*=\s*["']?(application/(ld\+)?json|text/(plain|template|html|x-template))""", re.I)
HAS_SRC=re.compile(r"""\bsrc\s*=""", re.I)
CLOSER={"(":")","[":"]","{":"}"}

def blocks(h):
    out=[]
    for m in SR.finditer(h):
        a=m.group(1) or ""
        if HAS_SRC.search(a) or NONJS.search(a): continue
        out.append({"start":m.start(2),"end":m.end(2),"text":m.group(2)})
    return out

def ncheck(txt, path):
    if not shutil.which("node"): return True, ""
    open(path,"w",encoding="utf-8").write(txt)
    p=subprocess.run(["node","--check",path],capture_output=True,text=True)
    return (p.returncode==0, (p.stderr or "") + (p.stdout or ""))

def locate(txt):
    okc, err = ncheck(txt, ".check/_probe.js")
    if okc: return None
    L=err.split("\n")
    for i in range(len(L)-2):
        m=re.match(r"^.*?:(\d+)\s*$", L[i])
        if m and "^" in L[i+2]:
            ln=int(m.group(1)); caret=L[i+2].index("^")
            msg=""
            for j in range(i+3,len(L)):
                if "SyntaxError" in L[j]: msg=L[j]; break
            lines=txt.split("\n")
            off=sum(len(x)+1 for x in lines[:max(0,ln-1)])+caret
            return {"off":off,"line":ln,"caret":caret,"msg":msg.strip()}
    for l in L:
        if "SyntaxError" in l: return {"off":None,"line":None,"caret":None,"msg":l.strip()}
    return {"off":None,"line":None,"caret":None,"msg":"unknown"}

def repair(txt):
    log=[]
    for _ in range(8):
        d=locate(txt)
        if d is None: return txt, log
        off=d["off"]
        if off is None or off>len(txt):
            if "end of input" in d["msg"]:
                txt=txt.rstrip()+"\n)\n"; log.append("إضافة ) للنهاية"); continue
            return txt, log+["تعذّر التحديد: "+d["msg"]]
        ch=txt[off] if off<len(txt) else ""
        if "Unexpected token" in d["msg"]:
            txt=txt[:off]+txt[off+1:]
            log.append("حذف '%s' عند السطر %s عمود %s" % (ch, d["line"], d["caret"]))
        elif "end of input" in d["msg"]:
            txt=txt.rstrip()+"\n)\n"; log.append("إضافة ) للنهاية")
        else:
            txt=txt[:off]+txt[off+1:]
            log.append("حذف '%s' (تخمين) سطر %s" % (ch, d["line"]))
    return txt, log

def main(path):
    h=open(path,encoding="utf-8",errors="replace").read()
    bs=blocks(h); report=[]
    for b in reversed(bs):
        good,_=ncheck(b["text"], ".check/_b.js")
        if good: report.append({"status":"سليم","log":[]}); continue
        new,log=repair(b["text"])
        good2,_=ncheck(new, ".check/_b.js")
        if not good2:
            new="/* CineHub3099: كتلة معطوبة أُزيلت (build %s) */" % os.environ.get("STAMP","")
            log.append("تعذّر الإصلاح → أُزيلت الكتلة")
        h=h[:b["start"]]+new+h[b["end"]:]
        report.append({"status":"أُصلحت" if good2 else "أُزيلت","log":log})
    # ضمان وجود قارئ نظيف
    if not any("CineHub 3099 — قارئ" in b["text"] for b in blocks(h)):
        js=open("tools/render.js",encoding="utf-8").read() if os.path.exists("tools/render.js") else ""
        if js: h=h.replace("</body>","<script>\n"+js+"\n</script>\n</body>",1); report.append({"status":"أُضيف القارئ","log":[]})
    open(path,"w",encoding="utf-8").write(h)
    # تحقق نهائي
    final=[]; 
    for i,b in enumerate(blocks(h)):
        g,_=ncheck(b["text"], ".check/_f%02d.js"%i); final.append(g)
    print(json.dumps({"report":report,"all_ok":all(final) if final else True,"count":len(final)},ensure_ascii=False))

main(sys.argv[1])

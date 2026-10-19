#!/bin/zsh
# A4 行程手冊：兩段式（先印一次找頁碼，回填目錄後再印）
cd "$(dirname "$0")"
CH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
OUT="行動基地台_出海去_行程手冊_A4.pdf"
print_pdf(){ "$CH" --headless=new --disable-gpu --no-pdf-header-footer --generate-pdf-document-outline --virtual-time-budget=10000 --print-to-pdf="$PWD/$2" "file://$PWD/$1" 2>/dev/null; }
python3 - <<'PY'
import re
s=open('guide.html',encoding='utf-8').read()
# 第一次列印用的暫存檔：在每個目錄目標的標題裡塞一個隱形記號，找頁碼用
s=re.sub(r'(<(?:section|h3)[^>]*id="([^"]+)"[^>]*>)',lambda m:m.group(1)+'<span style="font-size:.5pt;color:#fff">MK%sMK</span>'%m.group(2),s)
open('_pass1.html','w',encoding='utf-8').write(s)
PY
print_pdf _pass1.html _pass1.pdf
python3 - <<'PY'
import re,subprocess
s=open('guide.html',encoding='utf-8').read()
n=int(re.search(r'Pages:\s+(\d+)',subprocess.run(['pdfinfo','_pass1.pdf'],capture_output=True,text=True).stdout).group(1))
found={}
for i in range(1,n+1):
    t=subprocess.run(['pdftotext','-f',str(i),'-l',str(i),'_pass1.pdf','-'],capture_output=True,text=True).stdout
    for k in re.findall(r'MK([A-Za-z0-9\-]+)MK',t):
        found.setdefault(k,i)
print(found)
for k,i in found.items():
    s=re.sub(r'(<span class="pn" data-target="%s">)[^<]*(</span>)'%re.escape(k),r'\g<1>%d\2'%i,s)
open('guide.html','w',encoding='utf-8').write(s)
PY
print_pdf guide.html "$OUT"
pdfinfo "$OUT" | grep -E "Pages|Page size"
rm -f _pass1.pdf _pass1.html
# 同步一份到網頁 repo（之後記得 commit、push 05_網頁）
cp "$OUT" "../05_網頁/handbook_A4.pdf"

"""Annotate original x86 Dart code; analysis only, no binary modifications."""
import json, re, subprocess, sys
from pathlib import Path
root=Path(__file__).resolve().parents[2]
(root/'evidence/research').mkdir(parents=True,exist_ok=True)
functions=json.loads((root/'evidence/docs/faithful-reconstruction/x86-functions.json').read_text())
functions.sort(key=lambda f:f['addr'])
names={f['addr']:f['name'] for f in functions}
binary=root/'evidence/original-analysis/analysis/apktool/config.x86_64/lib/x86_64/libapp.so'
for i,f in enumerate(functions[:-1]):
    if not any(term in f['name'] for term in sys.argv[1:]): continue
    raw=subprocess.check_output(['objdump','-D','-Mintel','--no-show-raw-insn',f"--start-address={f['addr']}",f"--stop-address={functions[i+1]['addr']}",str(binary)],text=True)
    raw=re.sub(r'(call\s+)([0-9a-f]+)',lambda m:m.group(0)+' ; '+names.get(int(m[2],16),'unknown'),raw)
    name=re.sub('[^a-zA-Z0-9_-]','_',f['name'])
    out=root/'evidence/research'/f'{name}.asm'
    out.write_text(raw)
    print(f['name'],hex(f['addr']),out.name)

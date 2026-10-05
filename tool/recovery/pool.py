"""Preserve and display a decoded Dart snapshot pool slot."""
import json,struct,subprocess,sys
from pathlib import Path
root=Path(__file__).resolve().parents[2]
(root/'evidence/research').mkdir(parents=True,exist_ok=True)
binary=str(root/'evidence/original-analysis/analysis/apktool/config.x86_64/lib/x86_64/libapp.so')
for requested in sys.argv[1:]:
 # r15 is a tagged ObjectPool pointer in this x86 snapshot. r2Flutter's
 # aligned PP spec is one byte above the displacement shown by objdump.
 displacement = int(requested[4:], 0) if requested.startswith('r15+') else None
 spec = f'pp+{displacement + 1:#x}' if displacement is not None else requested
 out=root/'evidence/research'/('pool-'+spec.replace('+','_').replace(':','_')+'.json')
 if out.exists():
  raw = out.read_text()
 else:
  p=subprocess.run(['/home/quantavil/.local/bin/r2flutter','-j','-O',spec,binary],text=True,capture_output=True,check=True)
  raw = p.stdout
  out.write_text(raw)
 d=json.loads(raw)
 if displacement is not None:
  slot = d.get('pp_slot', {})
  if not slot.get('resolved') or slot.get('pool_offset') != displacement:
   raise ValueError(f'Unresolved or mismatched pool lookup: {requested} -> {spec}')
 def decode(v):
  if 'fields' in v:
   fields=v['fields'];result=[];i=0
   while i<len(fields):
    f=fields[i]
    if f['kind']=='unboxed' and i+1<len(fields) and fields[i+1]['kind']=='unboxed':
     a,b=f['value'],fields[i+1]['value']
     result.append(struct.unpack('<d',struct.pack('<II',a,b))[0] if v.get('name') in ['SleepStandard','DurationStandard','WakeWindowStandard'] else a+(b<<32));i+=2
    else: result.append(decode(f.get('value',f)));i+=1
   return {v.get('name','instance'):result}
  if 'elements' in v:return [decode(e.get('value',e)) for e in v['elements']]
  return v
 print(spec,json.dumps(decode(d.get('snapshot',d))))

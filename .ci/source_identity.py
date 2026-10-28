from pathlib import Path
import hashlib
import json
import subprocess

root=Path(__file__).resolve().parent.parent
files={}
for path in sorted(root.rglob('*')):
    if path.is_file() and not any(part in ('.git','_build','.mooncakes','__pycache__') for part in path.relative_to(root).parts):
        files[path.relative_to(root).as_posix()]={'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
output=root/'_build/ci'
output.mkdir(parents=True,exist_ok=True)
(output/'source-identity.json').write_text(json.dumps({'commit':commit,'files':files},indent=2),encoding='utf-8')
print(json.dumps({'commit':commit,'sourceFiles':len(files)}))

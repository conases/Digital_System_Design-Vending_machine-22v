#!/usr/bin/env python3
import hashlib,json,pathlib
root=pathlib.Path(__file__).resolve().parents[1]
manifest=json.loads((root/'legacy/MANIFEST.json').read_text())
for line in (root/'legacy/SHA256SUMS').read_text().splitlines():
 digest,name=line.split('  ',1)
 assert hashlib.sha256((root/name).read_bytes()).hexdigest()==digest,name
private=root/'legacy/private';checked=0
for source in manifest['sources']:
 file=private/pathlib.Path(source['path']).name
 if file.exists():assert hashlib.sha256(file.read_bytes()).hexdigest()==source['sha256'];checked+=1
for item in manifest['archive_entries']:
 file=private/'archive'/item['archive_path'].removeprefix('tiny project/')
 if file.exists():assert hashlib.sha256(file.read_bytes()).hexdigest()==item['sha256'];checked+=1
print(f'PASS 공개 원본 전체 SHA-256 및 로컬 비공개 보존 {checked}개 확인')

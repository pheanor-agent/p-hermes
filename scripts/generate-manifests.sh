#!/usr/bin/env bash
#==============================================================================
# generate-manifests.sh — versions.json에서 각 버전별 _manifest.json 파생 생성
#
# SSOT 원칙: versions.json이 유일한 진실 근원.
# 이 스크립트는 versions.json을 읽어 각 버전별 _manifest.json을 자동 생성.
# _manifest.json을 직접 수정하지 마세요.
#
# Usage: generate-manifests.sh [playground_dir]
#   playground_dir 기본값: docs/playground
#
# JOB-1742: 2026-06-21 신규 작성
#==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLAYGROUND_DIR="${1:-$PROJECT_ROOT/docs/playground}"
VERSIONS_FILE="$PLAYGROUND_DIR/versions.json"

if [[ ! -f "$VERSIONS_FILE" ]]; then
    echo "❌ versions.json not found at: $VERSIONS_FILE" >&2
    exit 1
fi

echo "📦 매니페스트 생성 시작 (SSOT: $VERSIONS_FILE)"

python3 -c "
import json, os, sys

versions_file = sys.argv[1]
playground_dir = sys.argv[2]

with open(versions_file) as f:
    data = json.load(f)

for v in data.get('versions', []):
    vid = v['id']
    vpath = v['path']  # 예: 'slides-v3/gc/'
    
    manifest = {
        'version': vid,
        'label': v['label'],
        'commit': v['commit'],
        'job': v['job'],
        'releasedAt': v['releasedAt'],
        'summary': v['summary'],
        'changes': v.get('changes', []),
        'decks': []
    }
    
    # 실제 파일 스캔하여 덱 메타데이터 생성
    gc_dir = os.path.join(playground_dir, os.path.dirname(vpath))
    if os.path.isdir(gc_dir):
        for fname in sorted(os.listdir(gc_dir)):
            if fname.endswith('.html'):
                fpath = os.path.join(gc_dir, fname)
                manifest['decks'].append({
                    'name': fname.replace('.html', ''),
                    'size': os.path.getsize(fpath),
                    'path': vpath + fname
                })
    
    # _manifest.json 출력 (slides-vN/ 디렉토리에)
    out_dir = os.path.join(playground_dir, f'slides-{vid}')
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, '_manifest.json')
    
    with open(out_path, 'w') as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
    
    print(f'  ✅ slides-{vid}/_manifest.json: {len(manifest[\"decks\"])} decks')

# experiments _manifest.json 갱신 (versions.json의 experiments 배열에서)
experiments = data.get('experiments', [])
if experiments:
    exp_manifest = {
        'playground': {
            'createdAt': '2026-06-20T15:10:00+09:00',
            'basedOn': 'slides Round 7 (JOB-1696)',
            'job': 'JOB-1734',
            'experiments': []
        }
    }
    for exp in experiments:
        exp_manifest['playground']['experiments'].append({
            'id': exp['id'],
            'name': exp['name'],
            'status': 'active',
            'createdAt': exp.get('createdAt', ''),
            'summary': exp.get('summary', ''),
            'file': exp.get('file', ''),
            'appliedIn': exp.get('appliedIn', '')
        })
    
    exp_path = os.path.join(playground_dir, 'experiments', '_manifest.json')
    os.makedirs(os.path.dirname(exp_path), exist_ok=True)
    with open(exp_path, 'w') as f:
        json.dump(exp_manifest, f, indent=2, ensure_ascii=False)
    print(f'  ✅ experiments/_manifest.json: {len(experiments)} experiments')

print('📦 매니페스트 생성 완료')
" "$VERSIONS_FILE" "$PLAYGROUND_DIR"

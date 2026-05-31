#!/usr/bin/env python3
"""Check that the Java enterprise workflow skill has not absorbed benchmark answers.

Run from the standalone skill repository root:

    python3 scripts/check_java_skill_deoverfit.py

or from a monorepo containing this skill at `skills/java-enterprise-workflow`:

    JAVA_WORKFLOW_SKILL_ROOT=skills/java-enterprise-workflow python3 scripts/check_java_skill_deoverfit.py
"""
from __future__ import annotations

import os
import re
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_ROOT = SCRIPT_DIR.parent
SKILL_ROOT = Path(os.environ.get('JAVA_WORKFLOW_SKILL_ROOT', DEFAULT_ROOT)).resolve()
ALLOWLIST = {
    (SKILL_ROOT / 'references' / 'benchmark.md').resolve(),
    (SKILL_ROOT / 'scripts' / 'check_java_skill_deoverfit.py').resolve(),
}
PATTERN = re.compile(
    r'UserSyncService|TransactionalWriter|saveProfile|RemoteUserClient|getCallCount|'
    r'FakeRepository|OrderRepairJob|updateStatusIfCurrent|RepairSummary|PageCursor|'
    r'gmt_modified|AccountProfile|riskLevel|risk_level|mapper-field-propagation|'
    r'cursor-pagination-stability|repair-dryrun-batch|Benchmark reinforcement|'
    r'Synthetic / tiny fixture|Recent benchmark rounds',
    re.IGNORECASE,
)
TEXT_SUFFIXES = {'.md', '.sh', '.py', '.txt', ''}


def main() -> int:
    if not SKILL_ROOT.exists():
        print(f'skill root not found: {SKILL_ROOT}')
        return 2

    hits: list[str] = []
    for path in SKILL_ROOT.rglob('*'):
        if not path.is_file() or path.suffix not in TEXT_SUFFIXES:
            continue
        resolved = path.resolve()
        if resolved in ALLOWLIST:
            continue
        rel = path.relative_to(SKILL_ROOT).as_posix()
        for line_no, line in enumerate(path.read_text(encoding='utf-8', errors='ignore').splitlines(), 1):
            if PATTERN.search(line):
                hits.append(f'{rel}:{line_no}:{line}')

    if hits:
        print('\n'.join(hits))
        return 1
    print('de-overfit grep OK')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())

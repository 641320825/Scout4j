#!/usr/bin/env python3
# Scout4j UserPromptSubmit hook
# 根据 prompt 关键词自动注入对应的 Java 编码 checklist
#
# REFS_DIR 查找顺序：
#   1. 环境变量 SCOUT4J_REFS_DIR
#   2. ~/.claude/skills/scout4j/references  （Friday Skillhub 安装路径）
#   3. ~/.claude/scout4j/references          （直接克隆 / 开发路径）
import sys
import json
import os
import re


def find_refs_dir():
    if env_path := os.environ.get("SCOUT4J_REFS_DIR"):
        return env_path
    candidates = [
        os.path.expanduser("~/.claude/skills/scout4j/references"),
        os.path.expanduser("~/.claude/scout4j/references"),
    ]
    for path in candidates:
        if os.path.isdir(path):
            return path
    return candidates[0]  # 找不到时 fallback，load_ref 会静默失败


REFS_DIR = find_refs_dir()

# 关键词 → reference 文件映射（按优先级排列，可多命中）
RULES = [
    ("transactions.md",          r"事务|transaction|@Transactional|rollback|回滚|outbox|一致性|提交|原子"),
    ("mq-consumer.md",           r"MQ|[Mm]afka|[Kk]afka|消费|[Cc]onsumer|[Ll]istener|投递|回调|监听|幂等"),
    ("data-repair.md",           r"刷数|修复|backfill|repair|补数|历史数据|存量|全量|批量更新"),
    ("rpc-dependency.md",        r"RPC|重试|[Rr]etry|超时|timeout|下游|远程调用|[Oo]cto"),
    ("add-field.md",             r"加字段|新增字段|[Aa]dd [Ff]ield|schema变更|API变更|兼容|向前兼容"),
    ("bugfix.md",                r"[Bb]ug|报错|NPE|空指针|[Ee]xception|[Ee]rror|修复|线上问题"),
    ("add-feature.md",           r"新功能|新需求|新增接口|新增[Ee]ndpoint|开发|实现"),
    ("performance.md",           r"慢查询|性能|[Pp]erformance|分页|[Pp]agination|索引|[Ii]ndex|超时|OOM"),
    ("compatibility-rollout.md", r"灰度|[Rr]ollout|兼容|双写|开关|[Ff]eature [Ff]lag|上线"),
]


def load_ref(filename):
    path = os.path.join(REFS_DIR, filename)
    try:
        with open(path) as f:
            return f.read()
    except Exception:
        return ""


def main():
    try:
        data = json.load(sys.stdin)
        prompt = data.get("prompt", "")
    except Exception:
        return

    matched = []
    for filename, pattern in RULES:
        if re.search(pattern, prompt):
            content = load_ref(filename)
            if content:
                matched.append(f"<!-- Scout4j: {filename} -->\n{content}")

    if not matched:
        return

    context = (
        "## Java 编码参考（Scout4j 自动注入）\n\n"
        + "\n\n---\n\n".join(matched)
    )

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": context
        }
    }))


if __name__ == "__main__":
    main()

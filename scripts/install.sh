#!/usr/bin/env bash
# Scout4j install.sh
# 将 hook 脚本注册到 ~/.claude/settings.json 的 UserPromptSubmit hooks
# 幂等：已注册则跳过

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK_SRC="${SKILL_DIR}/scripts/scout4j_hook.py"
HOOK_DST="${HOME}/.claude/scripts/scout4j_hook.py"
SETTINGS="${HOME}/.claude/settings.json"

# ── 1. 拷贝 hook 脚本 ──────────────────────────────────────────────────────────
mkdir -p "$(dirname "${HOOK_DST}")"
cp "${HOOK_SRC}" "${HOOK_DST}"
chmod +x "${HOOK_DST}"
echo "✅ Hook 脚本已安装：${HOOK_DST}"

# ── 2. 注册到 settings.json ────────────────────────────────────────────────────
if [ ! -f "${SETTINGS}" ]; then
    echo "{}" > "${SETTINGS}"
fi

python3 - <<'PYEOF'
import json, sys, os

settings_path = os.path.expanduser("~/.claude/settings.json")
hook_command  = "python3 ~/.claude/scripts/scout4j_hook.py"

with open(settings_path) as f:
    settings = json.load(f)

# 确保结构存在
hooks_root = settings.setdefault("hooks", {})
ups_list   = hooks_root.setdefault("UserPromptSubmit", [])

# 幂等检查：已注册则跳过
for entry in ups_list:
    for h in entry.get("hooks", []):
        if h.get("command", "") == hook_command:
            print("ℹ️  Hook 已注册，跳过（无重复添加）")
            sys.exit(0)

# 追加
ups_list.append({
    "hooks": [
        {
            "type": "command",
            "command": hook_command,
            "timeout": 5
        }
    ]
})

with open(settings_path, "w") as f:
    json.dump(settings, f, ensure_ascii=False, indent=4)

print("✅ Hook 已注册到 UserPromptSubmit")
PYEOF

# ── 3. 完成提示 ────────────────────────────────────────────────────────────────
echo ""
echo "🎉 Scout4j 安装完成！"
echo "   - Hook 路径：${HOOK_DST}"
echo "   - References：${SKILL_DIR}/references/"
echo ""
echo "用法："
echo "   /scout4j              — 审查全量未提交改动"
echo "   /scout4j --staged     — 只审查已 staged 的改动"
echo "   /scout4j <file>       — 审查指定文件"
echo "   /scout4j <commit>     — 审查某次 commit"
echo ""
echo "Java 相关 prompt 会自动注入对应编码规范（无需手动触发）。"

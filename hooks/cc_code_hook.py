#!/usr/bin/env python3
"""
cc-code - Stop Hook 静默结算引擎 (纯脚本, 零 LLM)
=================================================
设计原则: 本脚本只做「机械活」, 绝不调用 LLM。
  - 需要理解力的写入(推进 status / 记录 errors 新坑)由 AI 在对话内顺手完成。
  - 本 Hook 唯一职责: errors.md 超长时切片到 backup/。

部署方式: **项目层级**。由 /cc-code:init 复制到 <项目>/.cc_code/scripts/,
  并在 <项目>/.claude/settings.json 注册 Stop 事件。只作用于本项目,
  不做全局注册, 因此不会误伤无关项目。

每次 Stop 触发, 毫秒级, 静默, 异常吞掉绝不阻塞 AI 回合。
"""

import sys
from datetime import datetime
from pathlib import Path

ERRORS_HOT_LIMIT = 100   # errors.md 超此行数触发切片
ERRORS_KEEP_TAIL = 50    # 切片后热区保留的尾部行数


def locate_cc_code():
    """本脚本部署在 <项目>/.cc_code/scripts/ 下, 由自身位置直接推导黑匣子根。
    不看 cwd、不向上递归 —— 因此绝无跨项目误伤。"""
    cc = Path(__file__).resolve().parent.parent
    if cc.name == ".cc_code" and (cc / "active").is_dir():
        return cc
    return None


def slice_errors(active: Path, backup: Path) -> None:
    """errors.md 超长时: 保留头部说明 + 最近条目, 中段陈年记录切到 backup/。"""
    errors = active / "errors.md"
    if not errors.exists():
        return
    lines = errors.read_text(encoding="utf-8").splitlines()
    if len(lines) <= ERRORS_HOT_LIMIT:
        return

    head_end = 0
    for i, line in enumerate(lines):
        if line.strip().startswith("## ") and i > 5:
            head_end = i
            break
    head = lines[:max(head_end, 6)]
    tail = lines[-ERRORS_KEEP_TAIL:]
    archived = lines[max(head_end, 6):-ERRORS_KEEP_TAIL]
    if not archived:
        return

    ym = datetime.now().strftime("%Y-%m")
    arc_dir = backup / ym
    arc_dir.mkdir(parents=True, exist_ok=True)
    with (arc_dir / "errors_archive.md").open("a", encoding="utf-8") as f:
        f.write(f"\n\n<!-- archived {datetime.now().strftime('%Y-%m-%d %H:%M')} -->\n")
        f.write("\n".join(archived) + "\n")

    new = "\n".join(head + ["", "<!-- 陈年记录已切片至 backup/ -->", ""] + tail) + "\n"
    errors.write_text(new, encoding="utf-8")


def main() -> int:
    try:
        sys.stdin.read()   # 消费掉 hook 输入, 避免上游 EPIPE
    except Exception:
        pass

    cc = locate_cc_code()
    if cc is None:
        return 0  # 未部署在 .cc_code/scripts/ 下, 静默退出

    try:
        slice_errors(cc / "active", cc / "backup")
    except Exception as e:
        try:
            (cc / "scripts" / "hook_error.log").open("a", encoding="utf-8").write(
                f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} {e}\n"
            )
        except Exception:
            pass
    return 0


if __name__ == "__main__":
    sys.exit(main())

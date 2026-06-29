#!/usr/bin/env python3
"""
cc_code Plugin - Stop Hook 静默结算引擎 (纯脚本, 零 LLM)
=========================================================
设计原则: 本脚本只做「机械活」, 绝不调用 LLM。
  - 需要理解力的写入(推进 status / 记录 errors 新坑)由 AI 在对话内顺手完成。
  - 本 Hook 只负责: 冷热切片 / 归档骨架 / status 过长归档 / changelog。

每次 Stop 由 Claude Code 触发, 毫秒级, 静默, 异常吞掉绝不阻塞 AI 回合。
"""

import sys
from datetime import datetime
from pathlib import Path

ERRORS_HOT_LIMIT = 100   # errors.md 超此行数触发切片
ERRORS_KEEP_HEAD = 50    # 切片后热区保留尾部行数
STATUS_MAX_LINES = 120   # status.md 超此行数归档


def find_cc_code(start: Path):
    p = start.resolve()
    for cand in [p, *p.parents]:
        cc = cand / ".cc_code"
        if cc.is_dir():
            return cc
    return None


def slice_errors(active: Path, backup: Path) -> None:
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
    tail = lines[-ERRORS_KEEP_HEAD:]
    archived = lines[max(head_end, 6):-ERRORS_KEEP_HEAD]
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


def archive_status(active: Path, backup: Path) -> None:
    status = active / "status.md"
    if not status.exists():
        return
    lines = status.read_text(encoding="utf-8").splitlines()
    if len(lines) <= STATUS_MAX_LINES:
        return
    ym = datetime.now().strftime("%Y-%m")
    arc_dir = backup / ym
    arc_dir.mkdir(parents=True, exist_ok=True)
    (arc_dir / "status_archive.md").open("a", encoding="utf-8").write(
        f"\n<!-- {datetime.now().strftime('%Y-%m-%d %H:%M')} -->\n" + "\n".join(lines) + "\n"
    )
    status.write_text(
        "# ⏱️ 当前施工快照 (status.md)\n\n> 历史快照已归档至 backup/。\n\n## 📌 当前坐标\n* [待更新]\n",
        encoding="utf-8",
    )


def touch_session_doc(docs: Path) -> None:
    today = datetime.now().strftime("%Y-%m-%d")
    (docs / today / "images").mkdir(parents=True, exist_ok=True)
    doc = docs / today / "session_skeleton.md"
    if not doc.exists():
        doc.write_text(
            f"# 会话记录 {today}\n\n- 时间：{today}\n- 角色：[待填]\n\n"
            "## 讨论内容\n\n## 完成任务\n\n## 代码变更\n\n## 遗留问题\n",
            encoding="utf-8",
        )


def append_changelog(cc: Path) -> None:
    cl = cc / "changelog.md"
    if not cl.exists():
        return
    today = datetime.now().strftime("%Y-%m-%d")
    stamp = datetime.now().strftime("%H:%M")
    with cl.open("a", encoding="utf-8") as f:
        f.write(f"\n## [{today} {stamp}] 会话结算\n- Stop Hook 静默归档完成\n")


def main() -> int:
    try:
        sys.stdin.read()
    except Exception:
        pass

    cc = find_cc_code(Path.cwd())
    if cc is None:
        return 0  # 非 cc_code 项目, 静默退出

    active, backup, docs = cc / "active", cc / "backup", cc / "docs"
    try:
        slice_errors(active, backup)
        archive_status(active, backup)
        touch_session_doc(docs)
        append_changelog(cc)
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

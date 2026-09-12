#!/usr/bin/env python3
"""Boundary guard: fails a pull request that adds what does not belong in this repository.

  python3 .github/boundary_guard.py --base <sha> --head <sha>   # in CI: files changed on the PR side
  python3 .github/boundary_guard.py --files a.cs b.md ...       # test a path list (path rules only)
  python3 .github/boundary_guard.py --scan                      # content rules over the whole tracked tree (report only)

Rules live in .github/boundary.json. No language model; the same input always gives the same verdict.
"""
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RULES = json.loads((ROOT / ".github" / "boundary.json").read_text())


def git(*args):
    return subprocess.check_output(["git", "-C", str(ROOT), *args], text=True, errors="replace")


def allowed(path):
    return any(path.startswith(p) for p in RULES.get("allow_prefixes", [])) or path in RULES.get("allow_files", [])


def path_violations(paths):
    out = []
    for path in paths:
        if allowed(path):
            continue
        for prefix in RULES.get("deny_prefixes", []):
            if path.startswith(prefix):
                out.append((path, f"path under {prefix}: {RULES['deny_prefix_reasons'].get(prefix, 'does not belong in this repository')}"))
                break
        suffix = Path(path).suffix.lower()
        if suffix in RULES.get("deny_extensions", []):
            out.append((path, f"{suffix} file: binaries, media, databases and logs stay outside Git"))
        name = Path(path).name
        for pat in RULES.get("deny_names", []):
            if re.fullmatch(pat, name):
                out.append((path, f"file name matches {pat}: not allowed here"))
    return out


def content_violations(pairs):
    out = []
    patterns = [(re.compile(r["pattern"]), r["reason"]) for r in RULES.get("deny_content", [])]
    for path, text in pairs:
        if allowed(path):
            continue
        for lineno, line in enumerate(text.splitlines(), 1):
            for rx, reason in patterns:
                if rx.search(line):
                    out.append((f"{path}:{lineno}", reason))
                    break
    return out


def grep_gate_violations(pairs):
    gate = RULES.get("grep_gate")
    if not gate:
        return []
    rx = re.compile(gate["pattern"])
    out = []
    for path, text in pairs:
        if not any(path.startswith(p) for p in gate["paths"]) or path in gate.get("allow_files", []):
            continue
        for lineno, line in enumerate(text.splitlines(), 1):
            if rx.search(line):
                out.append((f"{path}:{lineno}", gate["reason"]))
                break
    return out


def changed(base, head):
    paths = []
    for line in git("diff", "--name-status", f"{base}...{head}").splitlines():
        parts = line.split("\t")
        status = parts[0][0]
        if status == "D":
            continue
        paths.append(parts[-1])
    return paths


def head_text(head, path):
    try:
        blob = subprocess.check_output(["git", "-C", str(ROOT), "show", f"{head}:{path}"], stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        return None
    if len(blob) > 2_000_000 or b"\0" in blob[:8000]:
        return None
    return blob.decode("utf-8", errors="replace")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base")
    ap.add_argument("--head")
    ap.add_argument("--files", nargs="*")
    ap.add_argument("--scan", action="store_true")
    a = ap.parse_args()
    if a.files is not None:
        problems = path_violations(a.files)
    elif a.scan:
        paths = git("ls-files").splitlines()
        pairs = [(p, t) for p in paths if (t := head_text("HEAD", p)) is not None]
        problems = content_violations(pairs) + grep_gate_violations(pairs)
    elif a.base and a.head:
        paths = changed(a.base, a.head)
        pairs = [(p, t) for p in paths if (t := head_text(a.head, p)) is not None]
        problems = path_violations(paths) + content_violations(pairs) + grep_gate_violations(pairs)
        print(f"Boundary guard checked {len(paths)} changed files.")
    else:
        ap.error("use --base/--head, --files, or --scan")
    for where, why in problems:
        print(f"BLOCK {where}: {why}")
    if problems:
        print(f"{len(problems)} problem(s). See REVIEW.md for what belongs in this repository.")
        sys.exit(1)
    print("Boundary guard: clean.")


if __name__ == "__main__":
    main()

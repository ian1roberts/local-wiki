from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
import re


_PLACEHOLDER_PATTERN = re.compile(r"\{\{(\w+)\}\}")


@dataclass(frozen=True)
class NewPageArgs:
    root: str
    parent: str
    filename: str
    title: str
    description: str = ""
    tags: str = ""
    template: str = "src/_templates/page.md"
    force: bool = False


def slugify(name: str) -> str:
    name = name.strip().lower()
    name = re.sub(r"[^\w\s-]", "", name)
    name = re.sub(r"[\s_]+", "-", name)
    name = re.sub(r"-{2,}", "-", name).strip("-")
    return name or "new-page"


def _render_template(template_text: str, values: dict[str, str]) -> str:
    def repl(match: re.Match[str]) -> str:
        key = match.group(1)
        return values.get(key, match.group(0))

    return _PLACEHOLDER_PATTERN.sub(repl, template_text)


def create_new_page(args: NewPageArgs) -> str:
    root = Path(args.root).resolve()
    src_dir = root / "src"
    template_path = root / args.template

    if not src_dir.exists():
        raise FileNotFoundError(f"Expected src dir not found: {src_dir}")
    if not template_path.exists():
        raise FileNotFoundError(f"Template not found: {template_path}")

    parent_rel = Path(args.parent)
    if parent_rel.is_absolute() or ".." in parent_rel.parts:
        raise ValueError("Parent must be a safe relative path under src/")

    filename = args.filename.strip()
    if not filename.lower().endswith(".md"):
        filename += ".md"

    stem = Path(filename).stem
    safe_stem = slugify(stem)

    out_path = (src_dir / parent_rel / f"{safe_stem}.md").resolve()
    if not str(out_path).startswith(str(src_dir.resolve())):
        raise ValueError("Output path escaped src/")

    out_path.parent.mkdir(parents=True, exist_ok=True)

    if out_path.exists() and not args.force:
        raise FileExistsError(f"File already exists: {out_path}")

    template_text = template_path.read_text(encoding="utf-8")
    tags = [t.strip() for t in args.tags.split(",") if t.strip()]

    values = {
        "title": args.title.strip(),
        "description": args.description.strip(),
        "date": datetime.now().strftime("%Y-%m-%d"),
        "slug": safe_stem,
        "tags": ", ".join(tags) if tags else "",
    }

    rendered = _render_template(template_text, values)
    out_path.write_text(rendered, encoding="utf-8", newline="\n")

    return str(out_path)

#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sys

from .new_page import create_new_page, NewPageArgs


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="wiki",
        description="Local-wiki helper CLI (page scaffolding, checks, utilities).",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    # ---- new-page ----
    p_new = subparsers.add_parser(
        "new-page",
        help="Create a new markdown page from a template.",
    )
    p_new.add_argument(
        "--root",
        default=".",
        help="Repo root (default: current directory).",
    )
    p_new.add_argument(
        "--parent",
        required=True,
        help="Parent folder under src (e.g. linux/ssh).",
    )
    p_new.add_argument(
        "--filename",
        required=True,
        help="Filename (with or without .md).",
    )
    p_new.add_argument(
        "--title",
        required=True,
        help="Page title.",
    )
    p_new.add_argument(
        "--description",
        default="",
        help="Short description (optional).",
    )
    p_new.add_argument(
        "--tags",
        default="",
        help="Comma-separated tags (optional).",
    )
    p_new.add_argument(
        "--template",
        default="src/_templates/page.md",
        help="Template path relative to repo root (default: src/_templates/page.md).",
    )
    p_new.add_argument(
        "--force",
        action="store_true",
        help="Overwrite if file already exists.",
    )

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    if args.command == "new-page":
        page_args = NewPageArgs(
            root=args.root,
            parent=args.parent,
            filename=args.filename,
            title=args.title,
            description=args.description,
            tags=args.tags,
            template=args.template,
            force=args.force,
        )
        created_path = create_new_page(page_args)
        # Print path for tasks/CI logs
        print(created_path)
        return 0

    parser.error(f"Unknown command: {args.command}")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())

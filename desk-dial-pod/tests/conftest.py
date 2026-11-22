"""Tests run from this project folder: repo_path() resolves against it."""
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent


def repo_path(*parts):
    return str(PROJECT.joinpath(*parts))

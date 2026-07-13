"""Regression tests for the Deck A/B contract normalizer."""
from __future__ import annotations

import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCRIPT = PROJECT_ROOT / "src" / "normalize-lecture-deck-contract.py"
DECK_DIR = PROJECT_ROOT / "docs" / "playground" / "lectures" / "v8"
DECKS = ("deck-c-skill.html", "deck-d-workflow.html")


class ContractNormalizerRegressionTests(unittest.TestCase):
    def normalize_in_sandbox(self) -> dict[str, str]:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            script_path = root / "src" / SCRIPT.name
            script_path.parent.mkdir(parents=True)
            shutil.copy2(SCRIPT, script_path)
            deck_dir = root / "docs" / "playground" / "lectures" / "v8"
            deck_dir.mkdir(parents=True)
            for name in DECKS:
                shutil.copy2(DECK_DIR / name, deck_dir / name)
            subprocess.run(["python3", str(script_path)], check=True, capture_output=True, text=True)
            return {name: (deck_dir / name).read_text() for name in DECKS}

    def test_mouse_hover_keeps_focusable_items_clickable(self) -> None:
        decks = self.normalize_in_sandbox()
        for name, html in decks.items():
            self.assertIn(
                ".slide.mouse-hovering [data-focusable].in-focus { outline:none; box-shadow:none; pointer-events:auto; }",
                html,
                name,
            )

    def test_generated_navigation_avoids_scroll_into_view_snap_conflict(self) -> None:
        for deck in ("deck-c-skill.html", "deck-d-workflow.html"):
            html = (DECK_DIR / deck).read_text()
            self.assertNotIn("scrollIntoView(", html)

        source = SCRIPT.read_text()
        self.assertIn(
            "re.sub(r'<br\\s*/?>', ' ', heading_html, flags=re.I)",
            source,
        )


if __name__ == "__main__":
    unittest.main()

#!/usr/bin/env python3
"""Generate the Cowboy theme's original small SVG assets (MIT, no downloads)."""

from pathlib import Path
import random


def generate():
    folder = Path(__file__).resolve().parent
    rng = random.Random(1876)
    wood = [
        '<svg xmlns="http://www.w3.org/2000/svg" width="440" height="80" viewBox="0 0 440 80">',
        '<defs><linearGradient id="wood" x2="0" y2="1">',
        '<stop stop-color="#ad814d"/><stop offset=".24" stop-color="#8e623a"/>',
        '<stop offset=".7" stop-color="#795133"/><stop offset="1" stop-color="#5b3c27"/>',
        '</linearGradient><clipPath id="edge"><path d="M4 5 L51 3 98 5 134 2 201 4 265 2 330 5 381 3 435 5 438 27 434 34 439 45 436 75 390 77 332 75 291 78 232 75 171 78 119 75 59 78 4 75 2 53 6 46 1 37Z"/></clipPath></defs>',
        '<g clip-path="url(#edge)">',
        '<path d="M0 0H440V80H0Z" fill="url(#wood)"/>',
    ]
    for i in range(32):
        y = 3 + i * 2.35
        x = rng.randint(-50, 90)
        end = rng.randint(330, 480)
        bend = rng.uniform(-3, 3)
        color = "#e2b777" if i % 4 == 0 else "#362314"
        wood.append(
            f'<path d="M{x} {y:.2f} C130 {y+bend:.2f} 258 {y-bend:.2f} {end} {y:.2f}" '
            f'fill="none" stroke="{color}" stroke-width="{rng.uniform(.35, 1):.2f}" opacity="{rng.uniform(.13, .3):.2f}"/>'
        )
    for cx, cy in [(117, 48), (341, 25)]:
        for radius in [5, 10, 17, 25]:
            wood.append(
                f'<ellipse cx="{cx}" cy="{cy}" rx="{radius}" ry="{radius*.22:.2f}" '
                'fill="none" stroke="#322015" stroke-width=".9" opacity=".36"/>'
            )
        wood.append(f'<ellipse cx="{cx}" cy="{cy}" rx="3" ry="1.5" fill="#352216" opacity=".8"/>')
    wood += [
        '<path d="M4 6L437 6M6 73L434 73" stroke="#e9bf7b" opacity=".2"/>',
        '<path d="M1 20L59 22 84 20M438 58L394 55 373 57" fill="none" stroke="#382317" stroke-width="1.3" opacity=".65"/>',
    ]
    for x in [16, 424]:
        wood.append(
            f'<circle cx="{x+1}" cy="41" r="5" fill="#302216" opacity=".5"/>'
            f'<circle cx="{x}" cy="39" r="4" fill="#6c6250" stroke="#302b24" stroke-width="1.1"/>'
            f'<path d="M{x-2} 38L{x+2} 40" stroke="#b6a47d" stroke-width="1.2"/>'
        )
    wood.append("</g></svg>")
    (folder / "CowboyWood.svg").write_text("\n".join(wood) + "\n")
    hole = """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
<path d="M31 2L35 20 45 9 42 24 60 20 47 32 61 42 43 41 48 59 34 47 25 62 24 46 7 53 16 37 2 29 20 26 15 8 28 20Z" fill="#c19a62"/>
<path d="M31 12L35 25 43 18 40 28 51 28 42 35 48 46 36 41 29 52 26 40 15 43 21 33 13 26 26 27Z" fill="#593a22"/>
<path d="M26 22L35 20 42 28 41 38 33 44 24 39 21 30Z" fill="#19130e"/>
<path d="M27 24L35 22 40 29" fill="none" stroke="#0d0b09" stroke-width="2"/>
<path d="M24 39L33 44 41 38" fill="none" stroke="#dfbb80" stroke-width="1.5"/>
</svg>
"""
    (folder / "CowboyHole.svg").write_text(hole)


if __name__ == "__main__":
    generate()

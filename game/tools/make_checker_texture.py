#!/usr/bin/env python3
"""
make_checker_texture.py: draws game/assets/checker_studs.png, the tile texture that gives the
map Steal An Egg's look (a two-tone checkerboard with a classic stud on every stud).

The image is mostly TRANSPARENT, so the part's own colour shows through:
  * light squares are clear, dark squares are black at low alpha (they darken the part colour)
  * every stud gets a soft round highlight (top-left) and shadow (bottom-right)
One image covers 2 x 2 squares of TILE_STUDS studs each. MapBuilder applies it as a Texture
with StudsPerTileU/V = 2 * TILE_STUDS (AreasConfig.Style), so it fits any part colour.

Usage: python3 tools/make_checker_texture.py   (needs Pillow)
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

TILE_STUDS = 4          # one checker square = 4 x 4 studs
PX_PER_STUD = 64
DARK_ALPHA = 38         # how much the dark squares darken (0-255)
SIZE = 2 * TILE_STUDS * PX_PER_STUD   # 512

OUT = Path(__file__).resolve().parent.parent / "assets" / "checker_studs.png"


def main():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    tile = TILE_STUDS * PX_PER_STUD
    checker = ImageDraw.Draw(img)
    for ty in range(2):
        for tx in range(2):
            if (tx + ty) % 2 == 1:
                checker.rectangle([tx * tile, ty * tile, (tx + 1) * tile - 1, (ty + 1) * tile - 1], fill=(0, 0, 0, DARK_ALPHA))

    # Studs: drawn on separate layers so they can be blurred into soft bumps
    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    light = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ds, dl = ImageDraw.Draw(shadow), ImageDraw.Draw(light)
    r = PX_PER_STUD * 0.27
    for sy in range(2 * TILE_STUDS):
        for sx in range(2 * TILE_STUDS):
            cx = (sx + 0.5) * PX_PER_STUD
            cy = (sy + 0.5) * PX_PER_STUD
            ds.ellipse([cx - r + 2, cy - r + 3, cx + r + 2, cy + r + 3], fill=(0, 0, 0, 55))
            dl.ellipse([cx - r - 1, cy - r - 1, cx + r - 1, cy + r - 1], fill=(255, 255, 255, 26))
    shadow = shadow.filter(ImageFilter.GaussianBlur(2))
    light = light.filter(ImageFilter.GaussianBlur(1))
    img = Image.alpha_composite(img, shadow)
    img = Image.alpha_composite(img, light)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT)
    print(f"Wrote {OUT} ({SIZE}x{SIZE})")


if __name__ == "__main__":
    main()

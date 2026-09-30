"""Generates the Splash GenX app and installer icon.

Run: python3 tool/make_icon.py  (needs Pillow)
Writes windows/runner/resources/app_icon.ico and assets/icon/app_icon.png.
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

S = 1024 * 2  # supersampled canvas
ROOT = Path(__file__).resolve().parent.parent

STOPS = [(0.0, (124, 58, 237)), (0.5, (236, 72, 153)), (1.0, (245, 158, 11))]


def lerp_colour(t):
    for (t0, c0), (t1, c1) in zip(STOPS, STOPS[1:]):
        if t <= t1:
            k = (t - t0) / (t1 - t0)
            return tuple(round(a + (b - a) * k) for a, b in zip(c0, c1))
    return STOPS[-1][1]


def gradient():
    # Diagonal gradient, top-left violet to bottom-right amber.
    small = Image.new("RGB", (256, 256))
    px = small.load()
    for y in range(256):
        for x in range(256):
            px[x, y] = lerp_colour((x + y) / 510)
    return small.resize((S, S), Image.BICUBIC)


def sparkle(draw, cx, cy, r, inner, fill):
    points = []
    for i in range(8):
        a = -math.pi / 2 + i * math.pi / 4
        rad = r if i % 2 == 0 else inner
        points.append((cx + rad * math.cos(a), cy + rad * math.sin(a)))
    draw.polygon(points, fill=fill)


def main():
    icon = Image.new("RGBA", (S, S), (0, 0, 0, 0))

    # Rounded-square tile with the gradient.
    margin = int(S * 0.04)
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (margin, margin, S - margin, S - margin), radius=int(S * 0.22), fill=255
    )
    icon.paste(gradient(), (0, 0), mask)

    # Soft glow behind the centre.
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    c = S / 2
    ImageDraw.Draw(glow).ellipse(
        (c - S * 0.26, c - S * 0.26, c + S * 0.26, c + S * 0.26),
        fill=(255, 255, 255, 90),
    )
    glow = glow.filter(ImageFilter.GaussianBlur(S * 0.06))
    icon.alpha_composite(Image.composite(glow, Image.new("RGBA", (S, S)), mask))

    draw = ImageDraw.Draw(icon)
    # Safe-zone circle guide.
    r = S * 0.33
    draw.ellipse((c - r, c - r, c + r, c + r), outline=(255, 255, 255, 235), width=int(S * 0.035))
    # Big sparkle plus two small ones.
    sparkle(draw, c, c, S * 0.22, S * 0.06, (255, 255, 255, 255))
    sparkle(draw, c + S * 0.25, c - S * 0.25, S * 0.07, S * 0.02, (255, 244, 214, 255))
    sparkle(draw, c - S * 0.24, c + S * 0.26, S * 0.05, S * 0.015, (255, 228, 240, 255))

    final = icon.resize((1024, 1024), Image.LANCZOS)
    png = ROOT / "assets/icon/app_icon.png"
    png.parent.mkdir(parents=True, exist_ok=True)
    final.save(png)
    final.save(
        ROOT / "windows/runner/resources/app_icon.ico",
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
    )


if __name__ == "__main__":
    main()

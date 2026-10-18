#!/usr/bin/env python3
"""One logo PNG in, every icon this project ships out.

Source of truth: `assets/branding/logo_source.png` — the client's artwork, the
teal ring with the orange dot on a white page. Everything else is generated
from it:

    assets/images/logo.png                     splash screen (in-app)
    android/.../drawable-nodpi/launch_logo.png native launch window
    android/.../mipmap-*/ic_launcher.png       Android launcher, 5 densities
    android/.../drawable-*/ic_launcher_foreground.png   Android 8+ adaptive
    ios/.../AppIcon.appiconset/*.png           iOS, 15 sizes, no alpha
    web/icons/*, web/favicon.png               PWA + browser tab

White is removed by un-premultiplying it out of every pixel, so the
anti-aliased edge of the ring stays smooth instead of getting a pale halo.

    python3 tools/make_icons.py            # write everything
    python3 tools/make_icons.py --check    # report only, touch nothing

Launcher style
--------------
`STYLE = "original"` keeps the artwork exactly as designed: teal ring on a
white tile. `STYLE = "on_teal"` draws the same ring in white on the brand teal
(#006B5C) — more contrast on a light wallpaper and at 48px. Both are generated
from the same file; switching is one line.
"""
from __future__ import annotations

import argparse
import pathlib
import sys

import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / "assets/branding/logo_source.png"

ANDROID = ROOT / "android/app/src/main/res"
IOS = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
WEB = ROOT / "web"

WHITE = (255, 255, 255)
DEEP = (0, 107, 92)      # AppTheme.primary
TEAL_HUE = 173.0

STYLE = "original"       # "original" or "on_teal"

# Android legacy launcher icons (pre-API 26), in px.
LEGACY = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
# Adaptive foreground: a 108dp canvas whose visible area is the middle 72dp, so
# the mark must sit inside ~66% or the circle/squircle mask clips it.
ADAPTIVE = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}


def strip_white(image: Image.Image) -> Image.Image:
    """White background -> transparent, without a halo.

    A pixel that is a blend of colour C and white is  P = a*C + (1-a)*255.
    Taking a = 1 - min(P)/255 recovers the coverage, and C = (P-(1-a)*255)/a
    recovers the original colour. Round-tripping that over white is exact,
    which is what keeps the edges smooth.
    """
    rgb = np.asarray(image.convert("RGB")).astype(np.float32)
    alpha = 1.0 - rgb.min(axis=2) / 255.0
    alpha[alpha < 0.02] = 0.0                      # kill paper noise
    safe = np.where(alpha > 0, alpha, 1.0)
    colour = (rgb - (1.0 - alpha)[..., None] * 255.0) / safe[..., None]
    out = np.dstack([np.clip(colour, 0, 255), alpha * 255.0]).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def whiten_ring(art: Image.Image) -> Image.Image:
    """Turn the teal ring white, keep the orange dot exactly as it is."""
    px = np.asarray(art).astype(np.float32)
    rgb, alpha = px[..., :3], px[..., 3:] / 255.0
    m = rgb / 255.0
    mx, mn = m.max(axis=2), m.min(axis=2)
    delta = mx - mn
    r, g, b = m[..., 0], m[..., 1], m[..., 2]

    hue = np.zeros_like(mx)
    valid = delta > 1e-6
    idx = (mx == r) & valid
    hue[idx] = (60 * ((g[idx] - b[idx]) / delta[idx])) % 360
    idx = (mx == g) & valid
    hue[idx] = 60 * ((b[idx] - r[idx]) / delta[idx]) + 120
    idx = (mx == b) & valid
    hue[idx] = 60 * ((r[idx] - g[idx]) / delta[idx]) + 240
    sat = np.where(mx > 1e-6, delta / np.maximum(mx, 1e-6), 0)

    teal = (np.abs(((hue - TEAL_HUE + 180) % 360) - 180) < 28) & (sat > 0.25)
    rgb[teal] = 255.0
    return Image.fromarray(np.dstack([rgb, alpha * 255.0]).astype(np.uint8), "RGBA")


def square_master(art: Image.Image) -> Image.Image:
    """Crop to the artwork and pad it back to a transparent square."""
    bbox = art.split()[-1].point(lambda v: 255 if v > 12 else 0).getbbox()
    if bbox is None:
        raise SystemExit("source image looks blank — nothing to cut out")
    art = art.crop(bbox)
    side = max(art.size)
    pad = int(side * 0.04)
    canvas = Image.new("RGBA", (side + 2 * pad, side + 2 * pad), (0, 0, 0, 0))
    canvas.paste(art, ((canvas.width - art.width) // 2,
                       (canvas.height - art.height) // 2))
    return canvas


def render(master: Image.Image, size: int, fill: float,
           background: tuple[int, int, int] | None) -> Image.Image:
    """Place the mark at `fill` of a `size` square, on a solid or no background."""
    inner = max(1, int(round(size * fill)))
    mark = master.resize((inner, inner), Image.LANCZOS)
    canvas = (Image.new("RGBA", (size, size), (0, 0, 0, 0)) if background is None
              else Image.new("RGBA", (size, size), background + (255,)))
    canvas.alpha_composite(mark, ((size - inner) // 2, (size - inner) // 2))
    return canvas


def save(image: Image.Image, path: pathlib.Path, dry: bool) -> None:
    if dry:
        print(f"  ~ {path.relative_to(ROOT)}  {image.width}x{image.height}")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)
    print(f"  ✓ {path.relative_to(ROOT)}  {image.width}x{image.height}")


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Generate every app icon from one PNG.")
    parser.add_argument("--source", default=str(SOURCE))
    parser.add_argument("--check", action="store_true", help="report only")
    parser.add_argument("--style", choices=["original", "on_teal"], default=STYLE)
    args = parser.parse_args(argv[1:])

    source = pathlib.Path(args.source)
    if not source.exists():
        print(f"Source not found: {source}")
        return 2

    dry = args.check
    art = strip_white(Image.open(source))

    # Two masters from one artwork:
    #   splash — exactly as the designer drew it (teal ring, orange dot)
    #   icon   — same shape, ring recoloured white when the tile is teal
    splash_master = square_master(art)
    icon_master = square_master(whiten_ring(art) if args.style == "on_teal" else art)
    tile_bg = DEEP if args.style == "on_teal" else WHITE
    print(f"Master: {icon_master.width}x{icon_master.height}   "
          f"launcher style: {args.style}\n")

    # 1. In-app asset (splash screen) + native launch window.
    save(render(splash_master, 512, 1.0, None), ROOT / "assets/images/logo.png", dry)
    save(render(splash_master, 384, 0.92, None),
         ANDROID / "drawable-nodpi/launch_logo.png", dry)

    # 2. Android legacy icons — the tile fills the square edge to edge, so the
    #    launcher's own mask never leaves a bare corner.
    print("Android launcher (legacy):")
    for density, size in LEGACY.items():
        icon = render(icon_master, size, 0.86, tile_bg).convert("RGB")
        save(icon, ANDROID / f"mipmap-{density}/ic_launcher.png", dry)

    # 3. Android 8+ adaptive icon: the same artwork as the foreground, on the
    #    background colour declared in ic_launcher.xml. 60% keeps it inside
    #    every mask (a circle crops ~12% off a square's corners).
    print("Android adaptive foreground:")
    for density, size in ADAPTIVE.items():
        save(render(icon_master, size, 0.60, None),
             ANDROID / f"drawable-{density}/ic_launcher_foreground.png", dry)

    # 4. iOS — App Store rejects icons with an alpha channel, so flatten it.
    print("iOS AppIcon:")
    for path in sorted(IOS.glob("Icon-App-*.png")):
        stem = path.stem                      # Icon-App-1024x1024@1x
        dims, scale = stem.replace("Icon-App-", "").split("@")
        size = int(round(float(dims.split("x")[0]) * int(scale.replace("x", ""))))
        icon = render(icon_master, size, 0.84, tile_bg).convert("RGB")
        save(icon, path, dry)

    # 5. Web / PWA.
    print("Web:")
    save(render(icon_master, 192, 0.86, tile_bg).convert("RGB"),
         WEB / "icons/Icon-192.png", dry)
    save(render(icon_master, 512, 0.86, tile_bg).convert("RGB"),
         WEB / "icons/Icon-512.png", dry)
    save(render(icon_master, 192, 0.60, tile_bg).convert("RGB"),
         WEB / "icons/Icon-maskable-192.png", dry)
    save(render(icon_master, 512, 0.60, tile_bg).convert("RGB"),
         WEB / "icons/Icon-maskable-512.png", dry)
    save(render(icon_master, 32, 0.92, tile_bg).convert("RGB"), WEB / "favicon.png", dry)

    print("\nDone. Rebuild for the launcher icon to change "
          "(`flutter clean` first — Android caches mipmaps).")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

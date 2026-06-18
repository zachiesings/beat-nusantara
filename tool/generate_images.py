#!/usr/bin/env python3
"""
Beat Nusantara — placeholder art generator (pure stdlib, no PIL).
Writes a 1024 app icon + 600px song covers as PNGs via a hand-rolled encoder.
All art is original geometric/gradient work (license-safe).
  python3 tool/generate_images.py
"""
import math, os, struct, zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def write_png(path, w, h, rgba_fn):
    raw = bytearray()
    for y in range(h):
        raw.append(0)  # filter type 0
        for x in range(w):
            r, g, b, a = rgba_fn(x, y)
            raw += bytes((r & 255, g & 255, b & 255, a & 255))

    def chunk(tag, data):
        c = tag + data
        return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c) & 0xffffffff)

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(png)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def make_icon(path, size=1024, c1=(124, 58, 237), c2=(236, 72, 153), c3=(34, 211, 238)):
    cx, cy = size / 2, size / 2
    R = size * 0.46

    def px(x, y):
        # diagonal gradient background
        t = (x + y) / (2 * size)
        bg = lerp(c1, c2, t)
        dx, dy = x - cx, y - cy
        d = math.sqrt(dx * dx + dy * dy)
        # rounded-square mask (superellipse-ish)
        m = (abs(x - cx) / R) ** 4 + (abs(y - cy) / R) ** 4
        if m > 1.0:
            return (10, 10, 24, 0)
        col = list(bg)
        # concentric neon pulse rings
        for ring in (0.34, 0.48, 0.62):
            rr = ring * size
            if abs(d - rr) < size * 0.012:
                col = list(lerp(tuple(col), c3, 0.85))
        # four falling "lane" bars in the lower middle
        for i, lx in enumerate((-0.21, -0.07, 0.07, 0.21)):
            bx = cx + lx * size
            if abs(x - bx) < size * 0.028 and y > cy - size * 0.05:
                glow = (255, 255, 255)
                fade = max(0.0, 1 - (y - (cy - size * 0.05)) / (size * 0.5))
                col = list(lerp(tuple(col), glow, 0.5 * fade + 0.2))
        # central play triangle
        tx = (x - cx) / size
        ty = (y - cy) / size
        if -0.10 < tx < 0.12 and abs(ty) < (0.13 - 0.9 * (tx + 0.10)):
            col = [255, 255, 255]
        return (col[0], col[1], col[2], 255)

    write_png(path, size, size, px)


def make_cover(path, size, base, accent):
    cx, cy = size / 2, size / 2

    def px(x, y):
        t = (x + 0.3 * y) / (1.3 * size)
        col = list(lerp(base, accent, t))
        dx, dy = x - cx, y - cy
        d = math.sqrt(dx * dx + dy * dy)
        # waveform-ish horizontal neon line
        wave = cy + math.sin(x / size * math.pi * 6) * size * 0.06
        if abs(y - wave) < size * 0.012:
            col = list(lerp(tuple(col), (255, 255, 255), 0.8))
        for rr in (0.3 * size, 0.42 * size):
            if abs(d - rr) < size * 0.008:
                col = list(lerp(tuple(col), (255, 255, 255), 0.35))
        return (col[0], col[1], col[2], 255)

    write_png(path, size, size, px)


PALETTES = {
    # batik tones (base -> accent), one per song
    "senja_jakarta":   ((120, 40, 60), (242, 183, 60)),
    "gamelan_pulse":   ((16, 84, 76), (242, 183, 60)),
    "koplo_neon":      ((150, 48, 64), (232, 116, 76)),
    "melati_senja":    ((75, 60, 160), (231, 106, 147)),
    "hujan_neon":      ((60, 70, 150), (47, 169, 135)),
    "sambal_bass":     ((140, 56, 44), (242, 183, 60)),
    "goyang_galaksi":  ((150, 48, 64), (242, 183, 60)),
    "sasando_drift":   ((24, 96, 90), (242, 183, 60)),
    "angklung_arcade": ((30, 110, 88), (252, 214, 117)),
    "tokyo_kilat":     ((70, 60, 160), (232, 116, 76)),
    "seoul_mirror":    ((110, 70, 180), (47, 169, 135)),
    "midnight_avenue": ((52, 56, 130), (242, 183, 60)),
    "concrete_flow":   ((64, 44, 44), (242, 183, 60)),
    "voltage":         ((58, 50, 150), (232, 116, 76)),
    "deep_jakarta":    ((40, 48, 120), (47, 169, 135)),
    "phonk_pasar":     ((90, 36, 56), (232, 116, 76)),
    "hyper_melati":    ((180, 64, 120), (252, 214, 117)),
    "ombak_tenang":    ((20, 80, 92), (116, 216, 176)),
    "kopi_pagi":       ((120, 60, 50), (242, 183, 60)),
    "garuda_rising":   ((130, 36, 52), (242, 183, 60)),
    "locked":          ((40, 28, 52), (90, 80, 110)),
}


def main():
    make_icon(os.path.join(ROOT, "assets/icon/app_icon.png"))
    for name, (b, a) in PALETTES.items():
        make_cover(os.path.join(ROOT, "assets/images", "cover_%s.png" % name), 600, b, a)
    print("Wrote app_icon.png + %d covers" % len(PALETTES))


if __name__ == "__main__":
    main()

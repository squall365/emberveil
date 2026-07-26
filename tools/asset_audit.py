#!/usr/bin/env python3
"""
EMBERVEIL — Asset Budget Audit (checklist E ⛔, art-bible §9.4).

Enforces, in CI, the hard web/HTML5 texture budget:
  * total DECODED texture memory <= --max-decoded-mb  (default 16 MB = w*h*4 bytes)
  * at most --max-atlases 1024² atlases               (default 4)
  * exactly one shared 128² grain atlas              (filename contains 'grain')
  * format restricted to WebP / PNG only             (no JPG)

Pure stdlib (no Pillow) — parses PNG IHDR and WebP VP8X/VP8L/VP8 headers for dimensions.
Exits non-zero on any violation so the GitHub Actions pipeline fails the build.

Usage:
    python3 tools/asset_audit.py [--root content --root assets]
                                [--max-decoded-mb 16] [--max-atlases 4]
                                [--grain-name grain] [--grain-size 128]
"""
import argparse
import os
import sys

MB = 1024 * 1024
ALLOWED_EXT = {".png", ".webp"}
FORBIDDEN_EXT = {".jpg", ".jpeg", ".bmp", ".gif", ".tga"}


def png_dimensions(data: bytes):
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    w = int.from_bytes(data[16:20], "big")
    h = int.from_bytes(data[20:24], "big")
    return w, h


def webp_dimensions(data: bytes):
    if data[:4] != b"RIFF" or data[8:12] != b"WEBP":
        raise ValueError("not a WebP")
    chunk = data[12:16]
    payload = data[20:]  # chunk header (8) + RIFF(12) => payload at 20
    if chunk == b"VP8X":
        # width-1 / height-1 are 24-bit LE at payload[4:7] / payload[7:10]
        w = int.from_bytes(payload[4:7], "little") + 1
        h = int.from_bytes(payload[7:10], "little") + 1
        return w, h
    if chunk == b"VP8L":
        # lossless: 1-byte sig 0x2f, then 14-bit w-1 (LE) + 14-bit h-1 (LE)
        w = (payload[1] | ((payload[2] & 0x3F) << 8)) + 1
        h = (((payload[2] & 0xC0) >> 6) | (payload[3] << 2) |
             ((payload[4] & 0x03) << 10)) + 1
        return w, h
    if chunk == b"VP8 ":
        # lossy keyframe: 3-byte start code + 1 header byte, then 14-bit w/h (LE)
        if payload[0:3] != b"\x9d\x01\x2a":
            raise ValueError("unsupported lossy VP8 frame")
        w = ((payload[5] << 8) | payload[4]) & 0x3FFF
        h = ((payload[7] << 8) | payload[6]) & 0x3FFF
        return w, h
    raise ValueError("unsupported WebP chunk %r (export as VP8X/VP8L)" % chunk)


def dimensions(path: str):
    with open(path, "rb") as f:
        head = f.read(64)
    ext = os.path.splitext(path)[1].lower()
    if ext == ".png":
        return png_dimensions(head)
    if ext == ".webp":
        return webp_dimensions(head)
    raise ValueError("unhandled ext %s" % ext)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", action="append", default=["content", "assets"],
                    help="directories to scan (repeatable)")
    ap.add_argument("--max-decoded-mb", type=float, default=16.0)
    ap.add_argument("--max-atlases", type=int, default=4)
    ap.add_argument("--grain-name", default="grain")
    ap.add_argument("--grain-size", type=int, default=128)
    args = ap.parse_args()

    total_bytes = 0
    atlas_count = 0
    grain_count = 0
    errors = []
    scanned = 0

    for root in args.root:
        if not os.path.isdir(root):
            print("[warn] root '%s' not found, skipping" % root)
            continue
        for dirpath, _, files in os.walk(root):
            for name in files:
                ext = os.path.splitext(name)[1].lower()
                path = os.path.join(dirpath, name)
                if ext in FORBIDDEN_EXT:
                    errors.append("FORBIDDEN FORMAT: %s (use WebP/PNG)" % path)
                    continue
                if ext not in ALLOWED_EXT:
                    continue
                try:
                    w, h = dimensions(path)
                except Exception as e:  # noqa: BLE001
                    errors.append("CANNOT READ %s: %s" % (path, e))
                    continue
                scanned += 1
                decoded = w * h * 4
                total_bytes += decoded
                is_atlas = max(w, h) >= 1024
                if is_atlas:
                    atlas_count += 1
                if args.grain_name in name.lower() and w == args.grain_size and h == args.grain_size:
                    grain_count += 1
                print("  %8d KB  %5dx%-5d%s  %s" % (decoded // 1024, w, h,
                      " [ATLAS]" if is_atlas else "", path))

    total_mb = total_bytes / MB
    print("\n=== EMBERVEIL Asset Audit ===")
    print("scanned images : %d" % scanned)
    print("decoded texture : %.2f MB / %.2f MB" % (total_mb, args.max_decoded_mb))
    print("atlases (>=1024): %d / %d" % (atlas_count, args.max_atlases))
    print("grain 128²      : %d (must be exactly 1)" % grain_count)

    if total_mb > args.max_decoded_mb:
        errors.append("DECODED BUDGET EXCEEDED: %.2f > %.2f MB" % (total_mb, args.max_decoded_mb))
    if atlas_count > args.max_atlases:
        errors.append("TOO MANY ATLASES: %d > %d" % (atlas_count, args.max_atlases))
    # Grain rule only applies once at least one texture exists. An empty repo (Sprint 1,
    # pre-art-import) has no grain atlas yet and must not fail the build; the rule re-arms
    # automatically when real art is added (scanned > 0).
    if scanned > 0 and grain_count != 1:
        errors.append("GRAIN ATLAS MUST BE EXACTLY 1 (found %d)" % grain_count)

    if errors:
        print("\n[FAIL]")
        for e in errors:
            print("  - " + e)
        sys.exit(1)
    print("\n[PASS] asset budget within limits")
    sys.exit(0)


if __name__ == "__main__":
    main()

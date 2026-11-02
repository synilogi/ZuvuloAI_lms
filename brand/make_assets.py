"""Cuts every brand asset the website and the mobile app ship from the official ZuviloAI logo.

    python3 brand/make_assets.py        (from the repository root; needs Pillow)

The source is brand/zuviloai-logo.png: the artwork as supplied (a JPEG, 1254 px square, on a white ground),
saved as PNG with its near-white JPEG noise set to pure white so the ground lifts cleanly. Nothing here redraws
it. The script lifts the artwork off the white, and arranges the same pixels as:

  full     the logo as supplied — symbol over wordmark — for sign-in and other roomy places
  lockup   symbol beside the wordmark, for headers (the stacked logo is unreadable at 40 px)
  mark     the symbol alone, for small squares: the collapsed sidebar, favicons, the launcher icon

The `-dark` variants are for dark surfaces: the black symbol and the black "Zuvilo", which vanish there, are set
in white. The orange "Ai" and the star are untouched.

Outputs: apps/web/src/assets/brand (bundled, content-hashed), apps/web/public (favicon.ico and the manifest icons),
apps/mobile/assets/brand (in-app), and apps/mobile/tool/brand_mark.png, which tool/make_launcher_icons.py turns
into the Android launcher icons. Replace the source with a better original (vector, or a larger transparent PNG
re-measured below) and run this again, then the launcher script.
"""
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'brand' / 'zuviloai-logo.png'
WEB_SRC = ROOT / 'apps/web/src/assets/brand'
WEB_PUBLIC = ROOT / 'apps/web/public'
MOBILE = ROOT / 'apps/mobile/assets/brand'
MOBILE_TOOL = ROOT / 'apps/mobile/tool'

# Where each part sits in the source (left, top, right, bottom — right and bottom exclusive), measured from the
# ink's bounding rows and columns.
SYMBOL = (349, 186, 962, 876)
WORDMARK = (154, 901, 1105, 1083)
# Where "Zuvilo" ends and the orange "Ai" begins, measured from the wordmark's left edge.
WORDMARK_SPLIT = 728

WHITE = (255, 255, 255)
# The orange of "Ai" and the star: kept as it is on a dark surface, so what is near it is recoloured, not it.
ORANGE_MIN_RED, ORANGE_MAX_BLUE = 150, 140


def cut_out(src):
    """The artwork without its white ground, as RGBA. Edge pixels are un-blended from the white they were
    anti-aliased against, so the cut-out sits cleanly on any colour. So are the near-white slivers between two
    letters set tightly together, which are ground that never quite reaches white."""
    width, height = src.size
    r, g, b = src.split()
    lightest = ImageChops.darker(r, ImageChops.darker(g, b))
    ground = lightest.point(lambda v: 255 if v >= 250 else 0)
    rim = ImageChops.subtract(ground.filter(ImageFilter.MaxFilter(5)), ground)
    rim = ImageChops.lighter(rim, ImageChops.subtract(lightest.point(lambda v: 255 if v >= 225 else 0), ground))
    # The colour just inside each edge: the darkest value of each channel nearby.
    ink = Image.merge('RGB', [c.filter(ImageFilter.MinFilter(7)) for c in (r, g, b)])
    alpha = ground.point(lambda v: 0 if v else 255)
    out = src.copy()
    seen, inside, edge, a_px, o_px = src.load(), ink.load(), rim.load(), alpha.load(), out.load()
    for y in range(height):
        for x in range(width):
            if not edge[x, y]:
                continue
            was, colour = seen[x, y], inside[x, y]
            k = max(range(3), key=lambda i: 255 - colour[i])
            span = 255 - colour[k]
            cover = 1.0 if span < 8 else max(0.0, min(1.0, (255 - was[k]) / span))
            if cover >= 0.97:
                continue
            a_px[x, y] = round(cover * 255)
            o_px[x, y] = colour if cover <= 0.02 else tuple(max(0, min(255, round((was[i] - 255 * (1 - cover)) / cover))) for i in range(3))
    out.putalpha(alpha)
    return out


def recolour(img, colour, until=None, keep_orange=False):
    """The same shapes in `colour` — the whole image, or its columns left of `until`. Coverage is kept. With
    `keep_orange`, the orange pixels (the star, "Ai") stay as they are."""
    out = img.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width if until is None else until):
            r, g, b, alpha = px[x, y]
            if not alpha:
                continue
            if keep_orange and r >= ORANGE_MIN_RED and b <= ORANGE_MAX_BLUE and r > b + 60:
                continue
            px[x, y] = (*colour, alpha)
    return out


def scaled(img, *, width=None, height=None):
    """Resized in proportion, in premultiplied alpha so transparent pixels never tint an edge."""
    if width is None:
        width = round(img.width * height / img.height)
    if height is None:
        height = round(img.height * width / img.width)
    return img.convert('RGBa').resize((width, height), Image.LANCZOS).convert('RGBA')


def on_canvas(img, size, *, fill=0.86, background=None):
    """Centred on a square of side `size`, its longer side taking `fill` of it."""
    longest = max(img.size)
    fitted = scaled(img, width=max(1, round(img.width * size * fill / longest)))
    canvas = Image.new('RGBA', (size, size), (*background, 255) if background else (0, 0, 0, 0))
    canvas.alpha_composite(fitted, ((size - fitted.width) // 2, (size - fitted.height) // 2))
    return canvas


def stacked(symbol, wordmark):
    """The logo as supplied, trimmed to its artwork: the given symbol over the given wordmark, where they sit in
    the source."""
    left, top = min(WORDMARK[0], SYMBOL[0]), SYMBOL[1]
    canvas = Image.new('RGBA', (max(WORDMARK[2], SYMBOL[2]) - left, WORDMARK[3] - top), (0, 0, 0, 0))
    canvas.alpha_composite(symbol, (SYMBOL[0] - left, 0))
    canvas.alpha_composite(wordmark, (WORDMARK[0] - left, WORDMARK[1] - top))
    return canvas


def lockup(symbol, wordmark):
    """Symbol, then the wordmark at its own size: the symbol a little over twice the wordmark's height."""
    mark = scaled(symbol, height=round(wordmark.height * 2.1))
    gap = round(wordmark.height * 0.3)
    canvas = Image.new('RGBA', (mark.width + gap + wordmark.width, mark.height), (0, 0, 0, 0))
    canvas.alpha_composite(mark, (0, 0))
    canvas.alpha_composite(wordmark, (mark.width + gap, (mark.height - wordmark.height) // 2))
    return canvas


def save(img, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, optimize=True)
    print(f'  {path.relative_to(ROOT)}  {img.width}x{img.height}  {path.stat().st_size // 1024} KB')


def main():
    art = cut_out(Image.open(SOURCE).convert('RGB'))
    symbol, wordmark = art.crop(SYMBOL), art.crop(WORDMARK)
    symbol_dark = recolour(symbol, WHITE, keep_orange=True)
    wordmark_dark = recolour(wordmark, WHITE, until=WORDMARK_SPLIT)

    full, full_dark = stacked(symbol, wordmark), stacked(symbol_dark, wordmark_dark)
    row, row_dark = lockup(symbol, wordmark), lockup(symbol_dark, wordmark_dark)

    print('web')
    save(scaled(row, height=112), WEB_SRC / 'logo-lockup.png')
    save(scaled(row_dark, height=112), WEB_SRC / 'logo-lockup-dark.png')
    save(scaled(full, width=640), WEB_SRC / 'logo-full.png')
    save(scaled(full_dark, width=640), WEB_SRC / 'logo-full-dark.png')
    save(on_canvas(symbol, 256, fill=0.94), WEB_SRC / 'logo-mark.png')
    save(on_canvas(symbol_dark, 256, fill=0.94), WEB_SRC / 'logo-mark-dark.png')
    save(on_canvas(symbol, 32, fill=1.0), WEB_SRC / 'favicon-32.png')
    # iOS draws the touch icon on its own tile and does not honour transparency.
    save(on_canvas(symbol, 180, fill=0.74, background=WHITE).convert('RGB'), WEB_SRC / 'apple-touch-icon.png')
    for size in (192, 512):
        save(on_canvas(symbol, size, fill=0.74, background=WHITE).convert('RGB'), WEB_PUBLIC / f'icon-{size}.png')
    ico = WEB_PUBLIC / 'favicon.ico'
    on_canvas(symbol, 256, fill=1.0).save(ico, sizes=[(16, 16), (32, 32), (48, 48)])
    print(f'  {ico.relative_to(ROOT)}  16/32/48  {ico.stat().st_size // 1024} KB')

    print('mobile')
    save(on_canvas(symbol, 384, fill=1.0), MOBILE / 'logo_mark.png')
    save(on_canvas(symbol_dark, 384, fill=1.0), MOBILE / 'logo_mark_dark.png')
    save(scaled(full, width=720), MOBILE / 'logo_full.png')
    save(scaled(full_dark, width=720), MOBILE / 'logo_full_dark.png')
    save(symbol, MOBILE_TOOL / 'brand_mark.png')


if __name__ == '__main__':
    main()

"""Renders the Android launcher icons from the official ZuviloAI symbol. Run from apps/mobile:

    python3 tool/make_launcher_icons.py

The symbol is tool/brand_mark.png — the face with the circuit strands and the star, cut from the logo
(brand/zuviloai-logo.png) by brand/make_assets.py at the repository root; run that first when the logo changes.
The wordmark is left out on purpose: it is unreadable at launcher size.

Writes the legacy PNGs (Android 7.x), the adaptive-icon foreground and monochrome layers (Android 8+, and
themed icons on 13+) and the 512 px Play Store listing icon (store/). The symbol sits on white, the logo's
own ground (res/values/ic_launcher_background.xml). Nothing here touches the application id or signing.
"""
from pathlib import Path

from PIL import Image, ImageDraw

WHITE = (255, 255, 255, 255)
MARK = Image.open(Path('tool/brand_mark.png')).convert('RGBA')
RES = Path('android/app/src/main/res')
DENSITIES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
SS = 4  # supersampling for a smooth tile edge


def symbol(width, *, silhouette=False):
    """The symbol [width] px wide, in proportion, resized in premultiplied alpha so its edges stay clean.
    As a silhouette it is its own shape in solid black — the launcher tints it for a themed icon."""
    art = MARK
    if silhouette:
        art = Image.new('RGBA', MARK.size, (0, 0, 0, 255))
        art.putalpha(MARK.getchannel('A'))
    height = round(MARK.height * width / MARK.width)
    return art.convert('RGBa').resize((width, height), Image.LANCZOS).convert('RGBA')


def render(size, *, background, rounded, mark_width, silhouette=False):
    """A square of side [size] with the symbol centred, [mark_width] px wide."""
    big = size * SS
    tile = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    if background:
        radius = big * 8 / 32 if rounded else 0
        ImageDraw.Draw(tile).rounded_rectangle((0, 0, big - 1, big - 1), radius=radius, fill=WHITE)
    img = tile.resize((size, size), Image.LANCZOS)
    art = symbol(mark_width, silhouette=silhouette)
    img.alpha_composite(art, ((size - art.width) // 2, (size - art.height) // 2))
    return img


for name, scale in DENSITIES.items():
    folder = RES / f'mipmap-{name}'
    folder.mkdir(exist_ok=True)
    legacy = round(48 * scale)
    render(legacy, background=True, rounded=True, mark_width=round(legacy * 0.76)).save(folder / 'ic_launcher.png')
    # Adaptive layers are 108 dp and a launcher's mask may show as little as the middle 66 dp circle. At 50 dp
    # wide the symbol's corners stay inside that circle, so no mask shape clips the cap or the book.
    layer = round(108 * scale)
    width = round(50 * scale)
    render(layer, background=False, rounded=False, mark_width=width).save(folder / 'ic_launcher_foreground.png')
    render(layer, background=False, rounded=False, mark_width=width, silhouette=True).save(folder / 'ic_launcher_monochrome.png')

# Play Console: 512 x 512, full square, opaque — Google applies its own mask.
Path('store').mkdir(exist_ok=True)
render(512, background=True, rounded=False, mark_width=round(512 * 0.68)).convert('RGB').save('store/play_store_icon_512.png')
print('icons written')

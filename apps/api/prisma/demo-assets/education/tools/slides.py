import sys, json
from PIL import Image, ImageDraw, ImageFont
spec, out = json.load(open(sys.argv[1])), sys.argv[2]
F = '/System/Library/Fonts/Supplemental/'
title_f = ImageFont.truetype(F + 'Arial Bold.ttf', 58); body_f = ImageFont.truetype(F + 'Arial Unicode.ttf', 36)
small_f = ImageFont.truetype(F + 'Arial Unicode.ttf', 22)
BG, INK, MUTED, ACCENT = (24, 22, 48), (245, 240, 230), (170, 165, 190), (232, 170, 66)
for key, lec in spec.items():
    n = len(lec['slides'])
    for i, s in enumerate(lec['slides']):
        im = Image.new('RGB', (1280, 720), BG); d = ImageDraw.Draw(im)
        d.rectangle((0, 0, 1280, 8), fill=ACCENT)
        d.text((96, 70), lec['course'].upper(), font=small_f, fill=ACCENT)
        d.text((96, 120), s['title'], font=title_f, fill=INK)
        y = 250
        for line in s['lines']:
            d.text((96, y), line, font=body_f, fill=INK); y += 56
        d.text((96, 650), 'ZuviloAI sample lecture · silent slides', font=small_f, fill=MUTED)
        d.text((1120, 650), f'{i + 1} / {n}', font=small_f, fill=MUTED)
        im.save(f'{out}/{key}-{i + 1:02d}.png')
    print(key, n)

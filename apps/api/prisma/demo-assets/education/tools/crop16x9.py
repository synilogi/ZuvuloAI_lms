import sys, json, subprocess
from PIL import Image
raw, out, plan = sys.argv[1], sys.argv[2], json.loads(sys.argv[3])
W, H = 1280, 720
for key, anchor in plan.items():
    im = Image.open(f'{raw}/{key}.jpg').convert('RGB'); w, h = im.size
    if w / h > W / H:
        nw = round(h * W / H); x = (w - nw) // 2; im = im.crop((x, 0, x + nw, h))
    else:
        nh = round(w * H / W); y = min(max(0, round(h * anchor - nh / 2)), h - nh); im = im.crop((0, y, w, y + nh))
    im = im.resize((W, H), Image.LANCZOS); png = f'{out}/{key}.png'; im.save(png)
    subprocess.run(['cwebp', '-quiet', '-q', '78', '-m', '6', '-metadata', 'none', png, '-o', f'{out}/{key}.webp'], check=True)

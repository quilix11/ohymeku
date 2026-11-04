"""Package the existing Meku artwork for web, Android and iOS (requires Pillow)."""
import json
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parent.parent
art = Image.open(root / 'assets/images/meku_cutout.png').convert('RGBA')

def icon(path, size, scale=.94):
    canvas = Image.new('RGBA', (size, size), '#F8F5F0')
    face = art.copy()
    face.thumbnail((round(size * scale), round(size * scale)), Image.Resampling.LANCZOS)
    canvas.alpha_composite(face, ((size-face.width)//2, (size-face.height)//2))
    canvas.convert('RGB').save(root / path)

for size in [192, 512]:
    icon(f'web/icons/meku-{size}.png', size)
    icon(f'web/icons/meku-maskable-{size}.png', size, .72)
icon('web/icons/apple-touch-icon.png', 180)
icon('web/favicon.png', 32)
for density, size in [('mdpi',48), ('hdpi',72), ('xhdpi',96), ('xxhdpi',144), ('xxxhdpi',192)]:
    icon(f'android/app/src/main/res/mipmap-{density}/ic_launcher.png', size)
folder = Path('ios/Runner/Assets.xcassets/AppIcon.appiconset')
for item in json.loads((root / folder / 'Contents.json').read_text())['images']:
    if 'filename' in item:
        size = round(float(item['size'].split('x')[0]) * float(item['scale'].rstrip('x')))
        icon(folder / item['filename'], size)

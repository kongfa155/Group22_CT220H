import os
from PIL import Image

assets_dir = "/Users/hqnghi/git/flutter_tuto/fooderlich/assets"
os.makedirs(assets_dir, exist_ok=True)

images = {
    "mag1.png": (350, 450, (200, 100, 100)), # Reddish placeholder
    "mag2.png": (350, 450, (100, 200, 100)), # Greenish placeholder
    "mag5.png": (350, 450, (100, 100, 200)), # Blueish placeholder
    "author_katz.jpeg": (100, 100, (150, 150, 150)) # Gray avatar placeholder
}

for filename, (w, h, color) in images.items():
    path = os.path.join(assets_dir, filename)
    img = Image.new('RGB', (w, h), color=color)
    img.save(path)
    print(f"Created {path}")

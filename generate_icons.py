import os
import math
from PIL import Image, ImageDraw, ImageFilter

def create_sprout_icon(size=1024):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Scale factor
    scale = size / 1024.0

    # Draw rounded squircle / circular dark background
    bg_radius = int(240 * scale)
    margin = int(24 * scale)
    
    # Gradient / Multi-layered deep dark slate background
    # Background shape
    draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=int(220 * scale),
        fill=(17, 17, 19, 255) # Deep rich black #111113
    )

    # Subtle inner border / highlight
    draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=int(220 * scale),
        outline=(255, 255, 255, 24),
        width=int(4 * scale)
    )

    # Inner subtle glow layer
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    
    center_x = size // 2
    center_y = int(520 * scale)
    
    # Sprout Geometry: An elegant, minimalist continuous-line / leaf pair in crisp white & platinum
    # Main Stem (smooth curve)
    stem_points = []
    for t in range(100):
        frac = t / 99.0
        # Curve from bottom to center
        x = center_x - int(math.sin(frac * math.pi * 0.8) * 60 * scale)
        y = int((740 - frac * 260) * scale)
        stem_points.append((x, y))

    for i in range(len(stem_points) - 1):
        thickness = int((32 - (i / len(stem_points)) * 14) * scale)
        glow_draw.line([stem_points[i], stem_points[i+1]], fill=(255, 255, 255, 255), width=thickness)

    # Right Main Leaf (large, organic, smooth teardrop)
    # Using polygon with anti-aliased coordinates
    leaf_r = []
    # Base at (center_x, 490)
    base_x = center_x - int(10 * scale)
    base_y = int(490 * scale)
    tip_x = center_x + int(240 * scale)
    tip_y = int(320 * scale)
    
    for t in range(50):
        frac = t / 49.0
        # Upper edge
        x = base_x + (tip_x - base_x) * frac + math.sin(frac * math.pi) * (40 * scale)
        y = base_y + (tip_y - base_y) * frac - math.sin(frac * math.pi) * (140 * scale)
        leaf_r.append((x, y))
    for t in range(50):
        frac = t / 49.0
        # Lower edge
        x = tip_x - (tip_x - base_x) * frac - math.sin(frac * math.pi) * (20 * scale)
        y = tip_y - (tip_y - base_y) * frac + math.sin(frac * math.pi) * (120 * scale)
        leaf_r.append((x, y))
    
    glow_draw.polygon(leaf_r, fill=(255, 255, 255, 255))

    # Left Secondary Leaf (smaller, elegant balance)
    leaf_l = []
    base_l_x = center_x - int(20 * scale)
    base_l_y = int(550 * scale)
    tip_l_x = center_x - int(210 * scale)
    tip_l_y = int(410 * scale)

    for t in range(50):
        frac = t / 49.0
        # Upper edge
        x = base_l_x + (tip_l_x - base_l_x) * frac - math.sin(frac * math.pi) * (30 * scale)
        y = base_l_y + (tip_l_y - base_l_y) * frac - math.sin(frac * math.pi) * (110 * scale)
        leaf_l.append((x, y))
    for t in range(50):
        frac = t / 49.0
        # Lower edge
        x = tip_l_x - (tip_l_x - base_l_x) * frac + math.sin(frac * math.pi) * (15 * scale)
        y = tip_l_y - (tip_l_y - base_l_y) * frac + math.sin(frac * math.pi) * (90 * scale)
        leaf_l.append((x, y))

    glow_draw.polygon(leaf_l, fill=(235, 235, 240, 245))

    # Central delicate dewdrop / seed accent
    seed_r = int(22 * scale)
    glow_draw.ellipse(
        [center_x - seed_r, int(730 * scale) - seed_r, center_x + seed_r, int(730 * scale) + seed_r],
        fill=(255, 255, 255, 255)
    )

    # Composite onto main image
    img = Image.alpha_composite(img, glow)
    return img

def create_foreground_icon(size=1024):
    # For Android adaptive icons (transparent background, centered sprout with padding)
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    scale = (size / 1024.0) * 0.72  # Scale down to fit within adaptive icon safe zone
    
    glow_draw = ImageDraw.Draw(img)
    center_x = size // 2
    center_y = size // 2
    offset_y = int(40 * scale)

    # Stem
    stem_points = []
    for t in range(100):
        frac = t / 99.0
        x = center_x - int(math.sin(frac * math.pi * 0.8) * 60 * scale)
        y = center_y + offset_y + int((240 - frac * 260) * scale)
        stem_points.append((x, y))

    for i in range(len(stem_points) - 1):
        thickness = int((34 - (i / len(stem_points)) * 14) * scale)
        glow_draw.line([stem_points[i], stem_points[i+1]], fill=(255, 255, 255, 255), width=thickness)

    # Right Leaf
    base_x = center_x - int(10 * scale)
    base_y = center_y + offset_y - int(10 * scale)
    tip_x = center_x + int(240 * scale)
    tip_y = center_y + offset_y - int(180 * scale)
    
    leaf_r = []
    for t in range(50):
        frac = t / 49.0
        x = base_x + (tip_x - base_x) * frac + math.sin(frac * math.pi) * (40 * scale)
        y = base_y + (tip_y - base_y) * frac - math.sin(frac * math.pi) * (140 * scale)
        leaf_r.append((x, y))
    for t in range(50):
        frac = t / 49.0
        x = tip_x - (tip_x - base_x) * frac - math.sin(frac * math.pi) * (20 * scale)
        y = tip_y - (tip_y - base_y) * frac + math.sin(frac * math.pi) * (120 * scale)
        leaf_r.append((x, y))
    
    glow_draw.polygon(leaf_r, fill=(255, 255, 255, 255))

    # Left Leaf
    base_l_x = center_x - int(20 * scale)
    base_l_y = center_y + offset_y + int(50 * scale)
    tip_l_x = center_x - int(210 * scale)
    tip_l_y = center_y + offset_y - int(90 * scale)

    leaf_l = []
    for t in range(50):
        frac = t / 49.0
        x = base_l_x + (tip_l_x - base_l_x) * frac - math.sin(frac * math.pi) * (30 * scale)
        y = base_l_y + (tip_l_y - base_l_y) * frac - math.sin(frac * math.pi) * (110 * scale)
        leaf_l.append((x, y))
    for t in range(50):
        frac = t / 49.0
        x = tip_l_x - (tip_l_x - base_l_x) * frac + math.sin(frac * math.pi) * (15 * scale)
        y = tip_l_y - (tip_l_y - base_l_y) * frac + math.sin(frac * math.pi) * (90 * scale)
        leaf_l.append((x, y))

    glow_draw.polygon(leaf_l, fill=(235, 235, 240, 245))

    # Dewdrop
    seed_r = int(22 * scale)
    glow_draw.ellipse(
        [center_x - seed_r, center_y + offset_y + int(230 * scale) - seed_r, center_x + seed_r, center_y + offset_y + int(230 * scale) + seed_r],
        fill=(255, 255, 255, 255)
    )

    return img

def export_all():
    master_icon = create_sprout_icon(1024)
    foreground_icon = create_foreground_icon(1024)

    os.makedirs('assets/images', exist_ok=True)
    master_icon.save('assets/images/app_icon.png', 'PNG')

    # Android Mipmaps
    android_sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }

    res_dir = 'android/app/src/main/res'
    for folder, size in android_sizes.items():
        dir_path = os.path.join(res_dir, folder)
        os.makedirs(dir_path, exist_ok=True)
        # Standard launcher icon
        resized = master_icon.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(os.path.join(dir_path, 'ic_launcher.png'), 'PNG')

        # Foreground for adaptive
        fg_resized = foreground_icon.resize((int(size * 1.5), int(size * 1.5)), Image.Resampling.LANCZOS)
        # Center in (size, size) or keep in drawable
    
    # Save foreground to drawable
    drawable_dir = os.path.join(res_dir, 'drawable')
    os.makedirs(drawable_dir, exist_ok=True)
    fg_drawable = foreground_icon.resize((432, 432), Image.Resampling.LANCZOS)
    fg_drawable.save(os.path.join(drawable_dir, 'ic_launcher_foreground.png'), 'PNG')

    # Web Icons
    web_icons = {
        'web/icons/Icon-192.png': 192,
        'web/icons/Icon-512.png': 512,
        'web/icons/Icon-maskable-192.png': 192,
        'web/icons/Icon-maskable-512.png': 512,
        'web/favicon.png': 64,
    }

    for path, size in web_icons.items():
        os.makedirs(os.path.dirname(path), exist_ok=True)
        resized = master_icon.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(path, 'PNG')

    print("All app icons successfully generated!")

if __name__ == '__main__':
    export_all()

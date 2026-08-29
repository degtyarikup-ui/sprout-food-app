import os
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

def bezier_curve(p0, p1, p2, p3, num_points=100):
    t = np.linspace(0, 1, num_points)
    curve = np.zeros((num_points, 2))
    for i in range(num_points):
        curve[i] = (
            (1 - t[i])**3 * np.array(p0) +
            3 * (1 - t[i])**2 * t[i] * np.array(p1) +
            3 * (1 - t[i]) * t[i]**2 * np.array(p2) +
            t[i]**3 * np.array(p3)
        )
    return curve

def generate_sculpted_3d_sprout_icon(size=1024):
    w, h = size, size
    scale = size / 1024.0

    # 1. Base Canvas
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    # Background Squircle Dimensions
    pad = int(44 * scale)
    radius = int(220 * scale)

    # Base Mask
    mask = Image.new("L", (w, h), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([pad, pad, w - pad, h - pad], radius=radius, fill=255)

    # 2. Studio Lighting on Pebble Background
    y_coords, x_coords = np.mgrid[0:h, 0:w]
    light_x, light_y = w * 0.35, h * 0.22
    dist_light = np.sqrt((x_coords - light_x)**2 + (y_coords - light_y)**2)
    radial_intensity = np.clip(1.0 - (dist_light / (w * 0.9)), 0.0, 1.0) ** 1.9

    v_grad = 1.0 - (y_coords / float(h)) * 0.45

    bg_np = np.zeros((h, w, 4), dtype=np.float32)
    base_dark = np.array([14.0, 15.0, 18.0])
    base_highlight = np.array([36.0, 40.0, 48.0])

    for c in range(3):
        bg_np[:, :, c] = base_dark[c] * v_grad + (base_highlight[c] - base_dark[c]) * radial_intensity
    bg_np[:, :, 3] = 255.0

    bg_img = Image.fromarray(np.uint8(np.clip(bg_np, 0, 255)))
    bg_img.putalpha(mask)

    # Ambient Drop Shadow under the squircle
    shadow_img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow_img)
    shadow_draw.rounded_rectangle([pad, pad + int(14 * scale), w - pad, h - pad + int(14 * scale)], radius=radius, fill=(0, 0, 0, 140))
    shadow_img = shadow_img.filter(ImageFilter.GaussianBlur(int(22 * scale)))

    img.paste(shadow_img, (0, 0), shadow_img)
    img.paste(bg_img, (0, 0), bg_img)

    # Platinum Outer Rim Bevel
    edge_draw = ImageDraw.Draw(img)
    edge_draw.rounded_rectangle(
        [pad, pad, w - pad, h - pad],
        radius=radius,
        outline=(255, 255, 255, 40),
        width=int(3 * scale)
    )

    # 3. Create Continuous Anti-Aliased Sprout Mask using High-Res Bezier Polygons
    high_res = 2048
    hr_scale = high_res / 1024.0
    sprout_mask_hr = Image.new("L", (high_res, high_res), 0)
    sprout_draw_hr = ImageDraw.Draw(sprout_mask_hr)

    # Organic Sprout Coordinates
    # Stem: smooth tapering spline
    p_base_l = (int(490 * hr_scale), int(750 * hr_scale))
    p_base_r = (int(534 * hr_scale), int(750 * hr_scale))
    p_ctrl1_l = (int(460 * hr_scale), int(640 * hr_scale))
    p_ctrl1_r = (int(495 * hr_scale), int(640 * hr_scale))
    p_ctrl2_l = (int(475 * hr_scale), int(540 * hr_scale))
    p_ctrl2_r = (int(510 * hr_scale), int(540 * hr_scale))
    p_top_l = (int(490 * hr_scale), int(480 * hr_scale))
    p_top_r = (int(515 * hr_scale), int(480 * hr_scale))

    stem_l = bezier_curve(p_base_l, p_ctrl1_l, p_ctrl2_l, p_top_l, 60)
    stem_r = bezier_curve(p_top_r, p_ctrl2_r, p_ctrl1_r, p_base_r, 60)
    stem_poly = [tuple(p) for p in stem_l] + [tuple(p) for p in stem_r]
    sprout_draw_hr.polygon(stem_poly, fill=255)

    # Base Root / Pebble
    sprout_draw_hr.ellipse(
        [int(485 * hr_scale), int(730 * hr_scale), int(539 * hr_scale), int(775 * hr_scale)],
        fill=255
    )

    # Right Leaf (Hero Sculpted Curved Leaf)
    p_base = (int(505 * hr_scale), int(495 * hr_scale))
    p_tip = (int(750 * hr_scale), int(310 * hr_scale))
    
    edge1 = bezier_curve(p_base, (int(530 * hr_scale), int(360 * hr_scale)), (int(640 * hr_scale), int(260 * hr_scale)), p_tip, 80)
    edge2 = bezier_curve(p_tip, (int(760 * hr_scale), int(420 * hr_scale)), (int(600 * hr_scale), int(560 * hr_scale)), p_base, 80)
    leaf_r_poly = [tuple(p) for p in edge1] + [tuple(p) for p in edge2]
    sprout_draw_hr.polygon(leaf_r_poly, fill=255)

    # Left Leaf (Balanced Counterpart)
    p_l_base = (int(480 * hr_scale), int(540 * hr_scale))
    p_l_tip = (int(270 * hr_scale), int(390 * hr_scale))
    
    edge_l1 = bezier_curve(p_l_base, (int(440 * hr_scale), int(430 * hr_scale)), (int(350 * hr_scale), int(330 * hr_scale)), p_l_tip, 80)
    edge_l2 = bezier_curve(p_l_tip, (int(265 * hr_scale), int(480 * hr_scale)), (int(380 * hr_scale), int(590 * hr_scale)), p_l_base, 80)
    leaf_l_poly = [tuple(p) for p in edge_l1] + [tuple(p) for p in edge_l2]
    sprout_draw_hr.polygon(leaf_l_poly, fill=255)

    # Downsample smooth mask to target size
    sprout_mask = sprout_mask_hr.resize((w, h), Image.Resampling.LANCZOS)

    # 4. Multi-Layer Heightmap for 3D Volume
    mask_np = np.array(sprout_mask, dtype=np.float32) / 255.0
    b1 = np.array(sprout_mask.filter(ImageFilter.GaussianBlur(int(3 * scale))), dtype=np.float32) / 255.0
    b2 = np.array(sprout_mask.filter(ImageFilter.GaussianBlur(int(10 * scale))), dtype=np.float32) / 255.0
    b3 = np.array(sprout_mask.filter(ImageFilter.GaussianBlur(int(22 * scale))), dtype=np.float32) / 255.0

    heightmap = (mask_np * 0.42 + b1 * 0.32 + b2 * 0.18 + b3 * 0.08)

    # 5. Normal Maps & 3D Lighting Computation
    dz_dx = np.zeros_like(heightmap)
    dz_dy = np.zeros_like(heightmap)
    dz_dx[:, 1:-1] = (heightmap[:, 2:] - heightmap[:, :-2]) * 9.0
    dz_dy[1:-1, :] = (heightmap[2:, :] - heightmap[:-2, :]) * 9.0

    norm_len = np.sqrt(dz_dx**2 + dz_dy**2 + 1.0)
    nx = -dz_dx / norm_len
    ny = -dz_dy / norm_len
    nz = 1.0 / norm_len

    # Key Light (Top-Left Elevated)
    lx1, ly1, lz1 = -0.42, -0.68, 0.60
    l_len1 = math.sqrt(lx1**2 + ly1**2 + lz1**2)
    lx1, ly1, lz1 = lx1 / l_len1, ly1 / l_len1, lz1 / l_len1

    # Fill Light (Bottom-Right)
    lx2, ly2, lz2 = 0.55, 0.40, 0.48
    l_len2 = math.sqrt(lx2**2 + ly2**2 + lz2**2)
    lx2, ly2, lz2 = lx2 / l_len2, ly2 / l_len2, lz2 / l_len2

    diffuse1 = np.clip(nx * lx1 + ny * ly1 + nz * lz1, 0.0, 1.0)
    diffuse2 = np.clip(nx * lx2 + ny * ly2 + nz * lz2, 0.0, 1.0)

    # Blinn-Phong Specular
    h1x, h1y, h1z = lx1, ly1, lz1 + 1.0
    h1_len = math.sqrt(h1x**2 + h1y**2 + h1z**2)
    h1x, h1y, h1z = h1x / h1_len, h1y / h1_len, h1z / h1_len
    n_dot_h1 = np.clip(nx * h1x + ny * h1y + nz * h1z, 0.0, 1.0)
    specular1 = n_dot_h1 ** 38.0

    # Secondary Soft Specular
    specular_soft = n_dot_h1 ** 10.0

    # Fresnel Rim Light
    fresnel = np.clip(1.0 - nz, 0.0, 1.0) ** 2.4

    # 6. Sculpted Porcelain / Pearl Glass Color Matrix
    sprout_rgb = np.zeros((h, w, 4), dtype=np.float32)

    ambient_c = np.array([215.0, 222.0, 226.0])
    key_c = np.array([255.0, 255.0, 255.0])
    fill_c = np.array([160.0, 175.0, 190.0])

    for c in range(3):
        sprout_rgb[:, :, c] = (
            ambient_c[c] * 0.32 +
            key_c[c] * diffuse1 * 0.55 +
            fill_c[c] * diffuse2 * 0.22 +
            key_c[c] * specular1 * 0.95 +
            key_c[c] * specular_soft * 0.25 +
            key_c[c] * fresnel * 0.45
        )

    sprout_rgb[:, :, 3] = mask_np * 255.0

    # 7. Cast Shadow from Sprout onto Dark Squircle
    sprout_shadow_mask = Image.fromarray(np.uint8(np.clip(mask_np * 160.0, 0, 255)))
    sprout_shadow_mask = sprout_shadow_mask.filter(ImageFilter.GaussianBlur(int(16 * scale)))
    shadow_layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shadow_layer.paste(Image.new("RGBA", (w, h), (0, 0, 0, 150)), (int(6 * scale), int(14 * scale)), sprout_shadow_mask)

    img.paste(shadow_layer, (0, 0), shadow_layer)

    # 8. Composite 3D Sprout
    sprout_layer = Image.fromarray(np.uint8(np.clip(sprout_rgb, 0, 255)))
    img.paste(sprout_layer, (0, 0), sprout_layer)

    # 9. Delicate Dewdrop Highlight
    dew_draw = ImageDraw.Draw(img)
    cx = w // 2
    dew_cx = cx + int(90 * scale)
    dew_cy = int(390 * scale)
    dew_r = int(9 * scale)
    dew_draw.ellipse(
        [dew_cx - dew_r, dew_cy - dew_r, dew_cx + dew_r, dew_cy + dew_r],
        fill=(255, 255, 255, 240)
    )
    dew_draw.ellipse(
        [dew_cx - int(3*scale), dew_cy - int(3*scale), dew_cx + int(3*scale), dew_cy + int(3*scale)],
        fill=(255, 255, 255, 255)
    )

    return img

def export_all():
    master_3d = generate_sculpted_3d_sprout_icon(1024)

    os.makedirs('assets/images', exist_ok=True)
    master_3d.save('assets/images/app_icon.png', 'PNG')

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
        resized = master_3d.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(os.path.join(dir_path, 'ic_launcher.png'), 'PNG')

    # Save 3D foreground for adaptive icon
    drawable_dir = os.path.join(res_dir, 'drawable')
    os.makedirs(drawable_dir, exist_ok=True)
    fg_drawable = master_3d.resize((432, 432), Image.Resampling.LANCZOS)
    fg_drawable.save(os.path.join(drawable_dir, 'ic_launcher_foreground.png'), 'PNG')

    # Web Icons & Favicons
    web_icons = {
        'web/icons/Icon-192.png': 192,
        'web/icons/Icon-512.png': 512,
        'web/icons/Icon-maskable-192.png': 192,
        'web/icons/Icon-maskable-512.png': 512,
        'web/favicon.png': 64,
    }

    for path, size in web_icons.items():
        os.makedirs(os.path.dirname(path), exist_ok=True)
        resized = master_3d.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(path, 'PNG')

    print("Sculpted 3D Sprout App Icon rendered & exported successfully!")

if __name__ == '__main__':
    export_all()

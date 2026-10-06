"""Uygulama ikonu, web ikonları ve Play Store görsellerini üretir (Pillow gerekir)."""
from PIL import Image, ImageDraw, ImageFont, ImageFilter

NAVY = (10, 12, 17)
NAVY2 = (17, 28, 54)
GOLD1 = (236, 205, 120)
GOLD2 = (190, 144, 52)
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"


def vgrad(size, top, bottom):
    w, h = size
    img = Image.new("RGB", size)
    d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(1, h - 1)
        d.line([(0, y), (w, y)], fill=tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return img


def coin(diameter):
    """Altın madeni para: degrade yüzey, iç halka, 'Au' yazısı. RGBA döner."""
    s = diameter * 2  # anti-alias için 2x
    face = vgrad((s, s), GOLD1, GOLD2).convert("RGBA")
    mask = Image.new("L", (s, s), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, s - 1, s - 1], fill=255)
    face.putalpha(mask)
    d = ImageDraw.Draw(face)
    m = int(s * 0.07)
    d.ellipse([m, m, s - m, s - m], outline=(120, 82, 20), width=max(2, s // 70))
    font = ImageFont.truetype(FONT, int(s * 0.44))
    text = "Au"
    bbox = d.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    d.text(((s - tw) / 2 - bbox[0], (s - th) / 2 - bbox[1]), text, font=font, fill=(96, 62, 10))
    return face.resize((diameter, diameter), Image.LANCZOS)


def icon(size, coin_ratio, transparent=False):
    bg = Image.new("RGBA", (size, size), (0, 0, 0, 0)) if transparent else vgrad((size, size), NAVY2, NAVY).convert("RGBA")
    c = coin(int(size * coin_ratio))
    shadow = Image.new("RGBA", bg.size, (0, 0, 0, 0))
    off = (size - c.width) // 2
    shadow.paste((0, 0, 0, 110), (off, off + size // 40), c.split()[3])
    bg = Image.alpha_composite(bg, shadow.filter(ImageFilter.GaussianBlur(size // 60)))
    bg.alpha_composite(c, (off, off))
    return bg


def main():
    full = icon(1024, 0.70)
    full.convert("RGB").save("assets/icon/icon.png")
    icon(1024, 0.52, transparent=True).save("assets/icon/icon_foreground.png")  # adaptive: güvenli alan
    full.convert("RGB").resize((512, 512), Image.LANCZOS).save("store/play_icon_512.png")

    full.resize((64, 64), Image.LANCZOS).save("web_extras/favicon.png")
    for n in (192, 512):
        full.resize((n, n), Image.LANCZOS).save(f"web_extras/icons/Icon-{n}.png")
        icon(n, 0.56).resize((n, n), Image.LANCZOS).save(f"web_extras/icons/Icon-maskable-{n}.png")

    # Play Store öne çıkan görsel 1024x500
    fg = vgrad((1024, 500), NAVY2, NAVY).convert("RGBA")
    c = coin(300)
    fg.alpha_composite(c, (90, 100))
    d = ImageDraw.Draw(fg)
    d.text((440, 150), "Altın Takip", font=ImageFont.truetype(FONT, 78), fill=(236, 205, 120))
    d.text((444, 262), "Güncel altın fiyatları, portföy", font=ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 32), fill=(230, 228, 220))
    d.text((444, 308), "ve hesaplama araçları", font=ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 32), fill=(230, 228, 220))
    fg.convert("RGB").save("store/feature_graphic_1024x500.png")


main()

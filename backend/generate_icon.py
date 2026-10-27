import os
import math
from PIL import Image, ImageDraw, ImageFilter

def create_app_icon():
    size = 1024
    img = Image.new("RGB", (size, size), color=(11, 11, 15)) # #0B0B0F
    draw = ImageDraw.Draw(img)

    # 1. Gradiente radiale scuro di sfondo
    cx, cy = size // 2, size // 2
    for r in range(size // 2, 0, -2):
        factor = (1.0 - (r / (size // 2))) * 0.28
        # Sfumatura morbida dal nero al deep charcoal con tocco arancio sottile
        col = (
            int(11 + 35 * factor),
            int(11 + 18 * factor),
            int(15 + factor * 5)
        )
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=col)

    # 2. Crea un livello glow per lo scudo cyber
    glow_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_img)

    # Coordinate dello scudo moderno (smooth shield)
    # Punti scudo: Top center, Top right, Mid right, Bottom point, Mid left, Top left
    shield_points = [
        (512, 180),  # Top center
        (760, 240),  # Top right
        (760, 520),  # Mid right
        (512, 840),  # Bottom point
        (264, 520),  # Mid left
        (264, 240)   # Top left
    ]

    # Disegna lo scudo con glow arancione neon
    for offset in range(35, 0, -5):
        alpha = int(12 * (1.0 - offset / 35.0))
        glow_draw.polygon(shield_points, outline=(255, 107, 0, alpha), width=offset * 2)

    # Applica sfocatura gaussiana per il glow
    glow_img = glow_img.filter(ImageFilter.GaussianBlur(radius=16))
    img.paste(Image.new("RGB", (size, size), (255, 107, 0)), mask=glow_img.split()[3])

    # 3. Disegna lo scudo principale in Cyber Orange vibrante
    draw = ImageDraw.Draw(img)
    draw.polygon(shield_points, fill=(18, 18, 24), outline=(255, 107, 0), width=18)

    # 4. Cerchio interno con sfumatura d'accento
    inner_r = 160
    draw.ellipse(
        [cx - inner_r, 470 - inner_r, cx + inner_r, 470 + inner_r],
        fill=(26, 26, 36),
        outline=(255, 135, 38),
        width=8
    )

    # 5. Icona Cyber: Lucchetto / Radar stilizzato in Cyber Orange
    # Arco superiore del lucchetto
    shackle_box = [cx - 65, 345, cx + 65, 475]
    draw.arc(shackle_box, start=180, end=0, fill=(255, 150, 50), width=18)

    # Corpo centrale del lucchetto con angoli arrotondati
    body_box = [cx - 85, 440, cx + 85, 590]
    draw.rounded_rectangle(body_box, radius=24, fill=(255, 107, 0), outline=(255, 160, 60), width=6)

    # Buco della serratura (foro superiore circolare + feritoia inferiore)
    draw.ellipse([cx - 16, 485, cx + 16, 517], fill=(15, 15, 20))
    keyhole_poly = [
        (cx - 12, 508),
        (cx + 12, 508),
        (cx + 18, 545),
        (cx - 18, 545)
    ]
    draw.polygon(keyhole_poly, fill=(15, 15, 20))

    # 6. Radar pulse waves sotto il lucchetto (tecnologia & monitoraggio)
    for w_r in [220, 260]:
        draw.arc(
            [cx - w_r, 512 - w_r + 60, cx + w_r, 512 + w_r + 60],
            start=45, end=135,
            fill=(255, 107, 0),
            width=6
        )

    # Salva l'immagine nella cartella dell'AppIcon
    output_dir = os.path.join(os.path.dirname(__file__), "..", "ios", "CyberNews", "Resources", "Assets.xcassets", "AppIcon.appiconset")
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, "AppIcon-1024.png")
    
    img.save(output_path, "PNG", quality=100)
    print(f"✅ Icona generata con successo: {output_path} (1024x1024 px)")

if __name__ == "__main__":
    create_app_icon()

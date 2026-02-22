import math
from PIL import Image

def generate_hald_image(filename, effect='original'):
    size = 512
    img = Image.new('RGB', (size, size))
    pixels = img.load()
    
    # Standard 8x8 grid of 64x64 sub-squares for a 512x512 LUT
    for b in range(64):
        x_offset = (b % 8) * 64
        y_offset = (b // 8) * 64
        
        for g in range(64):
            for r in range(64):
                px = x_offset + r
                py = y_offset + g
                
                # Base colors [0, 255]
                red = int((r / 63.0) * 255)
                green = int((g / 63.0) * 255)
                blue = int((b / 63.0) * 255)
                
                if effect == 'wetzlar_mono':
                    # Grayscale with high contrast
                    luma = int(red * 0.299 + green * 0.587 + blue * 0.114)
                    # S-curve for contrast
                    normalized = luma / 255.0
                    contrasted = (math.sin((normalized - 0.5) * math.pi) + 1.0) / 2.0
                    luma = int(min(255, max(0, contrasted * 255)))
                    red, green, blue = luma, luma, luma
                elif effect == 'portra_glow':
                    # Warm tone, lifted shadows
                    red = min(255, int(red * 1.1 + 10))
                    green = min(255, int(green * 1.05 + 5))
                    blue = int(blue * 0.95 + 10)
                elif effect == 'k_chrome_64':
                    # High sat reds/yellows
                    red = min(255, int(red * 1.25))
                    green = min(255, int(green * 1.15))
                    blue = int(blue * 0.9)
                elif effect == 'superia_teal':
                    # Cool magenta/green shadows, teal skies
                    red = int(red * 0.95)
                    green = min(255, int(green * 1.1))
                    blue = min(255, int(blue * 1.15))
                elif effect == 'night_cine':
                    # Heavy teal-shift (CineStill typically cool shadows)
                    red = int(red * 0.8)
                    green = min(255, int(green * 1.15))
                    blue = min(255, int(blue * 1.3))
                elif effect == 'magic_square':
                    # Faded blacks, bluish tint
                    red = int(red * 0.9 + 20)
                    green = int(green * 0.9 + 20)
                    blue = min(255, int(blue * 1.1 + 30))
                    
                pixels[px, py] = (red, green, blue)
                
    img.save(f"assets/luts/{filename}")

generate_hald_image("wetzlar_mono.png", "wetzlar_mono")
generate_hald_image("portra_glow.png", "portra_glow")
generate_hald_image("k_chrome_64.png", "k_chrome_64")
generate_hald_image("superia_teal.png", "superia_teal")
generate_hald_image("night_cine.png", "night_cine")
generate_hald_image("magic_square.png", "magic_square")
print("6 Professional LUT PNGs generated!")

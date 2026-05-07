# utils/ui/gradients_icons.py

import os
from typing import Dict, Tuple
from PIL import Image, ImageDraw, ImageFont, ImageTk
import tkinter.font as tkfont
from tkinter import ttk

# Ruta carpeta de iconos PNG reales
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ASSETS_DIR = os.path.join(os.path.dirname(os.path.dirname(BASE_DIR)), "assets", "icons")

# =========================
# CONVERSIONES DE COLOR
# =========================

def _hex_to_rgb(hexs: str):
    hexs = hexs.lstrip("#")
    return tuple(int(hexs[i:i+2], 16) for i in (0, 2, 4))


def _mix(c1, c2, t: float):
    r1, g1, b1 = _hex_to_rgb(c1)
    r2, g2, b2 = _hex_to_rgb(c2)
    r = int(r1 + (r2 - r1) * t)
    g = int(g1 + (g2 - g1) * t)
    b = int(b1 + (b2 - b1) * t)
    return f"#{r:02x}{g:02x}{b:02x}"


# =========================
# DEGRADADOS
# =========================

def _make_gradient(accent: str, w: int, h: int, lighten: float = 0.30) -> Image.Image:
    """
    Fondo degradado 3 bandas + franja inferior.
    """
    acc = _mix(accent, "#ffffff", lighten)

    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    top = _mix(acc, "#ffffff", 0.78)
    mid = _mix(acc, "#ffffff", 0.55)
    base = acc

    draw.rectangle([0, 0, w, int(h * 0.42)], fill=top)
    draw.rectangle([0, int(h * 0.42), w, int(h * 0.78)], fill=mid)
    draw.rectangle([0, int(h * 0.78), w, h - 8], fill=base)
    draw.rectangle([0, h - 8, w, h], fill=accent)

    # brillo superior
    for i in range(2):
        draw.line([(0, i), (w, i)], fill="#ffffff")

    return img


# =========================
# ICONOS VECTORIALES
# =========================

def _icon_calc(size=44, color="purple") -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    r = max(4, size // 6)
    d.rounded_rectangle([1, 1, size - 1, size - 1], radius=r,
                        outline=color, width=2)

    pad = max(3, size // 8)
    d.rounded_rectangle([pad + 1, pad + 2, size - pad - 1,
                         size // 2], radius=r // 2,
                        outline=color, width=2)

    gtop = size // 2 + 3
    cell = max(4, (size - 2 * pad) // 5)
    y = gtop + 1

    for _ in range(3):
        x = pad + 1
        for _ in range(3):
            d.rectangle([x, y, x + cell, y + cell],
                        outline=color, width=2)
            x += cell + 3
        y += cell + 3

    return img


def _icon_fuel_pretty(size=44, color="purple") -> Image.Image:
    """
    Versión estética del surtidor.
    """
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    bx = int(size * 0.10)
    by = int(size * 0.25)
    bw = int(size * 0.46)
    bh = int(size * 0.62)
    r = max(4, size // 7)

    d.rounded_rectangle([bx, by, bx + bw, by + bh], radius=r,
                        outline=color, width=2)

    pad = max(3, size // 12)
    scr_h = int(bh * 0.28)
    d.rounded_rectangle([bx + pad, by + pad, bx + bw - pad,
                         by + pad + scr_h], radius=4,
                        outline=color, width=2)

    key_top = by + pad + scr_h + 3
    key_w = int((bw - 2 * pad - 6) / 2)
    key_h = int(key_w * 0.7)

    ky = key_top
    for _ in range(2):
        kx = bx + pad
        for _ in range(2):
            d.rectangle([kx, ky, kx + key_w, ky + key_h],
                        outline=color, width=2)
            kx += key_w + 6
        ky += key_h + 6

    base_y = by + bh + 2
    d.line([bx - 4, base_y, bx + bw + 4, base_y], fill=color, width=3)

    hx = bx + bw + 3
    hy = by + int(bh * 0.18)

    d.arc([hx - 10, hy - 10, hx + 8, hy + 8], start=265, end=355,
          fill=color, width=2)
    d.line([hx + 5, hy + 6, hx + 5, base_y - 10], fill=color, width=2)

    noz_x = hx + 13
    noz_y = hy + 10
    d.rectangle([hx + 1, base_y - 14, hx + 11, base_y - 6],
                outline=color, width=2)
    d.line([hx + 11, base_y - 10, noz_x, noz_y],
           fill=color, width=2)
    d.line([noz_x, noz_y, noz_x + 6, noz_y - 3],
           fill=color, width=3)

    cx, cy = noz_x + 7, noz_y - 5
    d.ellipse([cx - 2, cy - 2, cx + 2, cy + 2],
              outline=color, width=2)
    d.polygon([(cx, cy + 4), (cx - 3, cy), (cx + 3, cy)],
              outline=color)

    return img


def _icon_caln(size=44, color="purple") -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    r = max(4, size // 7)
    d.rounded_rectangle([1, 4, size - 1, size - 2], radius=r,
                        outline=color, width=2)

    d.line([1, int(size * 0.35), size - 1, int(size * 0.35)],
           fill=color, width=2)

    d.line([int(size * 0.30), 1, int(size * 0.30), 6], fill=color, width=2)
    d.line([int(size * 0.70), 1, int(size * 0.70), 6], fill=color, width=2)

    left, top = 5, int(size * 0.40)
    right, bottom = size - 5, size - 5

    d.line([left, (top + bottom) // 2, right, (top + bottom) // 2],
           fill=color, width=2)
    d.line([(left + right) // 2, top, (left + right) // 2, bottom],
           fill=color, width=2)

    return img


def _get_icon(icon_key: str, height_px=44, color="purple") -> Image.Image:
    """
    Carga un PNG real desde /assets/icons/
    El PNG debe llamarse igual que icon_key: calc.png, fuel.png, help.png...
    """
    png_path = os.path.join(ASSETS_DIR, f"{icon_key}.png")

    try:
        icon = Image.open(png_path).convert("RGBA")
        icon = icon.resize((height_px, height_px), Image.LANCZOS)  # tamaño uniforme
        return icon
    except Exception as e:
        print(f"[WARN] No se encontró icono PNG '{png_path}', usando icono dibujado.")
        # fallback al sistema original
        if icon_key == "calc":
            return _icon_calc(height_px, color)
        elif icon_key == "fuel":
            return _icon_fuel_pretty(height_px, color)
        else:
            return _icon_caln(height_px, color)

# =========================
# FUENTES Y RENDER TABS
# =========================

def _load_pil_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    """
    Intenta usar Segoe UI o Arial en Windows.
    """
    if os.name == "nt":
        base = os.path.join(os.environ.get("WINDIR", "C:\\Windows"), "Fonts")
        fonts = []
        if bold:
            fonts += ["segoeuib.ttf", "seguisb.ttf"]
        fonts += ["segoeui.ttf", "arial.ttf", "calibri.ttf"]

        for name in fonts:
            p = os.path.join(base, name)
            if os.path.exists(p):
                try:
                    return ImageFont.truetype(p, size=size)
                except:
                    pass

    return ImageFont.load_default()


def _render_tab_image_full(title: str, subtitle: str, icon_key: str, accent: str,
                           height: int, tk_font_title: tkfont.Font,
                           tk_font_sub: tkfont.Font, text_color="#000000",
                           icon_color="#FFFFFF",
                           lighten_nor=0.85, lighten_sel=0.70) -> Tuple:
    """
    Renderiza una pestaña completa: fondo, icono y textos.
    """
    PADX = 18
    GAP_ICON_TXT = 12
    GAP_TITLE_SUB = 6

    size_title = max(14, tk_font_title.cget("size"))
    size_sub = max(11, tk_font_sub.cget("size"))

    pil_title = _load_pil_font(size_title, bold=True)
    pil_sub = _load_pil_font(size_sub, bold=False)

    img_dummy = Image.new("RGBA", (10, 10))
    draw_dummy = ImageDraw.Draw(img_dummy)

    t_w, t_h = draw_dummy.textbbox((0, 0), title, font=pil_title)[2:]
    s_w, s_h = (0, 0)
    if subtitle:
        s_w, s_h = draw_dummy.textbbox((0, 0), subtitle, font=pil_sub)[2:]

    icon = _get_icon(icon_key, height_px=48, color=icon_color)
    icon_w = icon.width
    w_text = max(t_w, s_w)

    w = max(180, PADX + icon_w + GAP_ICON_TXT + w_text + PADX)
    h = max(60, height)


    img_normal = _make_gradient(accent, w, h, lighten=lighten_nor)
    img_selected = _make_gradient(accent, w, h, lighten=lighten_sel)

    def _draw(img):
        d = ImageDraw.Draw(img)
        x = PADX
        y_mid = h // 2
        img.alpha_composite(icon, (x, y_mid - icon.height // 2))

        x += icon.width + GAP_ICON_TXT

        total_h = t_h + (GAP_TITLE_SUB + s_h if subtitle else 0)
        y_top = y_mid - total_h // 2

        d.text((x, y_top), title, font=pil_title, fill=text_color)
        if subtitle:
            d.text((x, y_top + t_h + GAP_TITLE_SUB), subtitle,
                   font=pil_sub, fill=text_color)

    _draw(img_normal)
    _draw(img_selected)

    return ImageTk.PhotoImage(img_normal), ImageTk.PhotoImage(img_selected)


# =========================
# APLICACIÓN DE ESTILO MODERNO
# =========================

def modernize_notebook_tabs(nb: ttk.Notebook, tabs_meta: Dict[int, Dict], height: int = 72):
    """
    Transformación completa de las pestañas del Notebook.
    """
    st = ttk.Style(nb)

    try:
        st.theme_use("clam")
    except:
        pass

    st.configure("Modern.TNotebook", tabmargins=(2, 2, 2, 0))
    st.configure("Modern.TNotebook.Tab", padding=(0, 0, 0, 0))
    nb.configure(style="Modern.TNotebook")

    try:
        base_font = st.lookup("TNotebook.Tab", "font")
        tk_font_title = tkfont.nametofont(base_font) if base_font else tkfont.Font(family="Segoe UI", size=14, weight="bold")
        tk_font_title.configure(weight="bold", size=14)
    except:
        tk_font_title = tkfont.Font(family="Segoe UI", size=14, weight="bold")

    tk_font_sub = tkfont.Font(family="Segoe UI", size=11)

    if not hasattr(nb, "_modern_tab_imgs"):
        nb._modern_tab_imgs = {}
        nb._modern_tab_imgs_sel = {}

    tab_ids = nb.tabs()

    for idx, tab_id in enumerate(tab_ids):
        meta = tabs_meta.get(idx, {})
        img_normal, img_selected = _render_tab_image_full(
            meta.get("title", f"Tab {idx+1}"),
            meta.get("subtitle", ""),
            meta.get("icon_key", "calc"),
            meta.get("accent", "#6e1b8a"),
            height,
            tk_font_title,
            tk_font_sub,
            text_color=meta.get("text_color", "#000000"),
            icon_color=meta.get("icon_color", "#FFFFFF"),
            lighten_nor=meta.get("lighten_nor", 0.85),
            lighten_sel=meta.get("lighten_sel", 0.70),
        )

        nb._modern_tab_imgs[idx] = img_normal
        nb._modern_tab_imgs_sel[idx] = img_selected

        nb.tab(tab_id, image=img_normal, text="", padding=0)

    def _apply(*_):
        cur = nb.select()
        for idx, tab_id in enumerate(nb.tabs()):
            img = nb._modern_tab_imgs_sel[idx] if tab_id == cur else nb._modern_tab_imgs[idx]
            nb.tab(tab_id, image=img)

    _apply()
    nb.bind("<<NotebookTabChanged>>", lambda e: _apply())
    nb.bind("<Configure>", lambda e: _apply())
    
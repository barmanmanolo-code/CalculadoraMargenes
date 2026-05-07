# utils/ui/styles.py

import tkinter as tk
from tkinter import ttk

# COLORES BASE (los mismos que en tu código original)
ACCENT_PURPLE = "#6e1b8a"
ACCENT_GREEN  = "#0a7d32"
ACCENT_DARK   = "#2e7d32"

LOCAL_BG = "#eaf7ee"
NAC_BG   = "#e1f3ea"
TOP_BG   = "#f3fbf3"


def init_custom_styles():
    """
    Inicializa todos los estilos ttk usados en la aplicación.
    Se llama UNA VEZ al iniciar la app desde main.py
    """
    st = ttk.Style()

    try:
        st.theme_use("clam")
    except Exception:
        pass

    # ==== PANEL SUPERIOR ====
    st.configure("PanelTop.TFrame", background=TOP_BG)
    st.configure("PlainLabelTop.TLabel",
                 background=TOP_BG,
                 foreground="#1d3d2a",
                 font=("Segoe UI", 10))

    # ==== LOCAL / NACIONAL ====
    st.configure("PanelLocal.TFrame", background=LOCAL_BG)
    st.configure("PanelNac.TFrame",   background=NAC_BG)

    st.configure("Local.TLabelframe",
                 background=LOCAL_BG,
                 borderwidth=1,
                 relief="groove")
    st.configure("Local.TLabelframe.Label",
                 background=LOCAL_BG,
                 foreground=ACCENT_GREEN,
                 font=("Segoe UI", 11, "bold"))

    st.configure("Nac.TLabelframe",
                 background=NAC_BG,
                 borderwidth=1,
                 relief="groove")
    st.configure("Nac.TLabelframe.Label",
                 background=NAC_BG,
                 foreground=ACCENT_GREEN,
                 font=("Segoe UI", 11, "bold"))

    st.configure("PlainLabelLocal.TLabel",
                 background=LOCAL_BG,
                 foreground="#1d3d2a",
                 font=("Segoe UI", 10))
    st.configure("PlainLabelNac.TLabel",
                 background=NAC_BG,
                 foreground="#1d3d2a",
                 font=("Segoe UI", 10))

    # ==== TEXTOS NEGRITA ====
    st.configure("BoldLocal.TLabel",
                 background=LOCAL_BG,
                 foreground=ACCENT_GREEN,
                 font=("Segoe UI", 10, "bold"))
    st.configure("BoldNac.TLabel",
                 background=NAC_BG,
                 foreground=ACCENT_GREEN,
                 font=("Segoe UI", 10, "bold"))

    # ==== VALORES ====
    st.configure("ValueLocal.TLabel",
                 background=LOCAL_BG,
                 foreground="#222",
                 font=("Segoe UI", 10, "bold"))
    st.configure("ValueNac.TLabel",
                 background=NAC_BG,
                 foreground="#222",
                 font=("Segoe UI", 10, "bold"))

    # ==== BOTÓN ESTÁNDAR VERDE ====
    st.configure("ActionGreen.TButton",
                 background=ACCENT_GREEN,
                 foreground="white")
    st.map("ActionGreen.TButton",
           background=[
               ("!disabled", ACCENT_GREEN),
               ("pressed",  "#096229"),
               ("active",   "#0c8b3d"),
           ],
           foreground=[
               ("disabled", "#ddd"),
               ("!disabled", "white"),
           ])

    # ==== TREEVIEW ====
    st.configure("Calc.Treeview",
                 font=("Segoe UI", 10),
                 rowheight=24,
                 background="white",
                 fieldbackground="white",
                 foreground="#222")

    st.configure("Calc.Treeview.Heading",
                 font=("Segoe UI", 10, "bold"),
                 background=ACCENT_PURPLE,
                 foreground="white")

    st.configure("PrettyGreen.Treeview",
                 font=("Segoe UI", 10),
                 rowheight=24,
                 background="white",
                 fieldbackground="white",
                 foreground="#222")

    st.configure("PrettyGreen.Treeview.Heading",
                 font=("Segoe UI", 10, "bold"),
                 background=ACCENT_GREEN,
                 foreground="white")

    # ==== BOTÓN COPIAR PEQUEÑO ====
    st.configure("CopySmall.TButton",
                 font=("Segoe UI", 9),
                 padding=2,
                 borderwidth=1,
                 relief="raised",
                 background="#A57EA3",
                 foreground="#070F1199")

    st.map("CopySmall.TButton",
           background=[
               ("active",  "#E2E2E2"),
               ("pressed", "#C0C0C0")
           ],
           foreground=[
               ("disabled", "#888"),
               ("!disabled", "black"),
           ])
# -*- coding: utf-8 -*-
import os
import sys
import tkinter as tk
from tkinter import ttk, messagebox
from tkinter.filedialog import asksaveasfilename

from PIL import Image, ImageTk
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Image as RLImage
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm
from reportlab.lib import colors


class HelpTab(ttk.Frame):
    """
    Versión corregida y funcional.
    """

    def __init__(self, master):
        super().__init__(master)

        ROOT = os.path.dirname(os.path.abspath(sys.modules["__main__"].__file__))
        self.PATH_ICONS = os.path.join(ROOT, "assets", "icons")
        self.PATH_IMG = os.path.join(ROOT, "assets", "help_manual")

        self._icons_cache = []
        self.sections_refs = {}

        # ==========================
        #  CONTENIDO UNIFICADO
        # ==========================
        self.manual = [
            ("1. Calculadora (Margen de Venta)", "",
             [("1.png", 300)]),

            ("1.1 Introducción del coste",
             "Introduce el coste y la aplicación mostrará automáticamente el rango de venta.",
             [("2.png", 250)]),

            ("1.2 Selección del rol",
             "Elige el rol deseado según corresponda.",
             ["3.png"]),

            ("1.2.1 Si queremos introducir un margen inferior",
             "(Por ejemplo en una contracted order) marcamos la casilla de Permitir % inferior al mínimo para habilitar dicha opción.",
             [("5.png", 250)]),

            ("1.3 Copiar venta",
             "Pulsa el botón copiar para copiar el valor del rol deseado.",
             [("4.png", 250)]),

            ("2. ADER Fuel", "",
             [("14.png", 300)]),

            ("2.1 Cálculo de fuel",
             "Calcula automáticamente Local o Nacional y aplica la fórmula adecuada.",
             ["7.png"]),

            ("2.2 Copiar coste",
             "Envía el valor final a la calculadora.",
             [("8.png", 250)]),

            ("2.3 Texto ADER",
             "Genera el texto listo para pegar en ADER.",
             ["9.png"]),

            ("3. Fuel Meses", "",
             [("15.png", 300)]),

            ("3.1 Añadir",
             "Introduce el mes y los valores deseados y clic en el botón Añadir / Actualizar para añadirlo.",
             ["10.png"]),

            ("3.2 Modificar",
             "Selecciona un mes existente, clic en Modificar, modifica sus valores y clic en Añadir / Actualizar.",
             ["11.png"]),

            ("3.3 Eliminar",
             "Elimina el mes seleccionado de la lista y clic en Eliminar.",
             ["12.png"]),
        ]

        self._build_canvas()
        self._render_manual()
        self._build_floating_bar()

    # ============================================
    # CANVAS
    # ============================================
    def _build_canvas(self):
        self.canvas = tk.Canvas(self, bg="white", highlightthickness=0)
        scroll = ttk.Scrollbar(self, orient="vertical", command=self.canvas.yview)
        self.canvas.configure(yscrollcommand=scroll.set)

        self.canvas.pack(side="left", fill="both", expand=True)
        scroll.pack(side="right", fill="y")

        self.container = tk.Frame(self.canvas, bg="white")
        self.canvas.create_window((0, 0), window=self.container, anchor="nw")

        self.container.bind("<Configure>",
                            lambda e: self.canvas.configure(scrollregion=self.canvas.bbox("all")))
        self.canvas.bind_all("<MouseWheel>",
                             lambda e: self.canvas.yview_scroll(int(-e.delta / 120), "units"))

    # ============================================
    # SECCIONES
    # ============================================
    def _add_section(self, title, text):
        anchor = tk.Label(self.container, bg="white")
        anchor.pack()
        self.sections_refs[title] = anchor

        tk.Label(
            self.container,
            text=title,
            font=("Segoe UI", 18, "bold"),
            fg="#6e1b8a",
            bg="white"
        ).pack(anchor="w", padx=260, pady=10)

        if text:
            tk.Label(
                self.container,
                text=text,
                font=("Segoe UI", 12),
                bg="white",
                wraplength=800,
                justify="left"
            ).pack(anchor="w", padx=260)

    # ============================================
    # IMÁGENES
    # ============================================
    def _add_image(self, img_def):
        if isinstance(img_def, tuple):
            fname, width = img_def
        else:
            fname, width = img_def, 450

        path = os.path.join(self.PATH_IMG, fname)
        if not os.path.exists(path):
            return

        img = Image.open(path)
        r = width / img.width
        img = img.resize((width, int(img.height * r)), Image.LANCZOS)

        tkimg = ImageTk.PhotoImage(img)
        self._icons_cache.append(tkimg)

        tk.Label(self.container, image=tkimg, bg="white").pack(anchor="w", padx=260, pady=10)

    # ============================================
    # RENDER MANUAL
    # ============================================
    def _render_manual(self):
        for title, text, imgs in self.manual:
            self._add_section(title, text)
            for img in imgs:
                self._add_image(img)

        tk.Button(
            self.container,
            text="Crear PDF",
            command=self._export_pdf,
            bg="#6e1b8a",
            fg="white",
            font=("Segoe UI", 12, "bold")
        ).pack(anchor="w", padx=260, pady=30)

    # ============================================
    # PDF
    # ============================================
    def _export_pdf(self):
        path = asksaveasfilename(
            defaultextension=".pdf",
            filetypes=[("PDF", "*.pdf")],
            initialfile="AYUDA_CALCULADORA.pdf"
        )
        if not path:
            return

        doc = SimpleDocTemplate(
            path, pagesize=A4,
            leftMargin=2 * cm, rightMargin=2 * cm,
            topMargin=2 * cm, bottomMargin=2 * cm
        )

        styles = getSampleStyleSheet()
        st_title = ParagraphStyle("title", parent=styles["Heading1"], fontSize=16,
                                  textColor=colors.HexColor("#6e1b8a"), spaceAfter=12)
        st_text = ParagraphStyle("text", parent=styles["Normal"], fontSize=10, spaceAfter=10)

        story = []

        def add_img(img_def):
            import PIL.Image as PIMG
            if isinstance(img_def, tuple):
                fname, width = img_def
            else:
                fname, width = img_def, None

            p = os.path.join(self.PATH_IMG, fname)
            if not os.path.exists(p):
                return

            im = PIMG.open(p)
            w, h = im.size

            if width:
                sc = width / w
                story.append(RLImage(p, width=width, height=h * sc))
            else:
                maxw = A4[0] - 4 * cm
                sc = maxw / w
                story.append(RLImage(p, width=maxw, height=h * sc))

            story.append(Spacer(1, 12))

        for title, text, imgs in self.manual:
            story.append(Paragraph(title, st_title))
            if text:
                story.append(Paragraph(text, st_text))
            for img in imgs:
                add_img(img)

        doc.build(story)
        messagebox.showinfo("PDF creado", "El archivo PDF se ha generado correctamente.")

    # ============================================
    # PANEL FLOTANTE
    # ============================================
    def _build_floating_bar(self):
        shadow = tk.Frame(self.canvas, bg="#b7a8d4")
        shadow.place(x=100, rely=0.45, anchor="center")

        flo = tk.Frame(shadow, bg="#6e1b8a")
        flo.pack(padx=4, pady=4)

        def scroll_to(ref):
            start = self.canvas.yview()[0]
            target = ref.winfo_y() / self.container.winfo_height()
            for i in range(20):
                t = i / 20
                ease = t * t * (3 - 2 * t)
                self.canvas.yview_moveto(start + (target - start) * ease)
                self.canvas.update()
                self.canvas.after(10)

        def add_btn(icon, text, section):
            f = os.path.join(self.PATH_ICONS, icon)
            if not os.path.exists(f):
                return

            im = Image.open(f).resize((32, 32), Image.LANCZOS)
            tki = ImageTk.PhotoImage(im)
            self._icons_cache.append(tki)

            row = tk.Frame(flo, bg="#6e1b8a")
            row.pack(fill="x", pady=6)

            tk.Label(row, image=tki, bg="#6e1b8a").pack(side="left", padx=6)

            tk.Button(
                row,
                text=text,
                bg="#6e1b8a",
                fg="white",
                cursor="hand2",
                relief="flat",
                padx=10, pady=6,
                anchor="w",
                command=lambda: scroll_to(self.sections_refs[section])
            ).pack(side="left", expand=True, fill="x")

        add_btn("calc.png", " Calculadora ", "1. Calculadora (Margen de Venta)")
        add_btn("fuel.png", " ADER Fuel ", "2. ADER Fuel")
        add_btn("caln.png", " Fuel Meses ", "3. Fuel Meses")

        pdf = os.path.join(self.PATH_ICONS, "PDF.png")
        if os.path.exists(pdf):
            im = Image.open(pdf).resize((32, 32), Image.LANCZOS)
            tki = ImageTk.PhotoImage(im)
            self._icons_cache.append(tki)

            row = tk.Frame(flo, bg="#6e1b8a")
            row.pack(fill="x", pady=6)

            tk.Label(row, image=tki, bg="#6e1b8a").pack(side="left", padx=6)

            tk.Button(
                row,
                text="Guardar PDF",
                bg="#6e1b8a",
                fg="white",
                relief="flat",
                padx=10, pady=6,
                command=self._export_pdf
            ).pack(side="left")
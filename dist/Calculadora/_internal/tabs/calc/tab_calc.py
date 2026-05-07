# tabs/calc/tab_calc.py

import tkinter as tk
from tkinter import ttk, messagebox
import re

from utils.formatting.formatos import (
    fmt_num_2, fmt_pct_1, parse_num, minimos_por_coste
)
from utils.formatting.formatos import calcular_venta_revao
from utils.ui.styles import ACCENT_PURPLE


class MainCalcTab(tk.Frame):
    def __init__(self, master, shared_coste_var: tk.StringVar):
        super().__init__(master)

        # Variable compartida entre tabs
        self.var_coste = shared_coste_var

        self._last_violation_key = None
        self._warn_lock = False

        # Construir TODA la UI primero
        self._build()

        # ✅ TRACE DESPUÉS del build (la tabla ya existe)
        self.var_coste.trace_add(
            "write",
            lambda *args: self._on_coste_change()
        )

    # -------- validaciones --------
    def _validate_coste(self, proposed: str) -> bool:
        p = (proposed or "").strip()
        if p == "":
            return True
        for ch in ("€", "EUR", "eur", "Eur"):
            p = p.replace(ch, "")
        p = p.strip()
        if not re.fullmatch(r"[0-9\.,\s]*", p):
            return False
        last_sep = max(p.rfind(","), p.rfind("."))
        if last_sep != -1:
            dec_len = len(p) - last_sep - 1
            if dec_len > 2:
                return False
        return True

    def _validate_pct_rol(self, proposed: str) -> bool:
        if proposed is None:
            return False
        t = (proposed or "").strip().replace(".", ",")
        if t == "":
            return True
        return bool(re.fullmatch(r"\d{1,2}(,\d{0,2})?", t))

    # ==========================================
    # BUILD UI
    # ==========================================
    def _build(self):
        wrap = tk.Frame(self)
        wrap.pack(fill="both", expand=True, padx=8, pady=8)

        # ─── Barra superior ─────────────────────────
        top = ttk.Frame(wrap, padding=(4, 4))
        top.pack(fill="x", pady=(0, 4))

        ttk.Label(top, text="COSTE (€):").pack(side="left", padx=(0, 6))
        self.ent_coste = ttk.Entry(
            top, textvariable=self.var_coste, width=16, justify="right"
        )
        self.ent_coste.pack(side="left", padx=(0, 10))

        vcmd_coste = (self.register(self._validate_coste), "%P")
        self.ent_coste.configure(validate="key", validatecommand=vcmd_coste)

        self.ent_coste.bind("<KeyRelease>", lambda e: self._on_coste_change())
        self.ent_coste.bind("<Return>", lambda e: (self._format_coste_and_recalc(), "break"))
        self.ent_coste.bind("<FocusOut>", lambda e: self._format_coste_and_recalc())

        self.var_permitir = tk.BooleanVar(value=False)
        ttk.Checkbutton(
            top,
            text="Permitir % inferior al mínimo",
            variable=self.var_permitir,
            command=self._on_toggle_permitir,
        ).pack(side="left", padx=(0, 10))

        ttk.Button(
            top, text="RESET",
            style="ActionGreen.TButton",
            command=self._reset_all
        ).pack(side="left")

        # ─── Tabla de roles ─────────────────────────
        LEFT, RIGHT = 15, 15
        grid = tk.Frame(wrap)
        grid.pack(fill="x", padx=(LEFT, RIGHT), pady=(2, 6))

        heads = [
            ("Categoría", 0), ("% (editable)", 10), ("VENTA", 14),
            ("", 0), ("REVAO", 14), ("Mín.", 14), ("Máx.", 6),
        ]
        for j, (txt, px) in enumerate(heads):
            tk.Label(grid, text=txt, font=("Segoe UI", 10, "bold")) \
                .grid(row=0, column=j, padx=(px, 0))

        self.roles = [
            ("sin_aprob", "Margen mínimo sin aprobación.", "#6aa84f"),
            ("supervisor", "Margen mínimo Supervisor.", "#6fa8dc"),
            ("manager", "Margen mínimo Manager.", "#f1c232"),
            ("joao", "Margen mínimo Senior Manager.", "#e69138"),
        ]

        self.rows = {}
        for i, (key, title, color) in enumerate(self.roles, start=1):
            tk.Label(
                grid, text=title, bg=color,
                fg=("white" if key != "manager" else "#4a2e00"),
                font=("Segoe UI", 10, "bold"),
                padx=10, pady=6, relief="raised", bd=2
            ).grid(row=i, column=0, padx=(0, 6), pady=5, sticky="ew")

            var_pct = tk.StringVar(value="")
            entry = tk.Entry(
                grid, textvariable=var_pct, width=10,
                bg=color, fg="white", insertbackground="white",
                relief="raised", bd=2, font=("Segoe UI", 11, "bold"),
                justify="center"
            )
            entry.grid(row=i, column=1, sticky="w")

            vcmd_pct = (self.register(self._validate_pct_rol), "%P")
            entry.configure(validate="key", validatecommand=vcmd_pct)

            entry.bind("<FocusIn>", lambda e, k=key: self._on_pct_focus(k))
            entry.bind("<KeyRelease>", lambda e, k=key: self._on_pct_change(k))
            entry.bind("<FocusOut>", lambda e, k=key: self._on_pct_change(k))
            entry.bind("<Return>", lambda e, k=key: (self._on_pct_change(k), "break"))

            var_venta = tk.StringVar(value="")
            tk.Label(grid, textvariable=var_venta, width=16,
                     bg=color, fg="white", relief="raised",
                     bd=2, font=("Segoe UI", 12, "bold"),
                     padx=10, pady=4).grid(row=i, column=2, sticky="w", padx=(14, 0))

            ttk.Button(
                grid, text="Copiar", width=7,
                style="CopySmall.TButton",
                command=lambda k=key: self._copiar_venta(k),
            ).grid(row=i, column=3, sticky="w", padx=8, pady=2)

            var_revao = tk.StringVar(value="")
            tk.Label(grid, textvariable=var_revao, width=16,
                     bg=color, fg="white", relief="raised",
                     bd=2, font=("Segoe UI", 11),
                     padx=10, pady=4).grid(row=i, column=4, sticky="w", padx=(14, 0))

            var_min, var_max = tk.StringVar(), tk.StringVar()
            lbl_min = tk.Label(grid, textvariable=var_min, bg=color,
                               fg=("white" if key != "manager" else "#4a2e00"),
                               font=("Segoe UI", 10, "bold"),
                               padx=8, relief="raised", bd=2)
            lbl_min.grid(row=i, column=5, sticky="w", padx=(6, 0))
            lbl_min.grid_remove()

            lbl_max = tk.Label(grid, textvariable=var_max, bg=color,
                               fg=("white" if key != "manager" else "#4a2e00"),
                               font=("Segoe UI", 10, "bold"),
                               padx=8, relief="raised", bd=2)
            lbl_max.grid(row=i, column=6, sticky="w", padx=(6, 0))
            lbl_max.grid_remove()

            self.rows[key] = {
                "pct": var_pct, "entry_pct": entry,
                "venta": var_venta, "revao": var_revao,
                "min": var_min, "max": var_max,
                "lbl_min": lbl_min, "lbl_max": lbl_max,
            }

        # ─── Rango + tabla ─────────────────────────
        self.var_rango = tk.StringVar(value="")
        row_rango = tk.Frame(wrap)
        row_rango.pack(fill="x", padx=(LEFT, RIGHT))

        tk.Label(row_rango, text="Venta dentro del rango:",
                 font=("Segoe UI", 14, "bold"),
                 fg=ACCENT_PURPLE).pack(side="left")
        tk.Label(row_rango, textvariable=self.var_rango,
                 font=("Segoe UI", 14, "bold"),
                 fg=ACCENT_PURPLE).pack(side="left")

        ref = tk.Frame(wrap)
        ref.pack(fill="both", expand=True, padx=(LEFT, RIGHT))

        self.tree = ttk.Treeview(
            ref, columns=("v", "sin", "sup", "man", "vp"),
            show="headings", height=9
        )
        self.tree.pack(fill="both", expand=True)

        for col, title in zip(
            ("v", "sin", "sup", "man", "vp"),
            ("Venta", "Sin aprobación", "Supervisor", "Manager", "Senior Manager")
        ):
            self.tree.heading(col, text=title, anchor="center")
            self.tree.column(col, anchor="center", stretch=True)

        datos = [
            ("0-99 EUR", "35", "", "", ""),
            ("100-249 EUR", "30", "", "", ""),
            ("250-849 EUR", "25", "", "", ""),
            ("850-1749 EUR", "22,5", "20–22,4", "", ""),
            ("1750-2249 EUR", "20", "17,5–19,9", "", ""),
            ("2250-3499 EUR", "20", "15–19,9", "", ""),
            ("3500-5499 EUR", "20", "15–19,9", "12,5–14,9", ""),
            ("5500-9999 EUR", "20", "15–19,9", "12,6–14,9", "10–12,5"),
            ("+10000 EUR", "15", "", "", "10–12,5"),
        ]

        self.range_key_to_iid = {}
        for row in datos:
            iid = self.tree.insert("", "end", values=row)
            key = row[0].replace(" EUR", "").replace("€", "").replace(" ", "")
            self.range_key_to_iid[key] = iid

    # ==========================================
    # EVENTOS Y CÁLCULOS
    # ==========================================
    def _format_coste_and_recalc(self):
        try:
            self.var_coste.set(fmt_num_2(parse_num(self.var_coste.get())))
        except:
            pass

    def _extraer_maximo(self, texto):
        return texto.split("–")[-1] if texto and "–" in texto else ""

    def _on_coste_change(self):
        coste = parse_num(self.var_coste.get())

        if coste <= 0:
            self.var_rango.set("")
            self.tree.selection_remove(self.tree.selection())
            for r in self.rows.values():
                r["lbl_min"].grid_remove()
                r["lbl_max"].grid_remove()
                for f in ("pct", "venta", "revao", "min", "max"):
                    r[f].set("")
            return

        # ✅ LIMPIEZA PREVENTIVA (ESTA ES LA CORRECCIÓN)
        # Evita valores residuales al cambiar de rango
        for r in self.rows.values():
            r["pct"].set("")
            r["venta"].set("")
            r["revao"].set("")
            r["min"].set("")
            r["max"].set("")
            r["lbl_min"].grid_remove()
            r["lbl_max"].grid_remove()

        mins = minimos_por_coste(coste)
        self.var_rango.set(mins["rango"].replace(" EUR", " €"))

        key = mins["rango"].replace(" EUR", "").replace("€", "").replace(" ", "")
        iid = self.range_key_to_iid.get(key)
        if iid:
            self.tree.selection_set(iid)
            self.tree.focus(iid)
            self.tree.see(iid)

            values = self.tree.item(iid, "values")
            for idx, role in enumerate(("sin_aprob", "supervisor", "manager", "joao"), start=1):
                max_txt = self._extraer_maximo(values[idx])
                if max_txt:
                    self.rows[role]["max"].set(f"{max_txt} %")
                    self.rows[role]["lbl_max"].grid()
                else:
                    self.rows[role]["lbl_max"].grid_remove()

        for role in self.rows:
            m = mins.get(role)
            if m is not None:
                self.rows[role]["min"].set(f"{fmt_pct_1(m)} %")
                self.rows[role]["pct"].set(fmt_pct_1(m))
                self.rows[role]["lbl_min"].grid()
                self._validate_and_calc_row(role)
            else:
                self.rows[role]["lbl_min"].grid_remove()

    def _on_pct_focus(self, key):
        entry = self.rows[key]["entry_pct"]
        entry.after_idle(lambda: (entry.select_range(0, "end"), entry.icursor("end")))

    def _on_pct_change(self, key):
        self._validate_and_calc_row(key)

    def _validate_and_calc_row(self, key):
        coste = parse_num(self.var_coste.get())
        txt = self.rows[key]["pct"].get().strip()
        if not txt:
            self.rows[key]["venta"].set("")
            self.rows[key]["revao"].set("")
            return
        try:
            pct = float(txt.replace(",", "."))
        except:
            return

        venta, revao = calcular_venta_revao(coste, pct)
        self.rows[key]["venta"].set(fmt_num_2(venta))
        self.rows[key]["revao"].set(fmt_num_2(revao))

    def _copiar_venta(self, key):
        txt = self.rows[key]["venta"].get()
        if txt:
            self.clipboard_clear()
            self.clipboard_append(txt)

    def _on_toggle_permitir(self):
        pass

    def _reset_all(self):
        self.var_coste.set("")
        self.var_rango.set("")
        self.var_permitir.set(False)
        self.tree.selection_remove(self.tree.selection())
        for r in self.rows.values():
            r["lbl_min"].grid_remove()
            r["lbl_max"].grid_remove()
            for f in ("pct", "venta", "revao", "min", "max"):
                r[f].set("")

# tabs/ader/tab_ader.py

import tkinter as tk
from tkinter import ttk, messagebox
from typing import Optional

# Utilidades importadas desde la nueva estructura modular
from utils.fuel.fuel_utils import (
    ader_load_config, ader_get_month, ader_set_month,
    ader_percent_to_4digits, ader_parse_fuel_to_percent,
    ader_calcular, ADER_MESES
)

from utils.formatting.formatos import fmt_num_2, fmt_num_3, parse_num
from utils.ui.styles import (
    ACCENT_GREEN, LOCAL_BG, NAC_BG
)

class AderFuelTab(ttk.Frame):
    def __init__(self, master, shared_coste_var: Optional[tk.StringVar] = None):
        super().__init__(master, padding=8)


        # Configuración
        self.cfg = ader_load_config()

        # Crear fichero por defecto si abril está vacío
        loc0, nac0 = ader_get_month(self.cfg, "abril")
        if loc0 == 0.0 and nac0 == 0.0:
            ader_set_month(self.cfg, "abril", 1.701, 2.992)
            self.cfg = ader_load_config()

        # ✅ Seleccionar automáticamente el último mes del JSON
        self.mes_actual = list(self.cfg.keys())[-1] if self.cfg else "abril"


        # Variables
        self.var_mes = tk.StringVar(value=self.mes_actual)
        self.var_coste = shared_coste_var if shared_coste_var is not None else tk.StringVar(value="")

        self.var_imp_local = tk.StringVar()
        self.var_imp_nac = tk.StringVar()
        self.var_res_local = tk.StringVar(value="—")
        self.var_res_nac = tk.StringVar(value="—")
        self.var_fuel_local = tk.StringVar(value="")
        self.var_fuel_nac = tk.StringVar(value="")

        self.var_lbl_supl_local = tk.StringVar(value="Suplemento combustible:")
        self.var_lbl_supl_nac   = tk.StringVar(value="Suplemento combustible:")

        self._build()
        self._init_traces()
        self.reload_from_disk_and_recalc()

    # =========================
    # BUILD UI
    # =========================
    def _build(self):

        # ───── Parte superior (Mes + Coste) ────────────
        top = ttk.Frame(self)
        top.grid(row=0, column=0, sticky="ew", pady=(0, 6))
        self.columnconfigure(0, weight=1)

        ttk.Label(top, text="Mes:").pack(side="left", padx=(0, 4))
        self.cb = ttk.Combobox(top, textvariable=self.var_mes,
                               values=self._sorted_months(), state="readonly", width=14)
        self.cb.pack(side="left", padx=(0, 12))
        self.cb.bind("<<ComboboxSelected>>", lambda e: self._on_month_changed())

        ttk.Label(top, text="Coste ofertado (€):").pack(side="left", padx=(0, 6))
        ttk.Entry(top, textvariable=self.var_coste, width=18).pack(side="left")

        ttk.Separator(self, orient="horizontal").grid(row=1, column=0, sticky="ew")

        # ───── Cuerpo con panel Local y panel Nacional ────────────
        body = ttk.Frame(self)
        body.grid(row=2, column=0, sticky="nsew")
        self.rowconfigure(2, weight=1)
        body.columnconfigure(0, weight=1)
        body.columnconfigure(1, weight=1)
        body.rowconfigure(0, weight=1)

        # PANEL LOCAL
        lf_wrap = ttk.Frame(body, style="PanelLocal.TFrame", padding=8)
        lf_wrap.grid(row=0, column=0, sticky="nsew", padx=(0, 4), pady=(8, 8))
        lf_wrap.rowconfigure(0, weight=1)
        lf_wrap.columnconfigure(0, weight=1)

        lf = ttk.LabelFrame(lf_wrap, text="Local", style="Local.TLabelframe")
        lf.grid(row=0, column=0, sticky="nsew")
        lf.columnconfigure(1, weight=1)
        lf.rowconfigure(6, weight=1)

        ttk.Label(lf, text="Resultado final (fuel incluido):",
                  style="BoldLocal.TLabel").grid(row=0, column=0, sticky="w", pady=(4, 2))

        ttk.Entry(
            lf, textvariable=self.var_res_local, width=18,
            state="readonly", justify="right"
        ).grid(row=0, column=1, sticky="e", pady=(4, 2))

        ttk.Button(
            lf, text="⭐ Copiar coste",
            style="ActionGreen.TButton",
            command=self._send_local_to_calc
        ).grid(row=0, column=2, sticky="w", padx=(6, 0))

        ttk.Label(
            lf, textvariable=self.var_lbl_supl_local,
            style="BoldLocal.TLabel"
        ).grid(row=1, column=0, sticky="w")

        ttk.Label(
            lf, textvariable=self.var_imp_local,
            style="ValueLocal.TLabel", anchor="e"
        ).grid(row=1, column=1, sticky="e")

        ttk.Label(
            lf, text="FUEL (Δ):", style="BoldLocal.TLabel"
        ).grid(row=2, column=0, sticky="w", pady=(6, 0))

        ttk.Label(
            lf, textvariable=self.var_fuel_local,
            style="ValueLocal.TLabel", anchor="e"
        ).grid(row=2, column=1, sticky="e", pady=(6, 0))

        tk.Frame(lf, bg=ACCENT_GREEN, height=2)\
            .grid(row=3, column=0, columnspan=3, sticky="ew", pady=(8, 6))

        txt_local_frame = ttk.Frame(lf, style="PanelLocal.TFrame")
        txt_local_frame.grid(row=6, column=0, columnspan=3, sticky="nsew")
        txt_local_frame.rowconfigure(0, weight=1)
        txt_local_frame.columnconfigure(0, weight=1)

        self.txt_local = tk.Text(
            txt_local_frame, wrap="word", bg=LOCAL_BG, fg="#222",
            relief="flat", borderwidth=0, highlightthickness=0,
            insertbackground="#222"
        )
        self.txt_local.grid(row=0, column=0, sticky="nsew")

        ysl_local = ttk.Scrollbar(
            txt_local_frame, orient="vertical", command=self.txt_local.yview
        )
        ysl_local.grid(row=0, column=1, sticky="ns")
        self.txt_local.configure(yscrollcommand=ysl_local.set)

        ttk.Button(
            lf, text="Copiar Local",
            style="ActionGreen.TButton",
            command=lambda: self._copiar(self.txt_local)
        ).grid(row=7, column=0, columnspan=3, sticky="w", pady=(6, 4))

        # PANEL NACIONAL
        nf_wrap = ttk.Frame(body, style="PanelNac.TFrame", padding=8)
        nf_wrap.grid(row=0, column=1, sticky="nsew", padx=(4, 0), pady=(8, 8))
        nf_wrap.rowconfigure(0, weight=1)
        nf_wrap.columnconfigure(0, weight=1)

        nf = ttk.LabelFrame(nf_wrap, text="Nacional", style="Nac.TLabelframe")
        nf.grid(row=0, column=0, sticky="nsew")
        nf.columnconfigure(1, weight=1)
        nf.rowconfigure(6, weight=1)

        ttk.Label(
            nf, text="Resultado final (fuel incluido):",
            style="BoldNac.TLabel"
        ).grid(row=0, column=0, sticky="w", pady=(4, 2))

        ttk.Entry(
            nf, textvariable=self.var_res_nac, width=18,
            state="readonly", justify="right"
        ).grid(row=0, column=1, sticky="e", pady=(4, 2))

        ttk.Button(
            nf, text="⭐ Copiar coste",
            style="ActionGreen.TButton",
            command=self._send_nac_to_calc
        ).grid(row=0, column=2, sticky="w", padx=(6, 0))

        ttk.Label(
            nf, textvariable=self.var_lbl_supl_nac,
            style="BoldNac.TLabel"
        ).grid(row=1, column=0, sticky="w")

        ttk.Label(
            nf, textvariable=self.var_imp_nac,
            style="ValueNac.TLabel", anchor="e"
        ).grid(row=1, column=1, sticky="e")

        ttk.Label(
            nf, text="FUEL (Δ):",
            style="BoldNac.TLabel"
        ).grid(row=2, column=0, sticky="w", pady=(6, 0))

        ttk.Label(
            nf, textvariable=self.var_fuel_nac,
            style="ValueNac.TLabel", anchor="e"
        ).grid(row=2, column=1, sticky="e", pady=(6, 0))

        tk.Frame(nf, bg=ACCENT_GREEN, height=2)\
            .grid(row=3, column=0, columnspan=3, sticky="ew", pady=(8, 6))

        txt_nac_frame = ttk.Frame(nf, style="PanelNac.TFrame")
        txt_nac_frame.grid(row=6, column=0, columnspan=3, sticky="nsew")
        txt_nac_frame.rowconfigure(0, weight=1)
        txt_nac_frame.columnconfigure(0, weight=1)

        self.txt_nac = tk.Text(
            txt_nac_frame, wrap="word", bg=NAC_BG, fg="#222",
            relief="flat", borderwidth=0, highlightthickness=0,
            insertbackground="#222"
        )
        self.txt_nac.grid(row=0, column=0, sticky="nsew")

        ysl_nac = ttk.Scrollbar(
            txt_nac_frame, orient="vertical", command=self.txt_nac.yview
        )
        ysl_nac.grid(row=0, column=1, sticky="ns")
        self.txt_nac.configure(yscrollcommand=ysl_nac.set)

        ttk.Button(
            nf, text="Copiar Nacional",
            style="ActionGreen.TButton",
            command=lambda: self._copiar(self.txt_nac)
        ).grid(row=7, column=0, columnspan=3, sticky="w", pady=(6, 4))

    # ==========================
    # EVENTOS Y CÁLCULOS
    # ==========================

    def _init_traces(self):
        try:
            self.var_coste.trace_add("write", lambda *_: self._calc_silent())
        except Exception:
            self.var_coste.trace("w", lambda *_: self._calc_silent())

    def _sorted_months(self):
        keys = list(self.cfg.keys())
        ordered = [m for m in ADER_MESES if m in keys] + \
                  sorted([k for k in keys if k not in ADER_MESES])
        return ordered or ADER_MESES

    def _on_month_changed(self):
        self._load_month_into_ui()
        self._calc_silent()

    def _update_supl_label_texts(self):
        mes = (self.var_mes.get() or "").strip().lower()
        if mes:
            self.var_lbl_supl_local.set(f"Suplemento combustible (mes de {mes}):")
            self.var_lbl_supl_nac.set(  f"Suplemento combustible (mes de {mes}):")
        else:
            self.var_lbl_supl_local.set("Suplemento combustible:")
            self.var_lbl_supl_nac.set("Suplemento combustible:")

    def _load_month_into_ui(self):
        mes = (self.var_mes.get() or "").lower()
        p_loc, p_nac = ader_get_month(self.cfg, mes)

        self.var_imp_local.set(ader_percent_to_4digits(p_loc))
        self.var_imp_nac.set(ader_percent_to_4digits(p_nac))

        self._update_supl_label_texts()

    def _calc_core(self):
        mes = (self.var_mes.get() or "").lower()
        p_loc, p_nac = ader_get_month(self.cfg, mes)

        try:
            coste, fuel_l, fuel_n, tb_l, tb_n = ader_calcular(
                self.var_coste.get(), p_loc, p_nac
            )
        except Exception:
            return None

        return {
            "mes": mes,
            "p_loc": p_loc,
            "p_nac": p_nac,
            "coste": coste,
            "fuel_l": fuel_l,
            "fuel_n": fuel_n,
            "tb_l": tb_l,
            "tb_n": tb_n
        }

    def _calc_ui(self, res):
        if not res:
            self.var_res_local.set("—")
            self.var_res_nac.set("—")
            self.var_fuel_local.set("")
            self.var_fuel_nac.set("")
            self._set_text(self.txt_local, "")
            self._set_text(self.txt_nac, "")
            return

        self.var_res_local.set(fmt_num_2(res["tb_l"]) + " €")
        self.var_res_nac.set(fmt_num_2(res["tb_n"]) + " €")
        self.var_fuel_local.set(fmt_num_3(res["fuel_l"]))
        self.var_fuel_nac.set(fmt_num_3(res["fuel_n"]))

        base_txt = (
            "Buenos días,\n\n"
            "Por favor proceder con el servicio conforme a lo acordado.\n"
            "Os rogamos que trasladéis las siguientes indicaciones al conductor, "
            "con el objetivo de garantizar una correcta ejecución del servicio "
            "y evitar posibles incidencias:\n"
            "- Es imprescindible informar de inmediato de cualquier retraso, "
            "incidencia o discrepancia con respecto a lo solicitado o prealertado, "
            "para poder gestionarlo con la mayor agilidad posible y evitar "
            "afectaciones al servicio."
        )

        txt_local = (
            base_txt +
            f"\n\nPorcentaje aplicado: {res['p_loc']:.3f}\n"
            "Para locales < 75 Km y vehículos < 3500kg.\n\n"
            "Cuyo importe es:\n"
            f"{fmt_num_2(res['coste'])} ofertado + {fmt_num_3(res['fuel_l'])} fuel = "
            f"{fmt_num_2(res['tb_l'])} € + IVA\n\n"
            "Por favor si no es correcto, indicadlo antes de facturar.\n\n"
            "Manolo."
        )

        txt_nac = (
            base_txt +
            f"\n\nPorcentaje aplicado: {res['p_nac']:.3f}\n"
            "Para nacionales o locales > 75 Km y vehículos ≥ 3500kg.\n\n"
            "Cuyo importe es:\n"
            f"{fmt_num_2(res['coste'])} ofertado + {fmt_num_3(res['fuel_n'])} fuel = "
            f"{fmt_num_2(res['tb_n'])} € + IVA\n\n"
            "Por favor si no es correcto, indicadlo antes de facturar.\n\n"
            "Manolo."
        )

        self._set_text(self.txt_local, txt_local)
        self._set_text(self.txt_nac, txt_nac)

    def _calc_silent(self):
        res = self._calc_core()
        self._calc_ui(res)

    def reload_from_disk_and_recalc(self):
        self.cfg = ader_load_config()
        self.cb["values"] = self._sorted_months()

        cur = (self.var_mes.get() or "").lower()
        if cur not in self.cfg and self.cb["values"]:
            self.var_mes.set(list(self.cfg.keys())[-1])


        self._load_month_into_ui()
        self._calc_silent()

    def _set_text(self, widget: tk.Text, content: str):
        widget.config(state="normal")
        widget.delete("1.0", "end")
        widget.insert("1.0", content)
        widget.config(state="normal")

    def _copiar(self, widget: tk.Text):
        contenido = widget.get("1.0", "end").strip()
        self.clipboard_clear()
        self.clipboard_append(contenido)
        messagebox.showinfo("Copiado", "Texto copiado al portapapeles.")

    # ✅ ÚNICO CAMBIO REAL
    def _activar_hoja_calculadora(self):
        parent = self
        while parent is not None:
            if isinstance(parent, ttk.Notebook):
                parent.select(0)  # ✅ Activar pestaña CALCULADORA
                return
            parent = parent.master
    def _send_local_to_calc(self):
        txt = (self.var_res_local.get() or "").strip()
        if not txt:
            return
        self.var_coste.set(fmt_num_2(parse_num(txt)))
        self._activar_hoja_calculadora()
        

    def _send_nac_to_calc(self):
        txt = (self.var_res_nac.get() or "").strip()
        if not txt:
            return
        self.var_coste.set(fmt_num_2(parse_num(txt)))
        self._activar_hoja_calculadora()
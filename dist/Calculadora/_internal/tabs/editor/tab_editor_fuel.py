# tabs/editor/tab_editor_fuel.py

import tkinter as tk
from tkinter import ttk, messagebox

# Utilidades desde módulos separados
from utils.fuel.fuel_utils import (
    ader_load_config, ader_save_config
)

from utils.ui.styles import ACCENT_GREEN


class AderEditorTab(ttk.Frame):

    def __init__(self, master, on_saved_callback=None):
        super().__init__(master, padding=12)
        self.on_saved_callback = on_saved_callback

        self.cfg = ader_load_config()

        self._build()
        self._populate()
        self._update_buttons_state()

    # =======================================================
    # UI
    # =======================================================

    def _build(self):
        style = ttk.Style()

        # ---------------------------
        # FILA DE ENTRADAS
        # ---------------------------
        row = ttk.Frame(self)
        row.grid(row=0, column=0, columnspan=7, sticky="ew", pady=(0, 8))

        # --- Mes ---
        ttk.Label(row, text="Mes:").pack(side="left", padx=(0, 4))
        self.var_mes = tk.StringVar()
        self.ent_mes = tk.Entry(row, textvariable=self.var_mes,
                                width=16, relief="solid", bd=1)
        self.ent_mes.pack(side="left", padx=(0, 12))

        # --- Local ---
        ttk.Label(row, text="Local (%):").pack(side="left", padx=(0, 4))
        self.var_local = tk.StringVar()
        self.ent_local = tk.Entry(row, textvariable=self.var_local,
                                  width=10, relief="solid", bd=1)
        self.ent_local.pack(side="left", padx=(0, 12))

        # --- Nacional ---
        ttk.Label(row, text="Nacional (%):").pack(side="left", padx=(0, 4))
        self.var_nac = tk.StringVar()
        self.ent_nac = tk.Entry(row, textvariable=self.var_nac,
                                width=10, relief="solid", bd=1)
        self.ent_nac.pack(side="left")

        # Validaciones
        self.var_mes.trace_add("write", lambda *_: self._validate_mes())
        self.var_local.trace_add("write", lambda *_: self._validate_number(self.ent_local, self.var_local))
        self.var_nac.trace_add("write", lambda *_: self._validate_number(self.ent_nac, self.var_nac))

        # ---------------------------
        # TABLA
        # ---------------------------
        cols = ("mes", "local", "nacional")
        self.tree = ttk.Treeview(self, columns=cols, show="headings", height=12)
        for c in cols:
            self.tree.heading(c, text=c.capitalize())

        self.tree.grid(row=1, column=0, columnspan=6,
                       sticky="nsew", pady=(4, 8))

        self.rowconfigure(1, weight=1)
        self.columnconfigure(0, weight=1)

        ysb = ttk.Scrollbar(self, orient="vertical", command=self.tree.yview)
        self.tree.configure(yscrollcommand=ysb.set)
        ysb.grid(row=1, column=6, sticky="ns")

        self.tree.bind("<<TreeviewSelect>>", lambda e: self._on_sel())

        # ---------------------------
        # BOTONES
        # ---------------------------
        btn_frame = ttk.Frame(self)
        btn_frame.grid(row=2, column=0, columnspan=7, sticky="ew")

        self.btn_add_upd = tk.Button(
            btn_frame, text="➕ Añadir / Actualizar",
            command=self._add_or_update,
            bg="#27ae60", fg="white",
            activebackground="#2ecc71",
            relief="flat", cursor="hand2",
            padx=10, pady=5
        )
        self.btn_add_upd.grid(row=0, column=0, padx=(0, 8))

        self.btn_mod = tk.Button(
            btn_frame, text="✏️ Modificar",
            command=self._load_selected_to_inputs,
            bg="#f39c12", fg="white",
            activebackground="#e67e22",
            relief="flat", cursor="hand2",
            padx=10, pady=5
        )
        self.btn_mod.grid(row=0, column=1, padx=(0, 8))

        self.btn_del = tk.Button(
            btn_frame, text="🗑️ Eliminar",
            command=self._delete_sel,
            bg="#e74c3c", fg="white",
            activebackground="#c0392b",
            relief="flat", cursor="hand2",
            padx=10, pady=5
        )
        self.btn_del.grid(row=0, column=2, padx=(0, 8))


    # =======================================================
    # VALIDACIONES
    # =======================================================

    def _set_valid(self, entry):
        entry.config(highlightthickness=1, highlightbackground="#bdc3c7")

    def _set_invalid(self, entry):
        entry.config(highlightthickness=2, highlightbackground="#e74c3c")

    def _validate_mes(self):
        ok = bool(self.var_mes.get().strip())
        self._set_valid(self.ent_mes) if ok else self._set_invalid(self.ent_mes)
        return ok

    def _validate_number(self, entry, var):
        val = var.get().strip().replace(",", ".")
        try:
            float(val)
            self._set_valid(entry)
            return True
        except:
            self._set_invalid(entry)
            return False

    def _all_valid(self):
        return (
            self._validate_mes() and
            self._validate_number(self.ent_local, self.var_local) and
            self._validate_number(self.ent_nac, self.var_nac)
        )


    # =======================================================
    # FUNCIONALIDAD
    # =======================================================

    def _populate(self):
        self.tree.delete(*self.tree.get_children())

        for mes, d in self.cfg.items():
            self.tree.insert(
                "", "end",
                values=(
                    mes,
                    f"{d.get('local', 0):.3f}",
                    f"{d.get('nacional', 0):.3f}",
                )
            )

    def _on_sel(self):
        self._update_buttons_state()

    def _update_buttons_state(self):
        if self.tree.selection():
            self.btn_mod.config(state="normal", bg="#f39c12")
            self.btn_del.config(state="normal", bg="#e74c3c")
        else:
            self.btn_mod.config(state="disabled", bg="#bdc3c7")
            self.btn_del.config(state="disabled", bg="#bdc3c7")

    def _load_selected_to_inputs(self):
        sel = self.tree.selection()
        if not sel:
            return

        mes, loc, nac = self.tree.item(sel[0], "values")

        # Se cargan directamente tal como están en el Treeview
        self.var_mes.set(mes)
        self.var_local.set(loc)
        self.var_nac.set(nac)

    def _clear_inputs(self):
        self.var_mes.set("")
        self.var_local.set("")
        self.var_nac.set("")

    def _save_and_callback(self):
        ader_save_config(self.cfg)
        if callable(self.on_saved_callback):
            self.on_saved_callback()

    def _add_or_update(self):
        if not self._all_valid():
            messagebox.showwarning("Validación", "Revisa los campos en rojo")
            return

        try:
            mes = self.var_mes.get().strip().lower()

            local = float(self.var_local.get().replace(",", "."))
            nac = float(self.var_nac.get().replace(",", "."))

            # GUARDAR SIN PORCENTAJE ✔
            self.cfg[mes] = {
                "local": local,
                "nacional": nac,
            }

            self._populate()
            self._save_and_callback()
            self._clear_inputs()

        except Exception as e:
            messagebox.showerror("Error", str(e))

    def _delete_sel(self):
        sel = self.tree.selection()
        if not sel:
            return

        mes = self.tree.item(sel[0], "values")[0]

        if mes in self.cfg:
            if messagebox.askyesno("Confirmar",
                                   f"¿Seguro que quieres eliminar '{mes}'?"):
                del self.cfg[mes]
                self._populate()
                self._save_and_callback()
                self._clear_inputs()
                self._update_buttons_state()
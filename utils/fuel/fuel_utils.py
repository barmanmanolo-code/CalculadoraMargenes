# utils/fuel/fuel_utils.py

import os
import sys
import json
from typing import Dict, Tuple
from decimal import Decimal, ROUND_HALF_UP

from utils.formatting.formatos import parse_num

# ==========================================
# CONFIGURACIÓN DEL ARCHIVO JSON (✅ FIX EXE)
# ==========================================

def base_path():
    """
    Devuelve la ruta base correcta:
    - En desarrollo: carpeta del proyecto
    - En .exe: carpeta donde está el ejecutable
    """
    if getattr(sys, "frozen", False):
        return os.path.dirname(sys.executable)
    else:
        return os.path.abspath(".")

BASE_PATH = base_path()
CONFIG_DIR = os.path.join(BASE_PATH, "config")
ADER_CONFIG_FILE = os.path.join(CONFIG_DIR, "fuel_config.json")

ADER_MESES = [
    "enero","febrero","marzo","abril","mayo","junio",
    "julio","agosto","septiembre","octubre","noviembre","diciembre"
]

# ==========================================
# UTILIDADES DE CONFIGURACIÓN
# ==========================================

def ader_load_config() -> Dict[str, Dict[str, float]]:
    """Carga porcentajes locales y nacionales desde JSON."""
    if not os.path.exists(ADER_CONFIG_FILE):
        return {}

    try:
        with open(ADER_CONFIG_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}


def ader_save_config(cfg: Dict[str, Dict[str, float]]):
    """Guarda el diccionario de fuel en JSON."""
    try:
        os.makedirs(CONFIG_DIR, exist_ok=True)
        with open(ADER_CONFIG_FILE, "w", encoding="utf-8") as f:
            json.dump(cfg, f, ensure_ascii=False, indent=2)
    except Exception:
        pass


def ader_get_month(cfg: Dict[str, Dict[str, float]], mes: str) -> Tuple[float, float]:
    """Obtiene porcentajes del mes: (local, nacional)."""
    d = cfg.get((mes or "").lower(), {})
    return float(d.get("local", 0.0)), float(d.get("nacional", 0.0))


def ader_set_month(cfg: Dict[str, Dict[str, float]], mes: str, p_loc: float, p_nac: float):
    """Actualiza los porcentajes de fuel para un mes concreto."""
    cfg[(mes or "").lower()] = {
        "local": float(p_loc),
        "nacional": float(p_nac),
    }
    ader_save_config(cfg)

# ==========================================
# PARSEOS Y CONVERSIONES
# ==========================================

def ader_percent_to_4digits(p: float) -> str:
    try:
        if p is None:
            return ""
        p = float(p)
    except Exception:
        return ""

    entero = int(p)
    milesimas = int(round((p - entero) * 1000))

    if milesimas == 1000:
        entero += 1
        milesimas = 0

    return f"{milesimas:04d}" if entero == 0 else f"{entero}{milesimas:03d}"


def ader_parse_fuel_to_percent(s: str) -> float:
    if s is None:
        return 0.0

    txt = str(s).strip().replace("%", "").replace(" ", "")
    if not txt:
        return 0.0

    if txt.isdigit():
        if len(txt) >= 4:
            entero = int(txt[:-3]) if len(txt) > 3 else 0
            miles = int(txt[-3:])
            return float(entero) + miles / 1000.0
        if len(txt) == 3:
            return int(txt) / 1000.0
        return float(txt)

    t = txt
    has_dot = "." in t
    has_com = "," in t

    if has_dot and has_com:
        if t.rfind(",") > t.rfind("."):
            t = t.replace(".", "").replace(",", ".")
        else:
            t = t.replace(",", "")
    elif has_com:
        t = t.replace(",", ".")
    elif has_dot:
        parts = t.split(".")
        if len(parts) == 2 and len(parts[1]) == 3 and parts[0].isdigit():
            t = t.replace(".", "")

    try:
        return float(t)
    except Exception:
        return 0.0

# ==========================================
# CÁLCULO DE FUEL
# ==========================================

def ader_calcular(coste_txt: str, pct_local: float, pct_nac: float):
    coste = parse_num(coste_txt)

    factor_local = 1.0 + pct_local / 100.0
    factor_nac = 1.0 + pct_nac / 100.0

    tb_local = float(
        Decimal(coste * factor_local).quantize(Decimal("0.01"), ROUND_HALF_UP)
    )
    tb_nac = float(
        Decimal(coste * factor_nac).quantize(Decimal("0.01"), ROUND_HALF_UP)
    )

    fuel_l = float(
        Decimal(tb_local - coste).quantize(Decimal("0.001"), ROUND_HALF_UP)
    )
    fuel_n = float(
        Decimal(tb_nac - coste).quantize(Decimal("0.001"), ROUND_HALF_UP)
    )

    return coste, fuel_l, fuel_n, tb_local, tb_nac
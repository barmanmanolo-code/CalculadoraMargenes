# utils/formatting/formatos.py

from decimal import Decimal, ROUND_HALF_UP
from typing import Optional, Tuple, Dict, Any
import re

# =========================
# FORMATEO DE NÚMEROS
# =========================

def fmt_num_2(x: float) -> str:
    q = Decimal(x).quantize(Decimal("0.01"), ROUND_HALF_UP)
    return (
        f"{q:,.2f}"
        .replace(",", "X")
        .replace(".", ",")
        .replace("X", ".")
    )

def fmt_num_3(x: float) -> str:
    q = Decimal(x).quantize(Decimal("0.001"), ROUND_HALF_UP)
    s = f"{q:,.3f}"
    return (
        s.replace(",", "X")
        .replace(".", ",")
        .replace("X", ".")
    )

def fmt_pct_1(x: float) -> str:
    q = Decimal(x).quantize(Decimal("0.1"), ROUND_HALF_UP)
    return str(q).replace(".", ",")


# =========================
# PARSEO DE NÚMEROS
# =========================

def parse_num(s: str) -> float:
    if s is None:
        return 0.0

    txt = str(s).strip()
    for ch in ("€", "EUR", "eur", "Eur", " "):
        txt = txt.replace(ch, "")
    txt = txt.strip()
    if not txt:
        return 0.0

    has_dot = "." in txt
    has_com = "," in txt

    try:
        if has_dot and has_com:
            last_dot = txt.rfind(".")
            last_com = txt.rfind(",")
            if last_com > last_dot:
                txt = txt.replace(".", "")
                txt = txt.replace(",", ".")
            else:
                txt = txt.replace(",", "")
        elif has_com and not has_dot:
            parts = txt.split(",")
            if len(parts) == 2 and len(parts[1]) != 3:
                txt = txt.replace(",", ".")
            else:
                txt = txt.replace(",", "")
        elif has_dot and not has_com:
            parts = txt.split(".")
            if len(parts) == 2:
                if len(parts[1]) == 3 and parts[0].isdigit():
                    txt = txt.replace(".", "")
            elif len(parts) > 2:
                txt = txt.replace(".", "")

        return float(txt)

    except Exception:
        try:
            return float(txt.replace(",", "."))
        except Exception:
            return 0.0


# =========================
# CÁLCULOS DE VENTA Y REVAO
# =========================

def calcular_venta_revao(coste: float, pct: float) -> Tuple[Optional[float], Optional[float]]:
    if coste <= 0 or pct <= 0 or pct >= 100:
        return None, None

    resto = 1 - pct / 100
    if resto <= 0:
        return None, None

    venta = coste / resto
    return venta, venta - coste


# =========================
# MÍNIMOS POR COSTE
# =========================

def minimos_por_coste(coste: float) -> Dict[str, Any]:
    res = {"rango": "", "sin_aprob": None, "supervisor": None, "manager": None, "joao": None}

    if coste <= 0:
        return res

    if coste <= 69:
        res["sin_aprob"] = 35
        res["rango"] = "0-99 EUR"
    elif coste <= 187:
        res["sin_aprob"] = 30
        res["rango"] = "100-249 EUR"
    elif coste <= 658:
        res["sin_aprob"] = 25
        res["rango"] = "250-849 EUR"
    elif coste <= 1399:
        res["sin_aprob"] = 22.5
        res["rango"] = "850-1749 EUR"
    elif coste <= 1855:
        res["sin_aprob"] = 20
        res["rango"] = "1750-2249 EUR"
    elif coste <= 2975:
        res["sin_aprob"] = 20
        res["rango"] = "2250-3499 EUR"
    elif coste <= 4812:
        res["sin_aprob"] = 20
        res["rango"] = "3500-5499 EUR"
    elif coste <= 9000:
        res["sin_aprob"] = 20
        res["rango"] = "5500-9999 EUR"
    else:
        res["sin_aprob"] = 15
        res["rango"] = "+10000 EUR"

    if 659 <= coste <= 679:
        tabla = {
            659: 22.5, 660: 22.4, 661: 22.3, 662: 22.2, 663: 22.1,
            664: 21.9, 665: 21.8, 666: 21.7, 667: 21.6, 668: 21.5,
            669: 21.3, 670: 21.2, 671: 21.1, 672: 21.0, 673: 20.9,
            674: 20.9, 675: 20.6, 676: 20.5, 677: 20.4, 678: 20.3, 679: 20.2
        }
        res["supervisor"] = tabla[max(k for k in tabla if k <= int(coste))]
    elif 659 <= coste <= 1399:
        res["supervisor"] = 20
    elif 1400 <= coste <= 1855:
        if coste >= 1444: res["supervisor"] = 17.5
        elif coste >= 1442: res["supervisor"] = 17.6
        elif coste >= 1441: res["supervisor"] = 17.7
        elif coste >= 1440: res["supervisor"] = 17.8
        else: res["supervisor"] = 17.5
    elif 1856 <= coste <= 2975:
        res["supervisor"] = 15
    elif coste >= 2976:
        res["supervisor"] = 15

    if 2976 <= coste <= 4812:
        res["manager"] = 12.5
    elif 4813 <= coste <= 9000:
        res["manager"] = 12.6

    if coste > 4813:
        res["joao"] = 10

    return res

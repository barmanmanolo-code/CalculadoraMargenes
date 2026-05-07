import os
import sys

def base_path():
    """
    Devuelve la ruta base correcta tanto en desarrollo
    como cuando se ejecuta como .exe con PyInstaller
    """
    if getattr(sys, 'frozen', False):
        return os.path.dirname(sys.executable)
    else:
        return os.path.abspath(".")
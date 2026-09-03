"""Genera el icono de BeautyConnect en todas las densidades de Android.

La marca es un frasco de esmalte blanco sobre fondo negro, con dos destellos. Se dibuja
a 1024 px y se reduce, para que los bordes queden limpios en los tamanos chicos.

Se ejecuta desde la raiz del proyecto:  python docs/marca/generar_icono.py
"""

import os
from PIL import Image, ImageDraw

BASE = 'android/app/src/main/res'
LIENZO = 1024

NEGRO = (43, 43, 43)
NEGRO_PROFUNDO = (15, 15, 15)
BLANCO = (255, 255, 255)


def fondo_degradado(tamano):
    """Negro en diagonal, de gris oscuro arriba a casi negro abajo."""
    imagen = Image.new('RGB', (tamano, tamano))
    pixeles = imagen.load()

    for y in range(tamano):
        for x in range(tamano):
            t = (x + y) / (2 * tamano - 2)
            pixeles[x, y] = tuple(
                round(NEGRO[i] + (NEGRO_PROFUNDO[i] - NEGRO[i]) * t)
                for i in range(3)
            )

    return imagen


def frasco_esmalte(dibujo, cx, cy, alto, color):
    """Frasco de esmalte: tapa, cuello y cuerpo.

    Se eligio el frasco y no la silueta de una una porque a 48 px una una sin
    contexto se confunde con un bombillo o un dedo; el frasco se reconoce solo.
    """
    ancho_cuerpo = alto * 0.58
    alto_cuerpo = alto * 0.50
    ancho_tapa = alto * 0.27
    alto_tapa = alto * 0.34
    alto_cuello = alto * 0.10

    arriba = cy - alto / 2

    # Tapa
    dibujo.rounded_rectangle(
        [
            cx - ancho_tapa / 2,
            arriba,
            cx + ancho_tapa / 2,
            arriba + alto_tapa,
        ],
        radius=ancho_tapa * 0.36,
        fill=color,
    )

    # Cuello
    dibujo.rectangle(
        [
            cx - ancho_tapa * 0.20,
            arriba + alto_tapa,
            cx + ancho_tapa * 0.20,
            arriba + alto_tapa + alto_cuello,
        ],
        fill=color,
    )

    # Cuerpo
    cuerpo_arriba = arriba + alto_tapa + alto_cuello
    dibujo.rounded_rectangle(
        [
            cx - ancho_cuerpo / 2,
            cuerpo_arriba,
            cx + ancho_cuerpo / 2,
            cuerpo_arriba + alto_cuerpo,
        ],
        radius=ancho_cuerpo * 0.24,
        fill=color,
    )


def destello(dibujo, cx, cy, radio, color):
    """Brillo de cuatro puntas, como el icono de 'auto_awesome'."""
    largo = radio
    ancho = radio * 0.24

    dibujo.polygon(
        [
            (cx, cy - largo),
            (cx + ancho, cy - ancho),
            (cx + largo, cy),
            (cx + ancho, cy + ancho),
            (cx, cy + largo),
            (cx - ancho, cy + ancho),
            (cx - largo, cy),
            (cx - ancho, cy - ancho),
        ],
        fill=color,
    )


def dibujar_marca(tamano, escala=1.0):
    """El frasco y sus destellos, sobre fondo transparente."""
    # Se dibuja al triple y se reduce: los bordes curvos quedan sin dientes.
    detalle = tamano * 3
    lienzo = Image.new('RGBA', (detalle, detalle), (0, 0, 0, 0))
    dibujo = ImageDraw.Draw(lienzo)

    centro = detalle / 2
    cx = centro - detalle * 0.045 * escala
    cy = centro + detalle * 0.025 * escala

    frasco_esmalte(dibujo, cx, cy, detalle * 0.58 * escala, BLANCO + (255,))

    destello(
        dibujo,
        cx + detalle * 0.225 * escala,
        cy - detalle * 0.185 * escala,
        detalle * 0.10 * escala,
        BLANCO + (255,),
    )
    destello(
        dibujo,
        cx + detalle * 0.285 * escala,
        cy - detalle * 0.015 * escala,
        detalle * 0.052 * escala,
        BLANCO + (235,),
    )

    return lienzo.resize((tamano, tamano), Image.LANCZOS)


def esquinas_redondas(imagen, radio):
    mascara = Image.new('L', imagen.size, 0)
    ImageDraw.Draw(mascara).rounded_rectangle(
        [0, 0, imagen.size[0] - 1, imagen.size[1] - 1],
        radius=radio,
        fill=255,
    )
    salida = imagen.convert('RGBA')
    salida.putalpha(mascara)
    return salida


def guardar(imagen, ruta, tamano):
    os.makedirs(os.path.dirname(ruta), exist_ok=True)
    imagen.resize((tamano, tamano), Image.LANCZOS).save(ruta)


# ---- icono clasico: fondo rosa con la marca encima ----
completo = fondo_degradado(LIENZO).convert('RGBA')
completo.alpha_composite(dibujar_marca(LIENZO))
redondeado = esquinas_redondas(completo, int(LIENZO * 0.22))

# ---- capa de frente para el icono adaptativo (Android 8+) ----
# El sistema recorta hasta un 33%, asi que la marca va mas pequena y centrada.
frente = Image.new('RGBA', (LIENZO, LIENZO), (0, 0, 0, 0))
frente.alpha_composite(dibujar_marca(LIENZO, escala=0.62))

DENSIDADES = {
    'mdpi': (48, 108),
    'hdpi': (72, 162),
    'xhdpi': (96, 216),
    'xxhdpi': (144, 324),
    'xxxhdpi': (192, 432),
}

for nombre, (clasico, adaptativo) in DENSIDADES.items():
    carpeta = '%s/mipmap-%s' % (BASE, nombre)
    guardar(redondeado, '%s/ic_launcher.png' % carpeta, clasico)
    guardar(redondeado, '%s/ic_launcher_round.png' % carpeta, clasico)
    guardar(frente, '%s/ic_launcher_foreground.png' % carpeta, adaptativo)
    print('  %-8s %3d px  /  %3d px' % (nombre, clasico, adaptativo))

# ---- logo grande para la pantalla de arranque ----
guardar(dibujar_marca(LIENZO), '%s/drawable/splash_logo.png' % BASE, 288)
guardar(dibujar_marca(LIENZO), '%s/drawable-v21/splash_logo.png' % BASE, 288)

# ---- version para usar dentro de la app ----
os.makedirs('docs/marca', exist_ok=True)
guardar(redondeado, 'docs/marca/logo-beautyconnect.png', 512)

print('listo')

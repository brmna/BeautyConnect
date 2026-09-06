import 'package:flutter/material.dart';

import '../../data/services/servicio_subida_imagenes.dart';

class AdjuntarFotos extends StatelessWidget {
  final String titulo;
  final List<String> fotos;
  final bool subiendo;
  final VoidCallback onAgregar;
  final ValueChanged<int> onQuitar;
  final int maximo;

  const AdjuntarFotos({
    super.key,
    required this.fotos,
    required this.subiendo,
    required this.onAgregar,
    required this.onQuitar,
    this.titulo = 'Fotos del resultado',
    this.maximo = 6,
  });

  bool get _cabenMas => fotos.length < maximo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              titulo,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: (subiendo || !_cabenMas) ? null : onAgregar,
              icon: subiendo
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_a_photo_outlined, size: 16),
              label: Text(_cabenMas ? 'Agregar' : 'Máximo $maximo'),
            ),
          ],
        ),
        if (fotos.isNotEmpty)
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: fotos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, indice) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      ServicioSubidaImagenes.miniatura(
                        fotos[indice],
                        ancho: 200,
                      ),
                      width: 78,
                      height: 78,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => onQuitar(indice),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/margenes.dart';

enum TipoTextoLegal { terminos, privacidad }

class TextoLegalScreen extends StatelessWidget {
  final TipoTextoLegal tipo;

  const TextoLegalScreen({super.key, required this.tipo});

  bool get _sonTerminos => tipo == TipoTextoLegal.terminos;

  @override
  Widget build(BuildContext context) {
    final secciones = _sonTerminos ? _terminos : _privacidad;

    return Scaffold(
      backgroundColor: TemaApp.grisClaro,
      appBar: AppBar(
        title: Text(
          _sonTerminos ? 'Términos de Servicio' : 'Política de Privacidad',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          margenInferior(context, base: 16),
        ),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final seccion in secciones) ...[
                    Text(
                      seccion.titulo,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      seccion.cuerpo,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: TemaApp.grisSubtitulo,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Última actualizacion: agosto de 2026',
                    style: TextStyle(fontSize: 11, color: TemaApp.grisTexto),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Seccion {
  final String titulo;
  final String cuerpo;

  const _Seccion(this.titulo, this.cuerpo);
}

const List<_Seccion> _terminos = [
  _Seccion(
    '1. Aceptacion de términos',
    'Al utilizar BeautyConnect aceptas estos términos de servicio. Si no estas '
        'de acuerdo, no utilices la aplicación.',
  ),
  _Seccion(
    '2. Uso del servicio',
    'BeautyConnect es una plataforma que conecta clientes con manicuristas '
        'independientes de Villavicencio. La aplicación se encuentra en versión '
        'beta como parte de un trabajo de grado, por lo que puede presentar '
        'cambios o interrupciones.',
  ),
  _Seccion(
    '3. Cuentas de usuario',
    'Eres responsable de mantener la confidencialidad de tu cuenta y '
        'contraseña. Notificanos si detectas un uso no autorizado.',
  ),
  _Seccion(
    '4. Reservas',
    'Las reservas se solicitan a traves de la aplicación y quedan confirmadas '
        'cuando tu manicurista las acepta. BeautyConnect no procesa pagos: el '
        'valor del servicio se acuerda y se paga directamente entre el cliente '
        'y tu manicurista.',
  ),
  _Seccion(
    '5. Cancelaciones',
    'Tanto el cliente como tu manicurista pueden cancelar una cita desde la '
        'aplicación. Al cancelar, el horario queda disponible nuevamente. Se '
        'recomienda avisar con la mayor anticipacion posible.',
  ),
  _Seccion(
    '6. Responsabilidad',
    'BeautyConnect actúa como intermediario entre clientes y manicuristas. No '
        'nos hacemos responsables por la calidad del servicio prestado ni por '
        'los acuerdos economicos entre las partes.',
  ),
  _Seccion(
    '7. Modificaciones',
    'Podemos modificar estos términos en cualquier momento. Los cambios '
        'importantes se informaran dentro de la aplicación.',
  ),
];

const List<_Seccion> _privacidad = [
  _Seccion(
    '1. Información que recopilamos',
    'Recopilamos nombre, correo electrónico, teléfono y ubicación aproximada '
        'para prestar el servicio. Las manicuristas pueden agregar ademas su '
        'dirección, especialidades, certificaciones y fotografias de su '
        'trabajo.',
  ),
  _Seccion(
    '2. Uso de la información',
    'Utilizamos tu información para permitir reservas entre clientes y '
        'manicuristas, enviarte recordatorios de tus citas y mejorar la '
        'aplicacion.',
  ),
  _Seccion(
    '3. Con quien se comparte',
    'No vendemos tu información. Los datos de contacto y ubicación de una '
        'manicurista son visibles para quienes tienen cuenta, ya que son '
        'necesarios para agendar. Tu nombre es visible para tu manicurista '
        'cuando agendas.',
  ),
  _Seccion(
    '4. Imagenes',
    'Las fotografias del portafolio y de las reseñas se almacenan en un '
        'servicio externo de gestión de imagenes. Al eliminarlas de la '
        'aplicación dejan de mostrarse, aunque el archivo puede permanecer en '
        'ese servicio.',
  ),
  _Seccion(
    '5. Seguridad',
    'El acceso a los datos esta protegido por autenticación y por reglas de '
        'seguridad que limitan que cada usuario solo pueda modificar su propia '
        'informacion.',
  ),
  _Seccion(
    '6. Tus derechos',
    'Puedes acceder y corregir tu información desde tu perfil, o solicitar la '
        'eliminación de tu cuenta escribiendonos.',
  ),
  _Seccion(
    '7. Contexto académico',
    'BeautyConnect se desarrolla como trabajo de grado del programa Tecnología '
        'en Desarrollo de Software de la Corporación Universitaria Minuto de '
        'Dios, Rectoría Orinoquía. Los datos recogidos durante las pruebas se '
        'usan unicamente con fines académicos.',
  ),
];

# BeautyConnect

Aplicación móvil en Flutter para conectar manicuristas independientes con clientas en Villavicencio, Meta. Permite buscar profesionales, reservar citas, chatear sobre ellas y calificar el servicio una vez terminado. Es un trabajo de grado de Tecnología en Desarrollo de Software (Uniminuto, Rectoría Orinoquía) y todavía está en fase beta.

La app tiene dos roles con navegación y pantallas separadas: cliente y profesional (manicurista). El rol se define al registrarse y determina qué se muestra después de iniciar sesión.

## Estructura del proyecto

```
lib/
├── main.dart              punto de entrada: inicializa Firebase, idioma es_CO y el tema
├── main_screen.dart       navegación inferior del cliente
├── theme/                 tema visual de la app
├── utils/                 formato de fechas/precios, validaciones, deep links, distancias, etc.
├── data/
│   ├── models/             profesional, reseña, horario, modalidad de cita, ubicación...
│   └── services/           acceso a Firestore, chat, notificaciones, subida de imágenes, IA
└── presentation/
    ├── screens/             pantallas de cliente y de profesional
    └── widgets/             componentes reutilizables (hojas modales, tarjetas, calendario...)
```

## Funcionalidades

### Autenticación

Registro e inicio de sesión con correo/contraseña o con Google, verificación de correo obligatoria, recuperación y cambio de contraseña, y cambio de correo (que queda pendiente hasta confirmarse en el buzón nuevo). Un profesional nuevo pasa por un onboarding de tres pasos (ubicación, contacto y especialidades, horario base) antes de poder usar la app.

### Cliente

- Galería de inspiración con fotos del portafolio de todas las profesionales, con búsqueda por texto, por etiqueta y por foto (usando reconocimiento de imágenes, ver más abajo).
- Búsqueda de profesionales en lista o en mapa, con filtros por nombre, zona y especialidad, orden por calificación, relevancia o distancia, y opción de escanear el código QR de una profesional.
- Perfil de cada profesional con información, servicios, portafolio y reseñas, y reserva de cita eligiendo fecha, hora y modalidad (en el local de la profesional o a domicilio, según lo que ella ofrezca).
- Favoritos, separados en diseños guardados y profesionales guardadas.
- Mis citas, agrupadas en pendientes, próximas y pasadas, con chat por cita, opción de pedir otro horario sin cancelar, cancelación con motivo y calificación una vez completada la cita.
- Perfil propio editable (foto, teléfono, bio, género) y vista de las reseñas que ha escrito y recibido.

### Profesional

- Panel principal con métricas de calificación, solicitudes pendientes, próximas citas y sugerencias para completar el perfil.
- Agenda de citas: aceptar, rechazar, reagendar, marcar como completadas, responder propuestas de cambio de horario del cliente, y chat con cada clienta.
- Gestión de servicios (nombre, precio, duración, foto) y de portafolio (fotos con título y etiquetas).
- Horarios: calendario mensual para bloquear o abrir franjas puntuales, y horario base semanal por día.
- Lista de clientes atendidos con historial y gasto acumulado por cliente.
- Certificados y perfil público con especialidades, zona de cobertura, redes sociales y código QR para compartir el perfil.
- Configuración de disponibilidad (aceptar nuevas citas, auto-aceptar solicitudes, anticipación mínima), de domicilio (zona de cobertura en mapa, recargo) y desactivación de cuenta.

### Detalles del funcionamiento

Las reseñas son en ambos sentidos: la clienta califica a la profesional y la profesional también califica a la clienta después de cada cita, y ambos promedios quedan visibles en los perfiles respectivos. Una cita activa se puede reprogramar sin cancelarla mediante una propuesta de cambio que la otra parte acepta o rechaza. En citas a domicilio, la dirección exacta de la clienta solo se revela a la profesional una vez que confirma la cita; antes de eso solo ve una zona aproximada. Desactivar una cuenta la oculta de las búsquedas sin borrar sus datos, y se reactiva sola al volver a iniciar sesión.

El chat, las notificaciones de recordatorio (24 y 2 horas antes de una cita confirmada) y los avisos de cambios de cita se generan automáticamente a partir de lo que pasa con las reservas en Firestore, sin que el usuario tenga que configurarlos.

Los enlaces `beautyconnect://perfil/{id}` se usan para compartir el perfil de una profesional, generar su código QR y abrirlo directamente al escanearlo.

## Servicios externos

Además de Firebase, la app usa dos servicios opcionales que se activan por variables de entorno en tiempo de compilación. Si no están configurados, la función correspondiente se desactiva con un aviso en vez de romper la app:

- **Gemini** (`GEMINI_API_KEY`, `GEMINI_MODELO`): usado solo en la búsqueda por foto de la galería de inspiración, para identificar si una imagen es de uñas y sugerir etiquetas.
- **Cloudinary** (`CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_UPLOAD_PRESET`): usado para subir cualquier foto de la app (perfil, servicios, portafolio, certificados, reseñas).

El mapa de ubicación y cobertura usa `flutter_map` sobre OpenStreetMap, no requiere clave.

## Configuración de Firebase

### Autenticación

1. En [Firebase Console](https://console.firebase.google.com), entra a Authentication → Sign-in method.
2. Habilita Email/Password.
3. Si vas a usar el inicio de sesión con Google, habilita también el proveedor de Google y registra el SHA-1 de tu keystore en la configuración de la app Android.

### Firestore

Crea la base de datos en modo de producción y en la región que prefieras. Las reglas de seguridad ya están en [`firestore.rules`](firestore.rules) en la raíz del proyecto; despliégalas con `firebase deploy --only firestore:rules` o pégalas manualmente en Firestore → Reglas.

Algunas consultas necesitan índices compuestos. Firebase los pide automáticamente la primera vez que se ejecuta una consulta nueva: el error en el log de debug trae un enlace que crea el índice directo en la consola. Los que se usan desde el inicio son:

| Colección | Campos |
|---|---|
| `bookings` | `professionalId` asc, `date` asc |
| `bookings` | `professionalId` asc, `status` asc |
| `bookings` | `clientId` asc, `createdAt` desc |
| `users/*/services` | `createdAt` asc |
| `users/*/portfolio` | `createdAt` desc |

## Cómo ejecutar

```bash
flutter pub get
flutter run \
  --dart-define=GEMINI_API_KEY=tu_clave \
  --dart-define=CLOUDINARY_CLOUD_NAME=tu_nube \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=tu_preset
```

Los `--dart-define` son opcionales para correr la app; sin ellos simplemente la búsqueda por foto y la subida de imágenes quedan desactivadas.

Las configuraciones de Firebase (`lib/firebase_options.dart` y `android/app/google-services.json`) son locales y están excluidas de git. Para preparar una copia nueva del proyecto:

1. Instala `flutterfire_cli` (`dart pub global activate flutterfire_cli`) y ejecuta `flutterfire configure` con acceso al proyecto de Firebase.
2. Verifica que `android/app/google-services.json` haya quedado en su sitio; si no, descárgalo desde Firebase Console.

Si una credencial llegó a publicarse por error, revócala y genera una nueva. Las API keys de Firebase también deberían restringirse por aplicación y por API desde Google Cloud Console.

## Pruebas

```bash
flutter test
```

Hay pruebas unitarias para la lógica que no depende de Firebase ni de la UI: validaciones, formato, cálculo de distancias, estados de cita, deep links, reseñas, disponibilidad, mensajes de error de autenticación, entre otras, en la carpeta `test/`.

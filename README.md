# 💅 Beauty App — Guía de Configuración y Firebase

Aplicación móvil Flutter para gestión de citas de manicuristas independientes en Villavicencio.

---

## 📁 Estructura del Proyecto

```
lib/
├── main.dart
├── main_screen.dart                        
├── firebase_options.dart
├── theme/
│   └── app_theme.dart
├── utils/
│   └── responsive.dart
├── widgets/
│   ├── beauty_button.dart
│   ├── beauty_logo.dart
│   ├── beauty_text_field.dart
│   └── user_type_selector.dart
├── data/
│   ├── auth_repository.dart
│   ├── models/
│   │   └── professional_model.dart
│   └── services/
│       ├── image_service.dart
│       └── profesional_service.dart
└── presentation/
    ├── auth_provider.dart
    ├── auth_wrapper.dart
    └── screens/
        ├── login_screen.dart
        ├── register_screen.dart
        ├── client_favorites_screen.dart
        ├── client_appointments_screen.dart
        ├── client_profile_screen.dart     
        ├── search_screen.dart
        ├── professional_detail_screen.dart
        ├── professional_home.dart
        ├── professional_agenda_screen.dart
        ├── professional_services_screen.dart
        ├── professional_portfolio_screen.dart
        └── professional_profile_screen.dart
```

---

## 🔥 Configuración de Firebase

### Paso 1 — Autenticación

1. Ve a [Firebase Console](https://console.firebase.google.com) 
2. **Authentication** → **Sign-in method**
3. Habilita **Email/Password**
4. Guarda

---

### Paso 2 — Firestore Database

1. Ve a **Firestore Database** → **Crear base de datos**
2. Selecciona **Modo de producción** 
3. Elige la región 

#### Reglas de Firestore

Ve a **Firestore** → **Reglas** y pega esto:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Usuarios: cada uno lee/escribe su propio doc
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;

      // Servicios del profesional: cualquier autenticado puede leer
      match /services/{serviceId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && request.auth.uid == userId;
      }

      // Portafolio del profesional: cualquier autenticado puede leer
      match /portfolio/{photoId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && request.auth.uid == userId;
      }
    }

    // Citas: el cliente o el profesional pueden leer/escribir
    match /bookings/{bookingId} {
      allow read: if request.auth != null &&
        (resource.data.clientId == request.auth.uid ||
         resource.data.professionalId == request.auth.uid);
      allow create: if request.auth != null;
      allow update: if request.auth != null &&
        (resource.data.clientId == request.auth.uid ||
         resource.data.professionalId == request.auth.uid);
    }
  }
}
```

---

### Paso 3 — Índices de Firestore

Algunos queries requieren índices compuestos. Firebase los solicita automáticamente la primera vez que se ejecuta la query (aparece un link en el log de debug). Para crearlos manualmente:

Ve a **Firestore** → **Índices** → **Agregar índice**:

| Colección | Campo 1 | Campo 2 | Orden |
|-----------|---------|---------|-------|
| `bookings` | `professionalId` (Ascendente) | `date` (Ascendente) | — |
| `bookings` | `professionalId` (Ascendente) | `status` (Ascendente) | — |
| `bookings` | `clientId` (Ascendente) | `createdAt` (Descendente) | — |
| `users/*/services` | `createdAt` (Ascendente) | — | — |
| `users/*/portfolio` | `createdAt` (Descendente) | — | — |

> **Alternativa rápida:** ejecuta la app en debug y cuando aparezca el error de índice en la consola, haz click en el link que aparece — te lleva directo a crearlo en Firebase.

---

## 📦 Dependencias — Agregar a pubspec.yaml

Agrega `intl` si no está:

```yaml
dependencies:
  intl: ^0.19.0
  # ... resto de dependencias existentes
```

Luego ejecuta:
```bash
flutter pub get
```

---

## 🚀 Funcionalidades Implementadas

### Para Clientes
- ✅ Registro e inicio de sesión
- ✅ Galería de inspiración
- ✅ Búsqueda de manicuristas por nombre o zona
- ✅ Ver perfil detallado del profesional (foto, servicios, portafolio)
- ✅ **Reservar cita** con fecha y hora
- ✅ **Favoritos** — guardar/quitar profesionales favoritos
- ✅ **Mis Citas** — ver estado, cancelar citas pendientes
- ✅ **Perfil** — editar nombre, teléfono; cerrar sesión

### Para Manicuristas (Profesionales)
- ✅ Registro e inicio de sesión como profesional
- ✅ **Agenda** — citas pendientes, confirmadas, historial
- ✅ **Gestión de citas** — confirmar, rechazar, marcar completadas
- ✅ **Servicios** — agregar, editar, eliminar servicios con precio y duración
- ✅ **Portafolio** — agregar/eliminar fotos de trabajos
- ✅ **Perfil** — editar nombre, ubicación, bio, especialidades, foto; estadísticas; cerrar sesión

---

## P.

- La app redirige automáticamente según el rol (`client` → MainScreen, `professional` → ProfessionalHome)
- Las fotos del portafolio se ingresan por URL (para agregar upload de imágenes, configurar **Firebase Storage** — ver abajo)

### Configurar Firebase Storage (opcional — para subir fotos reales)

1. Firebase Console → **Storage** → **Comenzar**
2. Selecciona modo de producción
3. Reglas de Storage:
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /portfolio/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /profiles/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```
4. Agrega `firebase_storage` al pubspec y actualiza `image_service.dart`

---

## 📱 Cómo Ejecutar

```bash
flutter pub get
flutter run --dart-define=PEXELS_API_KEY=tu_clave_de_pexels
```

Las configuraciones de Firebase y las claves de servicios externos son locales y están excluidas de Git. Para preparar una copia nueva del proyecto:

1. Ejecuta `flutterfire configure` con acceso al proyecto Firebase y conserva los archivos generados localmente.
2. Descarga `android/app/google-services.json` desde Firebase Console.
3. Ejecuta la app pasando la clave de Pexels mediante `--dart-define`; no la escribas en el código.

Si una credencial ya fue publicada, revócala y genera una nueva. Las API keys de Firebase también deben tener restricciones por aplicación y API desde Google Cloud Console.
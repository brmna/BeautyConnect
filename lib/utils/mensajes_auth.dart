String mensajeErrorAuth(String codigo) {
  switch (codigo) {
    case 'invalid-email':
      return 'El correo no es válido';
    case 'user-not-found':
      return 'No existe una cuenta con ese correo';
    case 'wrong-password':
      return 'La contraseña no es correcta';
    case 'invalid-credential':
      return 'Correo o contraseña incorrectos';
    case 'user-disabled':
      return 'Esa cuenta está deshabilitada';
    case 'email-already-in-use':
      return 'Ya existe una cuenta con ese correo';
    case 'weak-password':
      return 'La contraseña es muy débil';
    case 'network-request-failed':
      return 'Sin conexión a internet';
    case 'too-many-requests':
      return 'Demasiados intentos, espera un momento';
    default:
      return 'Ocurrió un error, intenta de nuevo';
  }
}

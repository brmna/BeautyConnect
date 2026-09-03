import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleNoConfigurado implements Exception {
  const GoogleNoConfigurado();
}

class AuthRepository {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Stream<User?> authState() => _auth.authStateChanges();

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    try {
      await _crearPerfil(
        uid: credential.user!.uid,
        nombre: name,
        correo: email,
        rol: role,
      );
    } catch (_) {
      try {
        await credential.user?.delete();
      } catch (_) {}
      rethrow;
    }

    await enviarVerificacion();
  }

  Future<void> enviarVerificacion() async {
    final usuario = _auth.currentUser;
    if (usuario == null || usuario.emailVerified) return;
    await usuario.sendEmailVerification();
  }

  Future<bool> revisarVerificacion() async {
    final usuario = _auth.currentUser;
    if (usuario == null) return false;

    await usuario.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  bool get correoNecesitaVerificacion {
    final usuario = _auth.currentUser;
    if (usuario == null) return false;
    if (usuario.emailVerified) return false;

    return usuario.providerData.any((p) => p.providerId == 'password');
  }

  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> enviarRecuperacion(String correo) {
    return _auth.sendPasswordResetEmail(email: correo.trim());
  }

  Future<bool> entrarConGoogle({required String rol}) async {
    final google = GoogleSignIn.instance;

    try {
      await google.initialize();
    } catch (_) {
      throw const GoogleNoConfigurado();
    }

    final GoogleSignInAccount cuenta;
    try {
      cuenta = await google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      rethrow;
    }

    final autorizacion = cuenta.authentication;

    final credencial = GoogleAuthProvider.credential(
      idToken: autorizacion.idToken,
    );

    final resultado = await _auth.signInWithCredential(credencial);
    final usuario = resultado.user;
    if (usuario == null) return false;

    final referencia = _firestore.collection('users').doc(usuario.uid);
    if ((await referencia.get()).exists) return true;

    await _crearPerfil(
      uid: usuario.uid,
      nombre: cuenta.displayName ?? usuario.displayName ?? '',
      correo: cuenta.email,
      rol: rol,
      fotoUrl: cuenta.photoUrl,
    );

    return true;
  }

  Future<void> _crearPerfil({
    required String uid,
    required String nombre,
    required String correo,
    required String rol,
    String? fotoUrl,
  }) {
    return _firestore.collection('users').doc(uid).set({
      'name': nombre,
      'email': correo,
      'role': rol,
      'photoUrl': ?fotoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> cambiarCorreo({
    required String contrasenaActual,
    required String correoNuevo,
  }) async {
    final usuario = _auth.currentUser;
    if (usuario == null || usuario.email == null) {
      throw FirebaseAuthException(code: 'no-current-user');
    }

    final credencial = EmailAuthProvider.credential(
      email: usuario.email!,
      password: contrasenaActual,
    );
    await usuario.reauthenticateWithCredential(credencial);

    await usuario.verifyBeforeUpdateEmail(correoNuevo.trim());
  }

  bool get puedeCambiarCorreo =>
      _auth.currentUser?.providerData.any((p) => p.providerId == 'password') ??
      false;

  Future<void> logout() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}

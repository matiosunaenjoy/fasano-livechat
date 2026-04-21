import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/service_locator.dart';
import 'core/services/notification_service.dart';
import 'core/models/user_model.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyBRSWTEWcOK07e_6LaX8RpjwAhyZMUrj2M',
      appId: '1:278029831412:web:3ddd732fd4726dfb3f62a1',
      messagingSenderId: '278029831412',
      projectId: 'empresa-chat-2b2a7',
      authDomain: 'empresa-chat-2b2a7.firebaseapp.com',
      storageBucket: 'empresa-chat-2b2a7.firebasestorage.app',
      measurementId: 'G-TLDWC5DS9G',
    ),
  );
  services.init();
  runApp(const EmpresaChat());
}

class EmpresaChat extends StatelessWidget {
  const EmpresaChat({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Empresa Chat',
      debugShowCheckedModeBanner: false,
      theme: whatsappTheme,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    notificationService.onNotificationTap.listen((chatId) {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: services.authRepository.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF111B21),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF00A884)),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          notificationService.init(snapshot.data!.uid);
          return HomeScreen(currentUser: snapshot.data!);
        }

        return const LoginScreen();
      },
    );
  }
}

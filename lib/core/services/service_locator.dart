import '../../core/repositories/auth_repository.dart';
import '../../core/repositories/chat_repository.dart';
import '../../core/repositories/message_repository.dart';
import '../../core/repositories/user_directory_repository.dart';
import '../../data/firebase/firebase_auth_repo.dart';
import '../../data/firebase/firebase_chat_repo.dart';
import '../../data/firebase/firebase_message_repo.dart';
import '../../data/firebase/firebase_directory_repo.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  late final AuthRepository authRepository;
  late final ChatRepository chatRepository;
  late final MessageRepository messageRepository;
  late final UserDirectoryRepository userDirectoryRepository;

  void init() {
    authRepository = FirebaseAuthRepository();
    chatRepository = FirebaseChatRepository();
    messageRepository = FirebaseMessageRepository();
    userDirectoryRepository = FirebaseDirectoryRepository();
  }
}

final services = ServiceLocator();

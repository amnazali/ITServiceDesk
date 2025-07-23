import 'dart:convert';
import 'package:get/get.dart';
import 'package:adf_ui/core/models/user_session.dart';
import 'package:adf_ui/core/utils/storage_manager.dart';
import 'package:adf_ui/core/utils/logger.dart';

class SessionController extends GetxController {
  static SessionController get instance => Get.find<SessionController>();
  
  final Rx<UserSession?> _currentSession = Rx<UserSession?>(null);
  
  UserSession? get currentSession => _currentSession.value;
  bool get isLoggedIn => _currentSession.value?.isValid == true;
  String? get token => _currentSession.value?.token;
  String? get userId => _currentSession.value?.userId;
  String? get userName => _currentSession.value?.userName;

  @override
  void onInit() {
    super.onInit();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final sessionData = await StorageManager.readData('user_session');
      if (sessionData != null) {
        final sessionMap = jsonDecode(sessionData);
        final session = UserSession.fromJson(sessionMap);
        
        if (!session.isExpired) {
          _currentSession.value = session;
          // Update last activity
          await updateLastActivity();
        } else {
          // Session expired, clear it
          await clearSession();
        }
      }
    } catch (e) {
      logger.e('Error loading session: $e');
      await clearSession();
    }
  }

  Future<void> createSession({
    required String token,
    required String userId,
    required String userName,
  }) async {
    final now = DateTime.now();
    final session = UserSession(
      token: token,
      userId: userId,
      userName: userName,
      loginTime: now,
      lastActivity: now,
    );
    
    _currentSession.value = session;
    await _saveSession();
  }

  Future<void> updateLastActivity() async {
    if (_currentSession.value != null) {
      _currentSession.value = _currentSession.value!.copyWith(
        lastActivity: DateTime.now(),
      );
      await _saveSession();
    }
  }

  Future<void> _saveSession() async {
    if (_currentSession.value != null) {
      final sessionJson = jsonEncode(_currentSession.value!.toJson());
      await StorageManager.saveData('user_session', sessionJson);
    }
  }

  Future<void> clearSession() async {
    _currentSession.value = null;
    await StorageManager.removeData('user_session');
    // Also clear individual keys for backward compatibility
    await StorageManager.removeData('token');
    await StorageManager.removeData('user_id');
    await StorageManager.removeData('user_name');
  }

  bool checkSessionValidity() {
    final session = _currentSession.value;
    if (session == null || !session.isValid || session.isExpired) {
      return false;
    }
    return true;
  }

  Future<void> refreshToken(String newToken) async {
    if (_currentSession.value != null) {
      _currentSession.value = _currentSession.value!.copyWith(
        token: newToken,
        lastActivity: DateTime.now(),
      );
      await _saveSession();
    }
  }
}
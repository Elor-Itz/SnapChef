import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/auth_service.dart';
import '../services/friend_service.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import '../models/preferences.dart';
import '../utils/ui_util.dart';

class UserViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  bool _isLoading = false;
  bool isLoggingOut = false;
  User? _user;
  Map<String, dynamic>? _userStats;

  bool get isLoading => _isLoading;
  User? get user => _user;

  String? get fridgeId => _user?.fridgeId;
  String? get cookbookId => _user?.cookbookId;
  Map<String, dynamic>? get userStats => _userStats;
  List<User> get friends => _user?.friends ?? [];

  // Fetch user data (including friends)
  Future<void> fetchUserData() async {
    try {
      final userProfile = await _userService.getUserData();
      _user = userProfile;
      notifyListeners();

      // Update FCM token after fetching user data
      final fcmToken = await FirebaseMessaging.instance.getToken();
      await updateFcmToken(fcmToken);
    } catch (e) {
      if (e.toString().contains('401')) {
        try {
          await _authService.refreshTokens();
          final userProfile = await _userService.getUserData();
          _user = userProfile;
          notifyListeners();

          // Update FCM token after refreshing user data
          final fcmToken = await FirebaseMessaging.instance.getToken();
          await updateFcmToken(fcmToken);
        } catch (refreshError) {
          _user = null;
          notifyListeners();
          rethrow;
        }
      } else {
        _user = null;
        notifyListeners();
        rethrow;
      }
    }
  }

  // Get friends list
  Future<List<User>> getFriends() async {
    await fetchUserData();
    return _user?.friends ?? [];
  }

  // Update User Profile
  Future<void> updateUser({
    required String firstName,
    required String lastName,
    String? password,
    File? profilePicture,
  }) async {
    _setLoading(true);
    try {
      final updatedData = await _userService.updateUser(
        firstName,
        lastName,
        password ?? '',
        profilePicture,
      );
      final newProfilePicture = updatedData['profilePicture'];
      if (_user != null) {
        _user = _user!.copyWith(
          firstName: firstName,
          lastName: lastName,
          password: password ?? _user!.password,
          profilePicture: profilePicture != null
              ? newProfilePicture ?? _user!.profilePicture
              : _user!.profilePicture,
        );
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Failed to update profile');
    } finally {
      _setLoading(false);
    }
  }

  // Update User Preferences
  Future<void> updateUserPreferences({
    List<String>? allergies,
    Map<String, bool>? dietaryPreferences,
    Map<String, bool>? notificationPreferences,
  }) async {
    if (_user == null) throw Exception('User not loaded');

    final updatedAllergies = allergies ?? _user!.preferences?.allergies ?? [];
    final updatedDietary =
        dietaryPreferences ?? _user!.preferences?.dietaryPreferences ?? {};
    final updatedNotifications =
        notificationPreferences ?? _user!.preferences?.notificationPreferences ?? {};

    await _userService.updateUserPreferences(
      allergies: updatedAllergies,
      dietaryPreferences: updatedDietary,
      notificationPreferences: updatedNotifications,
    );

    _user = _user!.copyWith(
      preferences: Preferences(
        allergies: updatedAllergies,
        dietaryPreferences: updatedDietary,
        notificationPreferences: updatedNotifications,
      ),
    );
    notifyListeners();
  }

  // Update FCM Token
  Future<void> updateFcmToken(String? token) async {
    if (token == null || token.isEmpty) return;
    try {
      await _userService.updateFcmToken(token);
      if (_user != null) {
        _user = _user!.copyWith(fcmToken: token);
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Failed to update FCM token: ${e.toString()}');
    }
  }

  // Listen for FCM token refresh and update backend
  void listenForFcmTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await updateFcmToken(newToken);
    });
  }

  // Delete User Account
  Future<void> deleteUser(BuildContext context) async {
    _setLoading(true);
    try {
      await _userService.deleteUser();
      _user = null;
      notifyListeners();
      if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (context.mounted) UIUtil.showError(context, e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Set the loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Set the logging out state
  void setLoggingOut(bool value) {
    isLoggingOut = value;
    notifyListeners();
  }

  // Fetch another user's profile by userId
  Future<User?> fetchUserProfile(String userId) async {
    try {
      final userProfile = await _userService.getUserProfile(userId);
      return userProfile;
    } catch (e) {
      return null;
    }
  }

  // Fetch user statistics
  Future<void> fetchUserStats({String? userId}) async {
    try {
      final stats = await _userService.getUserStats(userId: userId);
      _userStats = stats;
      notifyListeners();
    } catch (e) {
      _userStats = null;
      notifyListeners();
      rethrow;
    }
  }

  // Remove friend
  Future<void> removeFriend(String friendId) async {
    await FriendService().removeFriend(friendId);
    // Optionally, refresh the user data or friends list
    await fetchUserData();
  }
}

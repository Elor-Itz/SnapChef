import 'package:flutter/material.dart';
import 'package:snapchef/models/user.dart';
import 'package:snapchef/viewmodels/user_viewmodel.dart';
import 'package:snapchef/providers/connectivity_provider.dart';

import 'mock_connectivity_provider.dart';

class MockUserViewModel extends ChangeNotifier implements UserViewModel {
  @override
  ConnectivityProvider get connectivityProvider => MockConnectivityProvider();

  final Future<void> Function()? fetchUserDataOverride;

  MockUserViewModel({this.fetchUserDataOverride});

  Future<void> Function({
    String? firstName,
    String? lastName,
    String? password,
    dynamic profilePicture,
  })? updateUserCallback;

  Future<void> Function({Map<String, dynamic>? notificationPreferences})?
      updateUserPreferencesCallback;

  Future<void> Function(BuildContext context)? deleteUserCallback;

  Future<void> Function(String id)? removeFriendCallback;
  Future<User?> Function(String id)? fetchUserProfileCallback;

  @override
  bool get isLoading => _user == null;

  User? _user = User(
    id: 'test_user',
    firstName: 'Test',
    lastName: 'User',
    email: 'test@example.com',
    fridgeId: 'test_fridge_id',
    cookbookId: 'test_cookbook_id',
  );

  @override
  User? get user => _user;

  void setUser(User? value) {
    _user = value;
    notifyListeners();
  }

  @override
  String? get fridgeId => _user?.fridgeId;

  @override
  String? get cookbookId => _user?.cookbookId;

  String? get userId => _user?.id;

  String? get email => _user?.email;

  String? get name =>
      _user == null ? null : '${_user!.firstName} ${_user!.lastName}';

  @override
  Future<void> fetchUserData() async {
    if (fetchUserDataOverride != null) {
      return await fetchUserDataOverride!();
    }
    // Default: do nothing
  }

  @override
  void listenForFcmTokenRefresh() {}

  // Fallback for any other interface requirements
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  Map<String, dynamic>? _userStats = {
    'ingredientCount': 5,
    'recipeCount': 3,
    'favoriteRecipeCount': 2,
    'friendCount': 0,
    'mostPopularIngredients': [],
  };

  @override
  Map<String, dynamic>? get userStats => _userStats;

  void setUserStats(Map<String, dynamic> stats) {
    _userStats = stats;
    notifyListeners();
  }

  @override
  Future<void> updateUser({
    String? firstName,
    String? lastName,
    String? password,
    dynamic profilePicture,
  }) async {
    if (updateUserCallback != null) {
      return await updateUserCallback!(
        firstName: firstName,
        lastName: lastName,
        password: password,
        profilePicture: profilePicture,
      );
    }
    // Default: do nothing
  }

  @override
  Future<void> updateUserPreferences({
    Map<String, dynamic>? notificationPreferences,
    Map<String, dynamic>? dietaryPreferences,
    List<String>? allergies,
  }) async {
    if (updateUserPreferencesCallback != null) {
      // Only pass notificationPreferences for your test
      return await updateUserPreferencesCallback!(
        notificationPreferences: notificationPreferences,
      );
    }
    // Default: do nothing
  }

  @override
  Future<void> deleteUser(BuildContext context) async {
    if (deleteUserCallback != null) {
      return await deleteUserCallback!(context);
    }
    // Default: do nothing
  }

  @override
  Future<void> removeFriend(String id) async {
    if (removeFriendCallback != null) {
      return await removeFriendCallback!(id);
    }
    // Default: do nothing
  }

  @override
  Future<User?> fetchUserProfile(String id) async {
    if (fetchUserProfileCallback != null) {
      return await fetchUserProfileCallback!(id);
    }
    return null;
  }
}

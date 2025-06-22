import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/base_viewmodel.dart';
import '../core/session_manager.dart';
import '../services/auth_service.dart';
import '../utils/ui_util.dart';

class AuthViewModel extends BaseViewModel {
  final AuthService _authService;
  final GoogleSignIn _googleSignIn;

  // Constructor with optional parameters for dependency injection
  AuthViewModel({
    AuthService? authService,
    GoogleSignIn? googleSignIn,
  })  : _authService = authService ?? AuthService(),
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  /// Initiates the Google Sign-In process.
  /// After successful sign-in, it fetches the user profile and navigates to the main screen.
  Future<void> googleSignIn(
    BuildContext context,
    Future<void> Function() fetchUserProfile,
  ) async {
    setLoading(true);
    try {
      // Start the Google Sign-In process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Retrieve the idToken
        final idToken = googleAuth.idToken;

        if (idToken != null) {
          // Send the idToken to your backend for authentication
          await _authService.googleSignIn(idToken);

          // Fetch the user profile after successful sign-in using UserViewModel
          await fetchUserProfile();

          // Create a new session after fetching the profile
          if (context.mounted) {
            SessionManager.createSession(context);
          }
        } else {
          throw Exception('Failed to retrieve Google ID token');
        }
      }
    } catch (e) {
      if (context.mounted) {
        UIUtil.showError(context, 'Google Sign-In failed: $e');
      }
    } finally {
      setLoading(false);
    }
  }

  /// Logs in the user with the provided email and password.
  Future<void> login(
    String email,
    String password,
    BuildContext context,
    Future<void> Function() fetchUserProfile,
  ) async {
    setLoading(true);
    try {
      await _authService.login(email, password);

      // Fetch the user profile after login using UserViewModel
      await fetchUserProfile();

      // If login is successful, create a new session
      if (context.mounted) {
        SessionManager.createSession(context);
      }
    } catch (e) {
      final error = e.toString();
      if (context.mounted) {
        // If the error indicates that the email needs verification,
        // navigate to the verification screen with the email.
        if (error.contains('Please verify your email')) {
          Navigator.pushReplacementNamed(
            context,
            '/verify',
            arguments: {'email': email},
          );
          // If the error indicates that there is a mismatch in the details,
          // show an error message.
        } else if (error.contains('Wrong username or password')) {          
          UIUtil.showError(context, 'Wrong username or password. Please try again.');
        } else {
          // For any other error, show a generic error message.
          UIUtil.showError(context, error);
        }
      }
    } finally {
      setLoading(false);
    }
  }

  /// Signs up a new user with the provided details.
  Future<bool> signup(
    String firstName,
    String lastName,
    String email,
    String password,
    BuildContext context,
  ) async {
    setLoading(true);
    try {
      await _authService.signup(firstName, lastName, email, password);
      // Optionally show a success message here
      return true;
    } catch (e) {
      if (context.mounted) {
        UIUtil.showError(context, e.toString());
      }
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Logs out the user and clears the session.
  /// Navigates to the login screen after logout.
  Future<void> logout(BuildContext context) async {
    try {
      await _authService.logout();
      await SessionManager.clearSession();
      notifyListeners();
      if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (context.mounted) UIUtil.showError(context, e.toString());
    }
  }

  /// Refreshes the authentication tokens.
  Future<void> refreshTokens() async {
    try {
      await _authService.refreshTokens();
    } catch (e) {
      throw Exception('Failed to refresh tokens: $e');
    }
  }

  /// Verifies the OTP sent to the user's email.
  /// If successful, navigates to the login screen.
  Future<void> verifyOTP(String email, String otp, BuildContext context) async {
    setLoading(true);
    try {
      await _authService.verifyOTP(email, otp);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified! Please log in.')),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (context.mounted) UIUtil.showError(context, e.toString());
    } finally {
      setLoading(false);
    }
  }

  /// Resends the OTP to the user's email.
  Future<void> resendOTP(String email) async {
    setLoading(true);
    try {
      await _authService.resendOTP(email);
    } finally {
      setLoading(false);
    }
  }

  /// Requests a password reset by sending a reset code to the user's email.
  Future<void> requestPasswordReset(String email, BuildContext context) async {
    setLoading(true);
    try {
      await _authService.requestPasswordReset(email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Reset code sent! Please check your email.')),
        );
      }
    } catch (e) {
      if (context.mounted) UIUtil.showError(context, e.toString());
    } finally {
      setLoading(false);
    }
  }

  /// Confirms the password reset using the provided email, OTP, and new password.
  Future<void> confirmPasswordReset(String email, String otp,
      String newPassword, BuildContext context) async {
    setLoading(true);
    try {
      await _authService.confirmPasswordReset(email, otp, newPassword);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password reset successful! Please log in.')),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (context.mounted) UIUtil.showError(context, e.toString());
    } finally {
      setLoading(false);
    }
  }

  @override
  void clear() {
    setError(null);
    setLoading(false);
  }
}

/*
Auth repo -> outline the possible auth repo for this app
*/

import 'package:socialx/features/auth/domain/entities/app_users.dart';

abstract class AuthRepo {
  Future<AppUsers?> loginWithEmailPassword(String email, String password);
  Future<AppUsers?> registerWithEmailPassword(
      String name, String email, String password);
  Future<void> logout();
  Future<AppUsers?> getCurrentUsers();
  Future<void> deleteAccount(String currentPassword);
  Future<void> updateEmail(String newEmail, String currentPassword);
  Future<void> forgotPassword(String email);
}

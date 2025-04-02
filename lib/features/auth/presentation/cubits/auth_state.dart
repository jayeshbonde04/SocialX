/*
Auth state
 */

import 'package:socialx/features/auth/domain/entities/app_users.dart';

abstract class AuthState {}

//initial
class AuthInitial extends AuthState {}

//loading...
class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String message;
  AuthSuccess(this.message);
}

//Authenticated
class Authenticated extends AuthState {
  final AppUsers user;
  Authenticated(this.user);
}

class AuthFailure extends AuthState {
  final String error;
  AuthFailure(this.error);
}

class AuthErrors extends AuthState {
  final String message;
  AuthErrors(this.message);
}

//Unauthenticated
class Unauthenticated extends AuthState {}

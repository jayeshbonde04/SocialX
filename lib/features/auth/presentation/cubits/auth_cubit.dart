/*
Auth cubit state management
*/

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:socialx/features/auth/domain/entities/app_users.dart';
import 'package:socialx/features/auth/presentation/cubits/auth_state.dart';
import 'package:socialx/features/auth/domain/repos/auth_repo.dart';

class AuthCubit extends Cubit<AuthState>{
  final AuthRepo authRepo;
  AppUsers? _currentUser;

  AuthCubit({required this.authRepo}): super(AuthInitial());

  //check if user is already authenticated
  void checkAuth() async{
    final AppUsers? user= await authRepo.getCurrentUsers();

    if (user!=null){
      _currentUser =user;
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }
  
  //get current user
  AppUsers? get currentuser => _currentUser;

  //login with email + password
  Future<void> login(String email, String password)async{
    try {
      emit(AuthLoading());
      final user = await authRepo.loginWithEmailPassword(email, password);
      if (user!= null) {
        _currentUser = user;
        emit(Authenticated(user));
      }else{
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthErrors(e.toString()));
      emit(Unauthenticated());
    }
  }

  //register with email + password
  Future<void> register(String name, String email, String password)async{
    try {
      emit(AuthLoading());
      final user = await authRepo.registerWithEmailPassword(name, email, password);
      print("Attempting to register: $email");
      if (user!= null) {
        _currentUser = user;
        emit(Authenticated(user));
      }else{
        emit(Unauthenticated());
      }
    } catch (e) {
      print("Registration Error: $e"); // Debugging statement
      emit(AuthErrors(e.toString()));
      emit(Unauthenticated());
    }
  }

  //logout
  Future<void> logout() async{
    authRepo.logout();
    emit(Unauthenticated());
  }
}
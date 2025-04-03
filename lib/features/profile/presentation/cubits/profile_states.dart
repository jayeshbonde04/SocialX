/*
Profile States
*/

import 'package:socialx/features/profile/domain/entities/profile_user.dart';

abstract class ProfileStates {}

//initial
class ProfileInitial extends ProfileStates{}

//loading 
class ProfileLoading extends ProfileStates{}

//loaded
class ProfileLoaded extends ProfileStates{
  final ProfileUser profileUser;
  ProfileLoaded(this.profileUser);
}

//success
class ProfileSuccess extends ProfileStates{
  final String message;
  ProfileSuccess(this.message);
}

//errors
class ProfileErrors extends ProfileStates{
  final String message;
  ProfileErrors(this.message);
}
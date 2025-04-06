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

// Follow request states
class FollowRequestSent extends ProfileStates {
  final String message;
  FollowRequestSent(this.message);
}

class FollowRequestPending extends ProfileStates {
  final String message;
  FollowRequestPending(this.message);
}

class FollowRequestAccepted extends ProfileStates {
  final String message;
  FollowRequestAccepted(this.message);
}

class FollowRequestRejected extends ProfileStates {
  final String message;
  FollowRequestRejected(this.message);
}
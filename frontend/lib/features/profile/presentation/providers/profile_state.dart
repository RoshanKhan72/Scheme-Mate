import 'package:equatable/equatable.dart';
import '../../domain/entities/user_profile.dart';

enum ProfileStatus { initial, loading, loaded, saving, saved, error }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final UserProfile? profile;
  final String? errorMessage;

  const ProfileState({
    required this.status,
    this.profile,
    this.errorMessage,
  });

  factory ProfileState.initial() {
    return const ProfileState(status: ProfileStatus.initial);
  }

  factory ProfileState.loading() {
    return const ProfileState(status: ProfileStatus.loading);
  }

  factory ProfileState.loaded(UserProfile profile) {
    return ProfileState(status: ProfileStatus.loaded, profile: profile);
  }

  factory ProfileState.saving(UserProfile? profile) {
    return ProfileState(status: ProfileStatus.saving, profile: profile);
  }

  factory ProfileState.saved(UserProfile profile) {
    return ProfileState(status: ProfileStatus.saved, profile: profile);
  }

  factory ProfileState.error(String message, {UserProfile? profile}) {
    return ProfileState(status: ProfileStatus.error, errorMessage: message, profile: profile);
  }

  @override
  List<Object?> get props => [status, profile, errorMessage];
}

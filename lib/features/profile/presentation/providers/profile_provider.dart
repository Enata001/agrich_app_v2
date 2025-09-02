import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../data/repositories/profile_repository.dart';



final profileProviderNotifier = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(profileRepository);
});

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileNotifier(this._profileRepository) : super(ProfileState.initial());

  Future<String> uploadProfilePicture(File imageFile) async {
    try {
      state = state.copyWith(isLoading: true);
      final imageUrl = await _profileRepository.uploadProfilePicture(imageFile);
      state = state.copyWith(isLoading: false);
      return imageUrl;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true);
      await _profileRepository.updateProfile(userId, data);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

class ProfileState {
  final bool isLoading;
  final String? error;

  ProfileState({
    required this.isLoading,
    this.error,
  });

  factory ProfileState.initial() => ProfileState(isLoading: false);

  ProfileState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
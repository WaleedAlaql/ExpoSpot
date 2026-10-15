import 'package:easy_localization/easy_localization.dart';
import 'package:expo_spot/core/constants/api_constants.dart';
import 'package:expo_spot/features/auth/data/auth_api.dart';
import 'package:expo_spot/features/auth/data/session_storage.dart';
import 'package:expo_spot/features/auth/domain/auth_user.dart';
import 'package:expo_spot/features/group/data/mock_expo_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authApiProvider = Provider<AuthApi>((ref) => AuthApi());
final sessionStorageProvider = Provider<SessionStorage>((ref) => SessionStorage());

class AuthState {
  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.user,
  });

  final bool isLoading;
  final String? errorMessage;
  final AuthUser? user;

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    AuthUser? user,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      user: user ?? this.user,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._api, this._storage) : super(const AuthState());

  final AuthApi _api;
  final SessionStorage _storage;

  Future<AuthUser?> saveProfile({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      if (ApiConstants.useMockBackend) {
        await Future<void>.delayed(const Duration(milliseconds: 450));
        final demo = MockExpoData.currentUser;
        final user = AuthUser(
          id: demo.id,
          name: demo.name,
          email: demo.email ?? 'waleed@expospot.local',
        );
        state = state.copyWith(isLoading: false, user: user, clearError: true);
        return user;
      }

      final user = await _api.saveProfile(
        username: username,
        password: password,
      );

      await _storage.saveSession(
        userId: user.id,
        userName: user.name,
        userEmail: user.email,
      );

      state = state.copyWith(isLoading: false, user: user, clearError: true);
      return user;
    } on AuthApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return null;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'error_unexpected'.tr(),
      );
      return null;
    }
  }

  Future<AuthUser?> signInWithGoogle() => _signInWithSocial();

  Future<AuthUser?> _signInWithSocial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (!ApiConstants.useMockBackend) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'auth_social_coming_soon'.tr(),
        );
        return null;
      }

      await Future<void>.delayed(const Duration(milliseconds: 550));
      final demo = MockExpoData.currentUser;
      final user = AuthUser(
        id: demo.id,
        name: demo.name,
        email: demo.email ?? 'waleed@expospot.local',
      );
      await _storage.saveSession(
        userId: user.id,
        userName: user.name,
        userEmail: user.email,
      );
      state = state.copyWith(isLoading: false, user: user, clearError: true);
      return user;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'error_unexpected'.tr(),
      );
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _storage.clear();
    } catch (_) {
      // Mock / test environments may lack shared_preferences; still reset session.
    }
    state = const AuthState();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.watch(authApiProvider),
    ref.watch(sessionStorageProvider),
  );
});

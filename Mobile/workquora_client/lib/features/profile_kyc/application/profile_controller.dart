import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/app_exception.dart';
import '../data/profile_kyc_providers.dart';
import '../data/models/profile_model.dart';

class ProfileController extends AsyncNotifier<ProfileModel?> {
  @override
  Future<ProfileModel?> build() => _fetch();

  Future<ProfileModel?> _fetch() async {
    final repo = ref.read(profileRepositoryProvider);
    final result = await repo.getProfile();
    return result.match((failure) => throw failure, (profile) => profile);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<AppFailure?> updateProfile({String? name, String? bio, String? title}) async {
    final repo = ref.read(profileRepositoryProvider);
    final result = await repo.updateProfile(name: name, bio: bio, title: title);
    return result.match((failure) => failure, (_) {
      refresh();
      return null;
    });
  }
}

final profileControllerProvider = AsyncNotifierProvider<ProfileController, ProfileModel?>(ProfileController.new);
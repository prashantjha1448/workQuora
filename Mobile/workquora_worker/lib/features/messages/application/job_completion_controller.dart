import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/core_providers.dart';

/// Handles the worker side of mutual job completion.
///
/// Calls PUT /jobs/:id/complete. The backend records this side's approval;
/// when BOTH client and worker have approved, the backend marks the job
/// completed, releases payment, and soft-clears the chat (messages retained
/// in DB but hidden from both users — see BACKEND_chat_clear_patch).
///
/// So from the app's view: worker taps "Mark as Complete" → if the client has
/// already approved, the conversation will vanish on next refresh (both
/// confirmed); otherwise it waits for the client to also confirm.
class JobCompletionController extends AutoDisposeFamilyAsyncNotifier<bool, String> {
  @override
  Future<bool> build(String jobId) async => false; // false = not yet requested

  Future<AppFailure?> markComplete() async {
    final jobId = arg;
    state = const AsyncLoading();
    try {
      final dio = ref.read(apiClientProvider).dio;
      await dio.put(ApiEndpoints.jobComplete(jobId));
      state = const AsyncData(true);
      return null;
    } on DioException catch (e) {
      final msg = (e.response?.data is Map ? e.response?.data['message'] : null)
          ?? 'Could not mark complete. Please try again.';
      state = AsyncData(false);
      return AppFailure.fromMessage(msg, statusCode: e.response?.statusCode);
    } catch (_) {
      state = AsyncData(false);
      return AppFailure.fromMessage('Unexpected error.');
    }
  }
}

final jobCompletionControllerProvider =
    AutoDisposeAsyncNotifierProviderFamily<JobCompletionController, bool, String>(
        JobCompletionController.new);

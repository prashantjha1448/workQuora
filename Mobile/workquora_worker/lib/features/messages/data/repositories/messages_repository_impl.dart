import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/app_exception.dart';
import '../../domain/repositories/messages_repository.dart';
import '../datasources/messages_remote_datasource.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class MessagesRepositoryImpl implements MessagesRepository {
  MessagesRepositoryImpl(this._remote);
  final MessagesRemoteDataSource _remote;

  Future<Either<AppFailure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        return Left(AppFailure.network());
      }
      final message = (e.response?.data is Map) ? e.response?.data['message'] as String? : null;
      return Left(AppFailure.fromMessage(message ?? 'Something went wrong.', statusCode: e.response?.statusCode));
    } catch (_) {
      return Left(AppFailure.fromMessage('Unexpected error.'));
    }
  }

  @override
  Future<Either<AppFailure, List<ConversationModel>>> getConversations() =>
      _guard(() => _remote.getConversations());

  @override
  Future<Either<AppFailure, List<MessageModel>>> getChatHistory({
    required String jobId,
    required String otherUserId,
  }) =>
      _guard(() => _remote.getChatHistory(jobId: jobId, otherUserId: otherUserId));
}

import 'package:fpdart/fpdart.dart';
import '../../../../core/error/app_exception.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart';

abstract class MessagesRepository {
  Future<Either<AppFailure, List<ConversationModel>>> getConversations();
  Future<Either<AppFailure, List<MessageModel>>> getChatHistory({
    required String jobId,
    required String otherUserId,
  });
}

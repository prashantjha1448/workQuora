import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class MessagesRemoteDataSource {
  MessagesRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<ConversationModel>> getConversations() async {
    final res = await _dio.get(ApiEndpoints.conversations);
    final list = res.data['conversations'] as List;
    return list.map((e) => ConversationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<MessageModel>> getChatHistory({required String jobId, required String otherUserId}) async {
    final res = await _dio.get(ApiEndpoints.chatHistory(jobId, otherUserId));
    final list = res.data['data'] as List;
    return list.map((e) => MessageModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}

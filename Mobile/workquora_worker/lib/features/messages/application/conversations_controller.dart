import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/messages_providers.dart';
import '../data/models/conversation_model.dart';

final conversationsProvider = FutureProvider.autoDispose<List<ConversationModel>>((ref) async {
  final repo = ref.watch(messagesRepositoryProvider);
  final result = await repo.getConversations();
  return result.match((failure) => throw failure, (list) => list);
});

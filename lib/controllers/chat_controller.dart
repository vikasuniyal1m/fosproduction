import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';

/// Chat Controller
/// Handles chat logic and AI bot interactions
class ChatController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isSending = false.obs;
  final RxBool isTyping = false.obs;
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final Rx<ChatConversation?> currentConversation = Rx<ChatConversation?>(null);
  final RxString conversationId = ''.obs;
  final RxMap<int, String> failedMessages = <int, String>{}.obs; // Track failed messages with their text
  final ApiService _apiService = ApiService();
  
  @override
  void onInit() {
    super.onInit();
    initializeChat();
  }
  
  /// Initialize chat - create or get active conversation
  Future<void> initializeChat() async {
    isLoading.value = true;
    try {
      // Try to get active conversation first
      final listResponse = await _apiService.get(ApiEndpoints.chatConversationsList);
      final listData = ApiService.handleResponse(listResponse);
      final conversations = listData['conversations'] ?? [];
      
      // Find active conversation
      ChatConversation? activeConversation;
      for (var conv in conversations) {
        if (conv is Map<String, dynamic> && (conv['status'] as String? ?? '') == 'active') {
          activeConversation = ChatConversation.fromJson(conv);
          break;
        }
      }
      
      if (activeConversation != null) {
        // Load existing conversation
        currentConversation.value = activeConversation;
        conversationId.value = activeConversation.id.toString();
        await loadMessages();
      } else {
        // Create new conversation
        await createConversation();
      }
    } catch (e) {
      ApiService.showErrorSnackbar(e);
      // Try to create new conversation on error
      await createConversation();
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Create new conversation
  Future<void> createConversation() async {
    try {
      final response = await _apiService.post(ApiEndpoints.chatConversationsCreate);
      final data = ApiService.handleResponse(response);
      
      final convId = data['conversation_id'];
      if (convId != null) {
        conversationId.value = convId.toString();
        // Load conversation details
        await loadConversation();
      }
    } catch (e) {
      ApiService.showErrorSnackbar(e);
    }
  }
  
  /// Load conversation details
  Future<void> loadConversation() async {
    if (conversationId.value.isEmpty) return;
    
    try {
      final response = await _apiService.get(
        ApiEndpoints.chatConversationsGet,
        queryParameters: {'id': conversationId.value},
      );
      final data = ApiService.handleResponse(response);
      
      if (data['conversation'] != null) {
        currentConversation.value = ChatConversation.fromJson(data['conversation'] as Map<String, dynamic>);
      }
      if (data['messages'] != null) {
        messages.value = (data['messages'] as List).map<ChatMessage>((msg) {
          return ChatMessage.fromJson(msg as Map<String, dynamic>);
        }).toList();
      }
    } catch (e) {
      ApiService.showErrorSnackbar(e);
    }
  }
  
  /// Load messages for current conversation
  Future<void> loadMessages() async {
    if (conversationId.value.isEmpty) return;
    
    try {
      final response = await _apiService.get(
        ApiEndpoints.chatMessagesList,
        queryParameters: {'conversation_id': conversationId.value},
      );
      final data = ApiService.handleResponse(response);
      
      if (data['messages'] != null) {
        messages.value = (data['messages'] as List).map<ChatMessage>((msg) {
          return ChatMessage.fromJson(msg as Map<String, dynamic>);
        }).toList();
      }
    } catch (e) {
      ApiService.showErrorSnackbar(e);
    }
  }
  
  /// Send message and get bot response
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    if (conversationId.value.isEmpty) {
      await createConversation();
    }
    
    isSending.value = true;
    isTyping.value = true;
    
    try {
      // Add user message to UI immediately (optimistic update)
      final userMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch,
        senderType: 'user',
        message: message.trim(),
        createdAt: DateTime.now().toIso8601String(),
      );
      messages.add(userMessage);
      
      // Send to API
      final response = await _apiService.post(
        ApiEndpoints.chatMessagesSend,
        data: {
          'conversation_id': int.parse(conversationId.value),
          'message': message.trim(),
        },
      );
      
      final data = ApiService.handleResponse(response);
      
      // Remove temporary user message and add real ones
      messages.removeLast();
      
      // Add user message from API
      if (data['user_message'] != null) {
        messages.add(ChatMessage.fromJson(data['user_message']));
      }
      
      // Add bot response
      if (data['bot_response'] != null) {
        final botResponse = data['bot_response'] as Map<String, dynamic>?;
        if (botResponse != null) {
          messages.add(ChatMessage(
            id: botResponse['id'] as int? ?? DateTime.now().millisecondsSinceEpoch,
            senderType: 'bot',
            message: botResponse['message'] as String? ?? '',
            createdAt: botResponse['created_at'] as String? ?? DateTime.now().toIso8601String(),
          ));
        }
      }
    } catch (e) {
      // Mark message as failed instead of removing
      if (messages.isNotEmpty && messages.last.isUser) {
        final failedMessage = messages.last;
        failedMessages[failedMessage.id] = failedMessage.message;
      }
      // Show error but keep message for retry
      Get.snackbar(
        'Message Failed', 
        'Unable to send message. Tap to retry.',
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
    } finally {
      isSending.value = false;
      isTyping.value = false;
    }
  }
  
  /// Retry sending a failed message
  Future<void> retryMessage(int messageId) async {
    final messageText = failedMessages[messageId];
    if (messageText == null) return;
    
    // Remove failed message from list
    messages.removeWhere((msg) => msg.id == messageId);
    failedMessages.remove(messageId);
    
    // Retry sending
    await sendMessage(messageText);
  }
  
  /// Close conversation
  Future<void> closeConversation() async {
    if (conversationId.value.isEmpty) return;
    
    try {
      await _apiService.put(
        ApiEndpoints.chatConversationsClose,
        queryParameters: {'id': conversationId.value},
      );
      
      if (currentConversation.value != null) {
        currentConversation.value = ChatConversation(
          id: currentConversation.value!.id,
          sessionId: currentConversation.value!.sessionId,
          status: 'closed',
          messageCount: currentConversation.value!.messageCount,
          lastMessage: currentConversation.value!.lastMessage,
          createdAt: currentConversation.value!.createdAt,
          updatedAt: DateTime.now().toIso8601String(),
        );
      }
      
      Get.snackbar('Success', 'Conversation closed');
    } catch (e) {
      ApiService.showErrorSnackbar(e);
    }
  }
  
  /// Clear chat
  void clearChat() {
    messages.clear();
    failedMessages.clear();
    conversationId.value = '';
    currentConversation.value = null;
    Get.snackbar('Success', 'Chat cleared');
  }
}


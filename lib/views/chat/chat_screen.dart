import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../controllers/chat_controller.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/chat_action_card.dart';
import '../../widgets/loading_widget.dart';
import '../../routes/app_routes.dart';

/// Chat Screen
/// AI Chatbot interface for customer support
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatController _controller;
  
  @override
  void initState() {
    super.initState();
    // Get controller from binding, or create if not exists
    try {
      if (Get.isRegistered<ChatController>()) {
        _controller = Get.find<ChatController>();
      } else {
        _controller = Get.put(ChatController());
      }
    } catch (e) {
      // Fallback if controller not found
      _controller = Get.put(ChatController());
    }
    // Scroll to bottom when messages change
    ever(_controller.messages, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    });
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      _controller.sendMessage(message);
      _messageController.clear();
      _scrollToBottom();
    }
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: ScreenSize.buttonHeightMedium,
              height: ScreenSize.buttonHeightMedium,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: ScreenSize.iconSmall,
              ),
            ),
            SizedBox(width: ScreenSize.spacingSmall),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Support Assistant',
                    style: TextStyle(
                      fontSize: ScreenSize.headingSmall,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Obx(() => Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _controller.isTyping.value 
                              ? Colors.orange 
                              : Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        _controller.isTyping.value ? 'Typing...' : 'Online',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                          height: 1.0,
                        ),
                      ),
                    ],
                  )),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        toolbarHeight: ScreenSize.buttonHeightMedium,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            size: ScreenSize.iconMedium,
          ),
          onPressed: () => Get.back(),
        ),
        actions: [
          PopupMenuButton(
            icon: Icon(
              Icons.more_vert,
              size: ScreenSize.iconMedium,
            ),
            color: AppColors.cardBackground,
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(
                      Icons.close, 
                      color: AppColors.textPrimary, 
                      size: ScreenSize.iconMedium,
                    ),
                    SizedBox(width: ScreenSize.spacingSmall),
                    Text(
                      'Close Chat',
                      style: TextStyle(
                        fontSize: ScreenSize.textMedium,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  _controller.closeConversation();
                },
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline, 
                      color: AppColors.error, 
                      size: ScreenSize.iconMedium,
                    ),
                    SizedBox(width: ScreenSize.spacingSmall),
                    Text(
                      'Clear Chat',
                      style: TextStyle(
                        fontSize: ScreenSize.textMedium,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  _controller.clearChat();
                },
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (!Get.isRegistered<ChatController>()) {
          return const Center(child: CircularProgressIndicator());
        }
        return _controller.isLoading.value
            ? const LoadingWidget()
            : Column(
              children: [
                // Messages List
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: _controller.messages.isEmpty
                            ? _buildEmptyState()
                            : Container(
                          decoration: BoxDecoration(
                            color: AppColors.backgroundGrey,
                          ),
                            child: ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.all(ScreenSize.paddingMedium),
                            itemCount: _controller.messages.length,
                            itemBuilder: (context, index) {
                              final message = _controller.messages[index];
                              final isLastBotMessage = index == _controller.messages.length - 1 && message.isBot;
                              final isFailed = _controller.failedMessages.containsKey(message.id);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ChatBubble(
                                    message: message,
                                    isFailed: isFailed,
                                    onRetry: isFailed ? () => _controller.retryMessage(message.id) : null,
                                  ),
                                  // Show quick replies ONLY for bot questions (not for every message)
                                  if (isLastBotMessage && message.isBot && _hasQuestion(message.message))
                                    _buildQuickRepliesForMessage(message.message),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      // Quick Suggestions - Show when messages are few
                      if (_controller.messages.length <= 2)
                        _buildQuickSuggestions(),
                    ],
                  ),
                ),
                
                // Typing Indicator
                if (_controller.isTyping.value)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ScreenSize.paddingLarge,
                      vertical: ScreenSize.spacingSmall,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(ScreenSize.spacingMedium),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildAnimatedTypingDot(0),
                              SizedBox(width: ScreenSize.spacingXSmall),
                              _buildAnimatedTypingDot(1),
                              SizedBox(width: ScreenSize.spacingXSmall),
                              _buildAnimatedTypingDot(2),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Input Field
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ScreenSize.paddingMedium,
                    vertical: ScreenSize.spacingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.backgroundGrey,
                              borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                            ),
                            child: TextField(
                              controller: _messageController,
                              style: TextStyle(
                                fontSize: ScreenSize.textSmall,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: ScreenSize.textSmall,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: ScreenSize.paddingMedium,
                                  vertical: ScreenSize.spacingSmall,
                                ),
                              ),
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ),
                        SizedBox(width: ScreenSize.spacingSmall),
                        Obx(() => Container(
                          width: ScreenSize.buttonHeightMedium,
                          height: ScreenSize.buttonHeightMedium,
                          decoration: BoxDecoration(
                            color: _controller.isSending.value
                                ? AppColors.textTertiary
                                : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: _controller.isSending.value
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                                    ),
                                  )
                                : Icon(
                                    Icons.send, 
                                    color: Colors.white,
                                    size: ScreenSize.iconSmall,
                                  ),
                            onPressed: _controller.isSending.value ? null : _sendMessage,
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ],
            );
      }),
    );
  }
  
  Widget _buildEmptyState() {
    final actions = [
      {
        'title': 'Track Order',
        'icon': Icons.local_shipping_rounded,
        'query': 'order status',
        'color': AppColors.info,
      },
      {
        'title': 'Payment Methods',
        'icon': Icons.payment_rounded,
        'query': 'payment methods',
        'color': AppColors.success,
      },
      {
        'title': 'Add Payment',
        'icon': Icons.add_card_rounded,
        'action': 'navigate',
        'route': AppRoutes.addPaymentMethod,
        'color': AppColors.primary,
      },
      {
        'title': 'Shipping Info',
        'icon': Icons.delivery_dining_rounded,
        'query': 'shipping',
        'color': AppColors.warning,
      },
      {
        'title': 'Return Policy',
        'icon': Icons.assignment_return_rounded,
        'query': 'return policy',
        'color': AppColors.error,
      },
      {
        'title': 'My Orders',
        'icon': Icons.receipt_long_rounded,
        'action': 'navigate',
        'route': AppRoutes.orders,
        'color': AppColors.secondary,
      },
    ];
    
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(ScreenSize.paddingMedium),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: ScreenSize.spacingLarge),
            Container(
              width: ScreenSize.widthPercent(25),
              height: ScreenSize.widthPercent(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                Icons.smart_toy_rounded,
                size: ScreenSize.widthPercent(12),
                color: Colors.white,
              ),
            ),
            SizedBox(height: ScreenSize.spacingMedium),
            Text(
              'Hi! I\'m your Support Assistant',
              style: TextStyle(
                fontSize: ScreenSize.headingSmall,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'How can I help you today?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ScreenSize.textSmall,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            SizedBox(height: ScreenSize.spacingLarge),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingSmall),
                  child: Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: ScreenSize.textMedium,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                SizedBox(height: ScreenSize.spacingSmall),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: actions.map((action) {
                    return ChatActionCard(
                      title: action['title'] as String,
                      icon: action['icon'] as IconData,
                      iconColor: action['color'] as Color,
                      onTap: () {
                        if (action['action'] == 'navigate') {
                          Get.toNamed(action['route'] as String);
                        } else {
                          _controller.sendMessage(action['query'] as String);
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            SizedBox(height: ScreenSize.spacingLarge),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnimatedTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: ScreenSize.iconExtraSmall,
            height: ScreenSize.iconExtraSmall,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted && _controller.isTyping.value) {
          Future.delayed(Duration(milliseconds: index * 100), () {
            if (mounted) {
              setState(() {});
            }
          });
        }
      },
    );
  }
  
  Widget _buildTypingDot(int index) {
    return Container(
      width: ScreenSize.iconExtraSmall,
      height: ScreenSize.iconExtraSmall,
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
    );
  }
  
  bool _hasQuestion(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Only show quick replies for actual questions or when bot is asking something
    // Check for question marks or specific question patterns
    final hasQuestionMark = lowerMessage.contains('?');
    
    // Check for question patterns (bot asking user)
    final questionPatterns = [
      'would you like',
      'would you',
      'can i help',
      'how can i help',
      'what would you',
      'do you want',
      'would you like to',
      'can i',
      'do you need',
      'what would you like',
    ];
    
    bool hasQuestionPattern = false;
    for (var pattern in questionPatterns) {
      if (lowerMessage.contains(pattern)) {
        hasQuestionPattern = true;
        break;
      }
    }
    
    // Only show if it's clearly a question
    return hasQuestionMark || hasQuestionPattern;
  }
  
  Widget _buildQuickRepliesForMessage(String message) {
    final lowerMessage = message.toLowerCase();
    List<Map<String, dynamic>> options = [];
    
    // Detect question type and show relevant options with actions
    if (lowerMessage.contains('order') || lowerMessage.contains('track')) {
      options = [
        {'text': 'View Orders', 'action': 'navigate', 'route': AppRoutes.orders, 'icon': Icons.receipt_long_rounded, 'color': AppColors.secondary},
        {'text': 'Track Order', 'action': 'message', 'query': 'track order', 'icon': Icons.local_shipping_rounded, 'color': AppColors.info},
        {'text': 'Order Status', 'action': 'message', 'query': 'order status', 'icon': Icons.info_outline_rounded, 'color': AppColors.info},
      ];
    } else if (lowerMessage.contains('payment') || lowerMessage.contains('add payment')) {
      options = [
        {'text': 'Add Payment', 'action': 'navigate', 'route': AppRoutes.addPaymentMethod, 'icon': Icons.add_card_rounded, 'color': AppColors.primary},
        {'text': 'View Payments', 'action': 'navigate', 'route': AppRoutes.paymentMethods, 'icon': Icons.payment_rounded, 'color': AppColors.success},
        {'text': 'Payment Info', 'action': 'message', 'query': 'payment methods', 'icon': Icons.info_outline_rounded, 'color': AppColors.info},
      ];
    } else if (lowerMessage.contains('shipping') || lowerMessage.contains('delivery')) {
      options = [
        {'text': 'Delivery Time', 'action': 'message', 'query': 'delivery time', 'icon': Icons.access_time_rounded, 'color': AppColors.warning},
        {'text': 'Shipping Charges', 'action': 'message', 'query': 'shipping charges', 'icon': Icons.attach_money_rounded, 'color': AppColors.warning},
        {'text': 'Track Package', 'action': 'message', 'query': 'track package', 'icon': Icons.local_shipping_rounded, 'color': AppColors.info},
      ];
    } else if (lowerMessage.contains('return') || lowerMessage.contains('refund')) {
      options = [
        {'text': 'Return Policy', 'action': 'message', 'query': 'return policy', 'icon': Icons.assignment_return_rounded, 'color': AppColors.error},
        {'text': 'Start Return', 'action': 'message', 'query': 'how to return', 'icon': Icons.refresh_rounded, 'color': AppColors.error},
        {'text': 'Refund Status', 'action': 'message', 'query': 'refund status', 'icon': Icons.info_outline_rounded, 'color': AppColors.info},
      ];
    } else if (lowerMessage.contains('product')) {
      options = [
        {'text': 'Search Product', 'action': 'message', 'query': 'product search', 'icon': Icons.search_rounded, 'color': AppColors.primary},
        {'text': 'Product Price', 'action': 'message', 'query': 'product price', 'icon': Icons.attach_money_rounded, 'color': AppColors.success},
        {'text': 'Product Stock', 'action': 'message', 'query': 'product stock', 'icon': Icons.inventory_2_rounded, 'color': AppColors.info},
      ];
    } else if (lowerMessage.contains('account') || lowerMessage.contains('profile')) {
      options = [
        {'text': 'Edit Profile', 'action': 'navigate', 'route': AppRoutes.editProfile, 'icon': Icons.edit_rounded, 'color': AppColors.primary},
        {'text': 'Change Password', 'action': 'navigate', 'route': AppRoutes.changePassword, 'icon': Icons.lock_rounded, 'color': AppColors.warning},
        {'text': 'Account Settings', 'action': 'navigate', 'route': AppRoutes.profile, 'icon': Icons.settings_rounded, 'color': AppColors.textSecondary},
      ];
    } else if (lowerMessage.contains('address')) {
      options = [
        {'text': 'Add Address', 'action': 'navigate', 'route': AppRoutes.addAddress, 'icon': Icons.add_location_alt_rounded, 'color': AppColors.primary},
        {'text': 'View Addresses', 'action': 'navigate', 'route': AppRoutes.addresses, 'icon': Icons.location_on_rounded, 'color': AppColors.info},
        {'text': 'Manage Addresses', 'action': 'navigate', 'route': AppRoutes.addresses, 'icon': Icons.edit_location_alt_rounded, 'color': AppColors.secondary},
      ];
    } else if (lowerMessage.contains('help') || lowerMessage.contains('how can')) {
      options = [
        {'text': 'Order Status', 'action': 'message', 'query': 'order status', 'icon': Icons.shopping_bag_rounded, 'color': AppColors.info},
        {'text': 'Payment Methods', 'action': 'message', 'query': 'payment methods', 'icon': Icons.payment_rounded, 'color': AppColors.success},
        {'text': 'Shipping Info', 'action': 'message', 'query': 'shipping', 'icon': Icons.local_shipping_rounded, 'color': AppColors.warning},
        {'text': 'Returns', 'action': 'message', 'query': 'return policy', 'icon': Icons.assignment_return_rounded, 'color': AppColors.error},
      ];
    } else if (lowerMessage.contains('would you like') || lowerMessage.contains('can i help')) {
      options = [
        {'text': 'Yes', 'action': 'message', 'query': 'yes', 'icon': Icons.check_circle_rounded, 'color': AppColors.success},
        {'text': 'No', 'action': 'message', 'query': 'no', 'icon': Icons.cancel_rounded, 'color': AppColors.error},
        {'text': 'More Info', 'action': 'message', 'query': 'more information', 'icon': Icons.info_outline_rounded, 'color': AppColors.info},
      ];
    } else {
      // For general messages, don't show quick replies unless it's clearly a question
      // Return empty to not show quick replies
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: EdgeInsets.only(
        left: ScreenSize.paddingLarge,
        top: ScreenSize.spacingMedium,
        bottom: ScreenSize.spacingMedium,
      ),
      child: Wrap(
        spacing: ScreenSize.spacingMedium,
        runSpacing: ScreenSize.spacingMedium,
        children: options.map((option) {
          return ChatActionCard(
            title: option['text'] as String,
            icon: option['icon'] as IconData? ?? Icons.help_outline_rounded,
            iconColor: option['color'] as Color? ?? AppColors.primary,
            onTap: () {
              if (option['action'] == 'navigate') {
                Get.toNamed(option['route'] as String);
              } else {
                _controller.sendMessage(option['query'] as String);
              }
            },
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildQuickSuggestions() {
    final suggestions = [
      {'text': 'Order Status', 'query': 'order status', 'icon': Icons.shopping_bag},
      {'text': 'Payment Methods', 'query': 'payment methods', 'icon': Icons.payment},
      {'text': 'Add Payment', 'action': 'navigate', 'route': AppRoutes.addPaymentMethod, 'icon': Icons.add_card},
      {'text': 'Shipping Info', 'query': 'shipping', 'icon': Icons.local_shipping},
      {'text': 'Return Policy', 'query': 'return policy', 'icon': Icons.assignment_return},
      {'text': 'Product Search', 'query': 'product', 'icon': Icons.search},
    ];
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ScreenSize.paddingMedium,
        vertical: ScreenSize.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'How can I help you?',
            style: TextStyle(
              fontSize: ScreenSize.textMedium,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: ScreenSize.spacingSmall),
          Wrap(
            spacing: ScreenSize.spacingMedium,
            runSpacing: ScreenSize.spacingMedium,
            children: suggestions.map((suggestion) {
              return GestureDetector(
                onTap: () {
                  if (suggestion['action'] == 'navigate') {
                    Get.toNamed(suggestion['route'] as String);
                  } else {
                    _controller.sendMessage(suggestion['query'] as String);
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ScreenSize.paddingMedium,
                    vertical: ScreenSize.spacingSmall + 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(ScreenSize.inputBorderRadius),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (suggestion['icon'] != null)
                        Icon(
                          suggestion['icon'] as IconData,
                          size: ScreenSize.iconSmall,
                          color: AppColors.primary,
                        ),
                      if (suggestion['icon'] != null)
                        SizedBox(width: ScreenSize.spacingXSmall),
                      Text(
                        suggestion['text'] as String,
                        style: TextStyle(
                          fontSize: ScreenSize.textSmall,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}



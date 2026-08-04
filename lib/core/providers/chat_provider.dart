import 'dart:async';
import 'package:flutter/material.dart';
import '../../features/chats/models/chat_models.dart';
import '../../features/chats/services/chat_service.dart';
import '../utils/log_service.dart';

class ChatProvider extends ChangeNotifier {
  List<ChatConversation> _conversations = [];
  List<ChatConversation> _allConversations = []; // Orijinal liste
  bool _isLoading = false;
  String _searchQuery = '';
  StreamSubscription? _conversationsSubscription;

  List<ChatConversation> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  final ChatService _chatService = ChatService();

  void initConversations() {
    _isLoading = true;
    notifyListeners();

    _conversationsSubscription?.cancel();
    _conversationsSubscription = _chatService.getConversations().listen(
      (chats) {
        _allConversations = chats;
        _applyFilter();
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        LogService.e("Chat subscription error", error);
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Sohbetlerde arama yap
  void filterChats(String query) {
    _searchQuery = query.trim().toLowerCase();
    _applyFilter();
    notifyListeners();
  }

  /// Aramayı temizle
  void clearSearch() {
    _searchQuery = '';
    _conversations = List.from(_allConversations);
    notifyListeners();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _conversations = List.from(_allConversations);
    } else {
      _conversations = _allConversations.where((chat) {
        return chat.otherUserName.toLowerCase().contains(_searchQuery) ||
               chat.lastMessage.toLowerCase().contains(_searchQuery);
      }).toList();
    }
  }

  @override
  void dispose() {
    _conversationsSubscription?.cancel();
    super.dispose();
  }

  Future<void> markAsRead(String chatId) async {
    try {
      await _chatService.markAsRead(chatId);
    } catch (e) {
      LogService.e("Error marking chat as read", e);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _chatService.markAllConversationsAsRead();
    } catch (e) {
      LogService.e("Error marking all chats as read", e);
    }
  }
}

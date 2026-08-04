import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/user_provider.dart';
import 'models/story_model.dart';
import 'services/story_service.dart';
import '../chats/screens/chat_detail_screen.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<UserStories> stories;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentUserIndex;
  int _currentStoryIndex = 0;
  
  late AnimationController _progressController;
  final TextEditingController _replyController = TextEditingController();
  final StoryService _storyService = StoryService();

  @override
  void initState() {
    super.initState();
    _currentUserIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _startStory();
  }

  void _startStory() {
    _progressController.stop();
    _progressController.reset();
    _progressController.forward();
    
    // Hikaye izlendi kaydı
    final currentItem = _currentStoryItem;
    if (currentItem != null) {
      _storyService.markStoryAsViewed(currentItem.id);
    }
  }

  UserStories get _currentUserStories => widget.stories[_currentUserIndex];
  StoryItem? get _currentStoryItem =>
      _currentUserStories.items.isNotEmpty ? _currentUserStories.items[_currentStoryIndex] : null;

  void _nextStory() {
    if (_currentStoryIndex < _currentUserStories.items.length - 1) {
      setState(() => _currentStoryIndex++);
      _startStory();
    } else if (_currentUserIndex < widget.stories.length - 1) {
      setState(() {
        _currentUserIndex++;
        _currentStoryIndex = 0;
      });
      _pageController.animateToPage(
        _currentUserIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStory();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      setState(() => _currentStoryIndex--);
      _startStory();
    } else if (_currentUserIndex > 0) {
      setState(() {
        _currentUserIndex--;
        _currentStoryIndex = widget.stories[_currentUserIndex].items.length - 1;
      });
      _pageController.animateToPage(
        _currentUserIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStory();
    }
  }

  void _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    _progressController.stop();
    _replyController.clear();
    FocusScope.of(context).unfocus();

    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('💬 Hikayeye yanıt gönderildi!'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );

    _progressController.forward();
  }

  void _deleteCurrentStory() async {
    _progressController.stop();
    final item = _currentStoryItem;
    if (item == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF14161B),
        title: Text('Hikayeyi Sil', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900)),
        content: Text('Bu hikayeyi silmek istediğinize emin misiniz?', style: GoogleFonts.outfit(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İPTAL', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('SİL', style: GoogleFonts.outfit(color: AppColors.error, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storyService.deleteStory(item.id);
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<UserProvider>().currentUser;
    final isMyStory = _currentUserStories.userId == currentUser?.uid;
    final item = _currentStoryItem;

    if (item == null) {
      return const Scaffold(backgroundColor: Colors.black, body: SizedBox());
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 3) {
            _previousStory();
          } else if (details.globalPosition.dx > (screenWidth * 2) / 3) {
            _nextStory();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Media Background
            CachedNetworkImage(
              imageUrl: item.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
              ),
            ),

            // Gradient Top & Bottom Overlays
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.25, 0.75, 1.0],
                  ),
                ),
              ),
            ),

            // Top Header: Progress Bar & User Info
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress Indicator Bar
                    Row(
                      children: List.generate(_currentUserStories.items.length, (index) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 3,
                            child: AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, child) {
                                double progress = 0.0;
                                if (index < _currentStoryIndex) {
                                  progress = 1.0;
                                } else if (index == _currentStoryIndex) {
                                  progress = _progressController.value;
                                }
                                return LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.white30,
                                  color: Colors.white,
                                );
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),

                    // User Info Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: CachedNetworkImageProvider(_currentUserStories.userAvatar),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentUserStories.userName,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Hikaye',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (isMyStory)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                            onPressed: _deleteCurrentStory,
                          ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Reply Bar (For Other Users)
            if (!isMyStory)
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: TextField(
                            controller: _replyController,
                            style: GoogleFonts.outfit(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: '${_currentUserStories.userName}\'e yanıt ver...',
                              hintStyle: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _sendReply(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                        onPressed: _sendReply,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

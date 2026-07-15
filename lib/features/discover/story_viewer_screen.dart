import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/story_model.dart';
import '../../core/providers/story_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../features/chats/services/chat_service.dart';
import '../../core/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'user_profile_detail_screen.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<UserStories> stories;
  final int initialIndex;

  const StoryViewerScreen({
    super.key, 
    required this.stories, 
    this.initialIndex = 0
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> with TickerProviderStateMixin {
  late PageController _userPageController;
  late PageController _storyPageController;
  late AnimationController _animController;
  
  int _currentUserIndex = 0;
  int _currentStoryIndex = 0;
  
  final TextEditingController _replyController = TextEditingController();
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _currentUserIndex = widget.initialIndex;
    _userPageController = PageController(initialPage: widget.initialIndex);
    _storyPageController = PageController();
    
    _animController = AnimationController(vsync: this);
    
    _loadStory(storyIndex: 0);
  }

  @override
  void dispose() {
    _userPageController.dispose();
    _storyPageController.dispose();
    _animController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _loadStory({required int storyIndex, bool animate = true}) {
    _animController.stop();
    _animController.reset();
    _animController.duration = const Duration(seconds: 5);
    
    _animController.forward().whenComplete(() {
      _onNextStory();
    });

    if (animate && _storyPageController.hasClients) {
      _storyPageController.jumpToPage(storyIndex);
    }
    
    _currentStoryIndex = storyIndex;
    
    // Mark as viewed
    final currentStories = widget.stories[_currentUserIndex];
    if (_currentStoryIndex < currentStories.stories.length) {
      context.read<StoryProvider>().viewStory(currentStories.stories[_currentStoryIndex].id);
    }
  }

  void _onNextStory() {
    final currentStories = widget.stories[_currentUserIndex];
    
    if (_currentStoryIndex < currentStories.stories.length - 1) {
      setState(() {
        _currentStoryIndex++;
      });
      _loadStory(storyIndex: _currentStoryIndex);
    } else {
      // Go to next user
      if (_currentUserIndex < widget.stories.length - 1) {
        _userPageController.nextPage(
          duration: const Duration(milliseconds: 300), 
          curve: Curves.easeInOut
        );
      } else {
        Navigator.pop(context);
      }
    }
  }

  void _onPrevStory() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
      });
      _loadStory(storyIndex: _currentStoryIndex);
    } else {
      // Go to prev user
      if (_currentUserIndex > 0) {
        _userPageController.previousPage(
          duration: const Duration(milliseconds: 300), 
          curve: Curves.easeInOut
        );
      }
    }
  }

  void _onUserChanged(int index) {
    setState(() {
      _currentUserIndex = index;
      _currentStoryIndex = 0;
    });
    _loadStory(storyIndex: 0, animate: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _userPageController,
        itemCount: widget.stories.length,
        onPageChanged: _onUserChanged,
        itemBuilder: (context, userIndex) {
          final userStory = widget.stories[userIndex];
          return _buildUserStoryView(userStory);
        },
      ),
    );
  }

  Widget _buildUserStoryView(UserStories userStory) {
    final story = userStory.stories[_currentStoryIndex];
    final isMe = context.read<UserProvider>().currentUser?.uid == userStory.userId;

    return GestureDetector(
      onTapDown: (details) {
        final width = MediaQuery.of(context).size.width;
        if (details.globalPosition.dx < width / 3) {
          _onPrevStory();
        } else if (details.globalPosition.dx > 2 * width / 3) {
          _onNextStory();
        }
      },
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! > 500) {
          Navigator.pop(context);
        }
      },
      child: Stack(
        children: [
          // Image
           CachedNetworkImage(
            imageUrl: story.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            errorWidget: (context, url, error) => const Center(child: Icon(Icons.error, color: Colors.white)),
          ),

          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: isMe ? 0.3 : 0.6),
                ],
                stops: const [0.0, 0.2, 0.8, 1.0],
              ),
            ),
          ),

          // Progress & Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  // Progress Bars
                  Row(
                    children: List.generate(userStory.stories.length, (index) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: AnimatedBuilder(
                            animation: _animController,
                            builder: (context, child) {
                              double value = 0.0;
                              if (index < _currentStoryIndex) {
                                value = 1.0;
                              } else if (index == _currentStoryIndex) {
                                value = _animController.value;
                              }
                              return LinearProgressIndicator(
                                value: value,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                minHeight: 2,
                              );
                            },
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  
                  // Header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: CachedNetworkImageProvider(userStory.userAvatar),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        userStory.userName,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getTimeAgo(story.createdAt),
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom Actions
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: SafeArea(
              child: isMe ? _buildMyActions(story) : _buildOtherActions(story, userStory.userId),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyActions(Story story) {
    return Center(
      child: GestureDetector(
        onTap: () {
          // Show Viewers Bottom Sheet
          _showViewers(story);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.visibility_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                '${story.viewers.length} görüntülenme',
                style: GoogleFonts.plusJakartaSans(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtherActions(Story story, String targetUserId) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white30),
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.centerLeft,
            child: TextField(
              controller: _replyController,
              style: const TextStyle(color: Colors.white),
              cursorColor: AppColors.primary,
              decoration: const InputDecoration(
                hintText: 'Mesaj gönder...',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (value) async {
                if (value.isNotEmpty) {
                  final currentUser = context.read<UserProvider>().currentUser;
                  if (currentUser != null) {
                    try {
                      final chatId = await _chatService.startChat(targetUserId);
                      await _chatService.sendMessage(
                        chatId, 
                        value,
                        targetUserId,
                        storyReply: {
                          'storyId': story.id,
                          'storyUrl': story.imageUrl,
                          'timestamp': FieldValue.serverTimestamp(),
                        }
                      );
                      _replyController.clear();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mesaj gönderildi')),
                        );
                      }
                    } catch (e) {
                      debugPrint("Message error: $e");
                    }
                  }
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () {
            context.read<StoryProvider>().likeStory(story.id, targetUserId);
            // Like animation UI
            ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Hikaye beğenildi ❤️')),
            );
          },
          child: const Icon(Icons.favorite_border, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () async {
             // Send heart emoji as message
             final currentUser = context.read<UserProvider>().currentUser;
             if (currentUser != null) {
                try {
                  final messenger = ScaffoldMessenger.of(context);
                  final chatId = await _chatService.startChat(targetUserId);
                  await _chatService.sendMessage(
                    chatId, 
                    "❤️",
                    targetUserId
                  );
                  messenger.showSnackBar(
                    const SnackBar(content: Text('❤️ gönderildi')),
                  );
                } catch (e) {
                   debugPrint("Message error: $e");
                }
             }
          },
          child: const Icon(Icons.send, color: Colors.white, size: 28)
        ),
      ],
    );
  }

  void _showViewers(Story story) {
    _animController.stop(); // Pause animation
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Görüntüleyenler (${story.viewers.length})',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (story.viewers.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'Henüz kimse görmedi.',
                      style: GoogleFonts.plusJakartaSans(color: Colors.white38),
                    ),
                  ),
                )
              else
                Expanded(
                  child: FutureBuilder<List<DocumentSnapshot>>(
                    future: _fetchViewers(story.viewers),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                      }
                      
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                         return const Center(child: Text("Yüklenemedi", style: TextStyle(color: Colors.white54)));
                      }

                      final users = snapshot.data!;
                      return ListView.builder(
                        controller: controller,
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final data = users[index].data() as Map<String, dynamic>;
                          final userId = users[index].id;
                          final photoUrl = (data['photoUrls'] as List?)?.firstOrNull ?? '';
                          final name = data['name'] ?? 'Kullanıcı';
                          final hasLiked = story.likes.contains(userId);
                          
                          return ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserProfileDetailScreen(userId: userId),
                                ),
                              );
                            },
                            leading: CircleAvatar(
                              backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                              backgroundColor: Colors.grey[800],
                              child: photoUrl.isEmpty ? Text(name.isNotEmpty ? name[0] : '?') : null,
                            ),
                            title: Text(name, style: const TextStyle(color: Colors.white)),
                            subtitle: Text('Hikayeni gördü', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                            trailing: hasLiked 
                                ? const Icon(Icons.favorite, color: Colors.red, size: 20)
                                : null,
                          );
                        },
                      );
                    }
                  ),
                ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      _animController.forward(); // Resume
    });
  }

  Future<List<DocumentSnapshot>> _fetchViewers(List<String> ids) async {
    if (ids.isEmpty) return [];
    // Firestore limitation: whereIn supports max 10. 
    // We take first 10 for simplicity in this iteration.
    final limitedIds = ids.take(10).toList();
    if (limitedIds.isEmpty) return [];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: limitedIds)
          .get();
      return snapshot.docs;
    } catch (e) {
      debugPrint("Error fetching viewers: $e");
      return [];
    }
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}d';
    } else {
      return '${diff.inHours}s';
    }
  }
}


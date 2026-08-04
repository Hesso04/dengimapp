import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../models/story_model.dart';
import '../story_viewer_screen.dart';

class StorySection extends StatelessWidget {
  final List<UserStories> activeStories;
  final VoidCallback onAddStory;

  const StorySection({
    super.key,
    required this.activeStories,
    required this.onAddStory,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final currentUser = userProvider.currentUser;
        
        UserStories? myStories;
        final List<UserStories> otherStories = [];

        for (var s in activeStories) {
          if (s.userId == currentUser?.uid) {
            myStories = s;
          } else {
            otherStories.add(s);
          }
        }
        
        final List<UserStories> allViewableStories = [];
        if (myStories != null) allViewableStories.add(myStories);
        allViewableStories.addAll(otherStories);

        return Container(
          height: 120,
          padding: const EdgeInsets.only(top: 16),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: otherStories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                if (myStories != null) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StoryViewerScreen(
                              stories: allViewableStories,
                              initialIndex: 0,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.scaffold,
                              backgroundImage: (myStories.userAvatar.isNotEmpty && myStories.userAvatar.startsWith('http'))
                                  ? CachedNetworkImageProvider(myStories.userAvatar)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'SİZ',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: onAddStory,
                          child: Container(
                            width: 65,
                            height: 65,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2),
                              boxShadow: const [
                                BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                              ],
                            ),
                            child: const Icon(Icons.add, color: Colors.black, size: 28),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'SİZ', 
                          style: GoogleFonts.outfit(
                            fontSize: 10, 
                            color: Colors.black.withValues(alpha: 0.5), 
                            fontWeight: FontWeight.w900
                          )
                        ),
                      ],
                    ),
                  );
                }
              }

              final userStories = otherStories[index - 1];
              final name = userStories.userName.toUpperCase();

              return Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        final viewIndex = allViewableStories.indexOf(userStories);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StoryViewerScreen(
                              stories: allViewableStories,
                              initialIndex: viewIndex,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                          color: userStories.stories.any((s) => s.isPremium) 
                              ? AppColors.primary 
                              : AppColors.secondary,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: ClipOval(
                             child: CachedNetworkImage(
                               imageUrl: userStories.userAvatar,
                               width: 54,
                               height: 54,
                               fit: BoxFit.cover,
                               placeholder: (context, url) => Container(color: AppColors.scaffold),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name.length > 8 ? '${name.substring(0, 7)}..' : name, 
                      style: GoogleFonts.outfit(
                        fontSize: 10, 
                        color: Colors.black, 
                        fontWeight: FontWeight.w900,
                      )
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

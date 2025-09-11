import 'package:agrich_app_v2/core/router/app_router.dart';
import 'package:agrich_app_v2/features/auth/data/models/user_model.dart';
import 'package:agrich_app_v2/features/chat/presentation/widgets/chat_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';

import '../../auth/providers/auth_provider.dart';
import '../../shared/widgets/custom_input_field.dart';
import '../../shared/widgets/gradient_background.dart';
import '../../shared/widgets/network_error_widget.dart';
import 'providers/chat_provider.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _showSearch = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final currentUser = ref.watch(currentUserProvider);
    final userChats = currentUser != null
        ? ref.watch(userChatsProvider(currentUser.uid))
        : const AsyncValue<List<Map<String, dynamic>>>.data([]);

    return GradientBackground(
      floatingActionButton: _buildFloatingActionButton(context),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            if (_showSearch) _buildSearchBar(),
            Expanded(
              child: userChats.when(
                data: (chats) => _filteredChats(chats).isEmpty
                    ? _buildEmptyState(context)
                    : _buildChatsList(_filteredChats(chats)),
                loading: () => _buildLoadingState(),
                error: (error, stack) => _buildErrorState(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (_showSearch) ...[
          IconButton(
          onPressed: () {
    setState(() {
    _showSearch = false;
    _searchQuery = '';
    _searchController.clear();
    });
    },
      icon: const Icon(Icons.arrow_back, color: Colors.white),
    ),
    ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.chat_bubble,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Messages',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Connect with the farming community',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(onPressed: () {
                  setState(() {
                    _showSearch = true;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                }, icon: Icon(Icons.search, color: Colors.white,)),
                GestureDetector(
                  onTap: () => _openChatbot(context),
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ],
    ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return FadeInDown(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: CustomInputField(
          controller: _searchController,
          hint: 'Search conversations...',
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        ),
      ),
    );
  }

  Widget _buildChatsList(
    List<Map<String, dynamic>> chats,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        final currentUser = ref.read(currentUserProvider);
        if (currentUser != null) {
          ref.invalidate(userChatsProvider(currentUser.uid));
        }
        await Future.delayed(const Duration(seconds: 1));
      },
      color: AppColors.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: _buildChatItem(context, chat),
          );
        },
      ),
    );
  }
// 🔍 DEBUG: Add this debug version to your _buildChatItem method
// lib/features/chat/presentation/chat_list_screen.dart

  Widget _buildChatItem(BuildContext context, Map<String, dynamic> chat) {
    print('=== CHAT DATA DEBUG ===');
    print('Full chat object: $chat');

    final recipientName = chat['recipientName'] as String? ?? 'Unknown User';
    final recipientAvatar = chat['recipientAvatar'] as String? ?? '';
    final lastMessage = chat['lastMessage'] as String? ?? '';
    final lastMessageTime = chat['lastMessageTime'] as DateTime?;
    final unreadCount = chat['unreadCount'] as int? ?? 0;
    final isOnline = chat['isOnline'] as bool? ?? false;

    print('Extracted recipientName: "$recipientName"');
    print('Extracted recipientAvatar: "$recipientAvatar"');
    print('RecipientAvatar isEmpty: ${recipientAvatar.isEmpty}');
    print('RecipientAvatar length: ${recipientAvatar.length}');
    print('======================');

    return GestureDetector(
      onTap: () => _openChat(context, chat),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryGreen.withValues(
                    alpha: 0.2,
                  ),
                  // 🔍 DEBUG: Add validation before using CachedNetworkImageProvider
                  backgroundImage: (recipientAvatar.isNotEmpty &&
                      recipientAvatar.startsWith('http'))
                      ? CachedNetworkImageProvider(recipientAvatar)
                      : null,
                  child: (recipientAvatar.isEmpty ||
                      !recipientAvatar.startsWith('http'))
                      ? Text(
                    recipientName.isNotEmpty
                        ? recipientName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  )
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          recipientName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lastMessageTime != null)
                        Text(
                          timeago.format(lastMessageTime),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage.isNotEmpty
                              ? lastMessage
                              : 'Start a conversation',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                            color: lastMessage.isNotEmpty
                                ? AppColors.textSecondary
                                : AppColors.textTertiary,
                            fontStyle: lastMessage.isEmpty
                                ? FontStyle.italic
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// 🔍 ALSO UNCOMMENT AND ADD DEBUG TO _openChat:
  void _openChat(BuildContext context, Map<String, dynamic> chat) {
    print('🚀 OPENING CHAT WITH DATA:');
    print('chatId: ${chat['id']}');
    print('recipientName: ${chat['recipientName']}');
    print('recipientAvatar: ${chat['recipientAvatar']}');

    context.push(
      AppRoutes.chat,
      extra: {
        'chatId': chat['id'] ?? '',
        'recipientName': chat['recipientName'] ?? '',
        'recipientAvatar': chat['recipientAvatar'] ?? '',
      },
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      delay: const Duration(milliseconds: 400),
      child: FloatingActionButton(
        heroTag: UniqueKey(),
        key: Key('/chat'),
        onPressed: () => _startNewChat(context),
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  List<Map<String, dynamic>> _filteredChats(List<Map<String, dynamic>> chats) {
    if (_searchQuery.isEmpty) return chats;

    return chats.where((chat) {
      final recipientName = (chat['recipientName'] as String? ?? '')
          .toLowerCase();
      final lastMessage = (chat['lastMessage'] as String? ?? '').toLowerCase();
      return recipientName.contains(_searchQuery) ||
          lastMessage.contains(_searchQuery);
    }).toList();
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: FadeIn(
        duration: const Duration(milliseconds: 800),
        child: Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 60,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No conversations yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Start chatting with fellow farmers or try our AI assistant for farming advice',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _startNewChat(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Start Chat'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _openChatbot(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.smart_toy),
                    label: const Text('AI Assistant'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: 6,
      itemBuilder: (context, index) {
        return FadeInUp(
          duration: const Duration(milliseconds: 600),
          delay: Duration(milliseconds: 300 + (index * 100)),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: const ChatShimmer(),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context) {
    // ✅ ADD NETWORK-AWARE ERROR HANDLING
    return NetworkErrorWidget(
      title: 'Unable to load conversations',
      message: 'Please check your internet connection and try again.',
      onRetry: () {
        final currentUser = ref.read(currentUserProvider);
        if (currentUser != null) {
          ref.invalidate(userChatsProvider(currentUser.uid));
        }
      },
      showOfflineData: true,
      offlineWidget: _buildOfflineChatsContent(),
    );
  }

  Widget _buildOfflineChatsContent() {
    final user = ref.watch(currentUserProvider);
    if (user == null) return _buildEmptyState(context);

    final chatRepository = ref.read(chatRepositoryProvider);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: chatRepository.getCachedUserChats(user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return _buildChatsList(snapshot.data!);
        }
        return _buildError(context);
      },
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: FadeIn(
        duration: const Duration(milliseconds: 800),
        child: Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Unable to load your conversations. Please check your internet connection and try again.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  final currentUser = ref.read(currentUserProvider);
                  if (currentUser != null) {
                    ref.invalidate(userChatsProvider(currentUser.uid));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // void _openChat(BuildContext context, Map<String, dynamic> chat) {
  //   context.push(
  //     AppRoutes.chat,
  //     extra: {
  //       'chatId': chat['id'] ?? '',
  //       'recipientName': chat['recipientName'] ?? 'Unknown User',
  //       'recipientAvatar': chat['recipientAvatar'] ?? '',
  //     },
  //   );
  // }

  void _openChatbot(BuildContext context) {
    context.push('/chatbot');
  }

  // List<Map<String, dynamic>> _filteredChats(List<Map<String, dynamic>> chats) {
  //   if (_searchQuery.isEmpty) return chats;
  //
  //   return chats.where((chat) {
  //     final recipientName = (chat['recipientName'] as String? ?? '').toLowerCase();
  //     final lastMessage = (chat['lastMessage'] as String? ?? '').toLowerCase();
  //
  //     return recipientName.contains(_searchQuery) ||
  //         lastMessage.contains(_searchQuery);
  //   }).toList();
  // }

  // void _openChat(BuildContext context, Map<String, dynamic> chat) {
  //   context.push(
  //     AppRoutes.chat,
  //     extra: {
  //       'chatId': chat['id'] ?? '',
  //       'recipientName': chat['recipientName'] ?? '',
  //       'recipientAvatar': chat['recipientAvatar'] ?? '',
  //     },
  //   );
  // }

  void _startNewChat(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Start New Chat',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildUserSearchList(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSearchList(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(chatRepositoryProvider).searchUsers(''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No users found. Users will appear here when they join the community.',
            ),
          );
        }

        final users = snapshot.data!;
        final currentUser = UserModel.fromMap(ref.read(localStorageServiceProvider).getUserData() ?? {});

        // Filter out current user
        final otherUsers = users
            .where((user) => user['id'] != currentUser.id)
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: otherUsers.length,
          itemBuilder: (context, index) {
            final user = otherUsers[index];
            print("This is the other user data: $user");

            // 🔧 FIX: Helper function to safely get profile picture URL
            String getSafeProfilePictureUrl(dynamic profilePictureUrl) {
              if (profilePictureUrl == null) return '';
              final urlString = profilePictureUrl.toString();
              if (urlString == 'null' || urlString.isEmpty) return '';
              if (!urlString.startsWith('http')) return '';
              return urlString;
            }

            final safeProfileUrl = getSafeProfilePictureUrl(user['profilePictureUrl']);

            return ListTile(
                leading: CircleAvatar(
                  // 🔧 FIX: Only use CachedNetworkImageProvider for valid URLs
                  backgroundImage: safeProfileUrl.isNotEmpty
                      ? CachedNetworkImageProvider(safeProfileUrl)
                      : null,
                  child: safeProfileUrl.isEmpty
                      ? Text(user['username']?[0]?.toUpperCase() ?? 'U')
                      : null,
                ),
                title: Text(user['username'] ?? 'Unknown User'),
                subtitle: Text(user['bio'] ?? 'Farmer'),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);

                  try {
                    // 🔧 FIX: Pass recipient data with safely handled profile picture
                    final recipientData = {
                      'id': user['id'],
                      'username': user['username'],
                      'displayName': user['username'],
                      'profilePictureUrl': safeProfileUrl, // Use the safe URL
                      'isOnline': user['isOnline'] ?? false,
                    };

                    print('🔍 NEW CHAT DEBUG:');
                    print('User data: $user');
                    print('Safe profile URL: "$safeProfileUrl"');
                    print('Recipient data: $recipientData');

                    final chatId = await ref
                        .read(chatRepositoryProvider)
                        .createOrGetChat([currentUser.id, user['id']], recipientData: recipientData);

                    if (mounted) {
                      print('🚀 NAVIGATING TO CHAT:');
                      print('- chatId: $chatId');
                      print('- recipientName: ${user['username'] ?? 'Unknown User'}');
                      print('- recipientAvatar: "$safeProfileUrl"');

                      AppRouter.push(
                        AppRoutes.chat,
                        extra: {
                          'chatId': chatId,
                          'recipientName': user['username'] ?? 'Unknown User',
                          'recipientAvatar': safeProfileUrl, // ✅ Now safe - empty string won't cause errors
                        },
                      );
                    }
                  } catch (e) {
                    print('❌ Error creating chat: $e');
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Failed to start chat: $e')),
                      );
                    }
                  }
                }
            );
          },
        );
      },
    );
  }
}

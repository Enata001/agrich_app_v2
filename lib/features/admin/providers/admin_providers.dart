import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/config/app_config.dart';
import '../../../core/providers/app_providers.dart';
import '../data/repositories/admin_repository.dart';
import '../data/models/admin_models.dart';
import '../../auth/providers/auth_provider.dart';


final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final firestore = ref.watch(firestoreProvider);
  return AdminRepository(firebaseService, firestore);
});

final isCurrentUserAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.email == null) return false;
  return AppConfig.isAdminEmail(user!.email!);
});

final userTypeProvider = Provider<UserType>((ref) {
  final isAdmin = ref.watch(isCurrentUserAdminProvider);
  return isAdmin ? UserType.admin : UserType.regular;
});

final currentAdminIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  final isAdmin = ref.watch(isCurrentUserAdminProvider);
  return isAdmin ? user?.uid : null;
});

// ================ STATISTICS PROVIDERS ================

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final adminRepository = ref.watch(adminRepositoryProvider);
  return await adminRepository.getAdminStats();
});

// Auto-refresh stats every 5 minutes
final adminStatsAutoRefreshProvider = StreamProvider<AdminStats>((ref) async* {
  while (true) {
    try {
      final adminRepository = ref.read(adminRepositoryProvider);
      final stats = await adminRepository.getAdminStats();
      yield stats;
      await Future.delayed(const Duration(minutes: 5));
    } catch (e) {
      await Future.delayed(const Duration(minutes: 1));
      rethrow;
    }
  }
});

// ================ USER MANAGEMENT PROVIDERS ================

final userFilterProvider = StateProvider<UserFilterType>((ref) => UserFilterType.all);
final userSearchQueryProvider = StateProvider<String>((ref) => '');

final adminUsersProvider = StreamProvider<List<AdminUserView>>((ref) {
  final adminRepository = ref.watch(adminRepositoryProvider);
  final searchQuery = ref.watch(userSearchQueryProvider);
  final filter = ref.watch(userFilterProvider);

  return adminRepository.getUsers(
    searchQuery: searchQuery,
    filter: filter,
    limit: 100,
  );
});

final adminUserDetailsProvider = FutureProvider.family<AdminUserView?, String>((ref, userId) async {
  final adminRepository = ref.watch(adminRepositoryProvider);
  return await adminRepository.getUserDetails(userId);
});

final userPostsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final adminRepository = ref.watch(adminRepositoryProvider);
  return await adminRepository.getUserPosts(userId);
});

// ================ CONTENT MANAGEMENT PROVIDERS ================

// Tips Management
final tipsCategoryFilterProvider = StateProvider<String>((ref) => '');
final tipsSearchQueryProvider = StateProvider<String>((ref) => '');

final adminTipsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final adminRepository = ref.watch(adminRepositoryProvider);
  final categoryFilter = ref.watch(tipsCategoryFilterProvider);

  return adminRepository.getAllTips(category: categoryFilter);
});

final filteredAdminTipsProvider = Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final tipsAsync = ref.watch(adminTipsProvider);
  final searchQuery = ref.watch(tipsSearchQueryProvider);

  return tipsAsync.when(
    data: (tips) {
      if (searchQuery.isEmpty) return AsyncValue.data(tips);

      final filtered = tips.where((tip) {
        final title = (tip['title'] as String? ?? '').toLowerCase();
        final content = (tip['content'] as String? ?? '').toLowerCase();
        final category = (tip['category'] as String? ?? '').toLowerCase();
        final query = searchQuery.toLowerCase();

        return title.contains(query) || content.contains(query) || category.contains(query);
      }).toList();

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Videos Management
final videosCategoryFilterProvider = StateProvider<String>((ref) => '');
final videosSearchQueryProvider = StateProvider<String>((ref) => '');

final adminVideosProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final adminRepository = ref.watch(adminRepositoryProvider);
  final categoryFilter = ref.watch(videosCategoryFilterProvider);

  return adminRepository.getAllVideos(category: categoryFilter);
});

final filteredAdminVideosProvider = Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final videosAsync = ref.watch(adminVideosProvider);
  final searchQuery = ref.watch(videosSearchQueryProvider);

  return videosAsync.when(
    data: (videos) {
      if (searchQuery.isEmpty) return AsyncValue.data(videos);

      final filtered = videos.where((video) {
        final title = (video['title'] as String? ?? '').toLowerCase();
        final description = (video['description'] as String? ?? '').toLowerCase();
        final category = (video['category'] as String? ?? '').toLowerCase();
        final query = searchQuery.toLowerCase();

        return title.contains(query) || description.contains(query) || category.contains(query);
      }).toList();

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// ================ REPORTS MANAGEMENT PROVIDERS ================

final reportStatusFilterProvider = StateProvider<ReportStatus?>((ref) => null);

final adminReportsProvider = StreamProvider<List<ContentReport>>((ref) {
  final adminRepository = ref.watch(adminRepositoryProvider);
  final statusFilter = ref.watch(reportStatusFilterProvider);

  return adminRepository.getReports(status: statusFilter);
});

final pendingReportsCountProvider = Provider<int>((ref) {
  final reportsAsync = ref.watch(adminReportsProvider);

  return reportsAsync.when(
    data: (reports) => reports.where((report) => report.status == ReportStatus.pending).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final reportedContentProvider = FutureProvider.family<Map<String, dynamic>?, ReportContentParams>((ref, params) async {
  final adminRepository = ref.watch(adminRepositoryProvider);
  return await adminRepository.getReportedContent(params.contentId, params.contentType);
});

// ================ ADMIN LOGS PROVIDERS ================

final adminLogsProvider = StreamProvider<List<AdminActionLog>>((ref) {
  final adminRepository = ref.watch(adminRepositoryProvider);
  return adminRepository.getAdminLogs(limit: 50);
});

final adminLogsFilteredProvider = StreamProvider.family<List<AdminActionLog>, AdminLogsFilter>((ref, filter) {
  final adminRepository = ref.watch(adminRepositoryProvider);
  return adminRepository.getAdminLogs(
    adminId: filter.adminId,
    actionType: filter.actionType,
    limit: filter.limit,
  );
});

// ================ FORM PROVIDERS ================

// Tip Creation Form
final tipFormProvider = StateNotifierProvider<TipFormNotifier, TipFormState>((ref) {
  return TipFormNotifier();
});

// Video Creation Form
final videoFormProvider = StateNotifierProvider<VideoFormNotifier, VideoFormState>((ref) {
  return VideoFormNotifier();
});

// User Action Form
final userActionFormProvider = StateNotifierProvider<UserActionFormNotifier, UserActionFormState>((ref) {
  return UserActionFormNotifier();
});

// ================ BULK OPERATIONS PROVIDERS ================

final selectedTipsProvider = StateNotifierProvider<SelectedItemsNotifier, Set<String>>((ref) {
  return SelectedItemsNotifier();
});

final selectedVideosProvider = StateNotifierProvider<SelectedItemsNotifier, Set<String>>((ref) {
  return SelectedItemsNotifier();
});

final selectedUsersProvider = StateNotifierProvider<SelectedItemsNotifier, Set<String>>((ref) {
  return SelectedItemsNotifier();
});

// ================ STATE NOTIFIERS ================

class TipFormNotifier extends StateNotifier<TipFormState> {
  TipFormNotifier() : super(TipFormState.initial());

  void updateTitle(String title) {
    state = state.copyWith(title: title);
  }

  void updateContent(String content) {
    state = state.copyWith(content: content);
  }

  void updateCategory(String category) {
    state = state.copyWith(category: category);
  }

  void updateDifficulty(String difficulty) {
    state = state.copyWith(difficulty: difficulty);
  }

  void updateEstimatedTime(String estimatedTime) {
    state = state.copyWith(estimatedTime: estimatedTime);
  }

  void updateTools(List<String> tools) {
    state = state.copyWith(tools: tools);
  }

  void updateBenefits(List<String> benefits) {
    state = state.copyWith(benefits: benefits);
  }

  void updateTags(List<String> tags) {
    state = state.copyWith(tags: tags);
  }

  void reset() {
    state = TipFormState.initial();
  }

  Map<String, dynamic> toMap() {
    return {
      'title': state.title,
      'content': state.content,
      'category': state.category,
      'difficulty': state.difficulty,
      'estimatedTime': state.estimatedTime,
      'tools': state.tools,
      'benefits': state.benefits,
      'tags': state.tags,
      'author': 'Admin',
      'authorId': 'admin',
      'priority': 5,
    };
  }
}

class VideoFormNotifier extends StateNotifier<VideoFormState> {
  VideoFormNotifier() : super(VideoFormState.initial());

  void updateTitle(String title) {
    state = state.copyWith(title: title);
  }

  void updateDescription(String description) {
    state = state.copyWith(description: description);
  }

  void updateCategory(String category) {
    state = state.copyWith(category: category);
  }

  void updateYoutubeUrl(String youtubeUrl) {
    state = state.copyWith(youtubeUrl: youtubeUrl);
  }

  void updateThumbnailUrl(String thumbnailUrl) {
    state = state.copyWith(thumbnailUrl: thumbnailUrl);
  }

  void updateDuration(String duration) {
    state = state.copyWith(duration: duration);
  }

  void reset() {
    state = VideoFormState.initial();
  }

  Map<String, dynamic> toMap() {
    return {
      'title': state.title,
      'description': state.description,
      'category': state.category,
      'youtubeUrl': state.youtubeUrl,
      'thumbnailUrl': state.thumbnailUrl,
      'duration': state.duration,
      'authorName': 'Admin',
      'authorId': 'admin',
      'isYouTubeVideo': true,
    };
  }
}

class UserActionFormNotifier extends StateNotifier<UserActionFormState> {
  UserActionFormNotifier() : super(UserActionFormState.initial());

  void updateReason(String reason) {
    state = state.copyWith(reason: reason);
  }

  void updateNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void reset() {
    state = UserActionFormState.initial();
  }
}

class SelectedItemsNotifier extends StateNotifier<Set<String>> {
  SelectedItemsNotifier() : super(<String>{});

  void toggle(String id) {
    if (state.contains(id)) {
      state = Set.from(state)..remove(id);
    } else {
      state = Set.from(state)..add(id);
    }
  }

  void selectAll(List<String> ids) {
    state = Set.from(ids);
  }

  void clearAll() {
    state = <String>{};
  }

  void remove(String id) {
    state = Set.from(state)..remove(id);
  }
}

// ================ STATE CLASSES ================

class TipFormState {
  final String title;
  final String content;
  final String category;
  final String difficulty;
  final String estimatedTime;
  final List<String> tools;
  final List<String> benefits;
  final List<String> tags;

  TipFormState({
    required this.title,
    required this.content,
    required this.category,
    required this.difficulty,
    required this.estimatedTime,
    required this.tools,
    required this.benefits,
    required this.tags,
  });

  factory TipFormState.initial() {
    return TipFormState(
      title: '',
      content: '',
      category: 'general',
      difficulty: 'beginner',
      estimatedTime: '',
      tools: [],
      benefits: [],
      tags: [],
    );
  }

  TipFormState copyWith({
    String? title,
    String? content,
    String? category,
    String? difficulty,
    String? estimatedTime,
    List<String>? tools,
    List<String>? benefits,
    List<String>? tags,
  }) {
    return TipFormState(
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      tools: tools ?? this.tools,
      benefits: benefits ?? this.benefits,
      tags: tags ?? this.tags,
    );
  }

  bool get isValid => title.isNotEmpty && content.isNotEmpty && category.isNotEmpty;
}

class VideoFormState {
  final String title;
  final String description;
  final String category;
  final String youtubeUrl;
  final String thumbnailUrl;
  final String duration;

  VideoFormState({
    required this.title,
    required this.description,
    required this.category,
    required this.youtubeUrl,
    required this.thumbnailUrl,
    required this.duration,
  });

  factory VideoFormState.initial() {
    return VideoFormState(
      title: '',
      description: '',
      category: 'General',
      youtubeUrl: '',
      thumbnailUrl: '',
      duration: '0:00',
    );
  }

  VideoFormState copyWith({
    String? title,
    String? description,
    String? category,
    String? youtubeUrl,
    String? thumbnailUrl,
    String? duration,
  }) {
    return VideoFormState(
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
    );
  }

  bool get isValid => title.isNotEmpty && description.isNotEmpty && youtubeUrl.isNotEmpty;
}

class UserActionFormState {
  final String reason;
  final String notes;

  UserActionFormState({
    required this.reason,
    required this.notes,
  });

  factory UserActionFormState.initial() {
    return UserActionFormState(
      reason: '',
      notes: '',
    );
  }

  UserActionFormState copyWith({
    String? reason,
    String? notes,
  }) {
    return UserActionFormState(
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
    );
  }

  bool get isValid => reason.isNotEmpty;
}

// ================ HELPER CLASSES ================

class ReportContentParams {
  final String contentId;
  final ContentType contentType;

  ReportContentParams(this.contentId, this.contentType);
}

class AdminLogsFilter {
  final String? adminId;
  final AdminActionType? actionType;
  final int limit;

  AdminLogsFilter({
    this.adminId,
    this.actionType,
    this.limit = 50,
  });
}
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/news_item.dart';
import '../../../core/models/regulation.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/draft_api.dart';
import '../../../core/services/mock_content_api.dart';
import '../../../core/storage/account_profile_storage.dart';
import '../../../core/storage/bookmark_storage.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme.dart';
import '../../regulations/widgets/regulation_card.dart';
import '../bottomnavs/bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

extension StringExtension on String {
  String capitalize() {
    return this.split(' ').map((word) {
      if (word.isEmpty) return '';
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _homeNewsLimit = 6;

  final TextEditingController _searchController = TextEditingController();
  final PageController _newsPageController = PageController(viewportFraction: 0.6);
  final ApiService _apiService = ApiService.instance;
  final DraftApi _draftApi = DraftApi.instance;
  final MockContentApi _api = MockContentApi.instance;

  String? _displayUserName;
  bool _userLoading = true;

  List<NewsItem> _newsItems = [];
  bool _newsLoading = true;
  String? _newsError;

  List<Regulation> _regulationPreview = [];
  bool _regulationsLoading = true;
  String? _regulationsError;
  Set<String> _bookmarkedIds = <String>{};

  String _selectedLanguage = 'English';
  int _selectedNavIndex = 0;
  int _newsActiveIndex = 0;
  Timer? _newsAutoSlideTimer;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadNews();
    _loadBookmarks();
    _loadRegulationPreview();
    _startNewsAutoSlide();
  }

  @override
  void dispose() {
    _newsAutoSlideTimer?.cancel();
    _newsPageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startNewsAutoSlide() {
    _newsAutoSlideTimer?.cancel();
    _newsAutoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_newsPageController.hasClients) {
        return;
      }

      final visibleCount = _visibleNewsItems.length;
      if (visibleCount <= 1) {
        return;
      }

      final nextPage = (_newsActiveIndex + 1) % visibleCount;
      _newsPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  List<NewsItem> get _visibleNewsItems =>
      _newsItems.length > _homeNewsLimit
          ? _newsItems.sublist(0, _homeNewsLimit)
          : _newsItems;

  Future<void> _loadUser() async {
    try {
          final userId = await SecureStorage.readUserId();

      final backendProfile = await _apiService.fetchPortfolio(userId);
      final saved = await AccountProfileStorage.getProfile();
      final registered =
          await AccountProfileStorage.getRegisteredProfileForActiveUser();

      String? readString(Map<String, dynamic>? source, List<String> keys) {
        if (source == null) return null;
        for (final key in keys) {
          final value = source[key];
          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
        }
        return null;
      }

      final backendFirstName =
          readString(backendProfile, const ['first_name', 'firstName']);
      final backendMiddleName =
          readString(backendProfile, const ['middle_name', 'middleName']);
      final backendLastName =
          readString(backendProfile, const ['last_name', 'lastName']);
      final backendJoinedName = [
        if (backendFirstName != null) backendFirstName,
        if (backendMiddleName != null) backendMiddleName,
        if (backendLastName != null) backendLastName,
      ].where((part) => part.trim().isNotEmpty).join(' ');

      final backendFullName =
          readString(backendProfile, const ['full_name', 'fullName', 'name']) ??
          (backendJoinedName.isNotEmpty ? backendJoinedName : null);

      final registeredFirstName =
          (registered?['firstName'] as String?)?.trim();
      final registeredLastName = (registered?['lastName'] as String?)?.trim();
      final registeredFullName = [
        if (registeredFirstName != null && registeredFirstName.isNotEmpty)
          registeredFirstName,
        if (registeredLastName != null && registeredLastName.isNotEmpty)
          registeredLastName,
      ].join(' ');

      final savedFullName = (saved?['fullName'] as String?)?.trim();
      final resolvedUserName =
          (backendFullName != null && backendFullName.isNotEmpty)
              ? backendFullName
              : (savedFullName != null && savedFullName.isNotEmpty)
                  ? savedFullName.capitalize()
                  : (registeredFullName.isNotEmpty ? registeredFullName : 'Guest');

      final backendPreferredLanguage =
          readString(backendProfile, const ['preferred_language', 'preferredLanguage']);

      await AccountProfileStorage.saveProfile({
        if (backendFirstName != null) 'firstName': backendFirstName,
        if (backendLastName != null) 'lastName': backendLastName,
        if (backendFullName != null) 'fullName': backendFullName,
        if (backendPreferredLanguage != null)
          'preferredLanguage': backendPreferredLanguage,
      });

      if (!mounted) {
        return;
      }
      setState(() {
        _displayUserName = resolvedUserName;
        _selectedLanguage = backendPreferredLanguage ?? _selectedLanguage;
        _userLoading = false;
      });
    } catch (_) {
      try {
        final saved = await AccountProfileStorage.getProfile();
        final registered =
            await AccountProfileStorage.getRegisteredProfileForActiveUser();

        final firstName = (registered?['firstName'] as String?)?.trim();
        final lastName = (registered?['lastName'] as String?)?.trim();
        final fullName = [
          if (firstName != null && firstName.isNotEmpty) firstName,
          if (lastName != null && lastName.isNotEmpty) lastName,
        ].join(' ');

        final savedFullName = (saved?['fullName'] as String?)?.trim();
        final resolvedUserName =
            (savedFullName != null && savedFullName.isNotEmpty)
                ? savedFullName.capitalize()
                : (fullName.isNotEmpty ? fullName : 'Guest');

        if (!mounted) {
          return;
        }
        setState(() {
          _displayUserName = resolvedUserName;
          _userLoading = false;
        });
      } catch (_) {
        if (!mounted) {
          return;
        }
        setState(() => _userLoading = false);
      }
    }
  }
  Future<void> _loadNews() async {
    try {
      final items = await _api.fetchNews();
      if (!mounted) {
        return;
      }
      setState(() {
        _newsItems = items;
        _newsLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _newsError = 'Unable to load news.';
        _newsLoading = false;
      });
    }
  }

  Future<void> _loadRegulationPreview() async {
    try {
      final response = await _draftApi.fetchDraftRegulations(page: 1, pageSize: 3);
      if (!mounted) {
        return;
      }
      setState(() {
        _regulationPreview = response.items;
        _regulationsLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _regulationsError = 'Unable to load regulations.';
        _regulationsLoading = false;
      });
    }
  }

  Future<void> _loadBookmarks() async {
    final bookmarks = await BookmarkStorage.getBookmarks();
    if (!mounted) {
      return;
    }
    setState(() => _bookmarkedIds = bookmarks);
  }

  void _handleSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      context.go('/documents');
      return;
    }
    final encoded = Uri.encodeComponent(trimmed);
    context.go('/documents?q=$encoded');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final maxHeight = constraints.maxHeight;
          final horizontalPadding = (maxWidth * 0.06).clamp(16.0, 32.0);
          final contentMaxWidth = maxWidth > 720 ? 720.0 : maxWidth;
          final headerRadius = (maxWidth * 0.06).clamp(16.0, 28.0);

          return SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: AppTheme.brandGradient,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(headerRadius),
                        bottomRight: Radius.circular(headerRadius),
                      ),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentMaxWidth),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              bottom: 0,
                              child: Image.asset(
                                'assets/splash/backlogo.png',
                                width: 96,
                                height: 220,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                maxHeight * 0.05,
                                horizontalPadding,
                                28,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hello',
                                        style: theme
                                            .textTheme.bodyMedium
                                            ?.copyWith(
                                          color: AppTheme.surface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _userLoading
                                                ? 'Loading...'
                                                : '${_displayUserName ?? 'Guest'}!!',
                                            style: theme
                                                .textTheme.displayLarge
                                                ?.copyWith(
                                              color: AppTheme.surface,
                                            ),
                                          ),
                                          _buildLanguageToggle(),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  TextField(
                                    controller: _searchController,
                                    onSubmitted: _handleSearch,
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: AppTheme.primaryText,
                                    ),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Acts, amendments, publication etc',
                                      hintStyle:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: AppTheme.secondaryText,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      filled: true,
                                      fillColor: AppTheme.inputField,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: AppTheme.borderColor,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        color: AppTheme.secondaryText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 24,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'News',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go('/news'),
                              child: Text(
                                'Load More',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.secondaryText,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(height: 230, child: _buildNewsSection()),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Draft Documents',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                _buildRegulationPreviewSliver(horizontalPadding),
                SliverToBoxAdapter(
                  child: SizedBox(height: maxHeight * 0.12),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedNavIndex,
        onIndexChanged: (index) {
          setState(() => _selectedNavIndex = index);
          switch (index) {
            case 0:
              break;
            case 1:
              context.go('/documents');
              break;
            case 2:
              context.go('/feedback');
              break;
            case 3:
              context.go('/settings');
              break;
          }
        },
      ),
    );
  }

  Widget _buildNewsSection() {
    if (_newsLoading) {
      return ListView.builder(
        scrollDirection: Axis.vertical,
        itemCount: 3,
        itemBuilder: (context, index) => _buildNewsSkeleton(),
      );
    }

    if (_newsError != null) {
      return Center(child: Text(_newsError!));
    }

    if (_newsItems.isEmpty) {
      return const Center(child: Text('No news available.'));
    }

    final visibleNews = _visibleNewsItems;

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _newsPageController,
            padEnds: false,
            itemCount: visibleNews.length,
            onPageChanged: (index) {
              if (!mounted) {
                return;
              }
              setState(() => _newsActiveIndex = index);
            },
            itemBuilder: (context, index) {
              final item = visibleNews[index];
              final isLast = index == visibleNews.length - 1;
              return Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : 10),
                child: _buildNewsCard(item),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            visibleNews.length,
            (index) {
              final isActive = _newsActiveIndex == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: isActive ? 18 : 8,
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primaryDark : AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  SliverList _buildRegulationPreviewSliver(double horizontalPadding) {
    if (_regulationsLoading) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              0,
              horizontalPadding,
              16,
            ),
            child: _buildRegulationSkeleton(),
          ),
          childCount: 3,
        ),
      );
    }

    if (_regulationsError != null) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Text(_regulationsError!),
          ),
          childCount: 1,
        ),
      );
    }

    if (_regulationPreview.isEmpty) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: const Text('No regulations available.'),
          ),
          childCount: 1,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final regulation = _regulationPreview[index];
          return Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              0,
              horizontalPadding,
              16,
            ),
            child: RegulationCard(
              regulation: regulation,
              isBookmarked: _bookmarkedIds.contains(regulation.id),
              onTap: () => context.go('/documents/${regulation.id}'),
            ),
          );
        },
        childCount: _regulationPreview.length,
      ),
    );
  }

  Widget _buildLanguageToggle() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.stroke),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildLanguageButton('English', _selectedLanguage == 'English'),
          _buildLanguageButton('አማርኛ', _selectedLanguage == 'አማርኛ'),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(String lang, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = lang),
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.inputFocused : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          lang,
          style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
            color: isSelected ? AppTheme.primaryText : AppTheme.surface,
          ),
        ),
      ),
    );
  }

  Widget _buildNewsCard(NewsItem item) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Image.network(
              item.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: AppTheme.statusGrayBg),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.primaryText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  item.publishedAt,
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsSkeleton() {
    return Container(
      width: 200,
      height: 220,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Container(
            height: 150,
            color: AppTheme.statusGrayBg,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Container(
                  height: 1,
                  width: double.infinity,
                  color: AppTheme.statusGrayBg,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 120,
                  color: AppTheme.statusGrayBg,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegulationSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.statusGrayBg,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: double.infinity,
                  color: AppTheme.statusGrayBg,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 140,
                  color: AppTheme.statusGrayBg,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

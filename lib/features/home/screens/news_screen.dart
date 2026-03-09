import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/news_item.dart';
import '../../../core/models/paginated_response.dart';
import '../../../core/services/news_api.dart';
import '../../../core/theme.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final NewsApi _api = NewsApi.instance;
  final ScrollController _scrollController = ScrollController();

  final int _pageSize = 12;
  int _page = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  List<NewsItem> _news = <NewsItem>[];

  @override
  void initState() {
    super.initState();
    _fetchNews(reset: true);
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 120 &&
        !_isLoadingMore &&
        _hasMore &&
        _errorMessage == null) {
      _fetchNews();
    }
  }

  Future<void> _fetchNews({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _page = 1;
        _hasMore = true;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final PaginatedResponse<NewsItem> response = await _api.fetchNewsPage(
        page: _page,
        pageSize: _pageSize,
      );

      setState(() {
        if (reset) {
          _news = response.items;
        } else {
          _news.addAll(response.items);
        }
        _hasMore = response.hasMore;
        _page += 1;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Unable to load news.';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _fetchNews(reset: true);
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
            child: Column(
              children: [
                Container(
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
                              height: 100,
                              fit: BoxFit.contain,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              maxHeight * 0.04,
                              horizontalPadding,
                              16,
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => context.go('/home'),
                                  icon: const Icon(
                                    Icons.arrow_back_ios,
                                    color: AppTheme.surface,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'News',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      color: AppTheme.surface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 48),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentMaxWidth),
                      child: RefreshIndicator(
                        onRefresh: _refresh,
                        child: _buildContent(theme, horizontalPadding),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(ThemeData theme, double horizontalPadding) {
    if (_isLoading) {
      return ListView.builder(
        padding: EdgeInsets.all(horizontalPadding),
        itemCount: 6,
        itemBuilder: (context, index) => _buildSkeletonCard(),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [Text(_errorMessage!)],
      );
    }

    if (_news.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: const [Text('No news found.')],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 20),
      itemCount: _news.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _news.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final item = _news[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildNewsCard(item, theme),
        );
      },
    );
  }

  Widget _buildNewsCard(NewsItem item, ThemeData theme) {
    return InkWell(
      onTap: () => context.go('/news/${item.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 88,
                height: 72,
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: AppTheme.statusGrayBg),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppTheme.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.publishedAt,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      height: 110,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 88,
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.statusGrayBg,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, width: double.infinity, color: AppTheme.statusGrayBg),
                  const SizedBox(height: 8),
                  Container(height: 10, width: 180, color: AppTheme.statusGrayBg),
                  const Spacer(),
                  Container(height: 10, width: 90, color: AppTheme.statusGrayBg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/news_item.dart';
import '../../../core/services/news_api.dart';
import '../../../core/theme.dart';

class NewsDetailScreen extends StatefulWidget {
  const NewsDetailScreen({super.key, required this.newsId});

  final String newsId;

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final NewsApi _api = NewsApi.instance;

  bool _isLoading = true;
  String? _error;
  NewsItem? _news;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final item = await _api.fetchNewsById(widget.newsId);
      if (!mounted) return;
      setState(() => _news = item);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Unable to load news details.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          final contentMaxWidth = maxWidth > 820 ? 820.0 : maxWidth;
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
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          maxHeight * 0.04,
                          horizontalPadding,
                          16,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => context.pop(),
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
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.menu, color: AppTheme.surface),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentMaxWidth),
                      child: _buildBody(theme, horizontalPadding),
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

  Widget _buildBody(ThemeData theme, double horizontalPadding) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(horizontalPadding),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.secondaryText,
            ),
          ),
        ),
      );
    }

    final item = _news;
    if (item == null) {
      return Center(
        child: Text(
          'News not found',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.secondaryText,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 6, horizontalPadding, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: AppTheme.statusGrayBg),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.statusGrayBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.category,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.secondaryText,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                item.publishedAt,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppTheme.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.content.isEmpty ? item.summary : item.content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.primaryText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

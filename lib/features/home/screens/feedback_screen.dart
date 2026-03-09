import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/feedback_entry.dart';
import '../../../core/storage/feedback_storage.dart';
import '../../../core/theme.dart';
import '../../home/bottomnavs/bottom_nav.dart';

class FeedbackScreen extends StatefulWidget {
	const FeedbackScreen({super.key});

	@override
	State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  Future<List<FeedbackEntry>>? _feedbackFuture;
  final Set<String> _expandedIds = <String>{};
  final DateFormat _submittedDateFormat = DateFormat('MMMM d, y');

  @override
  void initState() {
    super.initState();
    _feedbackFuture = FeedbackStorage.getFeedbacks();
  }

  String _formatSubmittedDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    return _submittedDateFormat.format(parsed);
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
                              maxHeight * 0.05,
                              horizontalPadding,
                              24,
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: 12),
                                Row(
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
                                        'My Feedbacks',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.headlineMedium
                                            ?.copyWith(
                                          color: AppTheme.surface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    // IconButton(
                                    //   onPressed: () => context.go('/settings'),
                                    //   icon: const Icon(
                                    //     Icons.menu,
                                    //     color: AppTheme.surface,
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<FeedbackEntry>>(
                    future: _feedbackFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      final items = snapshot.data ?? [];
                      if (items.isEmpty) {
                        return Center(
                          child: Text(
                            'No feedback submitted yet.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.secondaryText,
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 20,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final entry = items[index];
                          final isExpanded = _expandedIds.contains(entry.id);
                          return _buildFeedbackCard(
                            entry: entry,
                            isExpanded: isExpanded,
                            onToggle: () {
                              setState(() {
                                if (isExpanded) {
                                  _expandedIds.remove(entry.id);
                                } else {
                                  _expandedIds.add(entry.id);
                                }
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
				selectedIndex: 2,
				onIndexChanged: (index) {
					switch (index) {
						case 0:
							context.go('/home');
							break;
						case 1:
							context.go('/documents');
							break;
						case 2:
							break;
						case 3:
							context.go('/settings');
							break;
					}
				},
			),
    );
  }

  Widget _buildFeedbackCard({
    required FeedbackEntry entry,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    final theme = Theme.of(context);
    final previewLines = isExpanded ? null : 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120D47AF),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.regulationTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Submitted: ${_formatSubmittedDate(entry.createdAt)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.feedbackText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onToggle,
                icon: Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppTheme.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.message,
            maxLines: previewLines,
            overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.feedbackText,
              // height: 1.5,
              fontWeight: FontWeight.w500,

            ),
          ),
        ],
      ),
    );
  }
}
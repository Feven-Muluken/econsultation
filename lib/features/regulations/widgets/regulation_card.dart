import 'package:flutter/material.dart';

import '../../../core/models/regulation.dart';
import '../../../core/theme.dart';

class RegulationCard extends StatelessWidget {
  final Regulation regulation;
  final bool isBookmarked;
  final VoidCallback onTap;

  const RegulationCard({
    super.key,
    required this.regulation,
    required this.isBookmarked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColors = _statusColors(regulation.commentClosed);
    final summaryPreview = regulation.summary.trim().isNotEmpty
        ? regulation.summary.trim()
        : regulation.description.trim();
    final summaryText = summaryPreview.isEmpty
      ? '...'
      : summaryPreview.endsWith('...')
        ? summaryPreview
        : '$summaryPreview...';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    regulation.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                    Text(
                      summaryText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryText,
                        height: 1.6,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                            
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColors.background,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${regulation.commentClosed?"closed":"open"} for comment',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: 
                                      statusColors.text,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: 'Law Category: ',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppTheme.lightText,
                                  fontWeight: FontWeight.w600,
                                ),
                                children: [
                                  TextSpan(
                                    text: regulation.category,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppTheme.secondaryText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Text.rich(
                            // TextSpan(
                            //   text: 'Law Category: ',
                            //   style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            //         color: AppTheme.lightText,
                            //         fontWeight: FontWeight.w600,
                            //       ),
                            //   children: <TextSpan>[
                            //     TextSpan(
                            //       text: regulation.category,
                            //       style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            //             color: AppTheme.secondaryText,
                            //           ),
                            //     )
                            //   ],
                            // ),
                          // ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          text: 'Institution: ',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppTheme.lightText,
                                fontWeight: FontWeight.w600,
                              ),
                          children: <TextSpan>[
                            TextSpan(
                              text: regulation.institution,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppTheme.secondaryText,
                                  ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (regulation.isOpenForComment &&
                          (regulation.commentClosingDate ?? '').isNotEmpty)
                        Text.rich(
                          TextSpan(
                            text: 'Comment closes by: ',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.lightText,
                                ),
                            children: <TextSpan>[
                              TextSpan(
                                text: regulation.commentClosingDate,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppTheme.secondaryText,
                                      fontWeight: FontWeight.w500,
                                    ),
                              )
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isBookmarked)
              Icon(
                Icons.bookmark,
                color: AppTheme.primaryDark,
              ),
          ],
        ),
      ),
    );
  }

  _StatusColors _statusColors(bool commentClosed) {
    final status = commentClosed ? 'closed' : 'open';
    final normalized = status.toLowerCase().trim();
    if (normalized == 'open') {
      return _StatusColors(AppTheme.statusGreenBg, AppTheme.statusGreen);
    }
    if (normalized == 'closed') {
      return _StatusColors(AppTheme.statusGrayBg, AppTheme.statusGray);
    }
    return _StatusColors(AppTheme.statusRedBg, AppTheme.statusRed);
  }
}

class _StatusColors {
  final Color background;
  final Color text;

  _StatusColors(this.background, this.text);
}
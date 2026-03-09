import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';

import '../../../core/models/feedback_entry.dart';
import '../../../core/models/draft_detail.dart';
import '../../../core/models/draft_section.dart';
import '../../../core/models/regulation.dart';
import '../../../core/services/draft_api.dart';
import '../../../core/services/mock_content_api.dart';
import '../../../core/storage/bookmark_storage.dart';
import '../../../core/storage/feedback_storage.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme.dart';

enum _ShareFormat { file, pdf, png }

enum _SharePlatform { telegram, whatsapp, email, copyLink }

enum _DownloadUiState { idle, downloading, done }

class RegulationDetailScreen extends StatefulWidget {
  final String regulationId;

  const RegulationDetailScreen({
    super.key,
    required this.regulationId,
  });

  @override
  State<RegulationDetailScreen> createState() => _RegulationDetailScreenState();
}

class _RegulationDetailScreenState extends State<RegulationDetailScreen> {
  static const String _backendBaseUrl = 'https://backend.e-consultation.gov.et';
  final MockContentApi _api = MockContentApi.instance;
  final DraftApi _draftApi = DraftApi.instance;
  final Dio _dio = Dio();
  final TextEditingController _feedbackController = TextEditingController();
  Future<Regulation?>? _regulationFuture;
  Future<List<DraftSection>>? _sectionsFuture;
  Regulation? _currentRegulation;
  DraftDetail? _currentDraftDetail;
  int? _draftId;
  bool _isAuthenticated = false;
  double _downloadProgress = 0.0;
  String? _downloadedFilePath;
  _DownloadUiState _downloadUiState = _DownloadUiState.idle;
  bool _isBookmarked = false;
    final Map<String, List<_InlineSectionComment>> _localSectionComments =
      <String, List<_InlineSectionComment>>{};
  final Map<String, String> _sectionCommentDrafts = <String, String>{};
  final Map<String, bool> _sectionCommentComposerVisible = <String, bool>{};
  final Map<String, String?> _editingCommentIdByDraftKey = <String, String?>{};
    final Map<String, String?> _sectionAttachmentName = <String, String?>{};
    final Map<String, bool> _sectionSuccessVisible = <String, bool>{};
    int _localCommentCounter = 0;
  CancelToken? _downloadCancelToken;
  String _selectedLanguage = 'English';
  Timer? _downloadResetTimer;

  @override
  void initState() {
    super.initState();
    _loadAuthState();
    final backendDraftId = int.tryParse(widget.regulationId);
    if (backendDraftId != null) {
      _draftId = backendDraftId;
      _regulationFuture = _loadRegulationFromDraft(backendDraftId);
      _sectionsFuture = _draftApi.fetchDraftSections(backendDraftId);
    } else {
      _regulationFuture = _api
          .fetchRegulationById(widget.regulationId)
          .then((regulation) {
        _currentRegulation = regulation;
        return regulation;
      });
    }
    _loadBookmark();
  }

  Future<void> _loadAuthState() async {
    final token = await SecureStorage.readToken();
    if (!mounted) {
      return;
    }
    setState(() {
      _isAuthenticated = token != null && token.trim().isNotEmpty;
    });
  }

  Future<Regulation?> _loadRegulationFromDraft(int draftId) async {
    final detail = await _draftApi.fetchDraftDetail(draftId);
    _currentDraftDetail = detail;

    final updatedAt = detail.updatedAt ?? '';
    final normalizedDate = updatedAt.length >= 10 ? updatedAt.substring(0, 10) : updatedAt;

    final mapped = Regulation(
      id: detail.id.toString(),
      title: detail.shortTitle,
      category: detail.category,
      region: '',
      institution: detail.institutionName,
      status: detail.status,
      commentOpeningDate: detail.commentOpeningDate,
      commentClosingDate: detail.commentClosingDate,
      commentClosed: detail.commentClosed,
      description: detail.summary ?? detail.commentRequestDescription ?? '',
      documentUrl: detail.fileUrl,
      updatedAt: normalizedDate,
      summary: detail.summary ?? '',
    );

    _currentRegulation = mapped;
    return mapped;
  }

  @override
  void dispose() {
    _downloadCancelToken?.cancel();
    _downloadResetTimer?.cancel();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadBookmark() async {
    final bookmarked = await BookmarkStorage.isBookmarked(widget.regulationId);
    if (!mounted) {
      return;
    }
    setState(() => _isBookmarked = bookmarked);
  }

  Future<void> _toggleBookmark() async {
    await BookmarkStorage.toggleBookmark(widget.regulationId);
    final bookmarked = await BookmarkStorage.isBookmarked(widget.regulationId);
    if (!mounted) {
      return;
    }
    setState(() => _isBookmarked = bookmarked);
  }

  void _startDownload(Regulation regulation) {
    if (_downloadUiState == _DownloadUiState.downloading) {
      return;
    }

    _downloadResetTimer?.cancel();
    setState(() {
      _downloadProgress = 0.0;
      _downloadUiState = _DownloadUiState.downloading;
    });

    _downloadDocument(regulation);
  }

  void _scheduleDownloadReset() {
    _downloadResetTimer?.cancel();
    _downloadResetTimer = Timer(const Duration(minutes: 3), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _downloadUiState = _DownloadUiState.idle;
      });
    });
  }

  Future<Directory> _resolveDocumentDirectory() async {
    Directory baseDirectory;
    try {
      baseDirectory = await getApplicationDocumentsDirectory();
    } on MissingPluginException {
      try {
        baseDirectory = await getTemporaryDirectory();
      } catch (_) {
        baseDirectory = Directory.systemTemp;
      }
    }

    final docDirectory = Directory('${baseDirectory.path}/econsultation');
    if (!await docDirectory.exists()) {
      await docDirectory.create(recursive: true);
    }
    return docDirectory;
  }

  Future<File> _resolveDownloadFile(Regulation regulation) async {
    final directory = await _resolveDocumentDirectory();
    return File('${directory.path}/${regulation.id}.docx');
  }

  String _resolveDownloadSourceUrl(Regulation regulation) {
    final fromDraftDetail = (_currentDraftDetail?.fileUrl ?? '').trim();
    final fallback = regulation.documentUrl.trim();
    final rawUrl = fromDraftDetail.isNotEmpty ? fromDraftDetail : fallback;

    if (rawUrl.isEmpty) {
      return '';
    }

    final parsed = Uri.tryParse(rawUrl);
    if (parsed != null && parsed.hasScheme) {
      return rawUrl;
    }

    if (rawUrl.startsWith('/')) {
      return '$_backendBaseUrl$rawUrl';
    }

    return '$_backendBaseUrl/$rawUrl';
  }

  Future<void> _downloadDocument(Regulation regulation) async {
    _downloadCancelToken?.cancel();
    _downloadCancelToken = CancelToken();

    try {
      final sourceUrl = _resolveDownloadSourceUrl(regulation);
      if (sourceUrl.isEmpty) {
        throw Exception('Document file URL is missing from backend response.');
      }

      final file = await _resolveDownloadFile(regulation);
      final token = await SecureStorage.readToken();
      final headers = <String, dynamic>{
        'Accept': '*/*',
        if (token != null && token.trim().isNotEmpty)
          'Authorization': 'Bearer ${token.trim()}',
      };

      await _dio.download(
        sourceUrl,
        file.path,
        options: Options(headers: headers),
        cancelToken: _downloadCancelToken,
        onReceiveProgress: (received, total) {
          if (!mounted || total <= 0) {
            return;
          }
          setState(() {
            _downloadProgress = (received / total).clamp(0.0, 1.0);
          });
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _downloadedFilePath = file.path;
        _downloadUiState = _DownloadUiState.done;
      });

      _scheduleDownloadReset();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download complete: ${file.path}')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _downloadUiState = _DownloadUiState.idle;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $error')),
      );
    }
  }

  Future<void> _openDownloadedFile() async {
    final path = _downloadedFilePath;
    if (path == null || path.trim().isEmpty) {
      return;
    }
    final result = await OpenFilex.open(path);
    if (!mounted) {
      return;
    }
    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open file: ${result.message}')),
      );
    }
  }

  Future<void> _shareDocument(
    Regulation regulation,
    _ShareFormat format,
    _SharePlatform platform,
  ) async {
    if (platform == _SharePlatform.copyLink) {
      await Clipboard.setData(ClipboardData(text: regulation.documentUrl));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Share link copied.')),
      );
      return;
    }

    try {
      final file = await _ensureShareFile(regulation, format);
      final mimeType = _shareMimeType(format);
      final xFile = XFile(
        file.path,
        mimeType: mimeType,
        name: file.uri.pathSegments.last,
      );
      await Share.shareXFiles(
        [xFile],
        subject: regulation.title,
        text: regulation.documentUrl,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to share file: $error')),
      );
      await Share.share(
        '${regulation.title}\n${regulation.documentUrl}',
        subject: regulation.title,
      );
    }
  }

  Future<File> _ensureShareFile(
    Regulation regulation,
    _ShareFormat format,
  ) async {
    final directory = await _resolveDocumentDirectory();

    if (format == _ShareFormat.pdf) {
      final file = File('${directory.path}/${regulation.id}.pdf');
      if (!await file.exists()) {
        await file.writeAsString(
          'Document: ${regulation.title}\n${regulation.documentUrl}\n\n'
          'This is a mock PDF payload for sharing.',
        );
      }
      return file;
    }

    if (format == _ShareFormat.png) {
      final file = File('${directory.path}/${regulation.id}.png');
      if (!await file.exists()) {
        await file.writeAsBytes(_mockPngBytes(), flush: true);
      }
      return file;
    }

    final file = File('${directory.path}/${regulation.id}.txt');
    if (!await file.exists()) {
      await file.writeAsString(
        'Document: ${regulation.title}\n${regulation.documentUrl}\n',
      );
    }
    return file;
  }

  String _shareMimeType(_ShareFormat format) {
    switch (format) {
      case _ShareFormat.file:
        return 'text/plain';
      case _ShareFormat.pdf:
        return 'application/pdf';
      case _ShareFormat.png:
        return 'image/png';
    }
  }

  List<int> _mockPngBytes() {
    const base64Png =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVQYV2NgYAAAAAMAAWgmWQ0AAAAASUVORK5CYII=';
    return base64Decode(base64Png);
  }

  Future<void> _openShareSheet(Regulation regulation) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        _ShareFormat selectedFormat = _ShareFormat.pdf;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Share Document',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose format',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.secondaryText,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: [
                      _buildShareFormatChip(
                        label: 'File',
                        isSelected: selectedFormat == _ShareFormat.file,
                        onTap: () => setSheetState(
                          () => selectedFormat = _ShareFormat.file,
                        ),
                      ),
                      _buildShareFormatChip(
                        label: 'PDF',
                        isSelected: selectedFormat == _ShareFormat.pdf,
                        onTap: () => setSheetState(
                          () => selectedFormat = _ShareFormat.pdf,
                        ),
                      ),
                      _buildShareFormatChip(
                        label: 'PNG',
                        isSelected: selectedFormat == _ShareFormat.png,
                        onTap: () => setSheetState(
                          () => selectedFormat = _ShareFormat.png,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Share to',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.secondaryText,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _buildSharePlatformTile(
                    icon: Icons.send,
                    label: 'Telegram',
                    onTap: () {
                      Navigator.of(context).pop();
                      _shareDocument(
                        regulation,
                        selectedFormat,
                        _SharePlatform.telegram,
                      );
                    },
                  ),
                  _buildSharePlatformTile(
                    icon: Icons.chat_bubble_outline,
                    label: 'WhatsApp',
                    onTap: () {
                      Navigator.of(context).pop();
                      _shareDocument(
                        regulation,
                        selectedFormat,
                        _SharePlatform.whatsapp,
                      );
                    },
                  ),
                  _buildSharePlatformTile(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    onTap: () {
                      Navigator.of(context).pop();
                      _shareDocument(
                        regulation,
                        selectedFormat,
                        _SharePlatform.email,
                      );
                    },
                  ),
                  _buildSharePlatformTile(
                    icon: Icons.link,
                    label: 'Copy link',
                    onTap: () {
                      Navigator.of(context).pop();
                      _shareDocument(
                        regulation,
                        selectedFormat,
                        _SharePlatform.copyLink,
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitFeedback(Regulation regulation, String message) async {
    if (!_isAuthenticated) {
      return;
    }

    final entry = FeedbackEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      regulationId: regulation.id,
      regulationTitle: regulation.title,
      message: message,
      createdAt: DateTime.now().toIso8601String(),
    );
    await FeedbackStorage.addFeedback(entry);
  }

  bool _isCommentWindowOpen(DraftDetail detail) {
    if (detail.commentClosed) {
      return false;
    }

    final now = DateTime.now();
    final openDate = _parseBackendDate(detail.commentOpeningDate);
    final closeDate = _parseBackendDate(detail.commentClosingDate);

    if (openDate != null && now.isBefore(openDate)) {
      return false;
    }
    if (closeDate != null && now.isAfter(closeDate)) {
      return false;
    }
    return true;
  }

  DateTime? _parseBackendDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  }

  String _formatDisplayDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) {
      return 'N/A';
    }

    final parsed = _parseBackendDate(rawDate);
    if (parsed == null) {
      return rawDate;
    }

    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}-$month-$day';
  }

  String _openingDateText() {
    return _formatDisplayDate(_currentDraftDetail?.commentOpeningDate);
  }

  String _closingDateText(Regulation regulation) {
    return _formatDisplayDate(
      _currentDraftDetail?.commentClosingDate ?? regulation.commentClosingDate,
    );
  }

  bool _isGeneralCommentAllowed(Regulation regulation) {
    final detail = _currentDraftDetail;
    if (detail != null) {
      return _isCommentWindowOpen(detail);
    }
    return _isRegulationCommentWindowOpen(regulation);
  }

  String _commentStatusText(Regulation regulation) {
    return _isGeneralCommentAllowed(regulation)
        ? 'Open for comment'
        : 'Closed for comment';
  }

  String _commentRuleHint(Regulation regulation) {
    if (!_isAuthenticated) {
      return 'Sign in to provide general or section comments.';
    }
    if (!_isGeneralCommentAllowed(regulation)) {
      return 'Commenting window is closed for this draft.';
    }
    return 'You can provide general feedback and section-by-section comments.';
  }

  Future<void> _pickAttachmentForSection(String draftKey) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );
      if (!mounted || result == null || result.files.isEmpty) {
        return;
      }
      final picked = result.files.first;
      setState(() {
        _sectionAttachmentName[draftKey] = picked.name;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open file picker right now.')),
      );
    }
  }

  void _showSectionThankYou(String draftKey) {
    setState(() => _sectionSuccessVisible[draftKey] = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      setState(() => _sectionSuccessVisible[draftKey] = false);
    });
  }

  List<_InlineSectionComment> _commentsForDraftSection(DraftSection section) {
    final serverComments = section.comments
        .map(
          (comment) => _InlineSectionComment(
            id: 'server_${comment.id}',
            author: (comment.author == null || comment.author!.trim().isEmpty)
                ? 'Public user'
                : comment.author!,
            body: comment.body,
            isMine: false,
          ),
        )
        .toList(growable: false);

    final localComments = _localSectionComments['draft_${section.id}'] ??
        const <_InlineSectionComment>[];

    return <_InlineSectionComment>[...serverComments, ...localComments];
  }

  List<_InlineSectionComment> _commentsForMockSection(RegulationSection section) {
    return _localSectionComments['mock_${section.sectionTitle}'] ??
        const <_InlineSectionComment>[];
  }

  void _deleteSectionComment(String draftKey, String commentId) {
    final list = _localSectionComments[draftKey];
    if (list == null) {
      return;
    }
    setState(() {
      _localSectionComments[draftKey] =
          list.where((comment) => comment.id != commentId).toList();
    });
  }

  void _editSectionComment(
    String draftKey,
    _InlineSectionComment comment,
  ) {
    setState(() {
      _sectionCommentDrafts[draftKey] = comment.body;
      _sectionCommentComposerVisible[draftKey] = true;
      _editingCommentIdByDraftKey[draftKey] = comment.id;
    });
  }

  void _replyToSectionComment(
    String draftKey,
    _InlineSectionComment comment,
  ) {
    setState(() {
      _sectionCommentDrafts[draftKey] = '@${comment.author} ';
      _sectionCommentComposerVisible[draftKey] = true;
    });
  }

  String _stripHtml(String html) {
    var text = html;
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    text = text.replaceAll('&nbsp;', ' ');
    return text.trim();
  }

  Future<void> _submitSectionComment({
    required int sectionId,
    required String sectionTitle,
    required String message,
  }) async {
    if (!_isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to comment.')),
      );
      return;
    }

    final detail = _currentDraftDetail;
    if (detail != null && !_isCommentWindowOpen(detail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commenting window is closed.')),
      );
      return;
    }

    try {
      await _draftApi.postSectionComment(sectionId: sectionId, comment: message);
      final regulation = _currentRegulation;
      if (regulation != null) {
        final entry = FeedbackEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          regulationId: regulation.id,
          regulationTitle: regulation.title,
          message: 'Section: $sectionTitle\n$message',
          createdAt: DateTime.now().toIso8601String(),
        );
        await FeedbackStorage.addFeedback(entry);
      }
      if (_draftId != null) {
        setState(() {
          _sectionsFuture = _draftApi.fetchDraftSections(_draftId!);
        });
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment submitted.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to submit comment right now.')),
      );
    }
  }

  Future<void> _submitInlineSectionComment(DraftSection section) async {
    final key = 'draft_${section.id}';
    final text = (_sectionCommentDrafts[key] ?? '').trim();
    final attachmentName = _sectionAttachmentName[key];
    final editingId = _editingCommentIdByDraftKey[key];
    if (text.isEmpty) {
      return;
    }

    final composed = attachmentName == null
        ? text
        : '$text\nAttachment: $attachmentName';

    await _submitSectionComment(
      sectionId: section.id,
      sectionTitle: section.title,
      message: composed,
    );

    if (!mounted) {
      return;
    }
    setState(() {
      final items = _localSectionComments[key] ?? <_InlineSectionComment>[];
      if (editingId != null) {
        _localSectionComments[key] = items
            .map(
              (item) => item.id == editingId
                  ? _InlineSectionComment(
                      id: item.id,
                      author: item.author,
                      body: composed,
                      isMine: item.isMine,
                    )
                  : item,
            )
            .toList();
      } else {
        _localCommentCounter += 1;
        _localSectionComments[key] = [
          ...items,
          _InlineSectionComment(
            id: 'local_${_localCommentCounter}',
            author: 'You',
            body: composed,
            isMine: true,
          ),
        ];
      }
      _sectionCommentDrafts[key] = '';
      _sectionAttachmentName[key] = null;
      _sectionCommentComposerVisible[key] = false;
      _editingCommentIdByDraftKey[key] = null;
    });
    _showSectionThankYou(key);
  }

  void _submitInlineMockSectionComment(RegulationSection section) {
    if (!_isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to add section comments.')),
      );
      return;
    }

    final regulation = _currentRegulation;
    if (regulation != null && !_isRegulationCommentWindowOpen(regulation)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment period is closed for this section.')),
      );
      return;
    }

    final key = 'mock_${section.sectionTitle}';
    final text = (_sectionCommentDrafts[key] ?? '').trim();
    final attachmentName = _sectionAttachmentName[key];
    final editingId = _editingCommentIdByDraftKey[key];
    if (text.isEmpty) {
      return;
    }

    final composed = attachmentName == null
        ? text
        : '$text\nAttachment: $attachmentName';

    setState(() {
      final existing = _localSectionComments[key] ?? <_InlineSectionComment>[];
      if (editingId != null) {
        _localSectionComments[key] = existing
            .map(
              (item) => item.id == editingId
                  ? _InlineSectionComment(
                      id: item.id,
                      author: item.author,
                      body: composed,
                      isMine: item.isMine,
                    )
                  : item,
            )
            .toList();
      } else {
        _localCommentCounter += 1;
        _localSectionComments[key] = [
          ...existing,
          _InlineSectionComment(
            id: 'local_${_localCommentCounter}',
            author: 'You',
            body: composed,
            isMine: true,
          ),
        ];
      }
      _sectionCommentDrafts[key] = '';
      _sectionAttachmentName[key] = null;
      _sectionCommentComposerVisible[key] = false;
      _editingCommentIdByDraftKey[key] = null;
    });
    _showSectionThankYou(key);
  }

  Widget _buildSectionsCard() {
    final future = _sectionsFuture;
    if (future == null) {
      final sections = _currentRegulation?.sections ?? const <RegulationSection>[];
      if (sections.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sections',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          ...sections.map(_buildMockSectionTile),
        ],
      );
    }

    return FutureBuilder<List<DraftSection>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Text('Unable to load draft sections.');
        }

        final sections = snapshot.data ?? const <DraftSection>[];
        if (sections.isEmpty) {
          return const Text('No draft sections available.');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Document Content',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            ...sections.map((section) => _buildSectionTile(section, 0)),
          ],
        );
      },
    );
  }

  bool _isRegulationCommentWindowOpen(Regulation regulation) {
    if (!regulation.isOpenForComment) {
      return false;
    }

    final closing = regulation.commentClosingDate;
    if (closing == null || closing.trim().isEmpty) {
      return true;
    }

    final parsed = DateTime.tryParse(closing.trim());
    if (parsed == null) {
      return true;
    }

    final now = DateTime.now();
    final closeAtEndOfDay = DateTime(parsed.year, parsed.month, parsed.day, 23, 59, 59);
    return !now.isAfter(closeAtEndOfDay);
  }

  Widget _buildMockSectionTile(RegulationSection section) {
    final regulation = _currentRegulation;
    final canComment = regulation != null &&
        _isAuthenticated &&
        _isRegulationCommentWindowOpen(regulation);
    final draftKey = 'mock_${section.sectionTitle}';
    final draftValue = _sectionCommentDrafts[draftKey] ?? '';
    final composerVisible = _sectionCommentComposerVisible[draftKey] ?? false;
    final comments = _commentsForMockSection(section);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 0,
        color: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.sectionTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (section.articles.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...section.articles.map(
                  (article) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $article',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              const Divider(color: AppTheme.borderColor, height: 16),
              Text(
                'Comments (${comments.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              if (comments.isNotEmpty)
                ...comments.map(
                  (comment) => _buildInlineCommentCard(
                    draftKey: draftKey,
                    comment: comment,
                  ),
                )
              else
                Text(
                  'No comments yet.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.secondaryText,
                      ),
                ),
              const SizedBox(height: 8),
              if (composerVisible) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: draftValue,
                        enabled: canComment,
                        minLines: 2,
                        maxLines: 4,
                        onChanged: (value) => _sectionCommentDrafts[draftKey] = value,
                        decoration: InputDecoration(
                          hintText: 'Write section comment',
                          filled: true,
                          fillColor: AppTheme.inputField,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.borderColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: canComment
                          ? () => _submitInlineMockSectionComment(section)
                          : null,
                      icon: Icon(
                        Icons.send,
                        color: canComment ? AppTheme.primaryDark : AppTheme.statusGray,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Attachment (optional):',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: canComment
                          ? () => _pickAttachmentForSection(draftKey)
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sign in and open comment window to attach files.'),
                                ),
                              );
                            },
                      child: const Text('Choose file'),
                    ),
                    Expanded(
                      child: Text(
                        _sectionAttachmentName[draftKey] ?? 'No file chosen',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.secondaryText,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              if (_sectionSuccessVisible[draftKey] == true)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.statusGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Thank you for your feedback.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.surface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: canComment
                      ? () => setState(() {
                          _sectionCommentComposerVisible[draftKey] = !composerVisible;
                        })
                      : null,
                  child: Text(
                    (_editingCommentIdByDraftKey[draftKey] != null)
                        ? 'Editing comment (${comments.length})'
                        : 'Add comment (${comments.length})',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: canComment
                              ? AppTheme.primary
                              : AppTheme.primary.withValues(alpha: 0.45),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildSectionTile(DraftSection section, int depth) {
    final plainBody = _stripHtml(section.body);
    final hasSectionBody = plainBody.isNotEmpty;
    final canComment = _isAuthenticated &&
        (_currentDraftDetail == null || _isCommentWindowOpen(_currentDraftDetail!));
    final draftKey = 'draft_${section.id}';
    final draftValue = _sectionCommentDrafts[draftKey] ?? '';
    final composerVisible = _sectionCommentComposerVisible[draftKey] ?? false;
    final comments = _commentsForDraftSection(section);

    final content = Column(
      // crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        if (hasSectionBody) ...[
          const SizedBox(height: 8),
          Text(
            plainBody,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (hasSectionBody) ...[
          const SizedBox(height: 16),
          Text(
            'Comments (${comments.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          if (comments.isNotEmpty)
            ...comments.map(
              (comment) => _buildInlineCommentCard(
                draftKey: draftKey,
                comment: comment,
              ),
            )
          else    
            Text(
              'No comments yet.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.secondaryText,
                  ),
            ),
          const SizedBox(height: 8),
          if (composerVisible) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: draftValue,
                    enabled: canComment,
                    minLines: 2,
                    maxLines: 4,
                    onChanged: (value) => _sectionCommentDrafts[draftKey] = value,
                    decoration: InputDecoration(
                      hintText: 'Write section comment',
                      filled: true,
                      fillColor: AppTheme.inputField,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.borderColor),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: canComment ? () => _submitInlineSectionComment(section) : null,
                  icon: Icon(
                    Icons.send,
                    color: canComment ? AppTheme.primaryDark : AppTheme.statusGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Attachment (optional):',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: canComment
                      ? () => _pickAttachmentForSection(draftKey)
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sign in and open comment window to attach files.'),
                            ),
                          );
                        },
                  child: const Text('Choose file'),
                ),
                Expanded(
                  child: Text(
                    _sectionAttachmentName[draftKey] ?? 'No file chosen',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.secondaryText,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          
          if (_sectionSuccessVisible[draftKey] == true)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.statusGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Thank you for your feedback.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.surface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: canComment
                  ? () => setState(() {
                      _sectionCommentComposerVisible[draftKey] = !composerVisible;
                    })
                  : null,
              child: Text(
                (_editingCommentIdByDraftKey[draftKey] != null)
                    ? 'Editing comment (${comments.length})'
                    : 'Add comment (${comments.length})',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: canComment
                          ? AppTheme.primary
                          : AppTheme.primary.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
                  const Divider(color: AppTheme.borderColor, height: 16),
        ],

        if (section.children.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...section.children.map((child) => _buildSectionTile(child, depth + 1)),
        ],
      ],
    );

    if (depth > 0) {
      return content;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 0,
        color: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: content,
        ),
      ),
    );
  }

  Widget _buildInlineCommentCard({
    required String draftKey,
    required _InlineSectionComment comment,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.inputField,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppTheme.statusGray,
                child: Text(
                  comment.author.isNotEmpty ? comment.author[0].toUpperCase() : 'U',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.surface,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  comment.author,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              if (comment.isMine)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editSectionComment(draftKey, comment);
                    } else if (value == 'delete') {
                      _deleteSectionComment(draftKey, comment.id);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comment.body,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryText,
                ),
          ),
          if (!comment.isMine)
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () => _replyToSectionComment(draftKey, comment),
                child: Text(
                  'Reply',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openFeedbackSheet() {
    if (!_isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to comment.')),
      );
      return;
    }

    final regulation = _currentRegulation;
    if (regulation == null) {
      return;
    }
    if (!_isGeneralCommentAllowed(regulation)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commenting window is closed.')),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Provide Feedback',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _feedbackController,
                maxLines: 6,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Write your feedback here!',
                  filled: true,
                  fillColor: AppTheme.inputField,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.borderColor),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final trimmed = _feedbackController.text.trim();
                    if (trimmed.isEmpty) {
                      return;
                    }
                    final regulation = _currentRegulation;
                    if (regulation != null) {
                      _submitFeedback(regulation, trimmed);
                    }
                    Navigator.of(context).pop();
                    _feedbackController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Feedback submitted.'),
                      ),
                    );
                  },
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        );
      },
    );
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
                                      onPressed: () => context.go('/documents'),
                                      icon: const Icon(
                                        Icons.arrow_back_ios,
                                        color: AppTheme.surface,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Document Details',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.headlineMedium
                                            ?.copyWith(
                                          color: AppTheme.surface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _toggleBookmark,
                                      icon: Icon(
                                        _isBookmarked
                                            ? Icons.bookmark
                                            : Icons.bookmark_border,
                                        color: AppTheme.surface,
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
                  ),
                ),
                Expanded(
                  child: FutureBuilder<Regulation?>(                    
                    future: _regulationFuture,
                    builder: (context, snapshot) {
                      if (
                        snapshot.connectionState == ConnectionState.waiting
                        ) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Unable to load the document.'),
                        );
                      }
                      final regulation = snapshot.data;
                      if (regulation == null) {
                        return const Center(
                          child: Text('Draft Document not found.'),
                        );
                      }

                      final statusColors = _statusColors(regulation.commentClosed? 'closed' : 'open');
                          final canComment = _isGeneralCommentAllowed(regulation);

                      final downloadIcon = _downloadUiState == _DownloadUiState.done
                          ? Icons.download_done
                          : _downloadUiState == _DownloadUiState.downloading
                              ? Icons.downloading
                              : Icons.download;
                      final downloadLabel = _downloadUiState == _DownloadUiState.done
                          ? 'Downloaded'
                          : _downloadUiState == _DownloadUiState.downloading
                              ? 'Downloading'
                              : 'Download';

                      return Stack(
                        children: [
                          SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              24,
                              horizontalPadding,
                              24,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16
                                    ),
                                    decoration: BoxDecoration(
                                      // color: const Color(0xFFF2F5FB),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppTheme.borderColor),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text.rich(
                                                TextSpan(
                                                  text: 'Opening Date: ',
                                                  style: theme.textTheme.displaySmall
                                                      ?.copyWith(
                                                    color: AppTheme.lightText,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text: _openingDateText(),
                                                      style: theme.textTheme.displaySmall
                                                          ?.copyWith(
                                                        color: AppTheme.secondaryText,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),

                                            Expanded(
                                              child: Text.rich(
                                                TextSpan(
                                                  text: 'Closing Date: ',
                                                  style: theme.textTheme.displaySmall
                                                      ?.copyWith(
                                                    color: AppTheme.lightText,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text: _closingDateText(regulation),
                                                      style: theme.textTheme.displaySmall
                                                          ?.copyWith(
                                                        color: AppTheme.secondaryText,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                        const SizedBox(height: 18),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                alignment: Alignment.center,
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: statusColors.background,
                                                  borderRadius:
                                                      BorderRadius.circular(999),
                                                ),
                                                child: Text(
                                                  _commentStatusText(regulation),
                                                  style: theme.textTheme.labelSmall
                                                      ?.copyWith(
                                                    color: statusColors.text,
                                                    fontWeight: FontWeight.w500,
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
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text.rich(
                                            TextSpan(
                                              text: 'Institution: ',
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: AppTheme.lightText,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: regulation.agency,
                                                  style: theme.textTheme.labelSmall?.copyWith(
                                                    color: AppTheme.secondaryText,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            _commentRuleHint(regulation),
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: canComment
                                                  ? AppTheme.secondaryText
                                                  : AppTheme.statusRed,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        // const SizedBox(height: 16),
                                      ]
                                    ),
                                  ),
                                  // child: Column()
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      _buildDocLanguageToggle(),
                                      const Spacer(),
                                      _buildDownloadFeatureButton(
                                        icon: downloadIcon,          
                                        label: downloadLabel,
                                        onPressed: _downloadUiState ==
                                                _DownloadUiState.downloading
                                            ? null
                                            : _downloadUiState ==
                                                    _DownloadUiState.done
                                                ? _openDownloadedFile
                                                : () => _startDownload(regulation),
                                      ),
                                    ],
                                  ),
                                  if (_downloadUiState == _DownloadUiState.downloading) ...[
                                    const SizedBox(height: 12),
                                    LinearProgressIndicator(
                                      color: AppTheme.primary,
                                      value: _downloadProgress,
                                    ),
                                  ],
                                  const SizedBox(height: 20),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    alignment: WrapAlignment.start,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      const Spacer(),
                                      _buildFeatureButton(
                                        icon: Icons.share,
                                        label: 'Share',
                                        onPressed: () => _openShareSheet(regulation),
                                      ),
                                      // _buildFeatureButton(
                                      //   icon: _isBookmarked
                                      //       ? Icons.bookmark
                                      //       : Icons.bookmark_border,
                                      //   label: _isBookmarked
                                      //       ? 'Bookmarked'
                                      //       : 'Bookmark',
                                      //   onPressed: _toggleBookmark,
                                      // ),
                                    ],
                                  ),
                                  if (_downloadedFilePath != null &&
                                      _downloadUiState != _DownloadUiState.downloading) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Saved locally for offline preview.',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppTheme.secondaryText,
                                      ),
                                    ),
                                  ],
                                  
                                  const SizedBox(height: 16),
                                  Text(
                                    regulation.title,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  // Text(
                                  //   'Description',
                                  //   style: theme.textTheme.titleMedium?.copyWith(
                                  //     fontWeight: FontWeight.w600,
                                  //     color: AppTheme.primaryText,
                                  //   ),
                                  // ),
                                  // const SizedBox(height: 8),
                                  // Text(
                                  //   regulation.description,
                                  //   style: theme.textTheme.bodyMedium?.copyWith(
                                  //     color: AppTheme.secondaryText,
                                  //     height: 1.6,
                                  //   ),
                                  // ),
                                  const SizedBox(height: 20),
                                  _buildSectionsCard(),
                                ],
                              ),
                            ),
                          Positioned(
                            right: horizontalPadding,
                            bottom: 20,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _openFeedbackSheet,
                                borderRadius: BorderRadius.circular(999),
                                child: Ink(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (_isAuthenticated && canComment)
                                        ? AppTheme.primary
                                        : AppTheme.statusGray,
                                    borderRadius: BorderRadius.circular(90),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: AppTheme.primary,
                                        blurRadius: 30,
                                        offset: Offset(0, 8),
                                        spreadRadius: 6
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.add,
                                        size: 18,
                                        color: AppTheme.surface,
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Provide Feedback',
                                        style: TextStyle(
                                          color: AppTheme.surface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocLanguageToggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          _buildDocLanguageButton('English', _selectedLanguage == 'English'),
          _buildDocLanguageButton('Amharic', _selectedLanguage == 'Amharic'),
        ],
      ),
    );
  }

  Widget _buildDocLanguageButton(String lang, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = lang),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.surfaceVariantLight : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          lang,
          style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isSelected ? AppTheme.langTextSelected : AppTheme.langText,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primaryDark,
        side: const BorderSide(color: AppTheme.borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  Widget _buildDownloadFeatureButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.surface,
        side: const BorderSide(color: AppTheme.borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 22),
        backgroundColor: AppTheme.langTextSelected,          
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),      
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
  

  Widget _buildShareFormatChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primaryLight.withValues(alpha: 0.35),
      backgroundColor: AppTheme.surface,
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: isSelected ? AppTheme.primaryDark : AppTheme.secondaryText,
          ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
    );
  }

  Widget _buildSharePlatformTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppTheme.inputField,
        child: Icon(icon, color: AppTheme.primaryDark),
      ),
      title: Text(label),
      onTap: onTap,
    );
  }

  _StatusColors _statusColors(String status) {
    final normalized = status.toLowerCase().trim();
    if (normalized == 'open') {
      return _StatusColors(AppTheme.statusGreenBg, AppTheme.statusGreen);
    }
    if (normalized == 'closed') {
      return _StatusColors(AppTheme.statusGrayBg, AppTheme.statusGray);
    }
    // if (normalized == 'openforconsultation') {
    //   return _StatusColors(AppTheme.statusGreenBg, AppTheme.statusGreen);
    // }
    // if (normalized == 'finalized') {
    //   return _StatusColors(AppTheme.statusGrayBg, AppTheme.statusGray);
    // }
    return _StatusColors(AppTheme.statusRedBg, AppTheme.statusRed);
  }
}

class _StatusColors {
  final Color background;
  final Color text;

  _StatusColors(this.background, this.text);
}

class _InlineSectionComment {
  final String id;
  final String author;
  final String body;
  final bool isMine;

  _InlineSectionComment({
    required this.id,
    required this.author,
    required this.body,
    required this.isMine,
  });
}

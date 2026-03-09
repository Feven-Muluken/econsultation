import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/paginated_response.dart';
import '../../../core/models/regulation.dart';
import '../../../core/models/regulation_filter.dart';
import '../../../core/services/draft_api.dart';
import '../../../core/storage/bookmark_storage.dart';
import '../../../core/theme.dart';
import '../widgets/regulation_card.dart';
import '../../home/bottomnavs/bottom_nav.dart';

class RegulationsScreen extends StatefulWidget {
  final String? initialQuery;

  const RegulationsScreen({
    super.key,
    this.initialQuery,
  });

  @override
  State<RegulationsScreen> createState() => _RegulationsScreenState();
}

class _RegulationsScreenState extends State<RegulationsScreen> {
  static const List<String> _statusOptions = [
    'Open',
    'Closed',
  ];

  static const List<String> _categoryOptions = [
    'Proclamation',
    'Directive',
    'Regulation',
  ];

  static const List<String> _regionOptions = [
    'Addis Ababa City Administration',
    'far National Regional State',
    'Amhara National Regional State',
    'Benishangul-Gumuz',
    'Dire Dawa',
    'Gambela',
    'Harari',
    'Oromia',
    'Sidama',
    'Somali',
    'South West Ethiopia Peoples',
    'Southern Nations, Nationalities, and Peoples',
    'Tigray',
  ];

  static const List<String> _institutionOptions = [
    'Disaster risk management commission',
    'Ethiopian capital market authority',
    'Ministry of Tourism',
    'Ministry of Planning and Development',
    'Authority for civil Society Organization',
    'ministry of finance',
    'Ministry of Foreign Affairs',
    'Ministry of water and energy',
    'Ministry of Defense',
    'Environmental Protection Authority',
    'Addis Ababa Justice Bureau',
    'Ministry of XYZ',
    'Ministry of ABC',
    'House of Peoples Representatives',
    'Ministry of Culture and Sport-Ethiopia',
    'Ministry of Industry',
    'Ministry of Labor and Skills',
    'Ministry of Revenues',
    'Ministry of Transport & Logistics',
    'Ministry of trade & Regional Integration',
    'Ministry of Peace',
    'Ethiopian Food and Drug Authority',
    'Ministry of Education',
    'Ministry of Mines',
    'Ministry of Irrigation and Lowlands',
    'Ministry of Women and Social Affairs',
    'National Bank of Ethiopia',
    'Ministry Of Agriculture',
    'Ministry of Urban and Infrastructure',
    'Ministry of Health',
    'Ministry of Test',
    'Ministry of Innovation and Technology',
    'Ministry of Justice',
  ];

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DraftApi _draftApi = DraftApi.instance;

  final int _pageSize = 8;
  int _page = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  List<Regulation> _regulations = [];
  RegulationFilter _filter = const RegulationFilter();
  bool _sortDescending = true;
  Set<String> _bookmarkedIds = <String>{};

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
    }
    _loadBookmarks();
    _fetchRegulations(reset: true);
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 120 &&
        !_isLoadingMore &&
        _hasMore &&
        _errorMessage == null) {
      _fetchRegulations();
    }
  }

  Future<void> _fetchRegulations({bool reset = false}) async {
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
      final PaginatedResponse<Regulation> response =
          await _draftApi.fetchDraftRegulations(
        page: _page,
        pageSize: _pageSize,
        query: _searchController.text,
        filter: _filter.isEmpty ? null : _filter,
        sortDescending: _sortDescending,
      );

      setState(() {
        if (reset) {
          _regulations = response.items.toList();
        } else {
          _regulations.addAll(response.items);
        }
        _hasMore = response.hasMore;
        _page += 1;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Unable to load regulations.';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadBookmarks();
    await _fetchRegulations(reset: true);
  }

  Future<void> _loadBookmarks() async {
    final bookmarks = await BookmarkStorage.getBookmarks();
    if (!mounted) {
      return;
    }
    setState(() => _bookmarkedIds = bookmarks);
  }

  void _openFilters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String? selectedStatus = _filter.status;
        String? selectedCategory = _filter.category;
        String? selectedRegion = _filter.region;
        String? selectedInstitution = _filter.institution;
        bool selectedSortDescending = _sortDescending;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: 'Status',
                    value: selectedStatus,
                    options: _statusOptions,
                    onChanged: (value) =>
                        setModalState(() => selectedStatus = value),
                  ),
                  _buildDropdown(
                    label: 'Category',
                    value: selectedCategory,
                    options: _categoryOptions,
                    onChanged: (value) =>
                        setModalState(() => selectedCategory = value),
                  ),
                  _buildDropdown(
                    label: 'Region',
                    value: selectedRegion,
                    options: _regionOptions,
                    onChanged: (value) =>
                        setModalState(() => selectedRegion = value),
                  ),
                  _buildDropdown(
                    label: 'Institution',
                    value: selectedInstitution,
                    options: _institutionOptions,
                    onChanged: (value) =>
                        setModalState(() => selectedInstitution = value),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              selectedStatus = null;
                              selectedCategory = null;
                              selectedRegion = null;
                              selectedInstitution = null;
                              selectedSortDescending = true;
                            });
                          },
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            setState(() {
                              _filter = RegulationFilter(
                                status: selectedStatus,
                                category: selectedCategory,
                                region: selectedRegion,
                                institution: selectedInstitution,
                              );
                              _sortDescending = selectedSortDescending;
                            });
                            _fetchRegulations(reset: true);
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
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
                              // crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 24),
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
                                        'Draft Documents',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.headlineMedium?.copyWith(
                                          color: AppTheme.surface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    // IconButton(
                                    //   onPressed: _openFilters,
                                    //   icon: const Icon(
                                    //     Icons.menu,
                                    //     color: AppTheme.surface,
                                    //   ),
                                    // ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                           
                                TextField(
                                  controller: _searchController,
                                  onSubmitted: (_) => _fetchRegulations(reset: true),
                                  decoration: InputDecoration(
                                    hintText: 
                                      'Acts, amendments, publication etc',
                                    hintStyle: theme.textTheme.labelSmall?.copyWith(
                                      color: AppTheme.secondaryText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      color: AppTheme.secondaryText,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.tune),
                                      onPressed: _openFilters,
                                      color: AppTheme.secondaryText,
                                    ),
                                    filled: true,
                                    fillColor: AppTheme.inputField,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppTheme.borderColor,
                                      ),
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
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: _buildContent(
                      horizontalPadding: horizontalPadding
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 1,
        onIndexChanged: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
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

  Widget _buildContent({
    required double horizontalPadding
  }) {

    if (_isLoading) {
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        itemCount: 6,
        itemBuilder: (context, index) => _buildSkeletonCard(),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Text(_errorMessage!),
        ],
      );
    }

    if (_regulations.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: const [
          Text('No regulations found.'),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
      // padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        horizontal: horizontalPadding,
        vertical: 24,
      ),
      // padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: _regulations.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _regulations.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final regulation = _regulations[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: RegulationCard(
            regulation: regulation,
            isBookmarked: _bookmarkedIds.contains(regulation.id),
            onTap: () => context.go('/documents/${regulation.id}'),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 16,
            width: 220,
            decoration: BoxDecoration(
              color: AppTheme.statusGrayBg,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 12,
            width: 140,
            decoration: BoxDecoration(
              color: AppTheme.statusGrayBg,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 180,
            decoration: BoxDecoration(
              color: AppTheme.statusGrayBg,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        items: options
            .map((option) => DropdownMenuItem(
                  value: option,
                  child: Text(option),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

}

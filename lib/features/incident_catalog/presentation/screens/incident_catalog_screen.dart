import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_spacing.dart';
import '../../../../app/constants/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../../categories/domain/models/category_model.dart';

class IncidentCatalogScreen extends StatefulWidget {
  const IncidentCatalogScreen({
    super.key,
    this.apiClient,
    this.onBackToDashboard,
  });

  final ApiClient? apiClient;
  final VoidCallback? onBackToDashboard;

  @override
  State<IncidentCatalogScreen> createState() => _IncidentCatalogScreenState();
}

class _IncidentCatalogScreenState extends State<IncidentCatalogScreen> {
  late final CategoryRepository _categoryRepository;
  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _categoryRepository = CategoryRepositoryImpl(apiClient: widget.apiClient ?? ApiClient());
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _categoryRepository.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('hardware') || lower.contains('device')) {
      return Icons.computer_rounded;
    } else if (lower.contains('software') || lower.contains('app')) {
      return Icons.apps_rounded;
    } else if (lower.contains('network') || lower.contains('wifi')) {
      return Icons.wifi_rounded;
    } else if (lower.contains('security') || lower.contains('access')) {
      return Icons.security_rounded;
    } else if (lower.contains('print')) {
      return Icons.print_rounded;
    }
    return Icons.support_agent_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredCategories = _categories.where((cat) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final inName = cat.name.toLowerCase().contains(q);
      final inDesc = cat.description?.toLowerCase().contains(q) ?? false;
      final inSub = cat.subCategories.any((s) => s.name.toLowerCase().contains(q));
      return inName || inDesc || inSub;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedCategory == null ? 'Incident Catalog' : _selectedCategory!.name),
        leading: _selectedCategory != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _selectedCategory = null),
              )
            : (widget.onBackToDashboard != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: widget.onBackToDashboard,
                  )
                : null),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: AppLoadingIndicator(message: 'Loading categories...'))
            : _errorMessage != null
                ? AppErrorState(
                    message: _errorMessage!,
                    onRetry: _loadCategories,
                  )
                : RefreshIndicator(
                    onRefresh: _loadCategories,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_selectedCategory == null) ...[
                            TextField(
                              onChanged: (val) => setState(() => _searchQuery = val),
                              decoration: InputDecoration(
                                hintText: 'Search categories or incident templates...',
                                prefixIcon: const Icon(Icons.search_rounded),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded),
                                        onPressed: () => setState(() => _searchQuery = ''),
                                      )
                                    : null,
                                filled: true,
                                fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                                border: OutlineInputBorder(
                                  borderRadius: AppSpacing.borderRadiusLg,
                                  borderSide: BorderSide(
                                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'Choose a category to report an issue:',
                              style: AppTypography.titleMedium.copyWith(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (filteredCategories.isEmpty)
                              const AppEmptyState(
                                title: 'No Categories Found',
                                message: 'Try searching with different keywords.',
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredCategories.length,
                                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                                itemBuilder: (context, index) {
                                  final cat = filteredCategories[index];
                                  return InkWell(
                                    onTap: () {
                                      setState(() => _selectedCategory = cat);
                                    },
                                    borderRadius: AppSpacing.borderRadiusLg,
                                    child: Container(
                                      padding: const EdgeInsets.all(AppSpacing.lg),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                                        borderRadius: AppSpacing.borderRadiusLg,
                                        border: Border.all(
                                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                        ),
                                        boxShadow: const [AppSpacing.shadow1],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withAlpha(25),
                                              borderRadius: AppSpacing.borderRadiusMd,
                                            ),
                                            child: Icon(
                                              _getCategoryIcon(cat.name),
                                              color: AppColors.primary,
                                              size: 26,
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.lg),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  cat.name,
                                                  style: AppTypography.titleMedium.copyWith(
                                                    color: isDark
                                                        ? AppColors.darkTextPrimary
                                                        : AppColors.lightTextPrimary,
                                                  ),
                                                ),
                                                if (cat.description != null) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    cat.description!,
                                                    style: AppTypography.bodyMedium.copyWith(
                                                      color: isDark
                                                          ? AppColors.darkTextSecondary
                                                          : AppColors.lightTextSecondary,
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${cat.subCategories.length} incident templates',
                                                  style: AppTypography.labelSmall.copyWith(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            color: isDark
                                                ? AppColors.darkTextMuted
                                                : AppColors.lightTextMuted,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(20),
                                borderRadius: AppSpacing.borderRadiusMd,
                              ),
                              child: Row(
                                children: [
                                  Icon(_getCategoryIcon(_selectedCategory!.name), color: AppColors.primary),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      _selectedCategory!.description ?? 'Select a specific template below:',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'Available Incident Templates:',
                              style: AppTypography.titleMedium.copyWith(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (_selectedCategory!.subCategories.isEmpty)
                              AppEmptyState(
                                title: 'No Templates Available',
                                message: 'No sub-issues defined under ${_selectedCategory!.name}.',
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _selectedCategory!.subCategories.length,
                                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                                itemBuilder: (context, index) {
                                  final sub = _selectedCategory!.subCategories[index];
                                  return InkWell(
                                    onTap: () {
                                      context.push(
                                        '/incident-catalog/${sub.id}/create',
                                        extra: {
                                          'category': _selectedCategory,
                                          'subCategory': sub,
                                        },
                                      );
                                    },
                                    borderRadius: AppSpacing.borderRadiusLg,
                                    child: Container(
                                      padding: const EdgeInsets.all(AppSpacing.lg),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                                        borderRadius: AppSpacing.borderRadiusLg,
                                        border: Border.all(
                                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                        ),
                                        boxShadow: const [AppSpacing.shadow1],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: isDark ? AppColors.darkInput : AppColors.lightBackground,
                                              borderRadius: AppSpacing.borderRadiusMd,
                                            ),
                                            child: const Icon(
                                              Icons.confirmation_number_outlined,
                                              color: AppColors.primary,
                                              size: 22,
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.md),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  sub.name,
                                                  style: AppTypography.bodyLarge.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark
                                                        ? AppColors.darkTextPrimary
                                                        : AppColors.lightTextPrimary,
                                                  ),
                                                ),
                                                if (sub.description != null) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    sub.description!,
                                                    style: AppTypography.bodyMedium.copyWith(
                                                      color: isDark
                                                          ? AppColors.darkTextSecondary
                                                          : AppColors.lightTextSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}

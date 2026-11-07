import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_spacing.dart';
import '../../../../app/constants/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/domain/user_role.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../../categories/domain/models/category_model.dart';
import '../../../profile/domain/models/user_profile_model.dart';
import '../../../users/data/repositories/user_repository.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../domain/models/ticket_model.dart';

class EditTicketScreen extends StatefulWidget {
  const EditTicketScreen({
    super.key,
    required this.ticketId,
    this.authController,
    this.apiClient,
    this.ticketRepository,
  });

  final String ticketId;
  final AuthController? authController;
  final ApiClient? apiClient;
  final TicketRepository? ticketRepository;

  @override
  State<EditTicketScreen> createState() => _EditTicketScreenState();
}

class _EditTicketScreenState extends State<EditTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late final ApiClient _client;
  late final TicketRepository _ticketRepo;
  late final CategoryRepository _categoryRepo;
  late final UserRepository _userRepo;

  TicketModel? _ticket;
  List<CategoryModel> _categories = [];
  List<UserProfileModel> _technicians = [];
  String _priority = 'MEDIUM';
  int? _selectedCategoryId;
  int? _selectedSubCategoryId;
  int? _selectedAssignedTo;
  List<String> _imageUrls = [];

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isUploading = false;
  String? _errorMessage;

  // 1x1 valid PNG for quick attachment upload testing on emulator
  static final List<int> _samplePngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
  );

  @override
  void initState() {
    super.initState();
    _client = widget.apiClient ?? widget.authController?.apiClient ?? ApiClient();
    _ticketRepo = widget.ticketRepository ?? TicketRepositoryImpl(apiClient: _client);
    _categoryRepo = CategoryRepositoryImpl(apiClient: _client);
    _userRepo = UserRepositoryImpl(apiClient: _client);
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final id = int.tryParse(widget.ticketId);
    if (id == null) {
      setState(() {
        _errorMessage = 'Invalid ticket ID';
        _isLoading = false;
      });
      return;
    }

    try {
      final ticket = await _ticketRepo.getTicketById(id);
      List<CategoryModel> categories = [];
      try {
        categories = await _categoryRepo.getCategories();
      } catch (_) {}

      List<UserProfileModel> techs = [];
      final isAdmin = widget.authController?.state.role == UserRole.admin;
      if (isAdmin) {
        try {
          final allUsers = await _userRepo.getAllUsers();
          techs = allUsers
              .where((u) => u.role.toUpperCase() == 'TECHNICIAN' || u.role.toUpperCase() == 'ADMIN')
              .toList();
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _ticket = ticket;
        _titleController.text = ticket.ticketTitle;
        _descriptionController.text = ticket.description;
        _priority = ticket.priority.toUpperCase();
        _selectedCategoryId = ticket.categoryId;
        _selectedSubCategoryId = ticket.subCategoryId;
        _selectedAssignedTo = ticket.assignedTo;
        _imageUrls = List<String>.from(ticket.imageUrls);
        _categories = categories;
        _technicians = techs;
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

  Future<void> _uploadAttachment() async {
    setState(() => _isUploading = true);
    try {
      final url = await _ticketRepo.uploadImage(
        _samplePngBytes,
        'ticket_${widget.ticketId}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      if (!mounted) return;
      if (url.isNotEmpty) {
        setState(() => _imageUrls.add(url));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attachment uploaded successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _addImageUrlDialog() async {
    final ctrl = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Attachment URL'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Image URL',
            hintText: 'https://...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) Navigator.pop(ctx, ctrl.text.trim());
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (url != null && url.isNotEmpty) {
      setState(() => _imageUrls.add(url));
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate() || _ticket == null) return;
    setState(() => _isSubmitting = true);

    try {
      await _ticketRepo.updateTicket(
        _ticket!.id,
        ticketTitle: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _priority,
        categoryId: _selectedCategoryId ?? _ticket!.categoryId,
        subCategoryId: _selectedSubCategoryId,
        assignedTo: _selectedAssignedTo,
        imageUrls: _imageUrls,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update ticket: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAdmin = widget.authController?.state.role == UserRole.admin;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Edit Ticket #${widget.ticketId}')),
        body: const Center(child: AppLoadingIndicator(message: 'Loading ticket...')),
      );
    }

    if (_errorMessage != null || _ticket == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Edit Ticket #${widget.ticketId}')),
        body: AppErrorState(
          message: _errorMessage ?? 'Ticket not found',
          onRetry: _loadData,
        ),
      );
    }

    final selectedCat = _categories.where((c) => c.id == _selectedCategoryId).firstOrNull;
    final subCategories = selectedCat?.subCategories ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Ticket #TCK-${_ticket!.id}'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _titleController,
                  label: 'Ticket Title *',
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: AppSpacing.lg),

                Text(
                  'Priority Level',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _buildPriorityChip('LOW', 'Low', AppColors.warning),
                    const SizedBox(width: AppSpacing.sm),
                    _buildPriorityChip('MEDIUM', 'Medium', AppColors.mediumPriority),
                    const SizedBox(width: AppSpacing.sm),
                    _buildPriorityChip('HIGH', 'High', AppColors.error),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                if (_categories.isNotEmpty) ...[
                  DropdownButtonFormField<int>(
                    initialValue: _categories.any((c) => c.id == _selectedCategoryId)
                        ? _selectedCategoryId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCategoryId = val;
                        _selectedSubCategoryId = null;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                if (subCategories.isNotEmpty) ...[
                  DropdownButtonFormField<int?>(
                    initialValue: subCategories.any((s) => s.id == _selectedSubCategoryId)
                        ? _selectedSubCategoryId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Sub-Issue (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('None')),
                      ...subCategories.map(
                        (s) => DropdownMenuItem<int?>(value: s.id, child: Text(s.name)),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedSubCategoryId = val),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                if (isAdmin && _technicians.isNotEmpty) ...[
                  DropdownButtonFormField<int?>(
                    initialValue: _technicians.any((t) => t.id == _selectedAssignedTo)
                        ? _selectedAssignedTo
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Assign Technician',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Unassigned')),
                      ..._technicians.map(
                        (t) => DropdownMenuItem<int?>(
                          value: t.id,
                          child: Text('${t.fullName} (${t.role})'),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedAssignedTo = val),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                AppTextField(
                  controller: _descriptionController,
                  label: 'Description *',
                  maxLines: 5,
                  validator: (val) => val == null || val.trim().length < 5
                      ? 'Description must be at least 5 characters'
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attachments (${_imageUrls.length})',
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: _isUploading ? null : _uploadAttachment,
                          icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                          label: Text(_isUploading ? 'Uploading...' : 'Upload File'),
                        ),
                        TextButton.icon(
                          onPressed: _addImageUrlDialog,
                          icon: const Icon(Icons.link_rounded, size: 18),
                          label: const Text('Add URL'),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_imageUrls.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imageUrls.length,
                      separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final resolved = UrlUtils.resolveImageUrl(_imageUrls[index]);
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: AppSpacing.borderRadiusMd,
                              child: Image.network(
                                resolved,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 90,
                                  height: 90,
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.image_outlined),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: InkWell(
                                onTap: () => setState(() => _imageUrls.removeAt(index)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),

                AppButton(
                  text: 'Save Changes',
                  isLoading: _isSubmitting,
                  onPressed: _handleSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String value, String label, Color activeColor) {
    final isSelected = _priority == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _priority = value),
        borderRadius: AppSpacing.borderRadiusMd,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withAlpha(30) : Colors.transparent,
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(
              color: isSelected ? activeColor : Colors.grey.shade400,
              width: isSelected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? activeColor : null,
            ),
          ),
        ),
      ),
    );
  }
}

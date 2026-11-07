import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_spacing.dart';
import '../../../../app/constants/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../categories/domain/models/category_model.dart';
import '../../data/repositories/ticket_repository.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({
    super.key,
    this.subCategoryId,
    this.category,
    this.subCategory,
    this.apiClient,
    this.ticketRepository,
  });

  final String? subCategoryId;
  final CategoryModel? category;
  final CategoryModel? subCategory;
  final ApiClient? apiClient;
  final TicketRepository? ticketRepository;

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  final _descriptionController = TextEditingController();

  String _priority = 'MEDIUM';
  bool _isSubmitting = false;
  bool _isUploading = false;
  final List<String> _attachedImageUrls = [];
  late final TicketRepository _repository;

  static final List<int> _samplePngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
  );

  @override
  void initState() {
    super.initState();
    if (widget.ticketRepository != null) {
      _repository = widget.ticketRepository!;
    } else {
      _repository = TicketRepositoryImpl(apiClient: widget.apiClient ?? ApiClient());
    }

    final initialTitle = widget.subCategory != null
        ? 'Issue with ${widget.subCategory!.name}'
        : 'New Support Incident';
    _titleController = TextEditingController(text: initialTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final categoryId = widget.category?.id ?? 1;
      final subCatId = widget.subCategory?.id ?? int.tryParse(widget.subCategoryId ?? '');

      final ticket = await _repository.createTicket(
        ticketTitle: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _priority,
        categoryId: categoryId,
        subCategoryId: subCatId,
        imageUrls: _attachedImageUrls,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ticket #${ticket.id} created successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pushReplacement('/tickets/${ticket.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit ticket: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _uploadAttachment() async {
    setState(() => _isUploading = true);
    try {
      final url = await _repository.uploadImage(
        _samplePngBytes,
        'incident_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      if (!mounted) return;
      if (url.isNotEmpty) {
        setState(() => _attachedImageUrls.add(url));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded to storage!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _addAttachment() async {
    final urlController = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Image Attachment'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            hintText: 'Enter image URL (http://...)',
            labelText: 'Image URL',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final text = urlController.text.trim();
              if (text.isNotEmpty) Navigator.pop(ctx, text);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (url != null && url.isNotEmpty) {
      setState(() {
        _attachedImageUrls.add(url);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Support Ticket'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.category != null || widget.subCategory != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: AppSpacing.borderRadiusLg,
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.category_outlined, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.category?.name ?? 'Category',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                widget.subCategory?.name ?? 'Incident Template',
                                style: AppTypography.titleMedium.copyWith(
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                AppTextField(
                  controller: _titleController,
                  label: 'Ticket Title',
                  hint: 'Short description of the issue',
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please provide a title for the ticket';
                    }
                    return null;
                  },
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

                AppTextField(
                  controller: _descriptionController,
                  label: 'Description of the Problem',
                  hint: 'Please provide full details, error messages, and steps to reproduce...',
                  maxLines: 5,
                  validator: (val) {
                    if (val == null || val.trim().length < 5) {
                      return 'Description must be at least 5 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attachments (${_attachedImageUrls.length})',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: _isUploading ? null : _uploadAttachment,
                          icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                          label: Text(_isUploading ? 'Uploading...' : 'Upload File'),
                        ),
                        TextButton.icon(
                          onPressed: _addAttachment,
                          icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                          label: const Text('Add URL'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_attachedImageUrls.isEmpty)
                  InkWell(
                    onTap: _uploadAttachment,
                    borderRadius: AppSpacing.borderRadiusLg,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: AppSpacing.borderRadiusLg,
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 36,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Tap to upload an image attachment or add by URL',
                            style: AppTypography.labelMedium.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _attachedImageUrls.length,
                      separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final rawUrl = _attachedImageUrls[index];
                        final resolvedUrl = UrlUtils.resolveImageUrl(rawUrl);
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: AppSpacing.borderRadiusMd,
                              child: Image.network(
                                resolvedUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _attachedImageUrls.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
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
                const SizedBox(height: AppSpacing.xxl),

                AppButton(
                  text: 'Submit Ticket',
                  isLoading: _isSubmitting,
                  onPressed: _handleSubmit,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _priority = value),
        borderRadius: AppSpacing.borderRadiusMd,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withAlpha(30)
                : (isDark ? AppColors.darkCard : AppColors.lightCard),
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isSelected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? activeColor
                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

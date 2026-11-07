import 'package:flutter/material.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_spacing.dart';
import '../../../../app/constants/app_typography.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../domain/models/ticket_model.dart';

class TicketCard extends StatelessWidget {
  const TicketCard({
    super.key,
    required this.ticket,
    required this.onTap,
    this.showCompletedDate = false,
  });

  final TicketModel ticket;
  final VoidCallback onTap;
  final bool showCompletedDate;

  AppBadgeVariant _statusVariant(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return AppBadgeVariant.success;
      case 'IN_PROGRESS':
        return AppBadgeVariant.info;
      case 'PENDING':
      default:
        return AppBadgeVariant.warning;
    }
  }

  AppBadgeVariant _priorityVariant(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return AppBadgeVariant.error;
      case 'MEDIUM':
        return AppBadgeVariant.orange;
      case 'LOW':
      default:
        return AppBadgeVariant.warning;
    }
  }

  String _formatStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'PENDING':
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Ticket ID + Badges
            Row(
              children: [
                Text(
                  '#TCK-${ticket.id}',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                AppBadge(
                  label: ticket.priority,
                  variant: _priorityVariant(ticket.priority),
                ),
                const SizedBox(width: AppSpacing.xs),
                AppBadge(
                  label: _formatStatusLabel(ticket.status),
                  variant: _statusVariant(ticket.status),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Title
            Text(
              ticket.ticketTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Description preview
            if (ticket.description.isNotEmpty) ...[
              Text(
                ticket.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),

            // Metadata row: requester, department, date
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    ticket.createdByName ?? 'User',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
                if (ticket.categoryName != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkInput : AppColors.lightBackground,
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: Text(
                      ticket.categoryName!,
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  showCompletedDate && ticket.completedAt != null
                      ? ticket.completedAt!
                      : (ticket.createdAt ?? ''),
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

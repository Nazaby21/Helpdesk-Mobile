import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_spacing.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../domain/models/ticket_model.dart';
import '../widgets/ticket_card.dart';

class TicketHistoryScreen extends StatefulWidget {
  const TicketHistoryScreen({
    super.key,
    this.apiClient,
    this.ticketRepository,
  });

  final ApiClient? apiClient;
  final TicketRepository? ticketRepository;

  @override
  State<TicketHistoryScreen> createState() => _TicketHistoryScreenState();
}

class _TicketHistoryScreenState extends State<TicketHistoryScreen> {
  late final TicketRepository _repository;
  List<TicketModel> _tickets = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedPriority = 'ALL';

  @override
  void initState() {
    super.initState();
    if (widget.ticketRepository != null) {
      _repository = widget.ticketRepository!;
    } else {
      _repository = TicketRepositoryImpl(apiClient: widget.apiClient ?? ApiClient());
    }
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _repository.getTicketHistory();
      if (!mounted) return;
      setState(() {
        _tickets = list;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredTickets = _tickets.where((t) {
      if (_selectedPriority != 'ALL' && t.priority.toUpperCase() != _selectedPriority) {
        return false;
      }
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final inTitle = t.ticketTitle.toLowerCase().contains(q);
      final inId = '#tck-${t.id}'.contains(q);
      return inTitle || inId;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolved Ticket History'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search resolved tickets...',
                      prefixIcon: const Icon(Icons.search_rounded),
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
                  const SizedBox(height: AppSpacing.sm),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPriorityChip('ALL', 'All Priorities'),
                        const SizedBox(width: AppSpacing.xs),
                        _buildPriorityChip('HIGH', 'High'),
                        const SizedBox(width: AppSpacing.xs),
                        _buildPriorityChip('MEDIUM', 'Medium'),
                        const SizedBox(width: AppSpacing.xs),
                        _buildPriorityChip('LOW', 'Low'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: AppLoadingIndicator(message: 'Loading resolved tickets...'),
                    )
                  : _errorMessage != null
                      ? AppErrorState(
                          message: _errorMessage!,
                          onRetry: _loadHistory,
                        )
                      : RefreshIndicator(
                          onRefresh: _loadHistory,
                          child: filteredTickets.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: const [
                                    SizedBox(height: AppSpacing.xxxl),
                                    AppEmptyState(
                                      title: 'No Completed Tickets',
                                      message: 'No resolved tickets found in history.',
                                    ),
                                  ],
                                )
                              : ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                                  itemCount: filteredTickets.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: AppSpacing.md),
                                  itemBuilder: (context, index) {
                                    final ticket = filteredTickets[index];
                                    return TicketCard(
                                      ticket: ticket,
                                      showCompletedDate: true,
                                      onTap: () => context.push('/tickets/${ticket.id}'),
                                    );
                                  },
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String value, String label) {
    final isSelected = _selectedPriority == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedPriority = value),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

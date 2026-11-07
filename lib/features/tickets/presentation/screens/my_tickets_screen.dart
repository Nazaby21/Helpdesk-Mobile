import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_spacing.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/ticket_repository.dart';
import '../../domain/models/ticket_model.dart';
import '../widgets/ticket_card.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({
    super.key,
    required this.authController,
    this.apiClient,
    this.ticketRepository,
  });

  final AuthController authController;
  final ApiClient? apiClient;
  final TicketRepository? ticketRepository;

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  late final TicketRepository _repository;
  List<TicketModel> _tickets = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'ALL';
  String _selectedPriority = 'ALL';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.ticketRepository != null) {
      _repository = widget.ticketRepository!;
    } else {
      _repository = TicketRepositoryImpl(
        apiClient: widget.apiClient ?? widget.authController.apiClient,
      );
    }
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _repository.getMyTickets();
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
      if (_selectedFilter != 'ALL' && t.status.toUpperCase() != _selectedFilter) {
        return false;
      }
      if (_selectedPriority != 'ALL' && t.priority.toUpperCase() != _selectedPriority) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final inTitle = t.ticketTitle.toLowerCase().contains(q);
        final inId = '#tck-${t.id}'.contains(q);
        return inTitle || inId;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tickets'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            tooltip: 'View History',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => context.push('/user/history'),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => widget.authController.logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/incident-catalog'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Ticket',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search my tickets...',
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
                        _buildFilterChip('ALL', 'All Active'),
                        const SizedBox(width: AppSpacing.sm),
                        _buildFilterChip('PENDING', 'Pending'),
                        const SizedBox(width: AppSpacing.sm),
                        _buildFilterChip('IN_PROGRESS', 'In Progress'),
                        const SizedBox(width: AppSpacing.md),
                        _buildPriorityChip('ALL', 'Any Priority'),
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

            // Main Content Area
            Expanded(
              child: _isLoading
                  ? const Center(child: AppLoadingIndicator(message: 'Loading tickets...'))
                  : _errorMessage != null
                      ? AppErrorState(
                          message: _errorMessage!,
                          onRetry: _loadTickets,
                        )
                      : RefreshIndicator(
                          onRefresh: _loadTickets,
                          child: filteredTickets.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    const SizedBox(height: AppSpacing.xxxl),
                                    AppEmptyState(
                                      title: 'No Tickets Found',
                                      message: _searchQuery.isEmpty
                                          ? 'You have no open tickets at the moment.'
                                          : 'No tickets matched your search criteria.',
                                    ),
                                    if (_searchQuery.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.xxxl,
                                          vertical: AppSpacing.lg,
                                        ),
                                        child: ElevatedButton.icon(
                                          onPressed: () => context.push('/incident-catalog'),
                                          icon: const Icon(Icons.add_circle_outline),
                                          label: const Text('Report an Incident'),
                                        ),
                                      ),
                                  ],
                                )
                              : ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  itemCount: filteredTickets.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: AppSpacing.md),
                                  itemBuilder: (context, index) {
                                    final ticket = filteredTickets[index];
                                    return TicketCard(
                                      ticket: ticket,
                                      onTap: () async {
                                        await context.push('/tickets/${ticket.id}');
                                        _loadTickets();
                                      },
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

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = value),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildPriorityChip(String value, String label) {
    final isSelected = _selectedPriority == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedPriority = value),
      selectedColor: AppColors.info,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

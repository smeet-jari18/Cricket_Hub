import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/tournament_service.dart';
import 'tournament_detail_screen.dart';

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  static const String route = '/create-tournament';

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _winController = TextEditingController(text: '2');
  final _tieController = TextEditingController(text: '1');
  final _lossController = TextEditingController(text: '0');
  final _noResultController = TextEditingController(text: '1');

  String _format = 'round_robin';
  int _overs = 20;
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime? _endDate;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _winController.dispose();
    _tieController.dispose();
    _lossController.dispose();
    _noResultController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isEnd}) async {
    final initial = isEnd ? (_endDate ?? _startDate) : _startDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      helpText: isEnd ? 'Tournament end date' : 'Tournament start date',
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isEnd) {
        _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59);
      } else {
        _startDate = DateTime(picked.year, picked.month, picked.day, 9);
        if (_endDate != null && _endDate!.isBefore(_startDate)) _endDate = null;
      }
    });
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = context.read<AuthProvider>().firebaseUser?.uid;
    if (uid == null || uid.isEmpty) return;
    if (_endDate != null && _endDate!.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after the start date.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final id = await context.read<TournamentService>().createTournament(
            name: _nameController.text.trim(),
            location: _locationController.text.trim(),
            startAt: _startDate,
            endAt: _endDate,
            format: _format,
            totalOvers: _overs,
            adminUid: uid,
            pointsConfig: {
              'win': int.parse(_winController.text),
              'tie': int.parse(_tieController.text),
              'loss': int.parse(_lossController.text),
              'no_result': int.parse(_noResultController.text),
            },
          );
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        TournamentDetailScreen.route,
        arguments: id,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create tournament: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, d MMM yyyy');
    return Scaffold(
      appBar: AppBar(title: const Text('Create tournament')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  Text('Bring every fixture together',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Set the competition rules first. You can choose app teams and generate the schedule next.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tournament details',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            maxLength: 60,
                            decoration: const InputDecoration(
                              labelText: 'Tournament name',
                              hintText: 'e.g. Ahmedabad Monsoon Cup',
                              prefixIcon: Icon(Icons.emoji_events_outlined),
                              counterText: '',
                            ),
                            validator: (value) => (value ?? '').trim().isEmpty
                                ? 'Enter a tournament name.'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _locationController,
                            textCapitalization: TextCapitalization.words,
                            maxLength: 60,
                            decoration: const InputDecoration(
                              labelText: 'Location',
                              hintText: 'City or ground',
                              prefixIcon: Icon(Icons.place_outlined),
                              counterText: '',
                            ),
                            validator: (value) => (value ?? '').trim().isEmpty
                                ? 'Add a location.'
                                : null,
                          ),
                          const SizedBox(height: 8),
                          _DateChoiceTile(
                            label: 'Starts',
                            value: dateFormat.format(_startDate),
                            onTap: () => _pickDate(isEnd: false),
                          ),
                          const SizedBox(height: 8),
                          _DateChoiceTile(
                            label: 'Ends (optional)',
                            value: _endDate == null
                                ? 'Add an end date'
                                : dateFormat.format(_endDate!),
                            onTap: () => _pickDate(isEnd: true),
                            onClear: _endDate == null
                                ? null
                                : () => setState(() => _endDate = null),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Competition format',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _FormatChip(
                                selected: _format == 'round_robin',
                                icon: Icons.sync_alt_rounded,
                                label: 'Round robin',
                                onTap: () => setState(() => _format = 'round_robin'),
                              ),
                              _FormatChip(
                                selected: _format == 'knockout',
                                icon: Icons.account_tree_outlined,
                                label: 'Knockout',
                                onTap: () => setState(() => _format = 'knockout'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _format == 'round_robin'
                                ? 'Every team plays every other team once. Points and NRR decide the table.'
                                : 'Single-elimination bracket with seeded byes for non-power-of-two team counts.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 18),
                          Text('Overs per match',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 9),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [5, 10, 15, 20, 25, 30].map((value) {
                              final selected = _overs == value;
                              return ChoiceChip(
                                label: Text('$value overs'),
                                selected: selected,
                                showCheckmark: false,
                                selectedColor: AppTheme.primary,
                                labelStyle: TextStyle(
                                  color: selected ? Colors.white : AppTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                                onSelected: (_) => setState(() => _overs = value),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Points system',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 6),
                          Text(
                            'Customize the default awards. NRR breaks points ties.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _PointsField(label: 'Win', controller: _winController),
                              const SizedBox(width: 10),
                              _PointsField(label: 'Tie', controller: _tieController),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _PointsField(label: 'Loss', controller: _lossController),
                              const SizedBox(width: 10),
                              _PointsField(label: 'No result', controller: _noResultController),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _create,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.arrow_forward_rounded),
                    label: Text(_saving ? 'Creating…' : 'Create tournament'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateChoiceTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateChoiceTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceSoft,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_outlined, color: AppTheme.primary),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            )),
                    const SizedBox(height: 2),
                    Text(value, style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
              ),
              if (onClear != null)
                IconButton(
                  tooltip: 'Clear date',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, size: 18),
                )
              else
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormatChip extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FormatChip({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      avatar: Icon(icon, size: 18, color: selected ? Colors.white : AppTheme.primary),
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppTheme.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      onSelected: (_) => onTap(),
    );
  }
}

class _PointsField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _PointsField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          final number = int.tryParse((value ?? '').trim());
          if (number == null || number < 0 || number > 20) return '0–20 only';
          return null;
        },
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../controller.dart';
import '../model.dart';
import 'theme.dart';

Future<void> showActivityMenu(BuildContext context, TrackerController c) async {
  final kind = await showModalBottomSheet<ActivityKind>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: ink,
    builder: (ctx) => SizedBox(
      height: MediaQuery.sizeOf(ctx).height * .86,
      child: Backdrop(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Log activity',
                      style: Theme.of(ctx).textTheme.headlineMedium,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: surface.withValues(alpha: .8),
                    ),
                    child: IconButton(
                      key: const ValueKey('close-menu'),
                      onPressed: () => Navigator.pop(ctx),
                      tooltip: 'Close',
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  for (final kind in ActivityKind.values)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      child: Material(
                        color: surface.withValues(alpha: .6),
                        borderRadius: BorderRadius.circular(18),
                        clipBehavior: Clip.antiAlias,
                        child: KeyedSubtree(
                          key: ValueKey('activity-${kind.name}'),
                          child: ListTile(
                            key: ValueKey(
                              'debug_log_activity_${kind.name}_row',
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: ActivityIcon(kind, size: 40),
                            title: Text(
                              kind.label,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              c.entries.where((e) => e.kind == kind).isEmpty
                                  ? 'No logs yet'
                                  : 'Last logged ${clockLabel(c.entries.where((e) => e.kind == kind).first.start, c.profile)}',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: lavender,
                              size: 22,
                            ),
                            onTap: () => Navigator.pop(ctx, kind),
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
  );
  if (kind != null && context.mounted) await showEditor(context, c, kind);
}

Future<void> showEditor(
  BuildContext context,
  TrackerController c,
  ActivityKind kind, {
  ActivityEntry? entry,
  DateTime? initialStart,
  DateTime? initialEnd,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: ink,
  builder: (ctx) => ActivityEditor(
    controller: c,
    kind: kind,
    entry: entry,
    initialStart: initialStart,
    initialEnd: initialEnd,
  ),
);

/// Predicted dial events open a summary before the original's log editor.
Future<void> showPredictionSummary(
  BuildContext context,
  TrackerController c,
  ActivityKind kind, {
  required DateTime start,
  DateTime? end,
}) async {
  final log = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: ink,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const SizedBox(width: 48),
                  Expanded(
                    child: Text(
                      'Predicted ${kind == ActivityKind.nap ? 'nap' : 'bedtime'}',
                      textAlign: TextAlign.center,
                      style: Theme.of(ctx).textTheme.headlineMedium,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('debug_tracking_event_close_button'),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(ctx, false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Image.asset(
                'assets/tracking/headers/${kind.asset}.webp',
                height: 148,
              ),
              const SizedBox(height: 24),
              Text(
                end == null
                    ? clockLabel(start, c.profile)
                    : scheduleDurationLabel(end.difference(start)),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (end != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${clockLabel(start, c.profile)} - ${clockLabel(end, c.profile)}',
                  style: const TextStyle(color: muted, fontSize: 16),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('debug_tracking_event_primary_button'),
                  onPressed: c.writing ? null : () => Navigator.pop(ctx, true),
                  child: Text(
                    'Log ${kind == ActivityKind.nap ? 'nap' : 'bedtime'}',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (log == true && context.mounted) {
    await showEditor(context, c, kind, initialStart: start, initialEnd: end);
  }
}

Future<bool> showActivityOverlap(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Overlapping Activity',
                  style: Theme.of(ctx).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                const Text(
                  'This activity overlaps with an existing one. You can discard it or change its time to continue.',
                  style: TextStyle(color: muted, fontSize: 18),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  key: const ValueKey('overlap-discard'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF47969),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Discard activity'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  key: const ValueKey('overlap-edit-time'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3C3154),
                  ),
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Edit time'),
                ),
              ],
            ),
          ),
        ),
      ),
    ) ??
    false;

Future<bool> confirmDeleteActivity(BuildContext context) async {
  final yes = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete activity?'),
      content: const Text('This removes the activity from your local history.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const ValueKey('confirm-delete'),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return yes == true;
}

/// A dial tap first shows the recorded activity; editing is a separate step.
Future<void> showEntrySummary(
  BuildContext context,
  TrackerController c,
  ActivityEntry entry,
) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  backgroundColor: ink,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
  ),
  builder: (ctx) => AnimatedBuilder(
    animation: c,
    builder: (ctx, _) {
      final current =
          c.entries.where((e) => e.id == entry.id).firstOrNull ?? entry;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    key: const ValueKey('summary-delete-entry'),
                    tooltip: 'Delete',
                    onPressed: c.writing
                        ? null
                        : () async {
                            final yes = await confirmDeleteActivity(ctx);
                            if (!yes || !ctx.mounted || c.writing) return;
                            final ok = await perform(
                              ctx,
                              () => c.deleteEntry(current.id),
                            );
                            if (ok && ctx.mounted) Navigator.pop(ctx);
                          },
                    icon: Image.asset(
                      'assets/common/delete_icon.webp',
                      width: 26,
                      height: 26,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      current.kind.label,
                      textAlign: TextAlign.center,
                      style: Theme.of(ctx).textTheme.headlineMedium,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('debug_tracking_event_close_button'),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Image.asset(
                'assets/tracking/headers/${current.kind.asset}.webp',
                height: 148,
                errorBuilder: (_, _, _) => ActivityIcon(current.kind, size: 96),
              ),
              const SizedBox(height: 24),
              Text(
                durationLabel(c.elapsed(current)),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${clockLabel(current.start, c.profile)} - ${current.end == null ? 'now' : clockLabel(current.end!, c.profile)}',
                style: const TextStyle(color: muted, fontSize: 16),
              ),
              if (current.note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(current.note),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('debug_tracking_event_primary_button'),
                  onPressed: c.writing
                      ? null
                      : () async {
                          await showEditor(
                            ctx,
                            c,
                            current.kind,
                            entry: current,
                          );
                          if (ctx.mounted &&
                              !c.entries.any((e) => e.id == current.id)) {
                            Navigator.pop(ctx);
                          }
                        },
                  child: const Text('Edit'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  ),
);

class ActivityEditor extends StatefulWidget {
  const ActivityEditor({
    super.key,
    required this.controller,
    required this.kind,
    this.entry,
    this.initialStart,
    this.initialEnd,
  });
  final TrackerController controller;
  final ActivityKind kind;
  final ActivityEntry? entry;
  final DateTime? initialStart;
  final DateTime? initialEnd;
  @override
  State<ActivityEditor> createState() => _ActivityEditorState();
}

class _ActivityEditorState extends State<ActivityEditor> {
  late DateTime start;
  DateTime? end;
  late TextEditingController note, amount, food;
  late String choice;
  late String initialAmount;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    start = widget.entry?.start ?? widget.initialStart ?? widget.controller.now;
    end = widget.entry?.end ?? widget.initialEnd;
    note = TextEditingController(text: widget.entry?.note ?? '');
    final details = widget.entry?.details ?? const TrackingDetails();
    final metric = widget.controller.profile.metric;
    final factor = widget.kind == ActivityKind.bottleFeeding
        ? kMlPerFlOz
        : kGramsPerOz;
    amount = TextEditingController(
      text: details.amount == null
          ? ''
          : (details.amount! / (metric ? 1 : factor)).toStringAsFixed(
              metric ? 0 : 2,
            ),
    );
    initialAmount = amount.text;
    food = TextEditingController(text: details.food);
    choice = details.choice.isNotEmpty
        ? details.choice
        : switch (widget.kind) {
            ActivityKind.nursing => 'Both',
            ActivityKind.bottleFeeding => 'Breast milk',
            ActivityKind.diaperChange => 'Wet',
            _ => '',
          };
  }

  @override
  void dispose() {
    note.dispose();
    amount.dispose();
    food.dispose();
    super.dispose();
  }

  String? get validation {
    if (start.isAfter(widget.controller.now) ||
        (end?.isAfter(widget.controller.now) ?? false)) {
      return 'Activity time cannot be in the future';
    }
    if (widget.kind == ActivityKind.wakeUp &&
        (start.hour * 60 + start.minute < 180 ||
            start.hour * 60 + start.minute > 900)) {
      return 'Choose wake-up between 3:00 AM and 3:00 PM';
    }
    if (end != null && !end!.isAfter(start)) return 'End must be after start';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final kind = widget.kind;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .95,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4C4078), Color(0xFF261B42), ink],
              stops: [0, .30, .65],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        IconButton(
                          key: const ValueKey(
                            'debug_tracking_event_back_button',
                          ),
                          onPressed: saving
                              ? null
                              : () => Navigator.pop(context),
                          tooltip: 'Back',
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF65578B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Text(
                            kind.label,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        IconButton(
                          key: const ValueKey(
                            'debug_tracking_event_close_button',
                          ),
                          onPressed: saving
                              ? null
                              : () => Navigator.pop(context),
                          tooltip: 'Close',
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF65578B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Image.asset(
                          'assets/tracking/headers/${kind.asset}.webp',
                          height: 148,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 18),
                        _field(
                          'Date',
                          shortDate(start, c.now),
                          () => _date(context),
                          key: kind == ActivityKind.wakeUp
                              ? const ValueKey('debug_wake_up_date_field')
                              : null,
                        ),
                        const SizedBox(height: 26),
                        if (kind.interval)
                          LayoutBuilder(
                            builder: (ctx, constraints) =>
                                constraints.maxWidth < 300 ||
                                    MediaQuery.textScalerOf(ctx).scale(1) > 1.4
                                ? Column(
                                    children: [
                                      _field(
                                        'Start',
                                        clockLabel(start, c.profile),
                                        () => _time(context, false),
                                        key: const ValueKey(
                                          'debug_tracking_start_time_field',
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _field(
                                        'End',
                                        end == null
                                            ? 'Set time'
                                            : clockLabel(end!, c.profile),
                                        () => _time(context, true),
                                        key: const ValueKey(
                                          'debug_tracking_end_time_field',
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _field(
                                          'Start',
                                          clockLabel(start, c.profile),
                                          () => _time(context, false),
                                          key: const ValueKey(
                                            'debug_tracking_start_time_field',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _field(
                                          'End',
                                          end == null
                                              ? 'Set time'
                                              : clockLabel(end!, c.profile),
                                          () => _time(context, true),
                                          key: const ValueKey(
                                            'debug_tracking_end_time_field',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          )
                        else
                          _field(
                            'Time',
                            clockLabel(start, c.profile),
                            () => _time(context, false),
                            key: kind == ActivityKind.wakeUp
                                ? const ValueKey('debug_wake_up_time_field')
                                : const ValueKey(
                                    'debug_tracking_start_time_field',
                                  ),
                          ),
                        if (kind.index >= ActivityKind.nursing.index) ...[
                          const SizedBox(height: 24),
                          if (choice.isNotEmpty) _choices(kind),
                          if (kind == ActivityKind.solids) ...[
                            const SizedBox(height: 12),
                            TextField(
                              key: const ValueKey('entry-food'),
                              controller: food,
                              decoration: const InputDecoration(
                                labelText: 'Food',
                              ),
                            ),
                          ],
                          if (kind == ActivityKind.bottleFeeding ||
                              kind == ActivityKind.solids) ...[
                            const SizedBox(height: 16),
                            TextField(
                              key: const ValueKey('entry-amount'),
                              controller: amount,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText:
                                    'Amount (${kind == ActivityKind.bottleFeeding ? (c.profile.metric ? 'ml' : 'fl oz') : (c.profile.metric ? 'g' : 'oz')})',
                              ),
                            ),
                          ],
                        ],
                        const SizedBox(height: 24),
                        const Text(
                          'Note',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 10),
                        KeyedSubtree(
                          key: const ValueKey('entry-note'),
                          child: TextField(
                            key: const ValueKey('debug_tracking_note_field'),
                            controller: note,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 3,
                            minLines: 1,
                            decoration: const InputDecoration(
                              hintText: 'Enter text',
                            ),
                          ),
                        ),
                        if (validation != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Text(
                              validation!,
                              style: const TextStyle(color: Color(0xFFFFC8AC)),
                            ),
                          ),
                        if (widget.entry != null)
                          TextButton.icon(
                            key: const ValueKey('delete-entry'),
                            onPressed: saving ? null : _delete,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Delete activity'),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: KeyedSubtree(
                        key: const ValueKey('save-entry'),
                        child: FilledButton(
                          key: const ValueKey(
                            'debug_tracking_event_primary_button',
                          ),
                          onPressed: saving || validation != null
                              ? null
                              : _save,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.entry == null &&
                                  kind.interval &&
                                  end == null) ...[
                                Image.asset(
                                  'assets/tracking/buttons/start_icon.webp',
                                  height: 22,
                                  width: 22,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                saving
                                    ? 'Saving…'
                                    : widget.entry != null ||
                                          !kind.interval ||
                                          end != null
                                    ? 'Save'
                                    : kind == ActivityKind.nap
                                    ? 'Start nap'
                                    : 'Start',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _choices(ActivityKind kind) {
    final options = switch (kind) {
      ActivityKind.nursing => ['Left', 'Right', 'Both'],
      ActivityKind.bottleFeeding => ['Breast milk', 'Formula'],
      _ => ['Wet', 'Dirty', 'Mixed', 'Dry'],
    };
    String asset(String v) => switch (kind) {
      ActivityKind.nursing => 'breast_${v.toLowerCase()}_icon',
      ActivityKind.bottleFeeding =>
        v == 'Formula' ? 'formula_icon' : 'breast_milk_icon',
      _ => 'diaper_${v.toLowerCase()}_icon',
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map(
            (v) => ChoiceChip(
              label: Text(v),
              avatar: Image.asset(
                'assets/tracking/buttons/${asset(v)}.webp',
                width: 24,
                height: 24,
              ),
              selected: choice == v,
              onSelected: saving ? null : (_) => setState(() => choice = v),
            ),
          )
          .toList(),
    );
  }

  TrackingDetails get details {
    double? value;
    if (amount.text == initialAmount && widget.entry != null) {
      return TrackingDetails(
        amount: widget.entry!.details.amount,
        choice: choice,
        food: food.text.trim(),
      );
    }
    if (amount.text.trim().isNotEmpty) {
      value = double.tryParse(amount.text.trim());
      if (value == null || !value.isFinite || value <= 0) {
        throw ArgumentError('Enter an amount greater than zero');
      }
      if (!widget.controller.profile.metric) {
        value *= widget.kind == ActivityKind.bottleFeeding
            ? kMlPerFlOz
            : kGramsPerOz;
      }
    }
    return TrackingDetails(
      amount: value,
      choice: choice,
      food: food.text.trim(),
    );
  }

  Widget _field(
    String title,
    String value,
    VoidCallback onTap, {
    Key? key,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          ),
          if (title == 'End' && end != null)
            IconButton(
              key: const ValueKey('debug_tracking_end_time_delete_button'),
              tooltip: 'Delete end time',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              onPressed: saving ? null : _removeEnd,
              icon: Image.asset(
                'assets/common/delete_icon.webp',
                width: 22,
                height: 22,
              ),
            ),
        ],
      ),
      const SizedBox(height: 10),
      InkWell(
        key: key,
        onTap: saving ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: surface.withValues(alpha: .85),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: value == 'Set time' ? muted : null,
            ),
          ),
        ),
      ),
    ],
  );
  Future<void> _removeEnd() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete end time'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('confirm-delete-end-time'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete end time'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) setState(() => end = null);
  }

  Future<void> _date(BuildContext context) async {
    final date = await pickWheel(
      context,
      'Date',
      start,
      CupertinoDatePickerMode.date,
      widget.controller.now,
    );
    if (date != null && mounted) {
      setState(() {
        final shifted = DateTime(
          date.year,
          date.month,
          date.day,
          start.hour,
          start.minute,
        );
        final delta = shifted.difference(start);
        start = shifted;
        if (end != null) end = end!.add(delta);
      });
    }
  }

  Future<void> _time(BuildContext context, bool isEnd) async {
    final value = await pickWheel(
      context,
      isEnd ? 'End time' : 'Start time',
      isEnd ? end ?? widget.controller.now : start,
      CupertinoDatePickerMode.time,
      widget.controller.now,
      use24Hour: widget.controller.profile.use24Hour,
    );
    if (value != null && mounted) {
      setState(() {
        if (isEnd) {
          var chosen = DateTime(
            start.year,
            start.month,
            start.day,
            value.hour,
            value.minute,
          );
          if (!chosen.isAfter(start)) {
            chosen = chosen.add(const Duration(days: 1));
          }
          end = chosen;
        } else {
          final previousEnd = end;
          start = DateTime(
            start.year,
            start.month,
            start.day,
            value.hour,
            value.minute,
          );
          if (previousEnd != null && !previousEnd.isAfter(start)) {
            end = start.add(const Duration(hours: 1));
          }
        }
      });
    }
  }

  Future<void> _save() async {
    setState(() => saving = true);
    final ok = await perform(
      context,
      () => widget.controller.saveEntry(
        widget.entry?.revised(
              start: start,
              end: end,
              note: note.text.trim(),
              details: details,
            ) ??
            ActivityEntry(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              kind: widget.kind,
              start: start,
              end: end,
              note: note.text.trim(),
              details: details,
            ),
      ),
      onOverlap: () async {
        final discard = await showActivityOverlap(context);
        if (discard && mounted) Navigator.pop(context);
      },
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => saving = false);
    }
  }

  Future<void> _delete() async {
    final yes = await confirmDeleteActivity(context);
    if (yes != true || !mounted) return;
    setState(() => saving = true);
    final ok = await perform(
      context,
      () => widget.controller.deleteEntry(widget.entry!.id),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => saving = false);
    }
  }
}

Future<DateTime?> pickWheel(
  BuildContext context,
  String title,
  DateTime initial,
  CupertinoDatePickerMode mode,
  DateTime now, {
  bool use24Hour = false,
}) async {
  var picked = initial;
  return showDialog<DateTime>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFF2C253D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                key: const ValueKey('debug_datetime_dialog_picker'),
                height: 200,
                child: CupertinoTheme(
                  data: const CupertinoThemeData(brightness: Brightness.dark),
                  child: CupertinoDatePicker(
                    mode: mode,
                    initialDateTime: initial,
                    minimumDate: mode == CupertinoDatePickerMode.time
                        ? null
                        : DateTime(1900),
                    maximumDate: mode == CupertinoDatePickerMode.time
                        ? null
                        : DateTime(now.year, now.month, now.day, 23, 59),
                    use24hFormat: use24Hour,
                    onDateTimeChanged: (d) => picked = d,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey(
                        'debug_datetime_dialog_cancel_button',
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF494056)),
                        foregroundColor: const Color(0xFFE6D8FF),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, null),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KeyedSubtree(
                      key: const ValueKey('picker-save'),
                      child: FilledButton(
                        key: const ValueKey(
                          'debug_datetime_dialog_save_button',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx, picked),
                        child: const Text('Save'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

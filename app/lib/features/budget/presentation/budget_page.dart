import 'package:flutter/material.dart';
import '../../../core/money.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/budget.dart';
import 'budget_view_model.dart';

const monthNames = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

const _chartColors = [
  Color(0xff2563eb),
  Color(0xff06b6d4),
  Color(0xff6366f1),
  Color(0xff0ea5e9),
  Color(0xff14b8a6),
  Color(0xff8b5cf6),
  Color(0xff64748b),
];

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key, required this.model});
  final BudgetViewModel model;

  BudgetCategory _categoryOf(String id) =>
      model.ledger.categories.firstWhere((c) => c.id == id);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    floatingActionButton: FloatingActionButton.extended(
      key: const Key('new-entry'),
      tooltip: 'Agregar movimiento al mes seleccionado',
      onPressed: () => _entry(context),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Movimiento'),
    ),
    body: ListenableBuilder(listenable: model, builder: _content),
  );

  Widget _content(BuildContext context, Widget? _) {
    final month = model.ledger.monthSummary(model.year, model.month);
    final groups = {
      for (final kind in EntryKind.values)
        kind: model.currentEntries
            .where((e) => _categoryOf(e.categoryId).kind == kind)
            .toList(),
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Space.lg,
        Space.md,
        Space.lg,
        Space.xxxl * 2.5,
      ),
      children: [
        const PageHeader(
          eyebrow: 'Presupuesto',
          title: 'Un plan para cada mes',
          subtitle: 'Mi hoja · Casa Rivera · BOB',
        ),
        const SizedBox(height: Space.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: _YearSelector(model: model, onPick: () => _year(context)),
            ),
            const SizedBox(width: Space.xs),
            IconButton.outlined(
              tooltip: 'Gestionar categorías',
              onPressed: () => _categories(context),
              icon: const Icon(Icons.category_outlined),
            ),
            const SizedBox(width: Space.xs),
            IconButton.outlined(
              tooltip: 'Vista previa CSV',
              onPressed: () => _csv(context),
              icon: const Icon(Icons.table_view_outlined),
            ),
          ],
        ),
        const SizedBox(height: Space.md),
        FadeSlideIn(child: _BalanceHero(summary: model.summary)),
        const SectionHeader(title: 'Los doce meses'),
        FadeSlideIn(index: 1, child: _MonthsChart(model: model)),
        const SizedBox(height: Space.lg),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: Space.sm,
          children: [
            Semantics(
              header: true,
              child: Text(
                monthNames[model.month - 1],
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text(
              'Saldo ${formatCents(month.balance)}',
              style: moneyStyle(
                Theme.of(context).textTheme.bodyMedium,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: Space.sm),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Ingresos',
                value: formatCents(month.income),
                icon: Icons.south_west_rounded,
                tone: Tone.success,
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: StatTile(
                label: 'Egresos',
                value: formatCents(month.expense),
                icon: Icons.north_east_rounded,
                tone: Tone.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.xs),
        if (model.currentEntries.isEmpty)
          const Card(
            child: EmptyState(
              compact: true,
              icon: Icons.receipt_long_outlined,
              title: 'Este mes empieza en blanco. Agrega tu primer movimiento.',
            ),
          ),
        for (final kind in EntryKind.values)
          if (groups[kind]!.isNotEmpty) ...[
            SectionHeader(
              title: kind == EntryKind.income ? 'Ingresos' : 'Egresos',
              action: Text(
                '${groups[kind]!.length} '
                '${groups[kind]!.length == 1 ? 'movimiento' : 'movimientos'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Card(
              child: Column(
                children: [
                  for (final (i, entry) in groups[kind]!.indexed) ...[
                    if (i > 0) const Divider(indent: 68),
                    _EntryTile(
                      entry: entry,
                      category: _categoryOf(entry.categoryId),
                      onTap: () => _entry(context, existing: entry),
                      onDelete: () async {
                        if (await showConfirmDialog(
                          context,
                          title: 'Confirmar eliminación',
                          message:
                              '¿Eliminar este movimiento de la demostración?',
                          confirmLabel: 'Eliminar',
                        )) {
                          model.deleteEntry(entry.id);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        _CategoryBreakdown(model: model),
      ],
    );
  }

  Future<void> _year(BuildContext context) async {
    final controller = TextEditingController(text: '${model.year}');
    String? error;
    await _ownedDialog<void>(
      context: context,
      controllers: [controller],
      builder: (context) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: const Text('Buscar año'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Año entre 1 y 9999',
              prefixIcon: const Icon(Icons.calendar_today_outlined),
              errorText: error,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(controller.text.trim());
                if (value == null || value < 1 || value > 9999) {
                  refresh(() => error = 'Escribe un año válido.');
                  return;
                }
                model.setYear(value);
                Navigator.pop(context);
              },
              child: const Text('Ver año'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _entry(BuildContext context, {BudgetEntry? existing}) async {
    if (model.ledger.categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crea una categoría primero.')),
      );
      return;
    }
    final amount = TextEditingController(
      text: existing == null
          ? ''
          : '${existing.amountCents ~/ 100}.${(existing.amountCents % 100).toString().padLeft(2, '0')}',
    );
    final description = TextEditingController(
      text: existing?.description ?? '',
    );
    var categoryId = existing?.categoryId ?? model.ledger.categories.first.id;
    var submitted = false;
    final form = GlobalKey<FormState>();
    await _ownedSheet<void>(
      context: context,
      controllers: [amount, description],
      builder: (context) {
        final text = Theme.of(context).textTheme;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          existing == null
                              ? 'Nuevo movimiento'
                              : 'Editar movimiento',
                          style: text.titleLarge,
                        ),
                      ),
                      StatusBadge(
                        label:
                            '${monthNames[(existing?.month ?? model.month) - 1]} de ${existing?.year ?? model.year}',
                        icon: Icons.event_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.lg),
                  DropdownButtonFormField<String>(
                    initialValue: categoryId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: model.ledger.categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              '${c.kind == EntryKind.income ? '+' : '−'} ${c.name}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => categoryId = v!,
                  ),
                  const SizedBox(height: Space.sm),
                  TextFormField(
                    key: const Key('entry-amount'),
                    controller: amount,
                    autofocus: existing == null,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    style: moneyStyle(
                      text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Monto en Bs',
                      hintText: '0,00',
                      prefixText: 'Bs ',
                      helperText: 'Hasta dos decimales, con coma o punto.',
                    ),
                    validator: (value) {
                      try {
                        Money.parse(value ?? '');
                        return null;
                      } on FormatException catch (e) {
                        return e.message;
                      }
                    },
                  ),
                  const SizedBox(height: Space.sm),
                  TextFormField(
                    controller: description,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: Space.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: FilledButton(
                          key: const Key('save-entry'),
                          onPressed: () {
                            if (submitted || !form.currentState!.validate()) {
                              return;
                            }
                            submitted = true;
                            model.saveEntry(
                              BudgetEntry(
                                id: existing?.id ?? model.newId(),
                                categoryId: categoryId,
                                year: existing?.year ?? model.year,
                                month: existing?.month ?? model.month,
                                amountCents: Money.parse(amount.text).cents,
                                description: description.text.trim(),
                              ),
                            );
                            Navigator.pop(context);
                          },
                          child: const Text('Guardar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _categories(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => ListenableBuilder(
        listenable: model,
        builder: (context, _) => AlertDialog(
          title: const Text('Tus categorías'),
          contentPadding: const EdgeInsets.fromLTRB(
            Space.sm,
            Space.md,
            Space.sm,
            0,
          ),
          content: SizedBox(
            width: 380,
            child: model.ledger.categories.isEmpty
                ? const EmptyState(
                    compact: true,
                    icon: Icons.category_outlined,
                    title: 'Todavía no hay categorías.',
                  )
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final category in model.ledger.categories)
                        ListTile(
                          leading: IconTile(
                            icon: category.kind == EntryKind.income
                                ? Icons.south_west_rounded
                                : Icons.north_east_rounded,
                            tone: category.kind == EntryKind.income
                                ? Tone.success
                                : Tone.danger,
                            size: 36,
                          ),
                          title: Text(
                            category.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            category.kind == EntryKind.income
                                ? 'Ingreso'
                                : 'Egreso',
                          ),
                          onTap: () => _category(context, existing: category),
                          trailing: IconButton(
                            tooltip: 'Eliminar categoría',
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: () {
                              try {
                                model.deleteCategory(category.id);
                              } on StateError catch (e) {
                                _message(context, e.message);
                              }
                            },
                          ),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
            FilledButton.icon(
              onPressed: () => _category(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crear categoría'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _category(
    BuildContext context, {
    BudgetCategory? existing,
  }) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final description = TextEditingController(
      text: existing?.description ?? '',
    );
    var kind = existing?.kind ?? EntryKind.expense;
    String? error;
    await _ownedDialog<void>(
      context: context,
      controllers: [name, description],
      builder: (context) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: Text(
            existing == null ? 'Crear categoría' : 'Editar categoría',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<EntryKind>(
                  segments: const [
                    ButtonSegment(
                      value: EntryKind.income,
                      icon: Icon(Icons.south_west_rounded),
                      label: Text('Ingreso'),
                    ),
                    ButtonSegment(
                      value: EntryKind.expense,
                      icon: Icon(Icons.north_east_rounded),
                      label: Text('Egreso'),
                    ),
                  ],
                  selected: {kind},
                  onSelectionChanged: (v) => refresh(() => kind = v.first),
                ),
                const SizedBox(height: Space.md),
                TextField(
                  controller: name,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: Space.xs),
                TextField(
                  controller: description,
                  maxLength: 300,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                InlineMessage(text: error, tone: Tone.danger),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                try {
                  model.saveCategory(
                    BudgetCategory(
                      id: existing?.id ?? model.newId(),
                      name: name.text.trim(),
                      description: description.text.trim(),
                      kind: kind,
                    ),
                  );
                  Navigator.pop(context);
                } on StateError catch (e) {
                  refresh(() => error = e.message);
                } on ArgumentError {
                  refresh(() => error = 'Escribe un nombre para la categoría.');
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _csv(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return AlertDialog(
        title: Text('CSV · ${model.year}'),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const InlineMessage(
                  text:
                      'Vista previa local. La descarga al dispositivo estará disponible en la versión completa.',
                ),
                const SizedBox(height: Space.xs),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Space.sm),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SelectableText(
                      model.ledger.exportYearCsv(model.year),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontFamilyFallback: ['Menlo', 'Courier'],
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      );
    },
  );
}

class _YearSelector extends StatelessWidget {
  const _YearSelector({required this.model, required this.onPick});
  final BudgetViewModel model;
  final VoidCallback onPick;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Año anterior',
            onPressed: model.year > 1
                ? () => model.setYear(model.year - 1)
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Flexible(
            child: TextButton(
              key: const Key('year-picker'),
              onPressed: onPick,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${model.year}',
                  semanticsLabel: 'Año ${model.year}, cambiar año',
                  style: moneyStyle(Theme.of(context).textTheme.titleMedium),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Año siguiente',
            onPressed: model.year < 9999
                ? () => model.setYear(model.year + 1)
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.summary});
  final BudgetSummary summary;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    const onHero = Colors.white;
    final muted = onHero.withValues(alpha: 0.78);
    final ratio = summary.income == 0
        ? (summary.expense > 0 ? 1.0 : 0.0)
        : (summary.expense / summary.income).clamp(0.0, 1.0);
    final percent = summary.income == 0
        ? null
        : (summary.expense * 100 / summary.income).round();
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.lg + 4),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xff1e3a8a), Color(0xff172554)]
              : const [Color(0xff2563eb), Color(0xff1e40af)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: dark ? 0.15 : 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              Text(
                'BALANCE DEL AÑO',
                style: text.labelSmall?.copyWith(color: muted),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: onHero.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                child: Text(
                  summary.balance < 0
                      ? 'Falta dinero · déficit'
                      : summary.balance > 0
                      ? 'Sobra dinero · superávit'
                      : 'Ingresos y egresos en equilibrio',
                  style: text.labelMedium?.copyWith(color: onHero),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatCents(summary.balance),
              key: const Key('annual-balance'),
              maxLines: 1,
              style: moneyStyle(text.displaySmall).copyWith(color: onHero),
            ),
          ),
          const SizedBox(height: Space.lg),
          Row(
            children: [
              Expanded(
                child: _HeroFigure(
                  icon: Icons.south_west_rounded,
                  label: 'Ingresos',
                  value: formatCents(summary.income),
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: onHero.withValues(alpha: 0.2),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: _HeroFigure(
                  icon: Icons.north_east_rounded,
                  label: 'Egresos',
                  value: formatCents(summary.expense),
                ),
              ),
            ],
          ),
          if (summary.income > 0 || summary.expense > 0) ...[
            const SizedBox(height: Space.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.pill),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: ratio),
                duration: Motion.of(context, Motion.slow),
                curve: Motion.curve,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: onHero.withValues(alpha: 0.2),
                  color: summary.expense > summary.income
                      ? const Color(0xfffca5a5)
                      : onHero,
                  semanticsLabel: 'Proporción de egresos sobre ingresos',
                ),
              ),
            ),
            const SizedBox(height: Space.xs),
            Text(
              percent == null
                  ? 'Hay egresos sin ingresos registrados este año.'
                  : summary.expense > summary.income
                  ? 'Los egresos superan a los ingresos ($percent %).'
                  : 'Los egresos usan el $percent % de los ingresos.',
              style: text.bodySmall?.copyWith(color: muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroFigure extends StatelessWidget {
  const _HeroFigure({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: Space.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: text.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: moneyStyle(
                    text.titleSmall,
                  ).copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Twelve tappable income/expense bar pairs; doubles as the month selector.
class _MonthsChart extends StatelessWidget {
  const _MonthsChart({required this.model});
  final BudgetViewModel model;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final months = [
      for (var m = 1; m <= 12; m++) model.ledger.monthSummary(model.year, m),
    ];
    final peak = months.fold<int>(
      1,
      (a, s) => [a, s.income, s.expense].reduce((x, y) => x > y ? x : y),
    );
    const barArea = 76.0;
    final duration = Motion.of(context, Motion.slow);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.sm,
          Space.md,
          Space.sm,
          Space.sm,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.xxs),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: Space.sm,
                runSpacing: Space.xxs,
                children: [
                  Text(
                    'Toca un mes para ver sus movimientos',
                    style: text.bodySmall,
                  ),
                  Wrap(
                    spacing: Space.sm,
                    children: [
                      _Legend(color: palette.success, label: 'Ingresos'),
                      _Legend(color: scheme.primary, label: 'Egresos'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.sm),
            Row(
              children: [
                for (var i = 0; i < 12; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: model.month == i + 1,
                      label:
                          '${monthNames[i]}: ingresos ${formatCents(months[i].income)}, '
                          'egresos ${formatCents(months[i].expense)}, '
                          'saldo ${formatCents(months[i].balance)}',
                      child: ExcludeSemantics(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(Radii.sm),
                          onTap: () => model.setMonth(i + 1),
                          child: AnimatedContainer(
                            duration: Motion.of(context, Motion.medium),
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: model.month == i + 1
                                  ? scheme.primaryContainer
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(Radii.sm),
                            ),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: barArea,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _Bar(
                                        height:
                                            barArea * months[i].income / peak,
                                        color: palette.success,
                                        duration: duration,
                                      ),
                                      const SizedBox(width: 2),
                                      _Bar(
                                        height:
                                            barArea * months[i].expense / peak,
                                        color: scheme.primary,
                                        duration: duration,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    monthNames[i].substring(0, 3),
                                    style: text.labelMedium?.copyWith(
                                      color: model.month == i + 1
                                          ? scheme.onPrimaryContainer
                                          : scheme.onSurfaceVariant,
                                      fontWeight: model.month == i + 1
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

class _Bar extends StatelessWidget {
  const _Bar({
    required this.height,
    required this.color,
    required this.duration,
  });
  final double height;
  final Color color;
  final Duration duration;
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: duration,
    curve: Motion.curve,
    width: 5,
    height: height <= 0 ? 2 : height.clamp(3, double.infinity),
    decoration: BoxDecoration(
      color: height <= 0 ? Theme.of(context).colorScheme.outlineVariant : color,
      borderRadius: BorderRadius.circular(3),
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: Space.xxs),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.category,
    required this.onTap,
    required this.onDelete,
  });
  final BudgetEntry entry;
  final BudgetCategory category;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final income = category.kind == EntryKind.income;
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final amount = Text(
      '${income ? '+' : '−'} ${formatCents(entry.amountCents)}',
      style: moneyStyle(text.titleSmall).copyWith(
        color: income ? palette.success : null,
        fontWeight: FontWeight.w700,
      ),
    );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.md,
          Space.sm,
          Space.xxs,
          Space.sm,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = MediaQuery.textScalerOf(context).scale(1);
            final stacked = constraints.maxWidth / scale < 300;
            return Row(
              children: [
                IconTile(
                  icon: income
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  tone: income ? Tone.success : Tone.danger,
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        maxLines: stacked ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall,
                      ),
                      if (entry.description.isNotEmpty)
                        Text(
                          entry.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall,
                        ),
                      if (stacked) amount,
                    ],
                  ),
                ),
                if (!stacked) ...[const SizedBox(width: Space.xs), amount],
                IconButton(
                  tooltip: 'Eliminar movimiento',
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  onPressed: onDelete,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Share of the year's expenses per category, from the ledger itself.
class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.model});
  final BudgetViewModel model;
  @override
  Widget build(BuildContext context) {
    final totals = <String, int>{};
    final names = {for (final c in model.ledger.categories) c.id: c};
    for (final e in model.ledger.entries.where((e) => e.year == model.year)) {
      if (names[e.categoryId]?.kind == EntryKind.expense) {
        totals[e.categoryId] = (totals[e.categoryId] ?? 0) + e.amountCents;
      }
    }
    final total = totals.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();
    final rows = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: 'Egresos por categoría · ${model.year}'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.pill),
                  child: SizedBox(
                    height: 10,
                    child: Row(
                      children: [
                        for (final (i, row) in rows.indexed)
                          Expanded(
                            flex: (row.value * 1000 / total).ceil(),
                            child: Container(
                              margin: EdgeInsets.only(
                                right: i == rows.length - 1 ? 0 : 2,
                              ),
                              color: _chartColors[i % _chartColors.length],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Space.sm),
                for (final (i, row) in rows.indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _chartColors[i % _chartColors.length],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: Space.sm),
                        Expanded(
                          child: Text(
                            names[row.key]!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium,
                          ),
                        ),
                        Text(
                          '${(row.value * 100 / total).round()} %',
                          style: text.bodySmall,
                        ),
                        const SizedBox(width: Space.sm),
                        Text(
                          formatCents(row.value),
                          style: moneyStyle(
                            text.bodyMedium,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Future<T?> _ownedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  required List<TextEditingController> controllers,
}) {
  final route = DialogRoute<T>(context: context, builder: builder);
  route.completed.whenComplete(() {
    for (final controller in controllers) {
      controller.dispose();
    }
  });
  return Navigator.of(context, rootNavigator: true).push(route);
}

Future<T?> _ownedSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  required List<TextEditingController> controllers,
}) {
  final route = ModalBottomSheetRoute<T>(
    builder: builder,
    isScrollControlled: true,
    useSafeArea: true,
  );
  route.completed.whenComplete(() {
    for (final controller in controllers) {
      controller.dispose();
    }
  });
  return Navigator.of(context, rootNavigator: true).push(route);
}

void _message(BuildContext context, String message) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    icon: const IconTile(
      icon: Icons.info_outline_rounded,
      tone: Tone.warning,
      size: 48,
    ),
    title: const Text('Revisa la categoría'),
    content: Text(message),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Entendido'),
      ),
    ],
  ),
);

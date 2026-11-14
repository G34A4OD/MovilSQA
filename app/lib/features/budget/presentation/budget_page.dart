import 'package:flutter/material.dart';
import '../../../core/money.dart';
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

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key, required this.model});
  final BudgetViewModel model;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) => ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Un plan para cada mes',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        const Text('Mi hoja · Casa Rivera · BOB'),
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton(
              tooltip: 'Año anterior',
              onPressed: model.year > 1
                  ? () => model.setYear(model.year - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            TextButton(
              key: const Key('year-picker'),
              onPressed: () => _year(context),
              child: Text(
                '${model.year}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: 'Año siguiente',
              onPressed: model.year < 9999
                  ? () => model.setYear(model.year + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Gestionar categorías',
              onPressed: () => _categories(context),
              icon: const Icon(Icons.category_outlined),
            ),
            IconButton(
              tooltip: 'Vista previa CSV',
              onPressed: () => _csv(context),
              icon: const Icon(Icons.table_view_outlined),
            ),
          ],
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BALANCE DEL AÑO'),
                const SizedBox(height: 8),
                Text(
                  formatCents(model.summary.balance),
                  key: const Key('annual-balance'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  model.summary.balance < 0
                      ? 'Falta dinero · déficit'
                      : model.summary.balance > 0
                      ? 'Sobra dinero · superávit'
                      : 'Ingresos y egresos en equilibrio',
                ),
                const Divider(height: 28),
                Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    Text('Ingresos  ${formatCents(model.summary.income)}'),
                    Text('Egresos  ${formatCents(model.summary.expense)}'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Los doce meses · desliza para explorar'),
        const SizedBox(height: 8),
        SizedBox(
          height: 182,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 12,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final value = model.ledger.monthSummary(model.year, index + 1);
              return SizedBox(
                width: 192,
                child: Card(
                  color: model.month == index + 1
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => model.setMonth(index + 1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            monthNames[index],
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Text('+ ${formatCents(value.income)}'),
                          Text('− ${formatCents(value.expense)}'),
                          const Divider(),
                          Text(
                            formatCents(value.balance),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              monthNames[model.month - 1],
              style: Theme.of(context).textTheme.titleLarge,
            ),
            FilledButton.icon(
              key: const Key('new-entry'),
              onPressed: () => _entry(context),
              icon: const Icon(Icons.add),
              label: const Text('Movimiento'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (model.currentEntries.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Este mes empieza en blanco. Agrega tu primer movimiento.',
              ),
            ),
          ),
        for (final kind in EntryKind.values) ...[
          Text(
            kind == EntryKind.income ? 'Ingresos' : 'Egresos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final entry in model.currentEntries.where(
            (e) =>
                model.ledger.categories
                    .firstWhere((c) => c.id == e.categoryId)
                    .kind ==
                kind,
          ))
            Card(
              child: ListTile(
                leading: Icon(
                  kind == EntryKind.income
                      ? Icons.south_west
                      : Icons.north_east,
                ),
                title: Text(
                  model.ledger.categories
                      .firstWhere((c) => c.id == entry.categoryId)
                      .name,
                ),
                subtitle: Text(
                  '${formatCents(entry.amountCents)} · ${entry.description}',
                ),
                onTap: () => _entry(context, existing: entry),
                trailing: IconButton(
                  tooltip: 'Eliminar movimiento',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    if (await _confirm(
                      context,
                      '¿Eliminar este movimiento de la demostración?',
                    )) {
                      model.deleteEntry(entry.id);
                    }
                  },
                ),
              ),
            ),
          const SizedBox(height: 12),
        ],
      ],
    ),
  );

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
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Año entre 1 y 9999',
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
    final form = GlobalKey<FormState>();
    await _ownedDialog<void>(
      context: context,
      controllers: [amount, description],
      builder: (context) => AlertDialog(
        title: Text(
          existing == null ? 'Nuevo movimiento' : 'Editar movimiento',
        ),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${monthNames[model.month - 1]} de ${model.year}'),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: categoryId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: model.ledger.categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            '${c.kind == EntryKind.income ? '+' : '−'} ${c.name}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => categoryId = v!,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('entry-amount'),
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Monto en Bs',
                    hintText: '0,00',
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: description,
                  maxLength: 500,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('save-entry'),
            onPressed: () {
              if (!form.currentState!.validate()) return;
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
        ],
      ),
    );
  }

  Future<void> _categories(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => ListenableBuilder(
        listenable: model,
        builder: (context, _) => AlertDialog(
          title: const Text('Tus categorías'),
          content: SizedBox(
            width: 380,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final category in model.ledger.categories)
                  ListTile(
                    title: Text(category.name),
                    subtitle: Text(
                      category.kind == EntryKind.income ? 'Ingreso' : 'Egreso',
                    ),
                    onTap: () => _category(context, existing: category),
                    trailing: IconButton(
                      tooltip: 'Eliminar categoría',
                      icon: const Icon(Icons.delete_outline),
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
            FilledButton(
              onPressed: () => _category(context),
              child: const Text('Crear categoría'),
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
              children: [
                TextField(
                  controller: name,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  maxLength: 300,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<EntryKind>(
                  initialValue: kind,
                  items: const [
                    DropdownMenuItem(
                      value: EntryKind.income,
                      child: Text('Ingreso'),
                    ),
                    DropdownMenuItem(
                      value: EntryKind.expense,
                      child: Text('Egreso'),
                    ),
                  ],
                  onChanged: (v) => kind = v!,
                ),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
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
    builder: (context) => AlertDialog(
      title: Text('CSV · ${model.year}'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vista previa local. La descarga al dispositivo estará disponible en la versión completa.',
              ),
              const SizedBox(height: 12),
              SelectableText(
                model.ledger.exportYearCsv(model.year),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
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
    ),
  );
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

Future<bool> _confirm(BuildContext context, String text) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ) ??
    false;
void _message(BuildContext context, String message) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
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

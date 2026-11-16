import 'package:flutter/material.dart';
import '../domain/invitation_repository.dart';
import 'invitation_view_model.dart';

class InvitationsPanel extends StatefulWidget {
  const InvitationsPanel({
    super.key,
    required this.repository,
    this.familyId,
    required this.onChanged,
  });
  final InvitationRepository repository;
  final String? familyId;
  final VoidCallback onChanged;
  @override
  State<InvitationsPanel> createState() => _InvitationsPanelState();
}

class _InvitationsPanelState extends State<InvitationsPanel> {
  late final model = InvitationViewModel(
    widget.repository,
    familyId: widget.familyId,
  );
  final publicId = TextEditingController();
  @override
  void initState() {
    super.initState();
    model.load();
  }

  @override
  void dispose() {
    model.dispose();
    publicId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.familyId == null
                        ? 'Mis invitaciones'
                        : 'Invitar familiar',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar invitaciones',
                  onPressed: model.busy ? null : model.load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (model.busy) const LinearProgressIndicator(),
            if (widget.familyId != null) ...[
              const Text(
                'Solo puedes buscar con el ID completo que te comparte tu familiar.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: publicId,
                maxLength: 32,
                decoration: const InputDecoration(
                  labelText: 'ID único del usuario',
                ),
                onChanged: (_) => model.clearCandidate(),
                enabled: !model.busy,
              ),
              OutlinedButton(
                onPressed: model.busy
                    ? null
                    : () => model.lookup(publicId.text),
                child: const Text('Buscar familiar'),
              ),
              if (model.candidate != null) ...[
                Text(model.candidate!.fullName),
                FilledButton(
                  onPressed: model.busy ? null : model.invite,
                  child: const Text('Enviar invitación'),
                ),
              ],
            ],
            if (model.message != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(model.message!),
              ),
            if (model.items.isEmpty && !model.busy)
              const Text('No hay invitaciones pendientes.'),
            for (final item in model.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.familyId == null
                          ? item.familyName
                          : item.targetName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      item.actionable
                          ? 'Pendiente · vence ${item.expiresAt.toLocal().toIso8601String().split('T').first}'
                          : 'Invitación caducada',
                    ),
                    if (widget.familyId == null)
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton(
                            onPressed: model.busy || !item.actionable
                                ? null
                                : () async {
                                    if (await model.respond(item, 'accept')) {
                                      widget.onChanged();
                                    }
                                  },
                            child: const Text('Aceptar'),
                          ),
                          TextButton(
                            onPressed: model.busy || !item.actionable
                                ? null
                                : () async {
                                    if (await model.respond(item, 'reject')) {
                                      widget.onChanged();
                                    }
                                  },
                            child: const Text('Rechazar'),
                          ),
                        ],
                      )
                    else
                      TextButton(
                        onPressed: model.busy ? null : () => model.revoke(item),
                        child: const Text('Revocar invitación'),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

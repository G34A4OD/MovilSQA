import 'package:flutter/material.dart';
import '../../../core/widgets/widgets.dart';
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

  static Tone _tone(String message) {
    if (message.startsWith('Invitación enviada')) return Tone.success;
    if (message.startsWith('Copia el ID') ||
        message.startsWith('No hay una coincidencia')) {
      return Tone.warning;
    }
    return Tone.danger;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final text = Theme.of(context).textTheme;
      final scheme = Theme.of(context).colorScheme;
      final inviting = widget.familyId != null;
      return SectionCard(
        icon: inviting ? Icons.person_add_alt_outlined : Icons.mail_outline,
        title: inviting ? 'Invitar familiar' : 'Mis invitaciones',
        subtitle: inviting
            ? 'Solo puedes buscar con el ID completo que te comparte tu familiar.'
            : 'Grupos que te invitaron a unirte.',
        refreshTooltip: 'Actualizar invitaciones',
        onRefresh: model.load,
        busy: model.busy,
        message: model.message,
        messageTone: model.message == null ? Tone.info : _tone(model.message!),
        children: [
          if (inviting) ...[
            const SizedBox(height: Space.xs),
            TextField(
              controller: publicId,
              maxLength: 32,
              autocorrect: false,
              enableSuggestions: false,
              style: moneyStyle(text.bodyLarge),
              decoration: const InputDecoration(
                labelText: 'ID único del usuario',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              onChanged: (_) => model.clearCandidate(),
              onSubmitted: (_) {
                if (!model.busy) model.lookup(publicId.text);
              },
              enabled: !model.busy,
            ),
            OutlinedButton.icon(
              onPressed: model.busy ? null : () => model.lookup(publicId.text),
              icon: const Icon(Icons.search_rounded),
              label: const Text('Buscar familiar'),
            ),
            AnimatedSize(
              duration: Motion.of(context, Motion.medium),
              curve: Motion.curve,
              child: model.candidate == null
                  ? const SizedBox(width: double.infinity)
                  : Container(
                      margin: const EdgeInsets.only(top: Space.sm),
                      padding: const EdgeInsets.all(Space.sm),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              AppAvatar(name: model.candidate!.fullName),
                              const SizedBox(width: Space.sm),
                              Expanded(
                                child: Text(
                                  model.candidate!.fullName,
                                  style: text.titleSmall,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Space.sm),
                          FilledButton.icon(
                            onPressed: model.busy ? null : model.invite,
                            icon: const Icon(Icons.send_rounded, size: 18),
                            label: const Text('Enviar invitación'),
                          ),
                        ],
                      ),
                    ),
            ),
            const Divider(height: Space.xxl),
            Text('Pendientes', style: text.labelLarge),
          ],
          if (model.items.isEmpty && !model.busy)
            const EmptyState(
              compact: true,
              icon: Icons.mark_email_read_outlined,
              title: 'No hay invitaciones pendientes.',
            ),
          for (final item in model.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppAvatar(
                        name: inviting ? item.targetName : item.familyName,
                        icon: inviting ? null : Icons.cottage_outlined,
                      ),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inviting ? item.targetName : item.familyName,
                              style: text.titleSmall,
                            ),
                            const SizedBox(height: Space.xxs),
                            StatusBadge(
                              label: item.actionable
                                  ? 'Pendiente · vence ${item.expiresAt.toLocal().toIso8601String().split('T').first}'
                                  : 'Invitación caducada',
                              tone: item.actionable
                                  ? Tone.warning
                                  : Tone.neutral,
                              icon: item.actionable
                                  ? Icons.schedule_rounded
                                  : Icons.event_busy_outlined,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.xs),
                  if (!inviting)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: model.busy || !item.actionable
                                ? null
                                : () async {
                                    if (await model.respond(item, 'reject') &&
                                        mounted) {
                                      widget.onChanged();
                                    }
                                  },
                            child: const Text('Rechazar'),
                          ),
                        ),
                        const SizedBox(width: Space.sm),
                        Expanded(
                          child: FilledButton(
                            onPressed: model.busy || !item.actionable
                                ? null
                                : () async {
                                    if (await model.respond(item, 'accept') &&
                                        mounted) {
                                      widget.onChanged();
                                    }
                                  },
                            child: const Text('Aceptar'),
                          ),
                        ),
                      ],
                    )
                  else
                    TextButton.icon(
                      style: destructiveTextStyle(context),
                      onPressed: model.busy ? null : () => model.revoke(item),
                      icon: const Icon(Icons.block_rounded, size: 18),
                      label: const Text('Revocar invitación'),
                    ),
                ],
              ),
            ),
        ],
      );
    },
  );
}

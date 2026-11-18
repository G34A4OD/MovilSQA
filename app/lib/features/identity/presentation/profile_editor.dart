import 'package:flutter/material.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/profile.dart';
import 'profile_view_model.dart';

class ProfileEditor extends StatefulWidget {
  const ProfileEditor({super.key, required this.model, required this.onSaved});
  final ProfileViewModel model;
  final VoidCallback onSaved;
  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  late final name = TextEditingController(
    text: widget.model.profile?.details.fullName,
  );
  late final ci = TextEditingController(
    text: widget.model.profile?.details.identityCard,
  );
  late final birth = TextEditingController(
    text: widget.model.profile?.details.birthDate,
  );
  late final address = TextEditingController(
    text: widget.model.profile?.details.address,
  );
  late String? blood = widget.model.profile?.details.bloodType;
  @override
  void dispose() {
    name.dispose();
    ci.dispose();
    birth.dispose();
    address.dispose();
    super.dispose();
  }

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    final current = DateTime.tryParse(birth.text.trim());
    final picked = await showDatePicker(
      context: context,
      initialDate: current != null && current.isBefore(now) ? current : now,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Fecha de nacimiento',
    );
    if (picked != null && mounted) {
      birth.text =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.model,
    builder: (context, _) {
      final busy = widget.model.busy;
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              Space.lg,
              Space.xs,
              Space.lg,
              Space.xxl,
            ),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  eyebrow: 'Perfil',
                  title: widget.model.profile == null
                      ? 'Conozcámonos'
                      : 'Mi perfil privado',
                  subtitle:
                      'Estos datos son privados. Tú eliges qué compartir con cada grupo.',
                ),
                const SizedBox(height: Space.lg),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.md,
                      Space.lg,
                      Space.md,
                      Space.xs,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: name,
                          maxLength: 120,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          decoration: const InputDecoration(
                            labelText: 'Nombre completo',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          enabled: !busy,
                        ),
                        const SizedBox(height: Space.xxs),
                        TextField(
                          controller: ci,
                          maxLength: 30,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Carnet de identidad',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          enabled: !busy,
                        ),
                        const SizedBox(height: Space.xxs),
                        TextField(
                          controller: birth,
                          keyboardType: TextInputType.datetime,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Nacimiento (AAAA-MM-DD)',
                            hintText: '2000-01-31',
                            prefixIcon: const Icon(Icons.cake_outlined),
                            suffixIcon: IconButton(
                              tooltip: 'Elegir fecha',
                              onPressed: busy ? null : _pickBirth,
                              icon: const Icon(Icons.calendar_month_outlined),
                            ),
                          ),
                          enabled: !busy,
                        ),
                        const SizedBox(height: Space.md),
                        DropdownButtonFormField<String>(
                          initialValue: blood,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de sangre',
                            prefixIcon: Icon(Icons.bloodtype_outlined),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('No sé'),
                            ),
                            ...ProfileInput.bloodTypes.map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            ),
                          ],
                          onChanged: busy
                              ? null
                              : (v) => setState(() => blood = v),
                        ),
                        const SizedBox(height: Space.md),
                        TextField(
                          controller: address,
                          maxLength: 250,
                          textCapitalization: TextCapitalization.sentences,
                          autofillHints: const [
                            AutofillHints.fullStreetAddress,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Domicilio',
                            prefixIcon: Icon(Icons.home_outlined),
                          ),
                          enabled: !busy,
                        ),
                      ],
                    ),
                  ),
                ),
                InlineMessage(text: widget.model.message, tone: Tone.danger),
                const SizedBox(height: Space.md),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () async {
                          final ok = await widget.model.save(
                            ProfileInput(
                              fullName: name.text,
                              bloodType: blood,
                              identityCard: ci.text,
                              birthDate: birth.text,
                              address: address.text,
                            ),
                          );
                          if (ok && mounted) widget.onSaved();
                        },
                  child: Text(busy ? 'Guardando…' : 'Guardar perfil'),
                ),
                const SizedBox(height: Space.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: Space.xxs),
                    Text(
                      'Solo tú puedes editar este perfil.',
                      style: Theme.of(context).textTheme.bodySmall,
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

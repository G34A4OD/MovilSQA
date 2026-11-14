import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.model,
    builder: (context, _) => SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.model.profile == null ? 'Conozcámonos' : 'Mi perfil privado',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Text(
            'Estos datos son privados. Tú eliges qué compartir con cada grupo.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: name,
            maxLength: 120,
            decoration: const InputDecoration(labelText: 'Nombre completo'),
            enabled: !widget.model.busy,
          ),
          TextField(
            controller: ci,
            maxLength: 30,
            decoration: const InputDecoration(labelText: 'Carnet de identidad'),
            enabled: !widget.model.busy,
          ),
          TextField(
            controller: birth,
            keyboardType: TextInputType.datetime,
            decoration: const InputDecoration(
              labelText: 'Nacimiento (AAAA-MM-DD)',
              hintText: '2000-01-31',
            ),
            enabled: !widget.model.busy,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: blood,
            decoration: const InputDecoration(labelText: 'Tipo de sangre'),
            items: [
              const DropdownMenuItem(value: null, child: Text('No sé')),
              ...ProfileInput.bloodTypes.map(
                (v) => DropdownMenuItem(value: v, child: Text(v)),
              ),
            ],
            onChanged: widget.model.busy
                ? null
                : (v) => setState(() => blood = v),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: address,
            maxLength: 250,
            decoration: const InputDecoration(labelText: 'Domicilio'),
            enabled: !widget.model.busy,
          ),
          if (widget.model.message != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(widget.model.message!),
            ),
          FilledButton(
            onPressed: widget.model.busy
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
            child: Text(widget.model.busy ? 'Guardando…' : 'Guardar perfil'),
          ),
        ],
      ),
    ),
  );
}

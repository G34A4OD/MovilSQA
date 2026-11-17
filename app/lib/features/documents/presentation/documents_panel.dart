import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../domain/document_repository.dart';
import 'document_view_model.dart';

/// Fuente de bytes inyectable. La selección real en dispositivo requiere
/// acordar `file_picker` (u otro) con Gerardo antes de añadirlo a pubspec.
typedef DocumentBytesPicker =
    Future<({String filename, Uint8List bytes})?> Function();

class DocumentsPanel extends StatefulWidget {
  const DocumentsPanel({
    super.key,
    required this.repository,
    required this.folderId,
    required this.folderName,
    required this.canUpload,
    this.pickBytes,
  });
  final DocumentRepository repository;
  final String folderId;
  final String folderName;
  final bool canUpload;
  final DocumentBytesPicker? pickBytes;

  @override
  State<DocumentsPanel> createState() => _DocumentsPanelState();
}

class _DocumentsPanelState extends State<DocumentsPanel> {
  late final model = DocumentViewModel(widget.repository, widget.folderId);

  @override
  void initState() {
    super.initState();
    model.load();
  }

  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  Future<void> uploadDocument() async {
    final input = await showDialog<DocumentUploadInput>(
      context: context,
      builder: (_) => _UploadDialog(pickBytes: widget.pickBytes),
    );
    if (input != null && mounted) {
      await model.upload(input);
    }
  }

  String _statusLabel(DocumentStatus status) => switch (status) {
    DocumentStatus.quarantine => 'En cuarentena (pendiente de escaneo)',
    DocumentStatus.approved => 'Aprobado',
    DocumentStatus.rejected => 'Rechazado',
  };

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
                const Icon(Icons.description_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Documentos · ${widget.folderName}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar documentos',
                  onPressed: model.busy ? null : model.load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (model.busy) const LinearProgressIndicator(),
            if (model.message != null) Text(model.message!),
            if (widget.canUpload)
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  key: const Key('document-upload'),
                  onPressed: model.busy ? null : uploadDocument,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Cargar documento'),
                ),
              ),
            if (model.items.isEmpty && !model.busy)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Los archivos quedan en cuarentena hasta un escaneo confiable.',
                ),
              ),
            for (final doc in model.items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: Text(doc.title),
                subtitle: Text(
                  '${_statusLabel(doc.status)} · ${doc.mimeType} · ${doc.sizeBytes} B',
                ),
                trailing: doc.status == DocumentStatus.quarantine
                    ? TextButton(
                        key: Key('document-process-${doc.id}'),
                        onPressed: model.busy ? null : () => model.process(doc),
                        child: const Text('Procesar'),
                      )
                    : null,
              ),
          ],
        ),
      ),
    ),
  );
}

class _UploadDialog extends StatefulWidget {
  const _UploadDialog({this.pickBytes});
  final DocumentBytesPicker? pickBytes;

  @override
  State<_UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends State<_UploadDialog> {
  final title = TextEditingController();
  final description = TextEditingController();
  DateTime? expiresOn;
  String? filename;
  Uint8List? bytes;
  String? error;

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> pickFile() async {
    final picker = widget.pickBytes;
    if (picker == null) {
      setState(() {
        error =
            'La selección de archivo en dispositivo está pendiente de acordar la dependencia compartida (file_picker) con Gerardo.';
      });
      return;
    }
    final picked = await picker();
    if (!mounted) {
      return;
    }
    if (picked == null) {
      return;
    }
    setState(() {
      filename = picked.filename;
      bytes = picked.bytes;
      error = null;
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Cargar documento'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('document-title'),
            controller: title,
            decoration: const InputDecoration(labelText: 'Título'),
          ),
          TextField(
            key: const Key('document-description'),
            controller: description,
            decoration: const InputDecoration(labelText: 'Descripción'),
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  expiresOn == null
                      ? 'Vencimiento opcional'
                      : 'Vence: ${expiresOn!.toIso8601String().split('T').first}',
                ),
              ),
              TextButton(
                key: const Key('document-expires'),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null && mounted) {
                    setState(() => expiresOn = picked);
                  }
                },
                child: const Text('Elegir fecha'),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('document-pick'),
              onPressed: pickFile,
              icon: const Icon(Icons.attach_file),
              label: Text(filename ?? 'Adjuntar JPG/PNG/PDF'),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
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
        key: const Key('document-save'),
        onPressed: () {
          final fileName = filename;
          final fileBytes = bytes;
          if (fileName == null || fileBytes == null) {
            setState(() => error = 'Adjunta un archivo JPG, PNG o PDF.');
            return;
          }
          Navigator.pop(
            context,
            DocumentUploadInput(
              title: title.text,
              description: description.text,
              filename: fileName,
              bytes: fileBytes,
              expiresOn: expiresOn,
            ),
          );
        },
        child: const Text('Cargar'),
      ),
    ],
  );
}

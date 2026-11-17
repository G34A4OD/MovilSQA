import 'package:flutter/material.dart';
import '../design/tokens.dart';
import 'surfaces.dart';

/// Confirmation with a visually distinct destructive action.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = true,
  Key? confirmKey,
  IconData? icon,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          icon: IconTile(
            icon:
                icon ??
                (destructive
                    ? Icons.delete_outline_rounded
                    : Icons.help_outline_rounded),
            tone: destructive ? Tone.danger : Tone.info,
            size: 48,
          ),
          title: Text(title, textAlign: TextAlign.center),
          content: Text(message, textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: confirmKey,
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                    )
                  : null,
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    ) ??
    false;

/// Error-colored style for secondary destructive buttons.
ButtonStyle destructiveTextStyle(BuildContext context) =>
    TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error);

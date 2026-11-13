import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../admin/domain/admin_models.dart';
import '../data/next_match_notifications.dart';

class NextMatchReminderButton extends StatefulWidget {
  const NextMatchReminderButton({
    super.key,
    required this.match,
    required this.homeTeam,
    required this.awayTeam,
  });

  final AdminMatch match;
  final String homeTeam;
  final String awayTeam;

  @override
  State<NextMatchReminderButton> createState() =>
      _NextMatchReminderButtonState();
}

class _NextMatchReminderButtonState extends State<NextMatchReminderButton> {
  bool _scheduled = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didUpdateWidget(covariant NextMatchReminderButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.match.id != widget.match.id) _refresh();
  }

  Future<void> _refresh() async {
    final scheduled = await NextMatchNotifications.hasReminder(widget.match.id);
    if (mounted) setState(() => _scheduled = scheduled);
  }

  Future<void> _toggle() async {
    if (_busy || kIsWeb) return;
    setState(() => _busy = true);
    try {
      if (_scheduled) {
        await NextMatchNotifications.cancel(widget.match.id);
        if (mounted) {
          setState(() => _scheduled = false);
          _message('Recordatorio cancelado.');
        }
      } else {
        final scheduled = await NextMatchNotifications.scheduleForMatch(
          match: widget.match,
          homeTeam: widget.homeTeam,
          awayTeam: widget.awayTeam,
        );
        if (mounted) {
          setState(() => _scheduled = scheduled);
          _message(
            scheduled ? 'Te avisaremos antes del partido.' : 'No se pudo activar. Permite notificaciones y verifica que falten más de 5 minutos.',
          );
        }
      }
    } catch (_) {
      if (mounted)
        _message('No se pudo actualizar el recordatorio. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || widget.match.status != AdminMatchStatus.scheduled) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: _busy ? null : _toggle,
        icon: _busy
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                _scheduled
                    ? Icons.notifications_active
                    : Icons.notifications_outlined,
              ),
        label: Text(
          _scheduled ? 'Desactivar recordatorio' : 'Avisarme antes del partido',
        ),
      ),
    );
  }
}

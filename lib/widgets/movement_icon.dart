import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

String _movementKey(String movement) {
  return movement
      .trim()
      .toUpperCase()
      .replaceAll('-', '_')
      .replaceAll(' ', '_');
}

bool isTextMovementPictogram(String movement) {
  final key = _movementKey(movement);
  return key == 'V' || key == 'V_BAR';
}

bool _isBoldArrowMovement(String movement) {
  final icon = getMovementIcon(movement);
  return icon == Icons.arrow_upward_rounded ||
      icon == Icons.arrow_downward_rounded ||
      icon == Icons.arrow_back_rounded ||
      icon == Icons.arrow_forward_rounded ||
      icon == FontAwesomeIcons.arrowRotateLeft ||
      icon == FontAwesomeIcons.arrowRotateRight;
}

Widget buildMovementPictogram(
  String movement, {
  required Color color,
  required double size,
}) {
  final key = _movementKey(movement);

  if (key == 'V' || key == 'V_BAR') {
    return Text(
      key == 'V' ? 'V' : 'Λ',
      style: TextStyle(
        color: color,
        fontSize: size * 1.65,
        fontWeight: FontWeight.w900,
        height: 0.8,
      ),
    );
  }

  if (_isBoldArrowMovement(movement)) {
    final icon = getMovementIcon(movement);
    const d = 0.9;
    return SizedBox(
      width: size * 1.25,
      height: size * 1.25,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, -d),
            child: Icon(icon, color: color, size: size),
          ),
          Transform.translate(
            offset: const Offset(0, d),
            child: Icon(icon, color: color, size: size),
          ),
          Transform.translate(
            offset: const Offset(-d, 0),
            child: Icon(icon, color: color, size: size),
          ),
          Transform.translate(
            offset: const Offset(d, 0),
            child: Icon(icon, color: color, size: size),
          ),
          Icon(icon, color: color, size: size),
        ],
      ),
    );
  }

  return Icon(getMovementIcon(movement), color: color, size: size);
}

IconData getMovementIcon(String movement) {
  final normalized = movement.toLowerCase();
  final compact = normalized.replaceAll(RegExp(r'[^a-z]'), '');
  final key = _movementKey(movement);

  if (key == 'V') return Icons.expand_more_rounded;
  if (key == 'V_BAR') return Icons.expand_less_rounded;

  if (compact.contains('cercleleft') ||
      compact.contains('circleleft') ||
      compact.contains('circlegauche')) {
    return FontAwesomeIcons.arrowRotateRight;
  }
  if (compact.contains('cercleright') ||
      compact.contains('circleright') ||
      compact.contains('circledroite') ||
      compact.contains('circledroit')) {
    return FontAwesomeIcons.arrowRotateLeft;
  }
  if (normalized.contains('cercle') &&
      (normalized.contains('gauche') ||
          normalized.contains('droit') ||
          normalized.contains('droite'))) {
    return normalized.contains('gauche')
        ? FontAwesomeIcons.arrowRotateLeft
        : FontAwesomeIcons.arrowRotateRight;
  }
  if (compact.contains('point')) return Icons.circle;
  if (compact == 'up' || compact.contains('haut'))
    return Icons.arrow_upward_rounded;
  if (compact == 'down' || compact.contains('bas'))
    return Icons.arrow_downward_rounded;
  if (compact == 'left' || compact.contains('gauche'))
    return Icons.arrow_back_rounded;
  if (compact == 'right' ||
      compact.contains('droite') ||
      compact.contains('droit'))
    return Icons.arrow_forward_rounded;
  if (compact.contains('tap') || compact.contains('touche'))
    return Icons.touch_app_rounded;
  if (compact.contains('double')) return Icons.repeat_rounded;
  if (compact.contains('long')) return Icons.pan_tool_rounded;
  return Icons.gesture_rounded;
}

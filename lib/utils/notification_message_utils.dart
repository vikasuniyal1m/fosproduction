/// Parse/strip metadata embedded in notification messages from the API.
class NotificationMessageUtils {
  NotificationMessageUtils._();

  static final RegExp _metaBlock =
      RegExp(r'\s*\{\{([^}]+)\}\}\s*$');

  static Map<String, String> parseMeta(String? raw) {
    final text = raw ?? '';
    final match = _metaBlock.firstMatch(text);
    if (match == null) return {};

    final out = <String, String>{};
    for (final part in match.group(1)!.split(',')) {
      final idx = part.indexOf(':');
      if (idx <= 0) continue;
      final key = part.substring(0, idx).trim();
      final value = part.substring(idx + 1).trim();
      if (key.isNotEmpty && value.isNotEmpty) {
        out[key] = value;
      }
    }
    return out;
  }

  static String displayText(String? raw) {
    return (raw ?? '').replaceFirst(_metaBlock, '').trim();
  }

  static int? parseProductId(String? raw) {
    final id = parseMeta(raw)['product_id'];
    return id != null ? int.tryParse(id) : null;
  }

  static int? parseOrderId(String? raw) {
    final id = parseMeta(raw)['order_id'];
    return id != null ? int.tryParse(id) : null;
  }

  static String normalizeType(String? raw) {
    switch ((raw ?? 'general').toLowerCase()) {
      case 'orders':
      case 'order':
        return 'order';
      case 'offers':
      case 'offer':
      case 'promotional':
        return 'offer';
      case 'payments':
      case 'payment':
        return 'payment';
      case 'alert':
      case 'announcement':
      case 'update':
        return 'general';
      default:
        return 'general';
    }
  }
}

/// Extracts a group invite code from QR text or deep-link URLs.
String? parseInviteCodeFromScan(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.hasScheme) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final joinIndex = segments.indexOf('join');
    if (joinIndex >= 0 && joinIndex + 1 < segments.length) {
      return segments[joinIndex + 1];
    }
    if (segments.isNotEmpty) {
      return segments.last;
    }
  }

  return trimmed;
}

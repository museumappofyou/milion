import '../content/models.dart';

/// O17 is still open: no support address exists yet, so "Report a change"
/// stays hidden until [milionSupportEmail] is filled in (P05 Decisions).
const String milionSupportEmail = '';

/// Google Maps walking directions to the entrance (or the checked point).
Uri walkingDirectionsUri(Place place) {
  final point = place.entrance ?? place.coordinates;
  return Uri(
    scheme: 'https',
    host: 'www.google.com',
    path: '/maps/dir/',
    query:
        'api=1&travelmode=walking&destination=${point.lat},${point.lng}',
  );
}

/// The mailto target for corrections; null while O17 is open.
Uri? reportChangeUri(
  Place place, {
  required String subject,
  required String body,
}) {
  if (milionSupportEmail.isEmpty) return null;
  return Uri(
    scheme: 'mailto',
    path: milionSupportEmail,
    query:
        'subject=${Uri.encodeComponent(subject)}'
        '&body=${Uri.encodeComponent(body)}',
  );
}

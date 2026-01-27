import '../constants/api_constants.dart';

String resolveMediaUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  final cleaned = url.replaceAll('\\', '/');
  final base = ApiConstants.baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');
  final baseUri = Uri.parse(base);

  if (cleaned.startsWith('http')) {
    return Uri.encodeFull(cleaned);
  }
  if (cleaned.startsWith('//')) {
    return Uri.encodeFull('${baseUri.scheme}:$cleaned');
  }
  if (cleaned.startsWith('/storage/')) {
    return Uri.encodeFull('$base$cleaned');
  }
  if (cleaned.startsWith('storage/')) {
    return Uri.encodeFull('$base/$cleaned');
  }
  return Uri.encodeFull('$base/storage/$cleaned');
}

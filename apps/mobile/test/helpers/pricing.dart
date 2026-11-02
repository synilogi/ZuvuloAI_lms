/// The captured fixtures predate course pricing (`pricing: free | paid | unset`), and a course that
/// carries a price but no `pricing` reads as undecided — not open to anyone. A test that means a
/// free or a paid course says so: every course object in [json] (anything with a `price` or a
/// `slug`) gets [pricing].
T withPricing<T>(T json, String pricing) => _walk(json, pricing) as T;

Object? _walk(Object? node, String pricing) {
  if (node is List) return [for (final item in node) _walk(item, pricing)];
  if (node is Map) {
    final copy = <String, dynamic>{
      for (final entry in node.entries) entry.key as String: _walk(entry.value, pricing),
    };
    if (copy.containsKey('price') || (copy.containsKey('slug') && copy.containsKey('chapters'))) {
      copy['pricing'] = pricing;
    }
    return copy;
  }
  return node;
}

/// Keep paging stable and request at most 100 rows, matching the Data API cap.
Future<List<Map<String, dynamic>>> readAll(
  Future<List<Map<String, dynamic>>> Function(int from, int to) page,
) async {
  final rows = <Map<String, dynamic>>[];
  for (var from = 0; ; from += 100) {
    final batch = await page(from, from + 99);
    rows.addAll(batch);
    if (batch.length < 100) return rows;
  }
}

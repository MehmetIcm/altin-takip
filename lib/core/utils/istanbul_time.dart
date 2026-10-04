/// Türkiye 2016'dan beri sabit UTC+3 kullanır; ek paket gerekmez.
class IstanbulTime {
  static const Duration offset = Duration(hours: 3);

  /// Anı, İstanbul duvar saatini gösteren (UTC işaretli) DateTime'a çevirir.
  /// Yalnızca biçimlendirme içindir.
  static DateTime toWall(DateTime instant) => instant.toUtc().add(offset);

  /// "yyyy-MM-dd HH:mm:ss" biçimindeki İstanbul saatini gerçek ana çevirir.
  static DateTime parseWall(String s) {
    final d = DateTime.parse('${s.trim().replaceFirst(' ', 'T')}Z');
    return d.subtract(offset);
  }
}

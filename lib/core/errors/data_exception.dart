enum DataErrorKind { network, timeout, rateLimit, server, invalidResponse, empty }

/// Veri kaynaklarından gelen tüm hataların ortak tipi.
class DataSourceException implements Exception {
  const DataSourceException(this.kind, [this.detail = '']);

  final DataErrorKind kind;
  final String detail;

  String get userMessage {
    switch (kind) {
      case DataErrorKind.network:
        return 'İnternet bağlantısı yok veya sunucuya ulaşılamıyor.';
      case DataErrorKind.timeout:
        return 'Sunucu zamanında yanıt vermedi.';
      case DataErrorKind.rateLimit:
        return 'İstek limiti aşıldı.';
      case DataErrorKind.server:
        return 'Veri sunucusunda bir hata var.';
      case DataErrorKind.invalidResponse:
        return 'Sunucudan geçersiz yanıt alındı.';
      case DataErrorKind.empty:
        return 'Sunucu boş veri döndürdü.';
    }
  }

  @override
  String toString() => 'DataSourceException($kind, $detail)';
}

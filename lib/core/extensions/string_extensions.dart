/// String yardımcısı ve UI formatlama extension'ları
extension StringTitleCaseExtension on String {
  /// Metni Title Case (Her sözcüğün ilk harfi büyük) yapar.
  /// Örnek: 'hakan alture' -> 'Hakan Alture'
  /// Türkçe karakter kümesini destekler ('i' -> 'İ', 'ı' -> 'I').
  String toTitleCase() {
    if (trim().isEmpty) return this;
    
    final words = trim().split(RegExp(r'\s+'));
    final formattedWords = words.map((word) {
      if (word.isEmpty) return word;
      final firstLetter = _capitalizeFirstChar(word);
      final remaining = word.length > 1 ? _lowerRemainingChars(word.substring(1)) : '';
      return '$firstLetter$remaining';
    });
    
    return formattedWords.join(' ');
  }

  String _capitalizeFirstChar(String word) {
    if (word.isEmpty) return '';
    final char = word[0];
    if (char == 'i') return 'İ';
    if (char == 'ı') return 'I';
    return char.toUpperCase();
  }

  String _lowerRemainingChars(String str) {
    if (str.isEmpty) return '';
    return str.toLowerCase();
  }
}

String cleanInput(String input) {
  RegExp invalidCharacters = RegExp(r'[^0-9+\-*/\(\)\s]');
  return input.replaceAll(invalidCharacters, '');
}

class PrePro {
  String filter(String source) {
    String noComments = source.replaceAll(RegExp(r'--.*'), '');
    // String cleaned = cleanInput(noComments);
    return noComments;
  }
}

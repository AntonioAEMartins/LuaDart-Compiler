enum TokenType {
  integer,
  plus,
  minus,
  multiply,
  divide,
  eof,
  openParen,
  closeParen,
  identifier,
  print,
  equal,
}

List<String> reservedKeywords = ['print'];

class Token {
  final TokenType type;
  final dynamic value;

  Token(this.type, this.value);
}

class Tokenizer {
  final String source;
  int position = 0;
  late Token next;

  Tokenizer(this.source) {
    selectNext();
  }

  void selectNext() {
    while (position < source.length && source[position].trim().isEmpty) {
      position++;
    }

    if (position == source.length) {
      next = Token(TokenType.eof, 0);
      return;
    }

    final char = source[position];
    switch (char) {
      case '+':
        next = Token(TokenType.plus, 0);
        break;
      case '-':
        next = Token(TokenType.minus, 0);
        break;
      case '*':
        next = Token(TokenType.multiply, 0);
        break;
      case '/':
        next = Token(TokenType.divide, 0);
        break;
      case '(':
        print("Open Paren");
        next = Token(TokenType.openParen, 0);
        break;
      case ')':
        print("Close Paren");
        next = Token(TokenType.closeParen, 0);
        break;
      case '=':
        next = Token(TokenType.equal, 0);
        break;
      default:
        if (char.startsWith(RegExp(r'^\d'))) {
          final start = position;
          while (position < source.length &&
              source[position].contains(RegExp(r'\d'))) {
            position++;
          }

          if (source[position + 1].contains(RegExp(r'^[a-zA-Z_=]'))) {
            throw FormatException(
                "Invalid character '${source[position]}' after number '$start'");
          }
          if (position < source.length &&
              source[position].contains(RegExp(r'^[a-zA-Z_]'))) {
            throw FormatException(
                "Invalid character '${source[position]}' after number '$start'");
          }

          final number = int.parse(source.substring(start, position));
          next = Token(TokenType.integer, number);
          return;
        } else {
          final start = position;
          while (position < source.length &&
              source[position].contains(RegExp(r'^[a-zA-Z0-9_]+$'))) {
            position++;
          }
          final identifier = source.substring(start, position);
          if (reservedKeywords.contains(identifier)) {
            next = Token(TokenType.print, 0);
          } else {
            next = Token(TokenType.identifier, identifier);
          }
          return;
        }
    }
    position++;
  }
}

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
  or,
  and,
  not,
  greater,
  less,
  equalEqual,
  endToken,
  ifToken,
  elseToken,
  doToken,
  thenToken,
  whileToken,
  read,
  lineBreak,
}

final Map<String, TokenType> keywordTokens = {
  'print': TokenType.print,
  'read': TokenType.read,
  'if': TokenType.ifToken,
  'else': TokenType.elseToken,
  'do': TokenType.doToken,
  'then': TokenType.thenToken,
  'while': TokenType.whileToken,
  'end': TokenType.endToken,
  'not': TokenType.not,
  'or': TokenType.or,
  'and': TokenType.and,
};

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
      case '\n':
        next = Token(TokenType.lineBreak, 0);
        break;
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
        next = Token(TokenType.openParen, 0);
        break;
      case ')':
        next = Token(TokenType.closeParen, 0);
        break;
      case '=':
        // check if next character is '='
        if (position + 1 < source.length && source[position + 1] == '=') {
          next = Token(TokenType.equalEqual, 0);
          position++;
        } else {
          next = Token(TokenType.equal, 0);
        }
        break;
      case '>':
        next = Token(TokenType.greater, 0);
        break;
      case '<':
        next = Token(TokenType.less, 0);
        break;
      default:
        if (char.startsWith(RegExp(r'^\d'))) {
          final start = position;
          while (position < source.length &&
              source[position].contains(RegExp(r'\d'))) {
            position++;
          }

          if (position < source.length &&
              source[position].contains(RegExp(r'^[a-zA-Z_]'))) {
            throw FormatException(
                "Invalid character '${source[position]}' after number '$start'");
          }

          final number = double.parse(source.substring(start, position));
          next = Token(TokenType.integer, number);
          return;
        } else {
          final start = position;
          while (position < source.length &&
              source[position].contains(RegExp(r'^[a-zA-Z0-9_]+$'))) {
            position++;
          }
          final identifier = source.substring(start, position);
          if (keywordTokens.containsKey(identifier)) {
            TokenType type = keywordTokens[identifier]!;
            if (type == TokenType.thenToken) {
              if (position < source.length && source[position] != '\n') {
                throw FormatException(
                    "Expected line break after 'then' but found '${source[position]}'");
              }
            }
            next = Token(type, identifier);
          } else {
            next = Token(TokenType.identifier, identifier);
          }
          return;
        }
    }
    position++;
  }
}

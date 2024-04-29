enum TokenType {
  integer,
  string,
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
  local,
  lineBreak,
  concat,
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
  'local': TokenType.local,
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
    while (position < source.length && " \t".contains(source[position])) {
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
        position++;
        break;
      case '+':
        next = Token(TokenType.plus, 0);
        position++;
        break;
      case '-':
        next = Token(TokenType.minus, 0);
        position++;
        break;
      case '*':
        next = Token(TokenType.multiply, 0);
        position++;
        break;
      case '/':
        next = Token(TokenType.divide, 0);
        position++;
        break;
      case '(':
        next = Token(TokenType.openParen, 0);
        position++;
        break;
      case ')':
        next = Token(TokenType.closeParen, 0);
        position++;
        break;
      case '=':
        if (position + 1 < source.length && source[position + 1] == '=') {
          next = Token(TokenType.equalEqual, 0);
          position += 2;
        } else {
          next = Token(TokenType.equal, 0);
          position++;
        }
        break;
      case '>':
        next = Token(TokenType.greater, 0);
        position++;
        break;
      case '<':
        next = Token(TokenType.less, 0);
        position++;
        break;
      case '.':
        if (position + 1 < source.length && source[position + 1] == '.') {
          next = Token(TokenType.concat, 0);
          position += 2; // Move beyond the ".."
        } else {
          throw FormatException(
              "Unrecognized character '.' at position $position");
        }
        break;
      case '"':
      case '\'':
        final delimiter = char;
        position++;
        final start = position;
        while (position < source.length && source[position] != delimiter) {
          position++;
        }
        if (position >= source.length) {
          throw FormatException("String not closed");
        }
        final stringValue = source.substring(start, position);
        next = Token(TokenType.string, stringValue);
        position++;
        break;
      default:
        if (char.startsWith(RegExp(r'[a-zA-Z_]'))) {
          final start = position;
          while (position < source.length &&
              source[position].contains(RegExp(r'^[a-zA-Z0-9_]+$'))) {
            position++;
          }
          final identifier = source.substring(start, position);
          if (keywordTokens.containsKey(identifier)) {
            next = Token(keywordTokens[identifier]!, identifier);
          } else {
            next = Token(TokenType.identifier, identifier);
          }
        } else if (char.startsWith(RegExp(r'^\d'))) {
          final start = position;
          while (position < source.length &&
              source[position].contains(RegExp(r'\d'))) {
            position++;
          }
          final number = double.parse(source.substring(start, position));
          next = Token(TokenType.integer, number);
        } else {
          throw FormatException(
              "Unrecognized character '$char' at position $position");
        }
        break;
    }
  }
}

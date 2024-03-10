import 'dart:io';

enum TokenType {
  integer,
  plus,
  minus,
  multiply,
  divide,
  eof,
  openParen,
  closeParen,
}

class Token {
  final TokenType type;
  final int value;

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
        next = Token(TokenType.openParen, 0);
        break;
      case ')':
        next = Token(TokenType.closeParen, 0);
        break;
      default:
        if (char.contains(RegExp(r'\d'))) {
          final start = position;
          while (position < source.length &&
              source[position].contains(RegExp(r'\d'))) {
            position++;
          }
          final number = int.parse(source.substring(start, position));
          next = Token(TokenType.integer, number);
          return;
        } else {
          throw FormatException(
              'Unexpected character $char at position $position');
        }
    }
    position++;
  }
}

class Parser {
  late final Tokenizer tokenizer;

  Parser(String source) {
    tokenizer = Tokenizer(source);
  }

  int parseExpression() {
    int result = parseTerm();
    while (tokenizer.next.type == TokenType.plus ||
        tokenizer.next.type == TokenType.minus) {
      var operator = tokenizer.next.type;
      tokenizer.selectNext(); // Consume operator
      int right = parseTerm();
      if (operator == TokenType.plus) {
        result += right;
      } else {
        result -= right;
      }
    }
    return result;
  }

  int parseTerm() {
    int result = parseFactor();
    while (tokenizer.next.type == TokenType.multiply ||
        tokenizer.next.type == TokenType.divide) {
      var operator = tokenizer.next.type;
      tokenizer.selectNext(); // Consume operator
      int right = parseFactor();
      if (operator == TokenType.multiply) {
        result *= right;
      } else {
        result ~/= right; // Use integer division
      }
    }
    return result;
  }

  int parseFactor() {
    if (tokenizer.next.type == TokenType.integer) {
      int value = tokenizer.next.value;
      tokenizer.selectNext(); // Consume number
      return value;
    } else if (tokenizer.next.type == TokenType.minus) {
      tokenizer.selectNext(); // Consume operator
      return -parseFactor();
    } else if (tokenizer.next.type == TokenType.plus) {
      tokenizer.selectNext(); // Consume operator
      return parseFactor();
    } else if (tokenizer.next.type == TokenType.openParen) {
      tokenizer.selectNext(); // Consume '('
      int result = parseExpression();
      if (tokenizer.next.type != TokenType.closeParen) {
        throw FormatException("Expected ')' but found ${tokenizer.next.type}");
      }
      tokenizer.selectNext(); // Consume ')'
      return result;
    } else {
      throw FormatException("Expected number but found ${tokenizer.next.type}");
    }
  }

  int run() {
    int result = parseExpression();
    if (tokenizer.next.type != TokenType.eof) {
      throw FormatException(
          'Unexpected token ${tokenizer.next.type} at the end of the expression');
    }
    return result;
  }
}

void main(List<String> args) {
  if (args.isEmpty) {
    print('No expression provided');
    return;
  }
  try {
    final parser = Parser(args[0]);
    final result = parser.run();
    print(result);
  } catch (e) {
    print('Error parsing expression: $e');
  }
}

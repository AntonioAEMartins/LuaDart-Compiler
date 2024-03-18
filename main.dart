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

// class Parser {
//   late final Tokenizer tokenizer;

//   Parser(String source) {
//     tokenizer = Tokenizer(source);
//   }

//   int parseExpression() {
//     int result = parseTerm();
//     while (tokenizer.next.type == TokenType.plus ||
//         tokenizer.next.type == TokenType.minus) {
//       var operator = tokenizer.next.type;
//       tokenizer.selectNext(); // Consume operator
//       int right = parseTerm();
//       if (operator == TokenType.plus) {
//         result += right;
//       } else {
//         result -= right;
//       }
//     }
//     return result;
//   }

//   int parseTerm() {
//     int result = parseFactor();
//     while (tokenizer.next.type == TokenType.multiply ||
//         tokenizer.next.type == TokenType.divide) {
//       var operator = tokenizer.next.type;
//       tokenizer.selectNext(); // Consume operator
//       int right = parseFactor();
//       if (operator == TokenType.multiply) {
//         result *= right;
//       } else {
//         result ~/= right; // Use integer division
//       }
//     }
//     return result;
//   }

//   int parseFactor() {
//     if (tokenizer.next.type == TokenType.integer) {
//       int value = tokenizer.next.value;
//       tokenizer.selectNext(); // Consume number
//       return value;
//     } else if (tokenizer.next.type == TokenType.minus) {
//       tokenizer.selectNext(); // Consume operator
//       return -parseFactor();
//     } else if (tokenizer.next.type == TokenType.plus) {
//       tokenizer.selectNext(); // Consume operator
//       return parseFactor();
//     } else if (tokenizer.next.type == TokenType.openParen) {
//       tokenizer.selectNext(); // Consume '('
//       int result = parseExpression();
//       if (tokenizer.next.type != TokenType.closeParen) {
//         throw FormatException("Expected ')' but found ${tokenizer.next.type}");
//       }
//       tokenizer.selectNext(); // Consume ')'
//       return result;
//     } else {
//       throw FormatException("Expected number but found ${tokenizer.next.type}");
//     }
//   }

//   int run() {
//     int result = parseExpression();
//     if (tokenizer.next.type != TokenType.eof) {
//       throw FormatException(
//           'Unexpected token ${tokenizer.next.type} at the end of the expression');
//     }
//     return result;
//   }
// }

// Now the class Parser must build the AST instead of evaluating the expression

class Parser {
  late final Tokenizer tokenizer;

  Parser(String source) {
    tokenizer = Tokenizer(source);
  }

  Node parseExpression() {
    Node result = parseTerm();
    while (tokenizer.next.type == TokenType.plus ||
        tokenizer.next.type == TokenType.minus) {
      var operator = tokenizer.next.type;
      tokenizer.selectNext(); // Consume operator
      Node left = parseTerm();
      result = BinOp(left, result, operator.toString());
    }
    return result;
  }

  Node parseTerm() {
    Node result = parseFactor();
    while (tokenizer.next.type == TokenType.multiply ||
        tokenizer.next.type == TokenType.divide) {
      var operator = tokenizer.next.type;
      tokenizer.selectNext(); // Consume operator
      Node left = parseFactor();
      result = BinOp(left, result, operator.toString());
    }
    return result;
  }

  Node parseFactor() {
    if (tokenizer.next.type == TokenType.integer) {
      int value = tokenizer.next.value;
      tokenizer.selectNext(); // Consume number
      return IntVal(value);
    } else if (tokenizer.next.type == TokenType.minus ||
        tokenizer.next.type == TokenType.plus) {
      var operator = tokenizer.next.type;
      tokenizer.selectNext(); // Consume operator
      return UnOp(parseFactor(), operator == TokenType.minus ? '-' : '+');
    } else if (tokenizer.next.type == TokenType.openParen) {
      tokenizer.selectNext(); // Consume '('
      Node result = parseExpression();
      if (tokenizer.next.type != TokenType.closeParen) {
        throw FormatException("Expected ')' but found ${tokenizer.next.type}");
      }
      tokenizer.selectNext(); // Consume ')'
      return result;
    } else {
      throw FormatException("Expected number but found ${tokenizer.next.type}");
    }
  }

  Node run() {
    Node result = parseExpression();
    if (tokenizer.next.type != TokenType.eof) {
      throw FormatException(
          'Unexpected token ${tokenizer.next.type} at the end of the expression');
    }
    return result;
  }
}

class PrePro {
  String filter(String source) {
    source = source.replaceAll(RegExp(r'\n'), ' ');
    return source.replaceAll(RegExp(r'--.*'), '');
  }
}

abstract class Node {
  dynamic value;
  List<Node> children = [];
  Node(this.value);

  dynamic Evaluate() {
    for (var child in children) {
      child.Evaluate();
    }
    ;
  }
}

class BinOp extends Node {
  final Node left;
  final Node right;
  BinOp(this.left, this.right, String op) : super(op);

  @override
  dynamic Evaluate() {
    switch (value) {
      case "TokenType.plus":
        return right.Evaluate() + left.Evaluate();
      case "TokenType.minus":
        return right.Evaluate() - left.Evaluate();
      case "TokenType.multiply":
        return right.Evaluate() * left.Evaluate();
      case "TokenType.divide":
        return right.Evaluate() ~/ left.Evaluate();
      default:
        throw Exception('Invalid operator: $value');
    }
  }
}

class UnOp extends Node {
  final Node expr;
  UnOp(this.expr, String op) : super(op);

  @override
  dynamic Evaluate() {
    if (value == '-') {
      return -expr.Evaluate();
    } else {
      return expr.Evaluate();
    }
  }
}

class IntVal extends Node {
  IntVal(int value) : super(value);

  @override
  dynamic Evaluate() {
    return value;
  }
}

class NoOp extends Node {
  NoOp() : super(null);

  @override
  dynamic Evaluate() {
    return null;
  }
}

void main(List<String> args) {
  if (args.isEmpty) {
    throw ArgumentError('Please provide an expression to parse');
  }
  PrePro prePro = PrePro();
  String filtered = prePro.filter(args[0]);
  try {
    print(filtered);
    final parser = Parser(filtered);
    final ast = parser.run();
    final result = ast.Evaluate();
    stdout.writeln(result);
  } catch (e) {
    throw Exception(e);
  }
}

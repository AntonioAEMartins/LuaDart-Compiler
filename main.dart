import 'dart:io';
import 'filters.dart';
import 'operands.dart';
import 'tonekizer.dart';

class SymbolTable {
  SymbolTable._privateConstructor();

  static final SymbolTable _instance = SymbolTable._privateConstructor();

  static SymbolTable get instance => _instance;

  final Map<String, double> _table = {};

  void set(String key, double value) {
    _table[key] = value;
  }

  double? get(String key) {
    return _table[key];
  }
}

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
      Node right = parseTerm();
      result = BinOp(result, right, operator.toString());
    }
    return result;
  }

  Node statement() {
    if (tokenizer.next.type == TokenType.identifier) {
      final Token identifier = tokenizer.next;
      tokenizer.selectNext();

      if (tokenizer.next.type == TokenType.equal) {
        tokenizer.selectNext();
        final Node expression = parseExpression();
        final Identifier id = Identifier(identifier.value);
        return AssignOp(id, expression);
      } else {
        throw FormatException("Expected '=' but found ${tokenizer.next.type}");
      }
    } else if (tokenizer.next.type == TokenType.print) {
      tokenizer.selectNext();
      final Node expression = parseExpression();
      return PrintOp(expression);
    } else if (tokenizer.next.type == TokenType.whileToken) {
      tokenizer.selectNext(); // Consume 'while'
      final Node condition = boolExpression();
      if (tokenizer.next.type != TokenType.doToken) {
        throw FormatException("Expected 'do' but found ${tokenizer.next.type}");
      }
      tokenizer.selectNext(); // Consume 'do'
      tokenizer.selectNext(); // Consume '\n'
      final Node block = this.block();
      if (tokenizer.next.type != TokenType.endToken) {
        throw FormatException(
            "Expected 'end' but found ${tokenizer.next.type}");
      }
      tokenizer.selectNext(); // Consume 'end'
      return WhileOp(condition, block);
    } else if (tokenizer.next.type == TokenType.ifToken) {
      tokenizer.selectNext();
      final Node condition = boolExpression();
      if (tokenizer.next.type != TokenType.thenToken) {
        throw FormatException(
            "Expected 'then' but found ${tokenizer.next.type}");
      }
      tokenizer.selectNext(); // Consume 'then'
      tokenizer.selectNext(); // Consume '\n'
      final Node block = this.block();
      if (tokenizer.next.type == TokenType.elseToken) {
        tokenizer.selectNext();
        final Node elseBlock = this.block();
        if (tokenizer.next.type != TokenType.endToken) {
          throw FormatException(
              "Expected 'end' but found ${tokenizer.next.type}");
        }
        tokenizer.selectNext(); // Consume 'end'
        return IfOp(condition, block, elseBlock);
      }
      if (tokenizer.next.type != TokenType.endToken) {
        throw FormatException(
            "Expected 'end' but found ${tokenizer.next.type}");
      }
      tokenizer.selectNext(); // Consume 'end'
      return IfOp(condition, block, null);
    }
    return NoOp();
  }

  Node block() {
    Node result = Block();
    while (tokenizer.next.type != TokenType.eof &&
        tokenizer.next.type != TokenType.integer) {
      if (tokenizer.next.type == TokenType.closeParen) {
        throw FormatException("The block is not closed");
      }
      result.children.add(statement());
    }
    return result;
  }

  Node parseTerm() {
    Node result = parseFactor();
    while (tokenizer.next.type == TokenType.multiply ||
        tokenizer.next.type == TokenType.divide) {
      var operator = tokenizer.next.type;
      tokenizer.selectNext(); // Consume operator
      Node right = parseFactor();
      result = BinOp(result, right, operator.toString());
    }
    return result;
  }

  Node parseFactor() {
    if (tokenizer.next.type == TokenType.integer) {
      double value = tokenizer.next.value;
      tokenizer.selectNext(); // Consume number
      return IntVal(value);
    } else if (tokenizer.next.type == TokenType.minus) {
      tokenizer.selectNext(); // Consume operator
      return UnOp(parseFactor(), '-');
    } else if (tokenizer.next.type == TokenType.plus) {
      tokenizer.selectNext(); // Consume operator
      return UnOp(parseFactor(), '+');
    } else if (tokenizer.next.type == TokenType.openParen) {
      tokenizer.selectNext(); // Consume '('
      Node result = parseExpression();
      if (tokenizer.next.type != TokenType.closeParen) {
        throw FormatException("Expected ')' but found ${tokenizer.next.type}");
      }
      tokenizer.selectNext(); // Consume ')'
      return result;
    } else if (tokenizer.next.type == TokenType.identifier) {
      final Token identifier = tokenizer.next;
      tokenizer.selectNext();
      return Identifier(identifier.value);
    } else if (tokenizer.next.type == TokenType.not) {
      tokenizer.selectNext(); // Consume operator
      return UnOp(parseFactor(), '!');
    } else if (tokenizer.next.type == TokenType.read) {
      // In lua the read function does not have a parameter
      tokenizer.selectNext(); // Consume operator
      if (tokenizer.next.type != TokenType.openParen) {
        throw FormatException("Expected '(' but found ${tokenizer.next.type}");
      }
      tokenizer.selectNext(); // Consume '('
      if (tokenizer.next.type != TokenType.closeParen) {
        throw FormatException("Expected ')' but found ${tokenizer.next.type}");
      }
      tokenizer.selectNext(); // Consume ')'
      return ReadOp();
    } else {
      throw FormatException("Expected number but found ${tokenizer.next.type}");
    }
  }

  Node boolExpression() {
    Node result = boolTerm();
    while (tokenizer.next.type == TokenType.or) {
      var operator = tokenizer.next.type;
      tokenizer.selectNext(); // Consume operator
      Node right = boolTerm();
      result = BinOp(result, right, operator.toString());
    }
    return result;
  }

  Node boolTerm() {
    Node result = relExpression();
    while (tokenizer.next.type == TokenType.and) {
      var operator = tokenizer.next.type;
      tokenizer.selectNext(); // Consume operator
      Node right = relExpression();
      result = BinOp(result, right, operator.toString());
    }
    return result;
  }

  Node relExpression() {
    Node result = parseExpression();
    switch (tokenizer.next.type) {
      case TokenType.equalEqual:
      case TokenType.greater:
      case TokenType.less:
        var operator = tokenizer.next.type;
        tokenizer.selectNext(); // Consume operator
        Node right = parseExpression();
        result = BinOp(result, right, operator.toString());
        break;
      default:
        break;
    }
    return result;
  }

  Node run() {
    Node result = block();
    return result;
  }
}

void main(List<String> args) {
  if (args.isEmpty) {
    throw ArgumentError('Please provide an expression to parse');
  }
  PrePro prePro = PrePro();
  final file = File(args[0]);
  final content = file.readAsStringSync();
  final filtered = prePro.filter(content);
  try {
    final SymbolTable table = SymbolTable.instance;
    final parser = Parser(filtered);
    final ast = parser.run();
    if (ast.children.isEmpty) throw Exception('No statements found');
    final result = ast.Evaluate(table);
    if (result != null) stdout.writeln(result);
  } catch (e) {
    throw Exception(e);
  }
}

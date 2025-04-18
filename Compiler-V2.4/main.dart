import 'dart:io';
import 'filters.dart';
import 'operands.dart';
import 'tonekizer.dart';

class FuncTable {
  FuncTable._privateConstructor();

  static final FuncTable _instance = FuncTable._privateConstructor();

  static FuncTable get instance => _instance;

  final Map<String, dynamic> _table = {};

  void set({required String key, required Node node}) {
    if (_table[key] == null) {
      _table[key] = node;
    } else {
      throw Exception('Function already defined: $key');
    }
  }

  dynamic get(String key) {
    final value = _table[key];
    if (value == null) {
      throw Exception('Undefined function: $key');
    }
    return value;
  }
}

class SymbolTable {
  SymbolTable._privateConstructor();

  static final SymbolTable _instance = SymbolTable._privateConstructor();

  static SymbolTable get instance => _instance;

  static SymbolTable getNewInstance() {
    return SymbolTable._privateConstructor();
  }

  final Map<String, Map<String, dynamic>> _table = {};

  void set(
      {required String key,
      required dynamic value,
      required dynamic type,
      required bool isLocal}) {
    if (!isLocal) {
      if (_table[key] != null) {
        _table[key] = {'value': value, 'type': type};
      } else {
        throw Exception('Variable already defined: $key');
      }
    } else if (_table[key] == null) {
      _table[key] = {'value': value, 'type': type};
    } else {
      throw Exception('Variable already defined: $key (local)');
    }
  }

  ({dynamic value, String type}) get(String key) {
    final value = _table[key];
    if (value == null) {
      throw Exception('Undefined variable: $key');
    }
    return (value: value['value'], type: value['type']);
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
        tokenizer.next.type == TokenType.minus ||
        tokenizer.next.type == TokenType.concat) {
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
        if (tokenizer.next.type == TokenType.equal) {
          throw FormatException("Token not expected ${tokenizer.next.type}");
        }
        return AssignOp(id, expression);
      }

      if (tokenizer.next.type == TokenType.openParen) {
        tokenizer.selectNext(); // Consume '('
        List<Node> parameters = [];
        if (tokenizer.next.type != TokenType.closeParen) {
          parameters.add(boolExpression());
          while (tokenizer.next.type == TokenType.comma) {
            tokenizer.selectNext(); // Consume ','
            parameters.add(boolExpression());
          }
        }

        if (tokenizer.next.type != TokenType.closeParen) {
          throw FormatException(
              "Expected ')' but found ${tokenizer.next.type}");
        }
        tokenizer.selectNext(); // Consume ')'
        return FuncCallOp(Identifier(identifier.value), parameters);
      }

      throw FormatException("Token not expected ${tokenizer.next.type}");
    } else if (tokenizer.next.type == TokenType.local) {
      tokenizer.selectNext();
      if (tokenizer.next.type != TokenType.identifier) {
        throw FormatException(
            "Expected identifier but found ${tokenizer.next.type}");
      }
      final Token identifier = tokenizer.next;
      final Identifier id = Identifier(identifier.value);
      tokenizer.selectNext();
      if (tokenizer.next.type == TokenType.lineBreak) {
        return VarDecOp(id, NullOp());
      }
      if (tokenizer.next.type != TokenType.equal) {
        throw FormatException("Expected '=' but found ${tokenizer.next.type}");
      }
      tokenizer.selectNext(); // Consume '='
      final Node expression = boolExpression();

      if (tokenizer.next.type == TokenType.equal) {
        throw FormatException("Token not expected ${tokenizer.next.type}");
      }
      return VarDecOp(id, expression);
    } else if (tokenizer.next.type == TokenType.print) {
      tokenizer.selectNext();
      if (tokenizer.next.type != TokenType.openParen) {
        throw FormatException("Expected '(' but found ${tokenizer.next.type}");
      }
      tokenizer.selectNext(); // Consume '('
      final Node expression = boolExpression();
      if (tokenizer.next.type != TokenType.closeParen) {
        throw FormatException("Expected ')' but found ${tokenizer.next.type}");
      }
      tokenizer.selectNext(); // Consume ')'
      return PrintOp(expression);
    } else if (tokenizer.next.type == TokenType.whileToken) {
      tokenizer.selectNext(); // Consume 'while'
      final Node condition = boolExpression();
      if (tokenizer.next.type != TokenType.doToken) {
        throw FormatException("Expected 'do' but found ${tokenizer.next.type}");
      }
      tokenizer.selectNext(); // Consume 'do'
      if (tokenizer.next.type != TokenType.lineBreak) {
        throw FormatException(
            "Expected line break but found ${tokenizer.next.type}");
      }
      tokenizer.selectNext();
      final Node block = this.endBlock();
      if (tokenizer.next.type != TokenType.endToken) {
        throw FormatException(
            "Expected 'end' but found ${tokenizer.next.type}");
      }
      tokenizer.selectNext(); // Consume 'end'
      return WhileOp(condition, block);
    } else if (tokenizer.next.type == TokenType.ifToken) {
      tokenizer.selectNext(); // Consume 'if'
      final Node condition = boolExpression();
      if (tokenizer.next.type != TokenType.thenToken) {
        throw FormatException(
            "Expected 'then' but found ${tokenizer.next.type}");
      }
      tokenizer.selectNext(); // Consume 'then'
      if (tokenizer.next.type != TokenType.lineBreak) {
        throw FormatException(
            "Expected line break but found ${tokenizer.next.type}");
      }
      tokenizer.selectNext();
      final Node block = this.endBlock();
      if (tokenizer.next.type == TokenType.elseToken) {
        tokenizer.selectNext();
        final Node elseBlock = this.endBlock();
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
      if (tokenizer.next.type != TokenType.lineBreak) {
        throw FormatException(
            "Expected line break but found ${tokenizer.next.type}");
      }
      tokenizer.selectNext();
      return IfOp(condition, block, null);
    } else if (tokenizer.next.type == TokenType.function) {
      tokenizer.selectNext(); // Consume 'function'
      if (tokenizer.next.type != TokenType.identifier) {
        throw FormatException(
            "Expected identifier but found ${tokenizer.next.type}");
      }
      final Token identifier = tokenizer.next;
      final Identifier id = Identifier(identifier.value);
      tokenizer.selectNext();
      if (tokenizer.next.type != TokenType.openParen) {
        throw FormatException("Expected '(' but found ${tokenizer.next.type}");
      }
      tokenizer.selectNext(); // Consume '('
      List<Identifier> parameters = [];
      if (tokenizer.next.type == TokenType.identifier) {
        final Token parameter = tokenizer.next;
        parameters.add(Identifier(parameter.value));
        tokenizer.selectNext();
        while (tokenizer.next.type == TokenType.comma) {
          tokenizer.selectNext(); // Consume ','
          if (tokenizer.next.type != TokenType.identifier) {
            throw FormatException(
                "Expected identifier but found ${tokenizer.next.type}");
          }
          final Token parameter = tokenizer.next;
          parameters.add(Identifier(parameter.value));
          tokenizer.selectNext();
        }
      }

      if (tokenizer.next.type != TokenType.closeParen) {
        throw FormatException("Expected ')' but found ${tokenizer.next.type}");
      }

      tokenizer.selectNext(); // Consume ')'

      if (tokenizer.next.type != TokenType.lineBreak) {
        throw FormatException(
            "Expected line break but found ${tokenizer.next.type}");
      }

      tokenizer.selectNext();

      final Node block = this.endBlock();

      if (tokenizer.next.type != TokenType.endToken) {
        throw FormatException(
            "Expected 'end' but found ${tokenizer.next.type}");
      }

      tokenizer.selectNext(); // Consume 'end'

      return FuncDecOp(id, parameters, block);
    } else if (tokenizer.next.type == TokenType.RETURN) {
      tokenizer.selectNext(); // Consume 'return'
      final Node expression = boolExpression();
      return ReturnOp(expression);
    }
    if (tokenizer.next.type != TokenType.lineBreak) {
      throw FormatException(
          "Expected line break but found ${tokenizer.next.type}");
    }
    tokenizer.selectNext();
    return NoOp();
  }

  Node block() {
    Node result = Block();

    while (tokenizer.next.type != TokenType.eof &&
        tokenizer.next.type != TokenType.endToken) {
      result.children.add(statement());
    }

    if (tokenizer.next.type == TokenType.endToken) {
      throw FormatException("The block is not closed");
    }

    return result;
  }

  Node endBlock() {
    Node result = Block();
    while (tokenizer.next.type != TokenType.endToken &&
        tokenizer.next.type != TokenType.elseToken &&
        tokenizer.next.type != TokenType.eof) {
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
      int value = tokenizer.next.value;
      tokenizer.selectNext(); // Consume number
      return IntVal(value);
    } else if (tokenizer.next.type == TokenType.string) {
      final String value = tokenizer.next.value;
      tokenizer.selectNext(); // Consume string
      return StringVal(value);
    } else if (tokenizer.next.type == TokenType.identifier) {
      final Token identifier = tokenizer.next;
      tokenizer.selectNext();

      if (tokenizer.next.type == TokenType.openParen) {
        tokenizer.selectNext(); // Consume '('
        List<Node> parameters = [];
        if (tokenizer.next.type != TokenType.closeParen) {
          parameters.add(boolExpression());
          while (tokenizer.next.type == TokenType.comma) {
            tokenizer.selectNext(); // Consume ','
            parameters.add(boolExpression());
          }
        }

        if (tokenizer.next.type != TokenType.closeParen) {
          throw FormatException(
              "Expected ')' but found ${tokenizer.next.type}");
        }
        tokenizer.selectNext(); // Consume ')'
        return FuncCallOp(Identifier(identifier.value), parameters);
      }
      return Identifier(identifier.value);
    } else if (tokenizer.next.type == TokenType.plus) {
      tokenizer.selectNext(); // Consume operator
      return UnOp(parseFactor(), '+');
    } else if (tokenizer.next.type == TokenType.minus) {
      tokenizer.selectNext(); // Consume operator
      return UnOp(parseFactor(), '-');
    } else if (tokenizer.next.type == TokenType.not) {
      tokenizer.selectNext(); // Consume operator
      return UnOp(parseFactor(), '!');
    } else if (tokenizer.next.type == TokenType.openParen) {
      tokenizer.selectNext(); // Consume '('
      Node result = boolExpression();
      if (tokenizer.next.type != TokenType.closeParen) {
        throw FormatException("Expected ')' but found ${tokenizer.next.type}");
      }
      tokenizer.selectNext(); // Consume ')'
      return result;
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
    final FuncTable funcTable = FuncTable.instance;
    final parser = Parser(filtered);
    final ast = parser.run();
    if (ast.children.isEmpty) {
      throw Exception('No statements found');
    }
    final result = ast.Evaluate(table, funcTable);
    if (result != null) {
      stdout.writeln(result);
    }
  } catch (e, s) {
    // print('Error: ${e.toString()}');
    // print('Stack Trace:\n$s');
    throw e;
  }
}

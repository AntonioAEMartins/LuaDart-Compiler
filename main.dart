import 'dart:io';
import 'filters.dart';
import 'operands.dart';
import 'tonekizer.dart';

class SymbolTable {
  SymbolTable._privateConstructor();

  static final SymbolTable _instance = SymbolTable._privateConstructor();

  static SymbolTable get instance => _instance;

  final Map<String, int> _table = {};

  void set(String key, int value) {
    _table[key] = value;
  }

  int? get(String key) {
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

      if (tokenizer.next.type != TokenType.closeParen &&
          tokenizer.next.type != TokenType.eof) {
        throw FormatException("Expected ')' but found ${tokenizer.next.type}");
      }
      tokenizer.selectNext();
      return PrintOp(expression);
    }
    return NoOp();
  }

  Node block() {
    Node result = Block();
    while (tokenizer.next.type != TokenType.eof) {
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
    } else {
      throw FormatException("Expected number but found ${tokenizer.next.type}");
    }
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
    final result = ast.Evaluate(table);
    stdout.writeln(result);
  } catch (e) {
    throw Exception(e);
  }
}

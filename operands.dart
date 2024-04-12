import 'dart:io';

import 'main.dart';

abstract class Node {
  dynamic value;
  List<Node> children = [];
  Node(this.value);

  dynamic Evaluate(SymbolTable _table) {
    for (var child in children) {
      child.Evaluate(_table);
    }
  }
}

class BinOp extends Node {
  final Node left;
  final Node right;
  BinOp(this.left, this.right, String op) : super(op);

  @override
  dynamic Evaluate(SymbolTable _table) {
    switch (value) {
      case "TokenType.plus":
        return left.Evaluate(_table) + right.Evaluate(_table);
      case "TokenType.minus":
        return left.Evaluate(_table) - right.Evaluate(_table);
      case "TokenType.multiply":
        return left.Evaluate(_table) * right.Evaluate(_table);
      case "TokenType.divide":
        return left.Evaluate(_table) / right.Evaluate(_table);
      case "TokenType.greater":
        return left.Evaluate(_table) > right.Evaluate(_table);
      case "TokenType.less":
        return left.Evaluate(_table) < right.Evaluate(_table);
      case "TokenType.equalEqual":
        return left.Evaluate(_table) == right.Evaluate(_table);
      case "TokenType.and":
        return left.Evaluate(_table) && right.Evaluate(_table);
      case "TokenType.or":
        return left.Evaluate(_table) || right.Evaluate(_table);
      default:
        throw Exception('Invalid operator: $value');
    }
  }
}

class UnOp extends Node {
  final Node expr;
  UnOp(this.expr, String op) : super(op);

  @override
  dynamic Evaluate(SymbolTable _table) {
    switch (value) {
      case "!":
        return !expr.Evaluate(_table);
      case "-":
        return -expr.Evaluate(_table);
      case "+":
        return expr.Evaluate(_table);
      default:
        throw Exception('Invalid operator: $value');
    }
  }
}

class IntVal extends Node {
  IntVal(double value) : super(value);

  @override
  dynamic Evaluate(SymbolTable _table) {
    return value;
  }
}

class NoOp extends Node {
  NoOp() : super(null);

  @override
  dynamic Evaluate(SymbolTable _table) {
    return null;
  }
}

class PrintOp extends Node {
  final Node expr;
  PrintOp(this.expr) : super(null);

  @override
  dynamic Evaluate(SymbolTable _table) {
    print(expr.Evaluate(_table).toStringAsFixed(0));
  }
}

class Identifier extends Node {
  final String name;
  Identifier(this.name) : super(null);

  @override
  dynamic Evaluate(SymbolTable _table) {
    if (_table.get(name) == null) {
      throw Exception('Undefined variable: $name');
    }
    return _table.get(name);
  }
}

class AssignOp extends Node {
  final Identifier identifier;
  final Node expr;
  AssignOp(this.identifier, this.expr) : super(null);

  @override
  dynamic Evaluate(SymbolTable _table) {
    _table.set(identifier.name, expr.Evaluate(_table));
  }
}

class Block extends Node {
  Block() : super(null);

  @override
  dynamic Evaluate(SymbolTable _table) {
    for (var child in children) {
      child.Evaluate(_table);
    }
  }
}

class ReadOp extends Node {
  ReadOp() : super(null);

  @override
  dynamic Evaluate(SymbolTable _table) {
    return double.tryParse(stdin.readLineSync() ?? '');
  }
}

class WhileOp extends Node {
  final Node condition;
  final Node block;
  WhileOp(this.condition, this.block) : super(null);

  @override
  dynamic Evaluate(SymbolTable _table) {
    while (condition.Evaluate(_table)) {
      block.Evaluate(_table);
    }
  }
}

class IfOp extends Node {
  final Node condition;
  final Node ifOp;
  final Node? elseOp;

  IfOp(this.condition, this.ifOp, this.elseOp) : super(null);

  @override
  dynamic Evaluate(SymbolTable _table) {
    if (condition.Evaluate(_table)) {
      ifOp.Evaluate(_table);
    } else {
      elseOp?.Evaluate(_table);
    }
  }
}

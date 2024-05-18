import 'dart:io';
import 'main.dart';

abstract class Node {
  dynamic value;
  List<Node> children = [];
  Node(this.value);

  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable);
}

class BinOp extends Node {
  final Node left;
  final Node right;
  BinOp(this.left, this.right, String op) : super(op);

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    var leftResult = left.Evaluate(_table, _funcTable);
    var rightResult = right.Evaluate(_table, _funcTable);

    if (value != "TokenType.and" && value != "TokenType.or") {
      if (leftResult['type'] == 'boolean') {
        leftResult['value'] = leftResult['value'] ? 1 : 0;
        leftResult['type'] = 'integer';
      }
      if (rightResult['type'] == 'boolean') {
        rightResult['value'] = rightResult['value'] ? 1 : 0;
        rightResult['type'] = 'integer';
      }
    }

    switch (value) {
      case "TokenType.plus":
        if (leftResult['type'] == 'string' && rightResult['type'] == 'string') {
          return {
            'value': leftResult['value'].toString() +
                rightResult['value'].toString(),
            'type': 'string'
          };
        } else if (leftResult['type'] == 'integer' &&
            rightResult['type'] == 'integer') {
          return {
            'value': leftResult['value'] + rightResult['value'],
            'type': 'integer'
          };
        }
        break;
      case "TokenType.concat":
        if (leftResult['type'] == 'string' || rightResult['type'] == 'string') {
          return {
            'value': leftResult['value'].toString() +
                rightResult['value'].toString(),
            'type': 'string'
          };
        } else if (leftResult['type'] == 'integer' &&
            rightResult['type'] == 'integer') {
          return {
            'value': leftResult['value'].toString() +
                rightResult['value'].toString(),
            'type': 'integer'
          };
        }
        break;

      case "TokenType.minus":
        if (leftResult['type'] == 'integer' &&
            rightResult['type'] == 'integer') {
          return {
            'value': leftResult['value'] - rightResult['value'],
            'type': 'integer'
          };
        }
        break;

      case "TokenType.multiply":
        if (leftResult['type'] == 'integer' &&
            rightResult['type'] == 'integer') {
          return {
            'value': leftResult['value'] * rightResult['value'],
            'type': 'integer'
          };
        }
        break;

      case "TokenType.divide":
        if (leftResult['type'] == 'integer' &&
            rightResult['type'] == 'integer') {
          return {
            'value': leftResult['value'] ~/ rightResult['value'],
            'type': 'integer'
          };
        }
        break;

      case "TokenType.greater":
      case "TokenType.less":
      case "TokenType.equalEqual":
        if (leftResult['type'] == rightResult['type']) {
          return {
            'value': evalComparison(
                leftResult['value'], rightResult['value'], value),
            'type': 'boolean'
          };
        }
        break;

      case "TokenType.and":
      case "TokenType.or":
        if (leftResult['type'] == 'boolean' &&
            rightResult['type'] == 'boolean') {
          return {
            'value': value == "TokenType.and"
                ? leftResult['value'] && rightResult['value']
                : leftResult['value'] || rightResult['value'],
            'type': 'boolean'
          };
        }
        break;
    }
    throw Exception('Invalid operator or type mismatch');
  }

  dynamic evalComparison(dynamic left, dynamic right, String operation) {
    if (left is String && right is String) {
      switch (operation) {
        case "TokenType.greater":
          return left.compareTo(right) > 0;
        case "TokenType.less":
          return left.compareTo(right) < 0;
        case "TokenType.equalEqual":
          return left.compareTo(right) == 0;
        default:
          throw Exception('Unsupported comparison operation');
      }
    }
    switch (operation) {
      case "TokenType.greater":
        return left > right;
      case "TokenType.less":
        return left < right;
      case "TokenType.equalEqual":
        return left == right;
      default:
        throw Exception('Unsupported comparison operation');
    }
  }
}

class UnOp extends Node {
  final Node expr;
  UnOp(this.expr, String op) : super(op);

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    var result = expr.Evaluate(_table, _funcTable);
    if (value == "!" && result['type'] == 'boolean') {
      return {'value': !result['value'], 'type': 'boolean'};
    } else if (value == "-" && result['type'] == 'integer') {
      return {'value': -result['value'], 'type': 'integer'};
    } else if (value == "+" && result['type'] == 'integer') {
      return {'value': result['value'], 'type': 'integer'};
    } else {
      throw Exception('Invalid unary operator or type mismatch');
    }
  }
}

class IntVal extends Node {
  IntVal(int value) : super({'value': value, 'type': 'integer'});

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    return value;
  }
}

class StringVal extends Node {
  StringVal(String value) : super({'value': value, 'type': 'string'});

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    return value;
  }
}

class NoOp extends Node {
  NoOp() : super(null);

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    return null;
  }
}

class PrintOp extends Node {
  final Node expr;
  PrintOp(this.expr) : super(null);

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    var result = expr.Evaluate(_table, _funcTable);
    if (result["type"] == "boolean") {
      result["value"] = result["value"] ? 1 : 0;
    }
    print(result['value']);
  }
}

class Identifier extends Node {
  final String name;
  Identifier(this.name) : super(null);

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    var entry = _table.get(name);
    return {'value': entry.value, 'type': entry.type};
  }
}

class AssignOp extends Node {
  final Identifier identifier;
  final Node expr;
  AssignOp(this.identifier, this.expr) : super(null);

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    var exprResult = expr.Evaluate(_table, _funcTable);
    _table.set(
      key: identifier.name,
      value: exprResult['value'],
      type: exprResult['type'],
      isLocal: false,
    );
  }
}

class VarDecOp extends Node {
  final Identifier identifier;
  final Node expr;
  VarDecOp(this.identifier, this.expr) : super(null);

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    var exprResult = expr.Evaluate(_table, _funcTable);
    _table.set(
      key: identifier.name,
      value: exprResult['value'],
      type: exprResult['type'],
      isLocal: true,
    );
  }
}

class Block extends Node {
  Block() : super(null);

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    for (var child in children) {
      if (child.runtimeType == ReturnOp) {
        return child.Evaluate(_table, _funcTable);
      }
      child.Evaluate(_table, _funcTable);
    }
  }
}

class ReadOp extends Node {
  ReadOp() : super(null);

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    var input = stdin.readLineSync() ?? '';
    try {
      int number = int.parse(input);
      return {'value': number, 'type': 'integer'};
    } catch (e) {
      return {'value': input, 'type': 'string'};
    }
  }
}

class WhileOp extends Node {
  final Node condition;
  final Node block;
  WhileOp(this.condition, this.block) : super(null);

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    while (condition.Evaluate(_table, _funcTable)['value']) {
      block.Evaluate(_table, _funcTable);
    }
  }
}

class IfOp extends Node {
  final Node condition;
  final Node ifOp;
  final Node? elseOp;

  IfOp(this.condition, this.ifOp, this.elseOp) : super(null);

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    if (condition.Evaluate(_table, _funcTable)['value']) {
      ifOp.Evaluate(_table, _funcTable);
    } else {
      elseOp?.Evaluate(_table, _funcTable);
    }
  }
}

class NullOp extends Node {
  NullOp() : super(null);

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    return {"value": null, "type": null};
  }
}

class FuncDecOp extends Node {
  final Identifier identifier;
  final List<Identifier> parameters;
  final Node block;
  FuncDecOp(this.identifier, this.parameters, this.block) : super(null);

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    _funcTable.set(
      key: identifier.name,
      node: this,
    );
  }
}

class FuncCallOp extends Node {
  final Identifier identifier;
  final List<Node> arguments;
  FuncCallOp(this.identifier, this.arguments) : super(null);

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    final func = _funcTable.get(identifier.name);

    if (func == null) {
      throw Exception('Function ${identifier.name} not found');
    }

    if (func.parameters.length != arguments.length) {
      throw Exception(
          'Function ${identifier.name} expects ${func.parameters.length} arguments');
    }

    final localTable = SymbolTable.getNewInstance();

    for (var i = 0; i < func.parameters.length; i++) {
      var arg = arguments[i].Evaluate(_table, _funcTable);
      localTable.set(
        key: func.parameters[i].name,
        value: arg['value'],
        type: arg['type'],
        isLocal: true,
      );
    }

    final functionReturn = func.block.Evaluate(localTable, _funcTable);

    if (functionReturn != null) {
      return functionReturn;
    }
  }
}

class ReturnOp extends Node {
  final Node expr;
  ReturnOp(this.expr) : super(null);

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    return expr.Evaluate(_table, _funcTable);
  }
}

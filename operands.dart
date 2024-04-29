import 'dart:io';
import 'main.dart';

abstract class Node {
  dynamic value;
  List<Node> children = [];
  Node(this.value);

  dynamic Evaluate(SymbolTable _table);
}

class BinOp extends Node {
  final Node left;
  final Node right;
  BinOp(this.left, this.right, String op) : super(op);

  @override
  dynamic Evaluate(SymbolTable _table) {
    var leftResult = left.Evaluate(_table);
    var rightResult = right.Evaluate(_table);

    // Verificar se os tipos são compatíveis para cada operação
    if (value == "TokenType.plus") {
      if (leftResult['type'] == 'string' || rightResult['type'] == 'string') {
        // Concatenação de strings
        return {
          'value':
              leftResult['value'].toString() + rightResult['value'].toString(),
          'type': 'string'
        };
      } else if (leftResult['type'] == 'integer' &&
          rightResult['type'] == 'integer') {
        // Soma de inteiros
        return {
          'value': leftResult['value'] + rightResult['value'],
          'type': 'integer'
        };
      } else {
        throw Exception('Type mismatch for + operator');
      }
    } else if (value == "TokenType.concat") {
      if (leftResult['type'] == 'string' || rightResult['type'] == 'string') {
        // Concatenação de strings
        return {
          'value':
              leftResult['value'].toString() + rightResult['value'].toString(),
          'type': 'string'
        };
      } else {
        throw Exception('Type mismatch for .. operator');
      }
    } else if (value == "TokenType.minus" &&
        leftResult['type'] == 'integer' &&
        rightResult['type'] == 'integer') {
      return {
        'value': leftResult['value'] - rightResult['value'],
        'type': 'integer'
      };
    } else if (value == "TokenType.multiply" &&
        leftResult['type'] == 'integer' &&
        rightResult['type'] == 'integer') {
      return {
        'value': leftResult['value'] * rightResult['value'],
        'type': 'integer'
      };
    } else if (value == "TokenType.divide" &&
        leftResult['type'] == 'integer' &&
        rightResult['type'] == 'integer') {
      return {
        'value': leftResult['value'] / rightResult['value'],
        'type': 'integer'
      };
    } else if (value == "TokenType.greater" &&
        leftResult['type'] == 'integer' &&
        rightResult['type'] == 'integer') {
      return {
        'value': leftResult['value'] > rightResult['value'],
        'type': 'boolean'
      };
    } else if (value == "TokenType.less" &&
        leftResult['type'] == 'integer' &&
        rightResult['type'] == 'integer') {
      return {
        'value': leftResult['value'] < rightResult['value'],
        'type': 'boolean'
      };
    } else if (value == "TokenType.equalEqual" &&
        leftResult['type'] == 'integer' &&
        rightResult['type'] == 'integer') {
      return {
        'value': leftResult['value'] == rightResult['value'],
        'type': 'boolean'
      };
    } else if (value == "TokenType.and" &&
        leftResult['type'] == 'boolean' &&
        rightResult['type'] == 'boolean') {
      return {
        'value': leftResult['value'] && rightResult['value'],
        'type': 'boolean'
      };
    } else if (value == "TokenType.or" &&
        leftResult['type'] == 'boolean' &&
        rightResult['type'] == 'boolean') {
      return {
        'value': leftResult['value'] || rightResult['value'],
        'type': 'boolean'
      };
    } else {
      print("leftResult: $leftResult");
      print("rightResult: $rightResult");
      print("value: $value");
      throw Exception('Invalid operator or type mismatch');
    }
  }
}

class UnOp extends Node {
  final Node expr;
  UnOp(this.expr, String op) : super(op);

  @override
  dynamic Evaluate(SymbolTable _table) {
    var result = expr.Evaluate(_table);
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
  IntVal(double value) : super({'value': value, 'type': 'integer'});

  @override
  dynamic Evaluate(SymbolTable _table) {
    return value;
  }
}

class StringVal extends Node {
  StringVal(String value) : super({'value': value, 'type': 'string'});

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
    var result = expr.Evaluate(_table);
    print(result['value'].toString());
  }
}

class Identifier extends Node {
  final String name;
  Identifier(this.name) : super(null);

  @override
  dynamic Evaluate(SymbolTable _table) {
    var entry = _table.get(name);
    return {'value': entry.value, 'type': entry.type};
  }
}

class AssignOp extends Node {
  final Identifier identifier;
  final Node expr;
  AssignOp(this.identifier, this.expr) : super(null);

  @override
  dynamic Evaluate(SymbolTable _table) {
    var exprResult = expr.Evaluate(_table);
    _table.set(
        key: identifier.name,
        value: exprResult['value'],
        type: exprResult['type']);
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
    var input = stdin.readLineSync() ?? '';
    try {
      double number = double.parse(input);
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
  dynamic Evaluate(SymbolTable _table) {
    while (condition.Evaluate(_table)['value']) {
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
    if (condition.Evaluate(_table)['value']) {
      ifOp.Evaluate(_table);
    } else {
      elseOp?.Evaluate(_table);
    }
  }
}

class NullOp extends Node {
  NullOp() : super(null);

  @override
  dynamic Evaluate(SymbolTable _table) {
    return {"value": null, "type": null};
  }
}

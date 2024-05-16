import 'dart:io';
import 'main.dart';

int loopCounter = 0;

abstract class Node {
  int id = loopCounter++;
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
    Write write = Write();
    var rightResult = right.Evaluate(_table);
    write.code += "PUSH EAX\n";
    var leftResult = left.Evaluate(_table);
    write.code += "POP EBX\n";

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
        write.code += "ADD EAX, EBX\n";
        if (leftResult['type'] == 'string' || rightResult['type'] == 'string') {
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
        write.code += "SUB EAX, EBX\n";

        if (leftResult['type'] == 'integer' &&
            rightResult['type'] == 'integer') {
          return {
            'value': leftResult['value'] - rightResult['value'],
            'type': 'integer'
          };
        }
        break;

      case "TokenType.multiply":
        write.code += "IMUL EAX, EBX\n";

        if (leftResult['type'] == 'integer' &&
            rightResult['type'] == 'integer') {
          return {
            'value': leftResult['value'] * rightResult['value'],
            'type': 'integer'
          };
        }
        break;

      case "TokenType.divide":
        write.code += "IDIV EAX, EBX\n";
        if (leftResult['type'] == 'integer' &&
            rightResult['type'] == 'integer') {
          return {
            'value': leftResult['value'] ~/ rightResult['value'],
            'type': 'integer'
          };
        }
        break;

      case "TokenType.greater":
        write.code += "CMP EAX, EBX\n";

        write.code += "CALL binop_jg\n";

        if (leftResult['type'] == rightResult['type']) {
          return {
            'value': evalComparison(
                leftResult['value'], rightResult['value'], value),
            'type': 'boolean'
          };
        }
        break;

      case "TokenType.less":
        write.code += "CMP EAX, EBX\n";
        write.code += "CALL binop_jl\n";

        if (leftResult['type'] == rightResult['type']) {
          return {
            'value': evalComparison(
                leftResult['value'], rightResult['value'], value),
            'type': 'boolean'
          };
        }
        break;

      case "TokenType.equalEqual":
        write.code += "CMP EAX, EBX\n";
        write.code += "CALL binop_je\n";

        if (leftResult['type'] == rightResult['type']) {
          return {
            'value': evalComparison(
                leftResult['value'], rightResult['value'], value),
            'type': 'boolean'
          };
        }
        break;

      case "TokenType.and":
        write.code += "AND EAX, EBX\n";
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
      case "TokenType.or":
        write.code += "OR EAX, EBX\n";
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
  IntVal(int value) : super({'value': value, 'type': 'integer'});

  @override
  dynamic Evaluate(SymbolTable _table) {
    Write write = Write();

    write.code += "MOV EAX, ${value["value"]}\n";

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
    Write write = Write();
    var result = expr.Evaluate(_table);
    write.code += "PUSH EAX\n";
    write.code += "PUSH formatout\n";
    write.code += "CALL printf\n";
    write.code += "ADD ESP, 8\n";
    if (result["type"] == "boolean") {
      result["value"] = result["value"] ? 1 : 0;
    }
  }
}

class Identifier extends Node {
  final String name;
  Identifier(this.name) : super(null);

  @override
  dynamic Evaluate(SymbolTable _table) {
    Write write = Write();
    final offset = _table.getOffset(name);
    write.code += "MOV EAX, [EBP-${offset}]\n";
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
    Write write = Write();
    var exprResult = expr.Evaluate(_table);

    final offset = _table.getOffset(identifier.name);
    write.code += "MOV [EBP-${offset}], EAX\n";

    _table.set(
      key: identifier.name,
      value: exprResult['value'],
      type: exprResult['type'],
      isLocal: false,
    );
  }
}

class LocalAssignOp extends Node {
  final Identifier identifier;
  final Node expr;
  LocalAssignOp(this.identifier, this.expr) : super(null);

  @override
  dynamic Evaluate(SymbolTable _table) {
    Write write = Write();
    write.code += "PUSH DWORD 0\n";

    var exprResult = expr.Evaluate(_table);

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
    Write write = Write();
    write.code += "PUSH scanint\n";
    write.code += "PUSH formatin\n";
    write.code += "CALL scanf\n";
    write.code += "ADD ESP, 8\n";
    write.code += "MOV EAX, DWORD [scanint]\n";
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
  dynamic Evaluate(SymbolTable _table) {
    Write write = Write();
    write.code += "LOOP_${id}:\n";
    final conditionResult = condition.Evaluate(_table);
    write.code += "CMP EAX, False\n";
    write.code += "JE EXIT_${id}\n";

    final eval = block.Evaluate(_table);

    write.code += "JMP LOOP_${id}\n";
    write.code += "EXIT_${id}:\n";

    while (conditionResult["value"] && eval != null) {
      eval;
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
    Write write = Write();
    write.code += "IF_${this.id}:\n";

    final ifCondition = condition.Evaluate(_table)["value"];

    write.code += "CMP EAX, False\n";
    write.code += "JE ELSE_${id}\n";

    final ifBlock = ifOp.Evaluate(_table);

    write.code += "JMP EXIT_${id}\n";
    write.code += "ELSE_${id}:\n";

    final elseBlock = elseOp?.Evaluate(_table);

    write.code += "EXIT_${id}:\n";

    if (ifCondition) {
      ifBlock;
    } else {
      elseBlock;
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

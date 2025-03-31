import 'main.dart';

int loopCounter = 0;

abstract class Node {
  int id = loopCounter++;
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
    Write write = Write();
    right.Evaluate(_table, _funcTable);
    write.code += "PUSH EAX\n";
    left.Evaluate(_table, _funcTable);
    write.code += "POP EBX\n";

    switch (value) {
      case "TokenType.plus":
        write.code += "ADD EAX, EBX\n";
        break;
      case "TokenType.minus":
        write.code += "SUB EAX, EBX\n";
        break;
      case "TokenType.multiply":
        write.code += "IMUL EAX, EBX\n";
        break;
      case "TokenType.divide":
        write.code += "IDIV EBX\n";
        break;
      case "TokenType.greater":
        write.code += "CMP EAX, EBX\nCALL binop_jg\n";
        break;
      case "TokenType.less":
        write.code += "CMP EAX, EBX\nCALL binop_jl\n";
        break;
      case "TokenType.equalEqual":
        write.code += "CMP EAX, EBX\nCALL binop_je\n";
        break;
      case "TokenType.and":
        write.code += "AND EAX, EBX\n";
        break;
      case "TokenType.or":
        write.code += "OR EAX, EBX\n";
        break;
      default:
        throw Exception('Invalid operator');
    }
  }
}

class UnOp extends Node {
  final Node expr;
  UnOp(this.expr, String op) : super(op);

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    expr.Evaluate(_table, _funcTable);
    Write write = Write();

    if (value == "!") {
      write.code += "NOT EAX\n";
    } else if (value == "-") {
      write.code += "NEG EAX\n";
    } else if (value != "+") {
      throw Exception('Invalid unary operator');
    }
  }
}

class IntVal extends Node {
  IntVal(int value) : super({'value': value, 'type': 'integer'});

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    Write write = Write();
    write.code += "MOV EAX, ${this.value["value"]}\n";
  }
}

class StringVal extends Node {
  StringVal(String value) : super({'value': value, 'type': 'string'});

  @override
  dynamic Evaluate(SymbolTable _table, _funcTable) {
    // String values are handled differently in assembly, typically involving storing in memory and addressing
  }
}

class NoOp extends Node {
  NoOp() : super(null);

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    // No operation, no assembly code needed
  }
}

class PrintOp extends Node {
  final Node expr;
  PrintOp(this.expr) : super(null);

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    Write write = Write();
    expr.Evaluate(_table, _funcTable);
    write.code += "PUSH EAX\n";
    write.code += "PUSH formatout\n";
    write.code += "CALL printf\n";
    write.code += "ADD ESP, 8\n";
  }
}

class Identifier extends Node {
  final String name;
  Identifier(this.name) : super(null);

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    Write write = Write();
    print("Identifier_Table: ${_table.table}");
    final offset = _table.getOffset(name);
    offset > 0
        ? write.code += "MOV EAX, [EBP-${offset}]\n"
        : write.code += "MOV EAX, [EBP + ${offset.abs()}]\n";
  }
}

class AssignOp extends Node {
  final Identifier identifier;
  final Node expr;
  AssignOp(this.identifier, this.expr) : super(null);

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    Write write = Write();
    expr.Evaluate(_table, _funcTable);
    final offset = _table.getOffset(identifier.name);
    offset > 0
        ? write.code += "MOV [EBP-${offset}], EAX\n"
        : write.code += "MOV [EBP + ${offset.abs()}], EAX\n";
  }
}

class VarDecOp extends Node {
  final Identifier identifier;
  final Node expr;
  VarDecOp(this.identifier, this.expr) : super(null);

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    Write write = Write();
    write.code += "PUSH DWORD 0\n";

    expr.Evaluate(_table, _funcTable);

    _table.set(
      key: identifier.name,
      value: null,
      type: null,
      isLocal: true,
    );
  }
}

class Block extends Node {
  Block() : super(null);

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    for (var child in children) {
      child.Evaluate(_table, _funcTable);
    }
  }
}

class ReadOp extends Node {
  ReadOp() : super(null);

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    Write write = Write();
    write.code += "PUSH scanint\n";
    write.code += "PUSH formatin\n";
    write.code += "CALL scanf\n";
    write.code += "ADD ESP, 8\n";
    write.code += "MOV EAX, DWORD [scanint]\n";
  }
}

class WhileOp extends Node {
  final Node condition;
  final Node block;
  WhileOp(this.condition, this.block) : super(null);

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    Write write = Write();
    write.code += "LOOP_${id}:\n";
    condition.Evaluate(_table, _funcTable);
    write.code += "CMP EAX, False\nJE EXIT_${id}\n";
    block.Evaluate(_table, _funcTable);
    write.code += "JMP LOOP_${id}\nEXIT_${id}:\n";
  }
}

class IfOp extends Node {
  final Node condition;
  final Node ifOp;
  final Node? elseOp;

  IfOp(this.condition, this.ifOp, this.elseOp) : super(null);

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    Write write = Write();
    write.code += "IF_${id}:\n";
    condition.Evaluate(_table, _funcTable);
    write.code += "CMP EAX, False\nJE ELSE_${id}\n";
    ifOp.Evaluate(_table, _funcTable);
    write.code += "JMP EXIT_${id}\nELSE_${id}:\n";
    elseOp?.Evaluate(_table, _funcTable);
    write.code += "EXIT_${id}:\n";
  }
}

class NullOp extends Node {
  NullOp() : super(null);

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    // Null operation, no assembly code needed
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
    Write write = Write();
    write.code += "JMP END_${identifier.name}\n";
    write.code += "${identifier.name}:\n";
    write.code += "PUSH EBP\n";
    write.code += "MOV EBP, ESP\n";

    final localTable = SymbolTable.getNewInstance();

    for (var param in parameters) {
      localTable.setLocalFunction(
        key: param.name,
        value: null,
        type: null,
        aditionalOffset: 4,
        signal: -1,
      );
    }

    block.Evaluate(localTable, _funcTable);
    print("Local_Table: ${localTable.table}");

    write.code += "MOV ESP, EBP\n";
    write.code += "POP EBP\n";
    write.code += "RET\n";
    write.code += "END_${identifier.name}:\n";
  }
}

class FuncCallOp extends Node {
  final Identifier identifier;
  final List<Node> arguments;
  FuncCallOp(this.identifier, this.arguments) : super(null);

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    Write write = Write();

    final func = _funcTable.get(identifier.name);

    if (func.parameters.length != arguments.length) {
      throw Exception(
          'Function ${identifier.name} expects ${func.parameters.length} arguments, but ${arguments.length} were given');
    }

    print("Symbols: ${_table.table}");

    for (var i = arguments.length - 1; i >= 0; i--) {
      arguments[i].Evaluate(_table, _funcTable);
      write.code += "PUSH EAX\n";
    }

    write.code += "CALL ${identifier.name}\n";
    write.code += "ADD ESP, ${arguments.length * 4}\n";
  }
}

class ReturnOp extends Node {
  final Node expr;
  ReturnOp(this.expr) : super(null);

  @override
  dynamic Evaluate(SymbolTable _table, FuncTable _funcTable) {
    Write write = Write();
    expr.Evaluate(_table, _funcTable);
    write.code += "MOV ESP, EBP\n";
    write.code += "POP EBP\n";
    write.code += "RET\n";
  }
}

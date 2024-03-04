import 'dart:io';

class Token {
  String type; // Tipo do Token [int, operator, EOF]
  int value; // Valor do Token [0-9, +, -, EOF]

  Token(this.type, this.value);
}

class Tokenizer {
  String source; // Código-fonte que será tokenizado
  int position = 0; // Posição atual que o Tokenizador está separando
  late Token next; // O último token separado

  Tokenizer({required this.source});

  selectNext() {
    String number = "";
    while (position < source.length) {
      final character = source[position];
      if (character == "+") {
        if (number != "") {
          next = Token("int", int.parse(number));
          return;
        }
        next = Token("plus", 0);
        position++;
        return;
      } else if (character == "-") {
        if (number != "") {
          next = Token("int", int.parse(number));
          return;
        }
        next = Token("minus", 0);
        position++;
        return;
      } else if (character == "*") {
        if (number != "") {
          next = Token("int", int.parse(number));
          return;
        }
        next = Token("multiply", 0);
        position++;
        return;
      } else if (character == "/") {
        if (number != "") {
          next = Token("int", int.parse(number));
          return;
        }
        next = Token("division", 0);
        position++;
        return;
      } else if (character == "0" ||
          character == "1" ||
          character == "2" ||
          character == "3" ||
          character == "4" ||
          character == "5" ||
          character == "6" ||
          character == "7" ||
          character == "8" ||
          character == "9") {
        number += character;
      }
      position++;
    }
    if (number != "") {
      next = Token("int", int.parse(number));
      return;
    }
    next = Token("EOF", 0);
    return;
  }
}

class Parser {
  late Tokenizer
      tokenizer; // Objeto da classe que irá ler o código fonte e alimentar o Analisador

  List<String> operators = ["plus", "minus", "multiply", "division", "EOF"];

  int parseExpression() {
    int result = 0;
    bool isSum = true;
    bool isMultiply = true;
    bool wasTerm = false;

    tokenizer.selectNext();
    Token actualToken = tokenizer.next;

    if (operators.contains(actualToken.type)) {
      throw ("Invalid Operator Order");
    }

    // Initial operation

    result = actualToken.value;

    tokenizer.selectNext();
    actualToken = tokenizer.next;

    while (actualToken.type != "EOF") {
      if (actualToken.type == "int") {
        tokenizer.selectNext();
        if (tokenizer.next.type == "multiply" ||
            tokenizer.next.type == "division") {
          int aux = 1;
          if (actualToken.type == "int") {
            aux = actualToken.value;
          }
          actualToken = tokenizer.next;
          isMultiply = tokenizer.next.type == "multiply";
          aux = term(actualToken, isMultiply, aux, operators);
          if (isSum) {
            result += aux;
          } else {
            result -= aux;
          }
          isSum = tokenizer.next.type == "plus";
        } else if (isSum) {
          result += actualToken.value;
        } else if (tokenizer.next.type == "EOF") {
          if (isSum) {
            result += actualToken.value;
          } else {
            result -= actualToken.value;
          }
          break;
        } else {
          result -= actualToken.value;
        }
      } else {
        // In case there is only multiplication or division
        if (tokenizer.next.type == "multiply" ||
            tokenizer.next.type == "division") {
          wasTerm = true;
          final aux = term(actualToken, isMultiply, result, operators);
          result = aux;
        }
        isSum = tokenizer.next.type == "plus";
        tokenizer.selectNext();
        if (tokenizer.next.type == "EOF" && wasTerm) {
          return result;
        } else if (tokenizer.next.type == "EOF" && !wasTerm) {
          throw ("Invalid Operator Order");
        } else if (tokenizer.next.type == "plus") {
          throw ("Invalid Operator Order");
        } else if (tokenizer.next.type == "minus") {
          throw ("Invalid Operator Order");
        }
      }
      actualToken = tokenizer.next;
    }

    return result;
  }

  int term(
      Token actualToken, bool isMultiply, int result, List<String> operators) {
    while (actualToken.type != "EOF") {
      if (actualToken.type == "int") {
        tokenizer.selectNext();
        if (isMultiply) {
          result *= actualToken.value;
        } else if (tokenizer.next.type == "EOF") {
          if (isMultiply) {
            result *= actualToken.value;
          } else {
            result ~/= actualToken.value;
          }
          break;
        } else {
          result ~/= actualToken.value;
        }
      } else {
        // If the next token is Minus or Plus, it needs to return the result
        if (tokenizer.next.type == "minus" || tokenizer.next.type == "plus") {
          return result;
        }
        isMultiply = tokenizer.next.type == "multiply";
        tokenizer.selectNext();
        if (operators.contains(tokenizer.next.type)) throw ("Invalid Input");
      }
      if (tokenizer.next.type != "EOF" && tokenizer.next.type != "int") {
        isMultiply = tokenizer.next.type == "multiply";
      }
      actualToken = tokenizer.next;
    }
    return result;
  }

  int run(String code) {
    // Inicia a análise do código fonte, retorna o resultado da expressão analisada, caso o token seja EOF, finaliza.
    if (code.contains(" ") &&
        !code.contains("+") &&
        !code.contains("-") &&
        !code.contains("*") &&
        !code.contains("/")) {
      throw ("Invalid Input");
    }
    tokenizer = Tokenizer(source: code);
    final result = parseExpression();
    stdout.writeln(result);
    return result;
  }
}

void main(List<String> args) {
  Parser parser = Parser();
  parser.run(args[0]);
}

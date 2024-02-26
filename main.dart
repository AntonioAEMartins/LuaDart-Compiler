

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

  int parseExpression() {
    int result = 0;
    bool isSum = true;

    tokenizer.selectNext();
    Token actualToken = tokenizer.next;

    if (actualToken.type == "EOF") {
      throw ("Invalid Input");
    } else if (actualToken.type == "plus") {
      throw ("Invalid Input");
    } else if (actualToken.type == "minus") {
      throw ("Invalid Input");
    }

    while (actualToken.type != "EOF") {
      if (actualToken.type == "int") {
        tokenizer.selectNext();
        if (isSum) {
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
        isSum = tokenizer.next.type == "plus";
        tokenizer.selectNext();
        // Checando se é válido, caso tenha terminado com + ou - é inválid
        if (tokenizer.next.type == "EOF") {
          throw ("Invalid Input");
        }
      }
      actualToken = tokenizer.next;
    }
    return result;
  }

  int run(String code) {
    // Inicia a análise do código fonte, retorna o resultado da expressão analisada, caso o token seja EOF, finaliza.
    tokenizer = Tokenizer(source: code);
    final result = parseExpression();
    return result;
  }
}

void main(List<String> args) {
  Parser parser = Parser();
  parser.run(args[0]);
}

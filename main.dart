// void main(List<String> args) {
//   List<String> digits = [];
//   List<String> operators = [];
//   int numberDivisors = 0;
//   bool isNumberLoop = false;
//   bool isInvalid = false;

//   // Discovering the Number of Digits
//   if (args.isEmpty) {
//     throw ("Invalid Input");
//   } else if (args[0] == "") {
//     throw ("Invalid Input");
//   }

//   for (final arg in args) {
//     arg.runes.forEach((int rune) {
//       final character = new String.fromCharCode(rune);
//       if (character == "+" || character == "-") {
//         numberDivisors++;
//         operators.add(character);
//         if (isNumberLoop) {
//           isInvalid = false;
//         }
//         isNumberLoop = false;
//         if (digits.length == 0) {
//           isInvalid = true;
//         }
//       } else if (character == "0" ||
//           character == "1" ||
//           character == "2" ||
//           character == "3" ||
//           character == "4" ||
//           character == "5" ||
//           character == "6" ||
//           character == "7" ||
//           character == "8" ||
//           character == "9") {
//         // Is the First Digit of the list
//         isNumberLoop = true;
//         if (digits.isEmpty || digits.length == numberDivisors) {
//           digits.add(character);
//         } else {
//           digits[numberDivisors] += character;
//         }
//       } else {
//         isInvalid = true;
//       }
//     });
//   }

//   if (isInvalid) {
//     throw ("Invalid Input");
//   }

//   // Validating the Input
//   if (digits.length - 1 != operators.length) {
//   } else if (digits.length == 0) {
//     throw ("Invalid Input");
//   } else if (digits.length == 1) {
//     if (operators.length == 1) {
//       throw ("Invalid Input");
//     }
//   } else if (digits.length == 2) {
//     if (operators.length == 0) {
//       throw ("Invalid Input");
//     }
//   } else if (digits.length == operators.length)

//   // Creating the Result

//   // -  If There is only on Number
//   if (digits.length == 1) {
//     print("${digits[0]}");
//     return;
//   }

//   int indexDigits = 0;
//   int result = 0;

//   for (final operator in operators) {
//     // For the First Run, the Result will be equal to the First Number (Operator) Second Number
//     if (operator == "+") {
//       if (indexDigits == 0) {
//         result =
//             int.parse(digits[indexDigits]) + int.parse(digits[indexDigits + 1]);
//       } else {
//         result += int.parse(digits[indexDigits + 1]);
//       }
//     } else if (operator == "-") {
//       if (indexDigits == 0) {
//         result =
//             int.parse(digits[indexDigits]) - int.parse(digits[indexDigits + 1]);
//       } else {
//         result -= int.parse(digits[indexDigits + 1]);
//       }
//     }
//     indexDigits++;
//   }

//   print("$result");
// }

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
    // print("Source: $source");
    while (position < source.length) {
      final character = source[position];
      // print("position: $position");
      // print("character: $character");
      // print("length: ${source.length}");
      if (character == "+") {
        if (number != "") {
          print("--- Saída 1 ---");
          next = Token("int", int.parse(number));
          // position++;
          return;
        }
        print("--- Saída 2 ---");
        next = Token("plus", 0);
        position++;
        return;
      } else if (character == "-") {
        if (number != "") {
          next = Token("int", int.parse(number));
          print("--- Saída 3 ---");
          // position++;
          return;
        }
        print("--- Saída 4 ---");
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
        print("--- Saída 5 ---");
        number += character;
      }
      position++;
    }
    // EOF Token
    print("Number: $number");
    if (number != "") {
      next = Token("int", int.parse(number));
      return;
    }
    next = Token("EOF", 0);
    print("EOF");
    return;
  }
}

class Parser {
  late Tokenizer
      tokenizer; // Objeto da classe que irá ler o código fonte e alimentar o Analisador

  // Parser({required this.tokenizer});

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
        print("Next Token Type: ${tokenizer.next.type}");
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
    print(result);
    return result;
  }
}

void main(List<String> args) {
  Parser parser = Parser();
  parser.run(args[0]);
}

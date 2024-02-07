void main(List<String> args) {
  List<String> digits = [];
  List<String> operators = [];
  int numberDivisors = 0;
  bool isNumberLoop = false;
  bool isInvalid = false;

  // Discovering the Number of Digits

  for (final arg in args) {
    arg.runes.forEach((int rune) {
      final character = new String.fromCharCode(rune);
      if (character == "+" || character == "-") {
        numberDivisors++;
        operators.add(character);
        if (isNumberLoop) {
          isInvalid = false;
        }
        isNumberLoop = false;
        if (digits.length == 0) {
          throw ("Invalid Input");
        }
      }
      if (character == "0" ||
          character == "1" ||
          character == "2" ||
          character == "3" ||
          character == "4" ||
          character == "5" ||
          character == "6" ||
          character == "7" ||
          character == "8" ||
          character == "9") {
        // Is the First Digit of the list
        isNumberLoop = true;
        if (digits.isEmpty || digits.length == numberDivisors) {
          digits.add(character);
        } else {
          digits[numberDivisors] += character;
        }
      } else {
        if (isNumberLoop) {
          isInvalid = true;
        }
      }
    });
  }

  if (isInvalid) {
    throw ("Invalid Input");
  }

  // Validating the Input
  if (digits.length - 1 != operators.length) {
  } else if (digits.length == 0) {
    throw ("Invalid Input");
  } else if (digits.length == 1) {
    if (operators.length == 1) {
      throw ("Invalid Input");
    }
  } else if (digits.length == 2) {
    if (operators.length == 0) {
      throw ("Invalid Input");
    }
  }

  // Creating the Result

  // -  If There is only on Number
  if (digits.length == 1) {
    print("${digits[0]}");
    return;
  }

  int indexDigits = 0;
  int result = 0;

  for (final operator in operators) {
    // For the First Run, the Result will be equal to the First Number (Operator) Second Number
    if (operator == "+") {
      if (indexDigits == 0) {
        result =
            int.parse(digits[indexDigits]) + int.parse(digits[indexDigits + 1]);
      } else {
        result += int.parse(digits[indexDigits + 1]);
      }
    } else if (operator == "-") {
      if (indexDigits == 0) {
        result =
            int.parse(digits[indexDigits]) - int.parse(digits[indexDigits + 1]);
      } else {
        result -= int.parse(digits[indexDigits + 1]);
      }
    }
    indexDigits++;
  }

  print("$result");
}

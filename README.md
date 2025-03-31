# 🚀 Lua Compiler - Computational Logic

![git status](http://3.129.230.99/svg/AntonioAEMartins/Compiler-Computacional-Logic/)

## 📝 Overview

This repository contains a Lua to Assembly compiler implemented in Dart. The compiler follows the principles of computational logic to transform Lua source code into executable assembly code. The project showcases the evolution of the compiler through three main versions, each adding new features and improvements.

## 🔄 Compiler Versions

### 🏗️ V2.4 - Initial Implementation
- Basic tokenization of Lua code
- Syntax analysis based on provided syntax diagram
- Expression parsing and evaluation
- Initial operand handling

### 🛠️ V3.0 - Assembly Generation
- Extended tokenization capabilities
- Implementation of assembly code generation
- Addition of header and footer templates for assembly output
- Complete compilation pipeline from Lua to ASM

### ⚡ V3.1 - Optimizations and Improvements
- Enhanced expression handling
- More efficient code generation
- Support for additional Lua language features
- Improved error handling and reporting

## 🧩 Project Structure

Each version of the compiler follows a similar structure:

- `main.dart` - Entry point and core compiler logic
- `tokenizer.dart` - Lexical analysis of Lua source code
- `operands.dart` - Handling of operands and operations
- `filters.dart` - Additional filtering and preprocessing
- `header.asm`/`footer.asm` - Templates for assembly output
- Sample input/output files (`.lua` and `.asm`)

## 🔍 Compilation Process

1. **Lexical Analysis**: Tokenization of Lua source code
2. **Syntax Analysis**: Parsing according to the syntax diagram
3. **Semantic Analysis**: Verification of program meaning
4. **Code Generation**: Translation to assembly language

## 📊 Syntax Diagram

The compiler follows a formal syntax diagram (see `diagrama_sintatico.jpg`) that defines the grammar rules for the subset of Lua language supported by this compiler.

## 🚦 Getting Started

### Prerequisites
- Dart SDK (version 2.x or higher)

### Running the Compiler
```bash
# Navigate to the desired version
cd compiler-V3.1

# Run the compiler with a Lua input file
dart main.dart program.lua
```

## 📚 Supported Features

- Variable declarations and assignments
- Arithmetic operations
- Conditional statements
- Basic loops
- Function calls
- String operations
- Logical expressions

## 🔧 Future Improvements

- Support for more Lua language features
- Enhanced optimization techniques
- Better error recovery mechanisms
- Expanded standard library support

## 📄 License

This project is open-source and available under the [MIT License](LICENSE).

## 👥 Contributors

- [AntonioAEMartins](https://github.com/AntonioAEMartins)

---

�� Happy Compiling!

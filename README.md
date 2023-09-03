# NTNU-MicroEx-Compiler

A compiler for **Micro/Ex** language written in C++, using yacc and lex.
(Chinese version see [here](/README.zh-TW.md))

## Install

You can use the following command to get the full code and testing data:
```bash
git clone https://github.com/OwOb/NTNU-MicroEx-Compiler
cd NTNU-MicroEx-Compiler
```

## Build
Before building the compiler, you need to install flex and bison.
You can use the following commands for Ubuntu:
```bash
sudo apt-get install flex
sudo apt-get install bison
```

Then, just use `make` command to build the compiler.
```bash
make
```

## Usage
After building, it will generate a file named `micro-ex`, which is our compiler.
To compile the code in Micro/Ex language use the following command:
```bash
./micro-ex < [input-file] > [output-file]
```

## Features

The compiler supports the following syntax:
* Declaration
* Arithmetic
* Assignment
* For loop
* While loop
* Conditional statement
* Nested structure

## Example
Input file:
```
Program test_11

Begin
    declare mul[100], i, j as Integer;

    FOR (i := 1 TO 10)
        FOR (j := 9 DOWNTO 0)
            IF (i*j < 50) THEN
                mul[i*10+j] := i*j;
            ELSE
                mul[i*10+j] := i*j - 50;
            ENDIF
        ENDFOR
        IF (i < 5) THEN
            FOR (j := 9 DOWNTO 0)
                mul[i*10+j] := mul[i*10+j] + 10;
            ENDFOR
        ELSE
            FOR (j := 9 DOWNTO 0)
                mul[i*10+j] := mul[i*10+j] - 10;
            ENDFOR
        ENDIF
    ENDFOR

    declare sum, a, b, c, d as Integer;

    scan(a, b, c, d);
    sum := 0;
    FOR (i := 0 TO a+b*c STEP d-1)
        IF (mul[i] > 20) THEN
            j := 0;
            WHILE (j != 10)
                sum := sum + j * mul[i];
                j := j+1;
            ENDWHILE
        ENDIF
    ENDFOR

    print(sum);
End
```
Expected output file:
```
	START test_11
	Declare mul, Integer_array, 100
	Declare i, Integer
	Declare j, Integer
	I_Store 1,i
lb&1:	I_Store 9,j
lb&2:	I_MUL i,j,T&1
	I_CMP T&1,50
	JGE lb&3
	I_MUL i,10,T&2
	I_ADD T&2,j,T&3
	I_MUL i,j,T&4
	I_Store T&4,mul[T&3]
	J lb&4
lb&3:	I_MUL i,10,T&5
	I_ADD T&5,j,T&6
	I_MUL i,j,T&7
	I_SUB T&7,50,T&8
	I_Store T&8,mul[T&6]
lb&4:	DEC j
	I_CMP j,0
	JG lb&2
	I_CMP i,5
	JGE lb&5
	I_Store 9,j
lb&6:	I_MUL i,10,T&9
	I_ADD T&9,j,T&10
	I_MUL i,10,T&11
	I_ADD T&11,j,T&12
	I_ADD mul[T&12],10,T&13
	I_Store T&13,mul[T&10]
	DEC j
	I_CMP j,0
	JG lb&6
	J lb&7
lb&5:	I_Store 9,j
lb&8:	I_MUL i,10,T&14
	I_ADD T&14,j,T&15
	I_MUL i,10,T&16
	I_ADD T&16,j,T&17
	I_SUB mul[T&17],10,T&18
	I_Store T&18,mul[T&15]
	DEC j
	I_CMP j,0
	JG lb&8
lb&7:	INC i
	I_CMP i,10
	JL lb&1
	Declare sum, Integer
	Declare a, Integer
	Declare b, Integer
	Declare c, Integer
	Declare d, Integer
	CALL scan,a,b,c,d
	I_Store 0,sum
	I_Store 0,i
	I_MUL b,c,T&19
	I_ADD a,T&19,T&20
	I_SUB d,1,T&21
lb&9:	I_CMP mul[i],20
	JLE lb&10
	I_Store 0,j
lb&11:	I_CMP j,10
	JE lb&12
	I_MUL j,mul[i],T&22
	I_ADD sum,T&22,T&23
	I_Store T&23,sum
	I_ADD j,1,T&24
	I_Store T&24,j
	J lb&11
lb&12:
lb&10:	I_ADD i,T&21,i
	I_CMP i,T&20
	JL lb&9
	CALL print,sum
	HALT test_11
	Declare T&1, Integer
	Declare T&2, Integer
	Declare T&3, Integer
	Declare T&4, Integer
	Declare T&5, Integer
	Declare T&6, Integer
	Declare T&7, Integer
	Declare T&8, Integer
	Declare T&9, Integer
	Declare T&10, Integer
	Declare T&11, Integer
	Declare T&12, Integer
	Declare T&13, Integer
	Declare T&14, Integer
	Declare T&15, Integer
	Declare T&16, Integer
	Declare T&17, Integer
	Declare T&18, Integer
	Declare T&19, Integer
	Declare T&20, Integer
	Declare T&21, Integer
	Declare T&22, Integer
	Declare T&23, Integer
	Declare T&24, Integer
```

You can find more testing data in `test` directory.

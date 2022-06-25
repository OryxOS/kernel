# Coding Style

when submitting a pull request, it important to follow the OryxOS Coding Style, this keeps the code base clean and consistent.

## Basics:

- Structs, enums, enum-variants and constant names: ``PascalCase``
- Function and variable names: ``camelCase``
- Tabs for indentation, spaces for alignment
- ``enum`` keyword is to be used for constants where possible
- Bracket-less control flow is encouraged

```d
struct Structure {
    ulong a;
    uint  b;
    char  c;  // Note how struct-members are aligned
}

// Acronyms are stylized as such:
struct GdtPointer {
    ...
}

enum ColorRed = 0xFFF // Hexadecimals are capitalised

enum Jobs {
    Cleaner,
    Engineer, // Note the last Comma
}

void sayHello(string name) {
    // Bracket-less if statement
    if (name == "Rob") // Note the spacing between the `if` and the `(`
        writefln("Welcome back Rob");
	else
		writefln("Hello %s", name);
}
```



## for (...) vs foreach (...)

- Use foreach wherever possible - it is shorter and cleaner
- For cases when the accumulator is not needed use the syntax ``foreach (_; 0..1000)``



## shared vs __gshared

although, ``shared`` is better for userspace applications, it is simply impractical for kernel code as kernels simply rely too heavily on C-style globals

## Casting 

- If a cast is used in a variable declaration, use the ``auto`` keyword - it saves unnecessary repetition

- use the syntax ``cast(T) variable`` - note the space and lack of brackets around the variable

  

## General File Structure

```d
module blah; // Module declaration

// Imports should form a pyramid

// Library imports
import lib.util;
import lib.limine;

// Other imports
import arch.amd64.memory;
import arch.acpi;

/* General comment, should explain the purpose and design of the system
 * contained in the file. Should be kept at 70 chars per line.
 */

/* Typically, files tend to have a library side and an 'instance', for
 * example, GDT managment code and the actual GDT, these are to be
 * seperated as such, with the instance following the library side:
 */

//////////////////////////////
//         Instance         //
//////////////////////////////

...
```




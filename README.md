# Kyubi Language Overview

Welcome in **Kyubi**, a queue-based programming language!

In Kyubi, we manipulate the **queue** data structure, which is built in.
You can use native operators to enqueue values into a queue.

Each name is, from the beginning, associated with an **empty queue**.
As a result, there is no way of handling shadowing or variable definition;
naming should therefore follow conventions.

---

## Machines and Queues

Saying that *everything is a queue* in Kyubi is conceptually true,
but everything is actually a **machine with an attached behavior**.

From the programmer’s point of view, a machine has:
- an **input queue**
- an **output queue**

Each machine has one or multiple attached **behaviors**.
A behavior is basically Kyubi’s name for a *function* in the functional programming sense.

Behaviors are **chained together**, and between each behavior there is a value queue:
- the **input queue** of behavior *n*
- the **output queue** of behavior *n − 1*

The input queue of the first behavior takes input directly from the program.
The output queue of the last behavior outputs directly to the program.

---

## Behavior Execution Semantics

You can enqueue values in a machine’s input queue, and later use the system

- If the input buffer has **3 elements** and the behavior takes **4 elements**,
  you will produce a *behavior as a value* which still needs **1 value**.
- If you directly give the **4 values**, the output is produced immediately.
- If you give **more than 4**, only the first 4 elements are consumed;
  the remaining ones stay in the input buffer.

A call to `behave` will **always make all behaviors behave once**, in the order
they are chained, producing value(s) once.

This can lead to many silent mistakes: it is unsafe, but very elegant.

---

## Default Machines

The default queue associated with all names is a **machine with no behavior**.
This means it is effectively a single queue that takes input from the program
and outputs to the program.

Saying that each machine has two queues is actually **absolutely wrong**:
a machine composed of *n* behaviors involves *n + 1* queues.
However, you can only interact with **two of them**.

---

## Error Model

There is **NO error design** in Kyubi.

Kyubi **never fails at runtime**.

---

## Syntax

- `left -> right`  
  Dequeue one value from the output buffer of `left` into the input buffer of `right`.

- `left -3> right`  
  Same as `->`, but dequeue/enqueue **3 values**.

- `left -_> right`  
  Dequeue **all values** of the queue `left` into the queue `right`.

- `-->`  Make a queue behave and then dequeue. 
- `-3->`  Make a queue 3 times behave and then dequeue 1 time
- `-3-3>`  Make a queue 3 times behave and then dequeue 3 time
- `-3_>`  Make a queue 3 times behave and then dequeue everything it has

You can use `=>`, `=3>`, `=_>` to interact with the **behavior queues**.

If you put a **value** as the left argument of `->`,
the value is schematically considered as an **anonymous queue of one element**.

You can also declare anonymous queues like this:

```kyubi
[1, 2, 3]
```

There is currently no syntax to create anonymous queues with behaviors.

## Example 

```kyubi
{'x 'y:           // Creates a literal behavior taking 2 arguments ('x represents a generic value)

     'x -> +;     // Now we have ['x |]
     'y -> +;     // Now we have ['x 'y |]
     + -->;        // produce and dequeue the output

     34 ->;       // Also output 34 (why not?)
                  // So the behavior produces 2 values
} => f;           // Enqueue the behavior into f

[10, 11] -2> q;        // Enqueue 10 and 11 into q
q -2> f;               // Dequeue q twice into f which triggers it's internal behavior

f --> print            // We make f behave in print
print -2_> side_effect // Print everything
```

# Another example

Here we use the chaining behavior system to define x + y + z

```kyubi

{ 'x 'y
    ['x, 'y] _> + -->; // Just take x and y and output it
} => add;               // enqueue this in add


{ 'x 'y 'z
   ['x, 'y] _> + -->;  // outputs x + y
   'z ->;               // also output 'z as it is
} => add;               // Also enqueue in add, so it is in first position


[1, 2, 3] _> add --> print --> side_effect; // add will behave twice and output 6

```

Without chaining you can do it in one pipeline for 4 values using
complex operators:
```kyubi 
[1, 2, 3, 4] _> + -_> + --> print --> side_effect
```

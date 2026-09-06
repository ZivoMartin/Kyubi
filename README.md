# Kyubi

Kyubi is a dataflow programming language built around **queues** and **production chains**.

Instead of calling functions and returning values, a Kyubi program moves values between named queues. Behaviors can be attached to queues, turning them into processing stages. Values can then be pushed through these stages explicitly.

A simple Kyubi program looks like this:

```text
1 -> +
2 -> +
+ --> result
```

Here:

1. `1` is inserted into the queue `+`.
2. `2` is inserted into the queue `+`.
3. `+` is a built-in behavior that consumes two numbers and produces their sum.
4. `-->` activates the behavior and transfers its result into `result`.

After execution:

```text
result = [3]
```

The important mental model is:

> **Values flow through queues. Behaviors turn queues into processing pipelines.**

---

# 1. Values

Kyubi currently has three main kinds of values:

```text
42
()
{ 'x: ... }
```

These correspond to:

* integers;
* the unit value `()`;
* behaviors.

For example:

```text
34 -> q
() -> q
```

inserts two values into `q`.

Negative integer literals are not currently part of the literal syntax. `-` is an identifier/operator-related symbol rather than a unary numeric sign.

---

# 2. Kyus: named queues

The central abstraction of the language is the **kyu**.

A kyu is essentially a queue that may also contain a chain of behaviors.

Names such as:

```text
q
q1
tmp
result
f
```

refer to kyus.

A kyu does not need to be declared before it is used.

```text
34 -> q1
```

creates `q1` if necessary and inserts `34`.

Values are FIFO:

```text
1 -> q
2 -> q
3 -> q
```

conceptually gives:

```text
q = [1, 2, 3]
```

A basic movement between queues is:

```text
q1 -> q2
```

This removes the first value from `q1` and inserts it into `q2`.

For example:

```text
67 -> q1
69 -> q1

q1 -> q2
```

leaves approximately:

```text
q1 = [69]
q2 = [67]
```

Repeated movements continue consuming values from the front.

---

# 3. Series

Square brackets provide a convenient way of starting several flows at once.

Instead of:

```text
1 -> q
2 -> q
3 -> q
4 -> q
```

you can write:

```text
[1, 2, 3, 4] -> q
```

This does **not** create a list value.

It is equivalent to sending each element through the following flow.

For example:

```text
[1, 2, 3, 4] -> q1 -3> q2
```

first inserts all four numbers into `q1`, then the flow transfers three elements from `q1` to `q2`.

Series may also contain behaviors:

```text
[
    { 'x: 'x -> @ },
    1,
    2
] -> q
```

---

# 4. Flow operators

Most Kyubi programs are chains of operations:

```text
value -> queue -> queue --> queue
```

Kyubi has several related flow operators.

| Operator | Meaning                       |
| -------- | ----------------------------- |
| `->`     | move/enqueue values           |
| `-->`    | produce, then move output     |
| `~>`     | attach/move behaviors         |
| `-~>`    | promote values into behaviors |
| `~->`    | demote behaviors into values  |
| `=>`     | duplicate/peek values         |

Most operators can additionally contain a **flow size**.

A flow size is:

```text
1
2
3
...
_
```

where `_` means **as many as possible**.

When no size is written, one element/production is implied.

---

# 5. Moving values with `->`

The simplest operator is:

```text
->
```

For a literal on the left:

```text
34 -> q
```

inserts the value into `q`.

For two queues:

```text
q1 -> q2
```

moves one value from `q1` into `q2`.

A number specifies how many values should be transferred:

```text
q1 -3> q2
```

moves three values.

For example:

```text
[1, 2, 3, 4] -> q1
q1 -3> q2
```

leaves:

```text
q1 = [4]
q2 = [1, 2, 3]
```

The special size `_` means "all available values":

```text
q1 -_> q2
```

For example:

```text
[1, 2, 3, 4] -> q1
q1 -_> q2
```

moves everything from `q1` into `q2`.

---

# 6. Built-in behaviors

Kyubi currently provides four built-ins:

```text
+
-
!print
!println
```

`+` and `-` consume two arguments.

`!print` and `!println` consume one argument.

## Addition

```text
1 -> +
2 -> +
+ --> result
```

produces:

```text
3
```

The builtin `+` can be thought of as:

```text
(x, y) -> x + y
```

## Subtraction

```text
6 -> -
1 -> -
- --> result
```

produces:

```text
5
```

Subtraction preserves input order:

```text
x -> -
y -> -
- --> result
```

computes:

```text
x - y
```

## Printing

```text
1 -> !print --> side_effect
2 -> !println --> side_effect
```

`!print` prints without a newline.

`!println` prints with a newline.

Both produce `()` afterward, so their result can continue through the dataflow.

---

# 7. Production with `-->`

Plain `->` only moves values.

To actually execute a behavior attached to a kyu, use a **production operator**:

```text
-->
```

For example:

```text
1 -> +
2 -> +

+ --> result
```

does two different things:

```text
1 -> +
2 -> +
```

enqueue arguments.

Then:

```text
+ --> result
```

runs one production of `+` and moves one produced value into `result`.

This distinction is fundamental.

```text
q1 -> q2
```

means:

> move a value.

while:

```text
q1 --> q2
```

means:

> run the production chain associated with `q1`, then move its output.

---

# 8. Production sizes

`-->` actually contains two independently controllable quantities:

```text
-N-M>
```

Conceptually:

```text
-N-M>
 │  │
 │  └── number of output values to transfer
 └───── number of productions to perform
```

For example:

```text
q -4-2> result
```

means:

1. perform four productions on `q`;
2. transfer two values from the resulting output.

Leaving either number absent means one.

Therefore:

```text
q --> result
```

is equivalent conceptually to:

```text
q -1-1> result
```

and:

```text
q --2> result
```

means:

> perform one production and transfer two outputs.

This is useful when a behavior generates multiple values.

For example, suppose `f` produces two values:

```text
{'x 'y:
    'x -> +
    'y -> +

    + --> @
    34 -> @
} ~> f
```

Then:

```text
[10, 11] -> f
f --2> result
```

produces two outputs:

```text
21
34
```

You may also combine explicit and unbounded sizes:

```text
+ -4-2> +
+ --_> +
```

---

# 9. Behaviors

Behaviors are Kyubi's equivalent of reusable pieces of computation.

A behavior has the form:

```text
{ 'arg1 'arg2:
    ...
}
```

For example:

```text
{ 'x:
    2 -> +
    'x -> +
    + --> @
}
```

defines a behavior taking one input called `'x`.

Inside the behavior, runtime arguments are referenced using the leading `'`:

```text
'x
```

A two-argument behavior looks like:

```text
{ 'x 'y:
    'x -> +
    'y -> +
    + --> @
}
```

---

# 10. Attaching a behavior with `~>`

A behavior is attached to a kyu using:

```text
~>
```

For example:

```text
{ 'x:
    2 -> +
    'x -> +
    + --> @
} ~> add_two
```

creates a processing stage in `add_two`.

It can then be used like this:

```text
10 -> add_two
add_two --> result
```

producing:

```text
12
```

A useful way of reading:

```text
behavior ~> f
```

is:

> attach this behavior as a production stage of `f`.

A behavior is therefore not called using syntax like:

```text
f(10)
```

Instead:

```text
10 -> f
f --> result
```

pushes data into the processing queue and then asks it to produce.

---

# 11. Behavior input and output

Inside a behavior, two special kyus exist:

```text
$
@
```

They mean:

```text
$    input
@    output
```

## `@`: behavior output

A value sent to `@` becomes an output of the behavior.

For example:

```text
{ 'x:
    'x -> @
} ~> identity
```

is an identity behavior.

```text
10 -> identity
identity --> result
```

produces:

```text
10
```

A behavior may produce several values:

```text
{ 'x:
    'x -> @
    34 -> @
} ~> f
```

Calling one production of `f` produces both values.

They can be transferred with:

```text
f --2> result
```

## `$`: behavior input

`$` exposes the input queue of the currently executing behavior.

This is particularly useful for behaviors that do not declare named arguments.

For example:

```text
{:
    $ -2> @
} ~> f
```

declares no named arguments and manually moves two input values to its output.

Then:

```text
10 -> f
11 -> f
f --2> result
```

produces:

```text
10
11
```

Another example:

```text
{
    $ -> +
    $ -> +
    + --> @
} ~> f
```

manually consumes two values, adds them, and emits the result.

Named parameters and `$` therefore represent two ways of accessing behavior input.

---

# 12. Behavior pipelines

A kyu may contain more than one behavior.

This means a kyu can represent an entire **production chain**, not merely one function.

Consider:

```text
{ 'x 'y:
    'x -> +
    'y -> +

    + --> @
    34 -> @
} ~> f
```

and then attach another behavior:

```text
{ 'x 'y:
    'x -> add_two --> @
    'y -> add_two --> @
} ~> f
```

Now `f` contains multiple processing stages.

When production occurs, output from one stage becomes input to another stage.

A useful consequence is that complicated computations can be assembled by attaching behaviors to queues rather than constructing nested function calls.

Kyubi is therefore closer to:

```text
input -> stage1 -> stage2 -> stage3 -> output
```

than:

```text
stage3(stage2(stage1(input)))
```

Internally, adding a behavior creates a new entry queue while preserving the previous queue as that behavior's output, which is what allows these stages to form a chain.

---

# 13. Moving behaviors with `~>`

`~>` can also move existing behaviors between kyus.

For example:

```text
f ~2> g
```

moves two behavior stages from `f` to `g`.

Without a flow size:

```text
f ~> g
```

moves one.

As with value movement:

```text
f ~_> g
```

moves as many behaviors as possible.

This allows production chains themselves to be manipulated dynamically.

---

# 14. Behaviors are values

One of Kyubi's more unusual features is that behaviors can exist both:

1. as ordinary values;
2. as active production stages.

For example, this behavior:

```text
{ 'x:
    'x -> @
}
```

can be inserted as an ordinary value:

```text
{ 'x:
    'x -> @
} -> q
```

At this point it is merely data stored in `q`.

It is **not** an active stage of `q`.

Compare:

```text
{ 'x:
    'x -> @
} ~> q
```

which installs it as a behavior.

This distinction enables dynamic manipulation of programs.

---

# 15. Promoting behaviors with `-~>`

A behavior stored as a normal value can be converted into an active behavior with:

```text
-~>
```

For example:

```text
{ 'x:
    'x -> @
} -> q
```

stores the behavior as a value.

Then:

```text
q -~> identity
```

takes that value from `q` and installs it as an active production stage of `identity`.

You can then write:

```text
10 -> identity
identity --> result
```

This operation is called **promotion**.

A larger example:

```text
[
    { 'x: 'x -> @ },
    1,
    2
] -> q

q -~> q
```

takes the first value — which is a behavior — and promotes it into a behavior of `q`.

The remaining values can then be processed through it.

---

# 16. Demoting behaviors with `~->`

The inverse operation is:

```text
~->
```

It removes an active behavior from a kyu and turns it back into an ordinary value.

For example:

```text
f ~-> h
```

takes one production stage from `f` and stores its behavior value in `h`.

It can subsequently be promoted again:

```text
f ~-> h -~> h
```

This means Kyubi programs can manipulate their own processing stages at runtime.

Promotion and demotion are therefore essentially:

```text
value representing behavior
          |
         -~>
          |
          v
active production stage
          |
         ~->
          |
          v
value representing behavior
```

## The evaluator explicitly converts behavior values into executable stages during promotion and converts stages back into values during demotion.

# 17. Duplication with `=>`

`=>` copies a value without consuming it.

For example:

```text
1 -> q1
q1 => q2
```

copies the first value of `q1` into `q2`.

The value remains in `q1`.

Conceptually:

```text
before:

q1 = [1]
q2 = []

q1 => q2

after:

q1 = [1]
q2 = [1]
```

Unlike `->`, this operation uses the front element without removing it.

Flow sizes work here too:

```text
q1 =2> q2
```

performs the duplication twice.

Because the source is only peeked rather than consumed, this duplicates the same front value.

## The implementation defines duplication as a normal sized transfer whose read operation is `peek` rather than `dequeue`.

# 18. Branching

Kyubi provides pattern-based branching using:

```text
| pattern
    ...
| pattern
    ...
|>
```

For example:

```text
1 ->
| 1 42 -> result
| 0 13 -> result
|>
```

matches the input against the branches.

Since the input is `1`, the first branch executes.

A more realistic example:

```text
[2, 1] -> q

1 ->
| 1 q -2> -
| 0 q -2> +
|>
--> result
```

The value `1` selects:

```text
q -2> -
```

so the two values from `q` are sent into subtraction.

The resulting `-` kyu is then passed through the remaining:

```text
--> result
```

flow.

Branches are therefore themselves pieces of flow.

---

# 19. Branch patterns

Branch patterns may be:

```text
0
1
42
()
'x
```

Numeric patterns match exactly:

```text
8 ->
| 2 ...
| 8 ...
|>
```

Unit can also be matched:

```text
() ->
| () ...
|>
```

A runtime-value pattern matches any value and binds it.

For example:

```text
8 ->
| 2 0 -> q
| 'x 'x -> q
|>
```

`8` does not match `2`, so:

```text
'x
```

matches and binds:

```text
'x = 8
```

The branch then executes:

```text
'x -> q
```

and therefore inserts `8` into `q`.

## Branches are checked in order and the first matching pattern is selected.

# 20. Wildcard-style patterns

A common idiom is:

```text
'_
```

For example:

```text
8 ->
| 2 0 -> q
| '_ 0 -> q
|>
```

Since runtime-value patterns match any value, `'_` can be used as a catch-all branch.

Technically this uses the same runtime binding mechanism as `'x`; `_` is simply a conventional name when the captured value is not needed.

---

# 21. Branching from queues

The input of a branch does not need to be a literal.

For example:

```text
q ->
| 0 ...
| 1 ...
| 'x ...
|>
```

removes the first value from `q` and branches on it.

Using duplication instead:

```text
q =>
| 0 ...
| 1 ...
| 'x ...
|>
```

branches on the first value **without consuming it**.

This provides a convenient way to inspect the state of a queue.

---

# 22. Branching on produced values

Production may directly feed a branch.

For example:

```text
+ -->
| 2 ...
| 'x ...
|>
```

runs one production of `+` and branches on the produced value.

This is useful for writing conditional pipelines.

---

# 23. Conditional execution

Because branches contain arbitrary flows, they can implement ordinary conditionals.

For example:

```text
[2, 1] -> q

1 ->
| 1
    q -2> -
| 0
    q -2> +
|>
--> result
```

is roughly analogous to:

```text
if condition == 1:
    result = 2 - 1
else:
    result = 2 + 1
```

except that the computation is expressed entirely as data movement.

Branches may themselves contain branches:

```text
1 ->
| 1
    8 ->
    | 1 2
    | 'x 'x -> g
    |>
    -> q -_> +
| 0
    q -2> +
|>
--> + --> result
```

---

# 24. Example: defining `add_two`

A reusable behavior:

```text
{ 'x:
    2 -> +
    'x -> +
    + --> @
} ~> add_two
```

can be understood step by step.

First:

```text
'x
```

is the behavior's input.

Then:

```text
2 -> +
'x -> +
```

fills the built-in addition queue.

Then:

```text
+ --> @
```

performs addition and sends the result to the behavior's output.

Usage:

```text
10 -> add_two
add_two --> result
```

Result:

```text
12
```

---

# 25. Example: multiple outputs

Consider:

```text
{'x 'y:
    'x -> +
    'y -> +

    + --> @
    34 -> @
} ~> f
```

`f` consumes two arguments.

It first computes:

```text
'x + 'y
```

and outputs it.

It then outputs `34`.

Therefore:

```text
[10, 11] -> f
f --2> result
```

gives:

```text
21
34
```

Notice why:

```text
--2>
```

is required.

One production is performed, but two values are transferred from its output.

---

# 26. Example: reduction

Kyubi's flow-size syntax makes reductions concise.

Consider:

```text
[0, 1, 2, 3, 4, 5, 6, 7,
 8, 9, 10, 11, 12, 13, 14, 15,
 16, 17, 18, 19, 20, 21, 22, 23,
 24, 25, 26, 27, 28, 29, 30, 31] -> +

+ -16-16> +
+ -8-8> +
+ -4-4> +
+ -2-2> +
+ --> result
```

Initially, 32 values are inserted into `+`.

Since addition consumes two inputs and produces one output:

```text
32 inputs
  ↓
16 additions
  ↓
16 outputs
```

The first stage:

```text
+ -16-16> +
```

performs 16 additions and feeds all 16 results back into `+`.

Then:

```text
16 → 8 → 4 → 2 → 1
```

until:

```text
+ --> result
```

produces the final sum.

This is a good example of the central Kyubi style: computation is expressed by controlling **how values circulate through production queues**.

---

# 27. Example: dynamic behavior construction

Because behaviors are values, programs can construct and transport computation.

For example:

```text
{
    { 'x:
        2 -> +
        'x -> + --> @
    } ~> add_two
} ~> gen
```

Here `gen` is itself a behavior whose execution installs another behavior into `add_two`.

This enables metaprogramming-like patterns without a separate code-generation system.

The distinction to remember is:

```text
behavior -> q
```

stores a behavior as data.

```text
behavior ~> q
```

installs a behavior as an executable production stage.

```text
q -~> f
```

turns behavior data into an executable stage.

```text
f ~-> q
```

turns an executable stage back into behavior data.

---

# 28. Comments

Kyubi supports both single-line and multiline comments.

Single-line:

```text
// This is a comment
1 -> +
```

Inline comments are also allowed:

```text
1 -> +  // insert 1
2 -> +  // insert 2
```

Multiline comments use:

```text
/*
    Everything here is ignored.
*/
```

For example:

```text
1 -> +

/*
2 -> +
3 -> +
*/

4 -> +
```

Both forms are handled as whitespace by the lexer.

---

# 29. Whitespace and formatting

Flows do not have to remain on one line.

This:

```text
4 -> -
+ --> - --> + --> result
```

can be formatted as:

```text
4 -> -

+ -->
    - -->
    + --> result
```

Whitespace and newlines generally separate tokens but do not define blocks.

Behaviors use `{ ... }` and branch expressions use `| ... |>`, so indentation is purely for readability.

---

# 30. Special kyus

Two queue names are reserved inside behaviors:

```text
$
@
```

They represent:

| Name | Meaning                 |
| ---- | ----------------------- |
| `$`  | current behavior input  |
| `@`  | current behavior output |

They only exist in behavior context.

For example:

```text
{:
    $ -2> @
} ~> passthrough
```

## Outside a behavior, using these special queues is rejected by the parser. The parser also prevents enqueuing into `$` and dequeuing from `@`.

# 31. Operator reference

## Value movement

```text
a -> b
```

Move/enqueue one value.

```text
a -N> b
```

Move `N` values.

```text
a -_> b
```

Move all available values.

---

## Production

```text
a --> b
```

Perform one production and move one output.

```text
a -N-M> b
```

Perform `N` productions and move `M` outputs.

```text
a -N-_> b
```

Perform `N` productions and move all available outputs.

---

## Behavior movement

```text
a ~> b
```

Attach a literal behavior to `b`, or move one behavior stage from `a` to `b`.

```text
a ~N> b
```

Move `N` behaviors.

```text
a ~_> b
```

Move all available behaviors.

---

## Promotion

```text
a -~> b
```

Take a behavior stored as a normal value in `a` and install it as a production stage in `b`.

Sized forms are also available:

```text
a -2~> b
a -_~> b
```

---

## Demotion

```text
a ~-> b
```

Remove an executable behavior stage from `a` and store it as a normal value in `b`.

Sized forms follow the same convention.

---

## Duplication

```text
a => b
```

Copy the first value from `a` into `b` without removing it from `a`.

```text
a =N> b
```

Perform the operation `N` times.

```text
a =_> b
```

continues while values are available.

---

# 32. Flow-size reference

The same three flow-size forms appear throughout the language:

```text
<absent>
N
_
```

Their general meaning is:

| Syntax  | Meaning                |
| ------- | ---------------------- |
| omitted | once / one value       |
| `N`     | exactly N times/values |
| `_`     | as many as possible    |

The exact object being counted depends on the operator.

For:

```text
q -3> p
```

it counts values.

For:

```text
q -3-2> p
```

the first size counts productions and the second counts transferred output values.

For:

```text
f ~3> g
```

it counts behaviors.

This representation is directly reflected in the implementation as `Absent`, `Const n`, and `All`.

---

# 33. A larger example

Consider:

```text
[1, 2] -> q

{ 'x:
    2 -> +
    'x -> + --> @
} ~> add_two

{'x 'y:
    'x -> +
    'y -> +

    + --> @
    34 -> @
} ~> f

{ 'x 'y:
    'x -> add_two --> @
    'y -> add_two --> @
} ~> f

q -2> f
f --2> result
```

There are two stages in `f`.

The newest stage receives:

```text
1
2
```

and transforms them using `add_two`:

```text
1 → 3
2 → 4
```

These become input for the previous stage, which computes:

```text
3 + 4 = 7
```

and additionally emits:

```text
34
```

Therefore:

```text
f --2> result
```

ultimately produces:

```text
7
34
```

This illustrates production chains: behaviors do not merely coexist inside a queue; their input/output queues connect them into a pipeline.

---

# 34. Recursive production chains

Behaviors can refer to named kyus, including kyus participating in larger recursive structures.

For example:

```text
{ 'x 'y:
    { 'x 'y 'next:
        ['next, 'y] -> work
        ...
    } ~> work

    ...
} ~> f
```

allows a behavior to build helper production stages and send values back through them.

As a result, iteration and recursion need not appear as conventional:

```text
for
while
recursive_function(...)
```

Instead, repeated computation can emerge from values circulating through kyus and production stages.

This is one of the major conceptual differences between Kyubi and conventional expression-oriented languages.

---

# 35. The Kyubi mental model

When reading a Kyubi program, avoid thinking primarily in terms of variables and function calls.

Instead, ask four questions.

### Where are the values?

```text
1 -> q
2 -> q
```

puts values into a queue.

### Where are the behaviors?

```text
{ 'x: ... } ~> q
```

adds a processing stage.

### When does computation happen?

```text
q --> result
```

explicitly requests production.

Merely putting values into `q` does not automatically execute its behavior.

### Where does the result go?

Inside a behavior:

```text
... -> @
```

creates behavior output.

Outside:

```text
q --> result
```

moves produced output somewhere else.

Once these four ideas are clear, most Kyubi syntax follows naturally.

---

# 36. Syntax cheat sheet

```text
// integer
42

// unit
()

// insert one value
42 -> q

// insert several values
[1, 2, 3] -> q

// move one value
q -> p

// move N values
q -3> p

// move everything
q -_> p

// behavior
{ 'x 'y:
    ...
}

// install behavior
{ 'x:
    'x -> @
} ~> identity

// run one production
identity --> result

// N productions, M outputs
q -N-M> result

// behavior input
$

// behavior output
@

// duplicate without consuming
q => p

// store behavior as a value
{ 'x: 'x -> @ } -> q

// promote behavior value
q -~> f

// demote active behavior
f ~-> q

// move active behavior
f ~> g

// branching
value ->
| 0 ...
| 1 ...
| 'x ...
|>

// comments
// single line

/*
multiline
*/
```

---

# 37. Complete introductory example

A compact program combining the main ideas:

```text
// Input data
[1, 2] -> q

// Define a reusable behavior
{ 'x:
    2 -> +
    'x -> +
    + --> @
} ~> add_two

// Define another behavior
{ 'x 'y:
    'x -> add_two --> +
    'y -> add_two --> +
    + --> @
} ~> compute

// Feed two values into it
q -2> compute

// Run the computation
compute --> result
```

Execution is:

```text
1 -> add_two -> 3
2 -> add_two -> 4
3 + 4 -> 7
```

so:

```text
result = [7]
```

---

# 38. Language philosophy

Kyubi deliberately separates three concepts that conventional languages often combine:

```text
data
execution
code
```

Data lives in kyus.

```text
42 -> q
```

Execution happens explicitly through production.

```text
q --> result
```

Code itself can be represented and transported as behavior values.

```text
{ 'x: 'x -> @ } -> q
```

and activated dynamically.

```text
q -~> f
```

This makes programs themselves dataflow structures whose processing topology can change during execution.

Instead of asking:

> Which function is being called?

Kyubi encourages asking:

> Which values are currently in which queues, which production stages are attached to those queues, and which flow operation happens next?

That is the core of the language.

# lazy-seq

Lazy sequences for Lua runtime, and functions to operate on those.

## Installation

Clone this library to your project:

    git clone https://gitlab.com/andreyorst/lazy-seq.git

## Rationale

Iterators in Lua can be considered lazy, however these are not really a data type.
You shouldn't pass iterators around, as these can be stateful.
Lazy sequences solve this problem by being immutable.

## Design

A lazy sequence is implemented in terms of closures, and works similarly to the linked list.
Each element of a sequence is a cons cell, and there are three cons cell types:

- `cons` - an ordinary cons cell, containing a value, and the next cons cell,
- `empty-cons` - an empty cons cell, which contains `nil` as a value, and itself as the next cons cell,
- `lazy-cons` - a lazy variant of a cons cell, which will not get realized until it's first element is accessed.

This library provides a set of functions for creating and manipulating (lazy) sequences.

For example, consider `map` function:

``` fennel
>> (local lazy (require :lazy-seq))
>> (lazy.map print [1 2 3])
1
2
3
@seq(nil nil nil)
```

Each element of the vector `[1 2 3]` was printed and we got back a sequence of results: `@seq(nil nil nil)`.
However, if the result of `lazy.map` call is put into the variable, there are no prints happening until this variable is realized:

``` fennel
>> (local {: map : first} (require :lazy-seq))
>> (local s (map print [1 2 3]))
>> (first s)
1
nil
>> s
2
3
@seq(nil nil nil)
```

A sequence can be constructed from the table with the `seq` function, and a lazy variant with the `lazy-seq` macro:

``` fennel
>> (local {: seq} (require :lazy-seq))
>> (import-macros {: lazy-seq} :lazy-seq)
>> (seq [1 2 3 4 5])                    ; eager sequence
@seq(1 2 3 4 5)
>> (lazy-seq [1 2 3 4 5])               ; lazy sequence
@seq(1 2 3 4 5)
```

Lazy sequences can be self-referencing:

``` fennel
>> (local bc (require :bc)) ; lbc library for arbitrary precision math
>> (tset (getmetatable (bc.new 1)) :__fennelview tostring) ; render arbitrary precision numbers
>> (local {: cons : take} (require :lazy-seq))
>> (import-macros {: lazy-seq} :lazy-seq)
>> (local fib ((fn fib [a b] (lazy-seq (cons a (fib b (+ (bc.new a) (bc.new b)))))) 0 1))
>> (take 20 fib)
@seq(0 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610 987 1597 2584 4181)
```

`fib` here is an infinite sequence of Fibonacci numbers.

## Documentation

The documentation is auto-generated with [Fenneldoc](https://gitlab.com/andreyorst/fenneldoc) and can be found [here](https://gitlab.com/andreyorst/lazy-seq/-/blob/main/doc/lazy-seq.md).

## Contributing

Please do.
You can report issues or feature request at [project's GitLab repository](https://gitlab.com/andreyorst/lazy-seq).
Consider reading [contribution guidelines](https://gitlab.com/andreyorst/lazy-seq/-/blob/main/CONTRIBUTING.md) beforehand.

<!--  LocalWords:
      LocalWords:  GitLab submodule stateful runtime Fenneldoc
 -->

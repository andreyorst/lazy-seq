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
- `lazy-cons` - a lazy variant of a cons cell, which will not get realized until accessed.

This library provides a set of functions for creating and manipulating (lazy) sequences.

For example, consider `map` function:

``` fennel
(local lazy (require :lazy-seq))
(lazy.map print [1 2 3])
;; prints: 1, 2, 3 on separate lines
;; returns: @seq(nil nil nil)
```

Each element of the vector `[1 2 3]` was printed and we got back a sequence of results: `@seq(nil nil nil)`.
However, if the result of `lazy.map` call is put into the variable, there are no prints happening until this variable is realized:

``` fennel
(local {: map : first : doall} (require :lazy-seq))
(local s (map print [1 2 3]))
(first s)
;; only prints 1, returns nil
(doall s)
;; only prints 2, 3, and returns @seq(nil nil nil)
```

Sequences can be constructed with the `seq` function, which accepts tables and strings, and via the `lazy-seq` macro to produce a lazy variant:

``` fennel
(local {: seq} (require :lazy-seq))
(import-macros {: lazy-seq} :lazy-seq)
(seq [1 2 3 4 5])
;; @seq(1 2 3 4 5)
(seq {:a 1 :b 2 :c 3})
;; @seq([:b 2] [:c 3] [:a 1])
(seq "foobar")
;; @sseq("f" "o" "o" "b" "a" "r")
(lazy-seq (do (print "I'm lazy!") [1 2 3 4 5]))
;; prints "I'm lazy!" upon access
;; @seq(1 2 3 4 5)
```

Lazy sequences can be self-referencing:

``` fennel
(local bc (require :bc)) ; lbc library for arbitrary precision math
(tset (getmetatable (bc.new 1)) :__fennelview tostring) ; render arbitrary precision numbers

(local {: map : rest : take : drop} (require :lazy-seq))
(import-macros {: lazy-cat} :lazy-seq)

(global fib (lazy-cat [(bc.new 0) (bc.new 1)] (map #(+ $1 $2) (rest fib) fib)))
(take 20 fib)
;; @seq(0 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610 987 1597 2584 4181)
```

`fib` here is an infinite sequence of Fibonacci numbers.

## Documentation

The documentation is auto-generated with [Fenneldoc](https://gitlab.com/andreyorst/fenneldoc) and can be found [here](doc/lazy-seq.md).

## Contributing

Please do.
You can report issues or feature request at [project's GitLab repository](https://gitlab.com/andreyorst/lazy-seq).
Consider reading [contribution guidelines](CONTRIBUTING.md) beforehand.

<!--  LocalWords:
      LocalWords:  GitLab submodule stateful runtime Fenneldoc
 -->

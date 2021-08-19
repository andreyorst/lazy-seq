# Init.fnl (v0.0.1)

**Table of contents**

- [`seq`](#seq)
- [`cons`](#cons)
- [`first`](#first)
- [`rest`](#rest)
- [`map`](#map)
- [`concat`](#concat)
- [`range`](#range)
- [`take`](#take)

## `seq`
Function signature:

```
(seq vec)
```

Construct an eager sequence out of a table or another sequence.
Returns `nil` if given empty table, or sequence.

## `cons`
Function signature:

```
(cons ...)
```

Construct a cons cell.
Second element must be either a table or a sequence, or nil.

## `first`
Function signature:

```
(first c)
```

Return first element of a sequence.

## `rest`
Function signature:

```
(rest c)
```

Return the tail of a sequence.
If the sequence is empty, returns empty sequence

## `map`
Function signature:

```
(map f col)
```

Map function `f` over every element of a collection `col`.
Returns lazy sequence.

### Examples

```fennel
(map #(+ $ 1) [1 2 3]) ;; => @seq(2 3 4)
(local res (map #(+ $ 1) [:a :b :c])) ;; will blow up when realized
```

## `concat`
Function signature:

```
(concat x y)
```

Return a lazy sequence of concatenated sequences.

## `range`
Function signature:

```
(range ...)
```

Create a possibly infinite sequence of numbers.

If one argument is specified, returns a finite sequence from 0 up to this argument.
If two arguments were specified, returns a finite sequence from lower to, but not included, upper bound.
A third argument provides step interval.

If no arguments were specified, returns an infinite sequence starting at 0.

### Examples

Various ranges:

```fennel
(range 10) ;; => @seq(0 1 2 3 4 5 6 7 8 9)
(range 4 8) ;; => @seq(4 5 6 7)
(range 0 -5 -2) ;; => @seq(0 -2 -4)
(take 10 (range)) ;; => @seq(0 1 2 3 4 5 6 7 8 9)
```

## `take`
Function signature:

```
(take n coll)
```

Take `n` elements from the collection `coll`.
Returns a lazy sequence of specified amount of elements.

### Examples

Take 10 element from a sequential table

```fennel
(take 10 [1 2 3]) ;=> @seq(1 2 3)
(take 5 [1 2 3 4 5 6 7 8 9 10]) ;=> @seq(1 2 3 4 5)
```


---

Copyright (C) 2021 Andrey Listopadov

License: [MIT](https://gitlab.com/andreyorst/lazy-seq/-/raw/master/LICENSE)


<!-- Generated with Fenneldoc v0.1.7
     https://gitlab.com/andreyorst/fenneldoc -->

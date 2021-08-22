# Lazy-seq.fnl (v0.0.1)
Lazy sequence library for Fennel and Lua.

**Table of contents**

- [`seq`](#seq)
- [`cons`](#cons)
- [`first`](#first)
- [`rest`](#rest)
- [`next`](#next)
- [`lazy-seq*`](#lazy-seq)
- [`dorun`](#dorun)
- [`doall`](#doall)
- [`realized?`](#realized)
- [`seq-pack`](#seq-pack)
- [`seq-unpack`](#seq-unpack)
- [`concat`](#concat)
- [`drop`](#drop)
- [`every?`](#every)
- [`filter`](#filter)
- [`keep`](#keep)
- [`map`](#map)
- [`range`](#range)
- [`some?`](#some)
- [`take`](#take)

## `seq`
Function signature:

```
(seq t size)
```

Construct a sequence out of a table or another sequence `t`.
Takes optional `size` argument for defining the length of the
resulting sequence.  Since sequences can contain `nil` values,
transforming packed table to a sequence is possible by passing the
value of `n` key from such table.  Returns `nil` if given empty table,
or empty sequence.

Sequences are immutable and persistent, though their contents are not
immutable, meaning that if a sequence contains mutable tables, the
contents of a sequence can change.  Unlike iterators, sequences are
non-destructive, and can be shared.

Sequences support two main operations: `first`, and `rest`.  Being a
single linked list, sequences have linear access complexity, but can
be sliced and concatenated in constant time.

### Examples

Transform sequential table to a sequence:

``` fennel
(local nums [1 2 3 4 5])
(local num-seq (seq nums))

(assert-eq nums [(seq-unpack num-seq)])
```

Sequences can have nils as their values, so packed tables can be
easily transformed to a sequence:

``` fennel
(local t (table.pack :a nil nil :b :c nil nil nil))
(local s (seq t t.n))
(local view (require :fennel.view))
(assert-eq "@seq(\"a\" nil nil \"b\" \"c\" nil nil nil)"
           (view s))
```

Iterating through a sequence:

```fennel
(local s (seq [1 2 3 4 5]))

(fn reverse [s]
  ((fn reverse [s res]
     (match (seq s)
       s* (reverse (rest s*) (cons (first s*) res))
       _ res))
   s nil))

(assert-eq [5 4 3 2 1]
           [(seq-unpack (reverse s))])

```


Sequences can also be created manually by using `cons` function.

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
(first s)
```

Return first element of a sequence.

## `rest`
Function signature:

```
(rest s)
```

Return the tail of a sequence.

If the sequence is empty, returns empty sequence.

## `next`
Function signature:

```
(next s)
```

Return the tail of a sequence.

If the sequence is empty, returns nil.

## `lazy-seq*`
Function signature:

```
(lazy-seq* f)
```

Create lazy sequence from the result of function `f`.
Delays execution of `f` until sequence is consumed.

See `lazy-seq` macro from init-macros.fnl for more convenient usage.

## `dorun`
Function signature:

```
(dorun s)
```

Realize whole sequence for side effects.

Walks whole sequence, realizing each cell.  Use at your own risk on
infinite sequences.

## `doall`
Function signature:

```
(doall s)
```

Realize whole lazy sequence.

Walks whole sequence, realizing each cell.  Use at your own risk on
infinite sequences.

## `realized?`
Function signature:

```
(realized? s)
```

Check if sequence is fully realized.

Use at your own risk on infinite sequences.

## `seq-pack`
Function signature:

```
(seq-pack s)
```

Pack sequence into sequential table with size indication.

## `seq-unpack`
Function signature:

```
(seq-unpack s)
```

Unpack sequence items to multiple values.

## `concat`
Function signature:

```
(concat ...)
```

Return a lazy sequence of concatenated sequences.

## `drop`
Function signature:

```
(drop n coll)
```

Drop `n` elements from collection `coll`, returning a lazy sequence
of remaining elements.

## `every?`
Function signature:

```
(every? pred coll)
```

Check if `pred` is true for every element of a sequence `coll`.

## `filter`
Function signature:

```
(filter pred coll)
```

Returns a lazy sequence of the items in the `coll` for which `pred`
returns logical true.

## `keep`
Function signature:

```
(keep f coll)
```

Returns a lazy sequence of the non-nil results of calling `f` on the
items of the `coll`.

## `map`
Function signature:

```
(map f ...)
```

Map function `f` over every element of a collection `col`.
Returns lazy sequence.

### Examples

```fennel
(map #(+ $ 1) [1 2 3]) ;; => @seq(2 3 4)
(local res (map #(+ $ 1) [:a :b :c])) ;; will blow up when realized
```

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

## `some?`
Function signature:

```
(some? pred coll)
```

Check if `pred` returns logical true for any element of a sequence
`coll`.

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


<!-- Generated with Fenneldoc v0.1.5
     https://gitlab.com/andreyorst/fenneldoc -->

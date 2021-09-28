# Lazy-seq.fnl (v0.0.2-dev)
Lazy sequence library for Fennel and Lua.

Most functions in this library return a so called lazy sequence.  The
contents of such sequences aren't computed until requested, and
similarly to iterators, lazy sequences can be infinite.

The key difference from iterators is that sequence itself is a data
structure.  It can be passed, and shared between functions, and
operations on a sequence will not affect other callers.  Infinite
sequences are either consumed on per element basis, or bade finite by
calling `take` with desired size argument.

Both eager and lazy sequences support `pairs` iteration, which will
never terminate in case of infinite lazy sequence.  Such iterator
returns current sequence tail and it's head element as values.

Lazy sequences can also be created with the help of macros `lazy-seq`
and `lazy-cat`.  These macros are provided for convenience only.

**Table of contents**

- [`seq`](#seq)
- [`cons`](#cons)
- [`first`](#first)
- [`rest`](#rest)
- [`next`](#next)
- [`lazy-seq`](#lazy-seq)
- [`list`](#list)
- [`dorun`](#dorun)
- [`doall`](#doall)
- [`realized?`](#realized)
- [`pack`](#pack)
- [`unpack`](#unpack)
- [`concat`](#concat)
- [`cycle`](#cycle)
- [`drop`](#drop)
- [`every?`](#every)
- [`filter`](#filter)
- [`interleave`](#interleave)
- [`interpose`](#interpose)
- [`iter`](#iter)
- [`keep`](#keep)
- [`line-seq`](#line-seq)
- [`map`](#map)
- [`range`](#range)
- [`repeat`](#repeat)
- [`repeatedly`](#repeatedly)
- [`some?`](#some)
- [`take`](#take)

## `seq`
Function signature:

```
(seq s)
```

Construct a sequence out of a table or another sequence `s`.
Returns `nil` if given an empty sequence or an empty table.

Sequences are immutable and persistent, but their contents are not
immutable, meaning that if a sequence contains mutable references, the
contents of a sequence can change.  Unlike iterators, sequences are
non-destructive, and can be shared.

Sequences support two main operations: `first`, and `rest`.  Being a
single linked list, sequences have linear access time complexity..

### Examples

Transform sequential table to a sequence:

``` fennel
(local nums [1 2 3 4 5])
(local num-seq (seq nums))

(assert-eq nums [(unpack num-seq)])
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
           [(unpack (reverse s))])
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

## `lazy-seq`
Function signature:

```
(lazy-seq f)
```

Create lazy sequence from the result of calling a function `f`.
Delays execution of `f` until sequence is consumed.

See `lazy-seq` macro from init-macros.fnl for more convenient usage.

## `list`
Function signature:

```
(list ...)
```

Create eager sequence of provided values.

### Examples

``` fennel
(local l (list 1 2 3 4 5))
(assert-eq [1 2 3 4 5] [(unpack l)])
```

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

Check if sequence's first element is realized.

## `pack`
Function signature:

```
(pack s)
```

Pack sequence into sequential table with size indication.

## `unpack`
Function signature:

```
(unpack s)
```

Unpack sequence items to multiple values.

## `concat`
Function signature:

```
(concat ...)
```

Return a lazy sequence of concatenated sequences.

## `cycle`
Function signature:

```
(cycle coll)
```

Create a lazy infinite sequence of repetitions of the items in the
`coll`.

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

## `interleave`
Function signature:

```
(interleave ...)
```

Returns a lazy sequence of the first item in each sequence, then the
second one, until any sequence exhausts.

## `interpose`
Function signature:

```
(interpose separator coll)
```

Returns a lazy sequence of the elements of `coll` separated by `separator`.

## `iter`
Function signature:

```
(iter s)
```

Transform sequence `s` to a stateful iterator going over its elements.

Provides a safer* iterator that only returns values of a sequence
without the sequence tail. Returns `nil` when no elements left.
Automatically converts its argument to a sequence by calling `seq` on
it.

(* Accidental realization of a tail of an
infinite sequence can freeze your program and eat all memory, as the
sequence is infinite.)

## `keep`
Function signature:

```
(keep f coll)
```

Returns a lazy sequence of the non-nil results of calling `f` on the
items of the `coll`.

## `line-seq`
Function signature:

```
(line-seq file)
```

Accepts a `file` handle, and creates a lazy sequence of lines using
`lines` metamethod.

### Examples

Lazy sequence of file lines may seem similar to an iterator over a
file, but the main difference is that sequence can be shared onve
realized, and iterator can't.  Lazy sequence can be consumed in
iterator style with the `doseq` macro.

Bear in mind, that since the sequence is lazy it should be realized or
truncated before the file is closed:

```fennel
(let [lines (with-open [f (io.open "init.fnl" :r)]
              (line-seq f))]
  ;; this errors because only first line was realized, but the file
  ;; was closed before the rest of lines were cached
  (assert-not (pcall next lines)))
```

Sequence is realized with `doall` before file was closed and can be shared:

``` fennel
(let [lines (with-open [f (io.open "init.fnl" :r)]
              (doall (line-seq f)))]
  (assert-is (pcall next lines)))
```

Infinite files can't be fully realized, but can be partially realized
with `take`:

``` fennel
(let [lines (with-open [f (io.open "/dev/urandom" :r)]
              (doall (take 3 (line-seq f))))]
  (assert-is (pcall next lines)))
```

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
(local res (map #(+ $ 1) [:a :b :c])) ;; will raise an error only when realized
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

## `repeat`
Function signature:

```
(repeat x)
```

Takes a value `x` and returns an infinite lazy sequence of this value.

### Examples

``` fennel
(assert-eq 10 (accumulate [res 0
                           _ x (pairs (take 10 (repeat 1)))]
                (+ res x)))
```

## `repeatedly`
Function signature:

```
(repeatedly f ...)
```

Takes a function `f` and returns an infinite lazy sequence of
function applications.  Rest arguments are passed to the function.

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


<!-- Generated with Fenneldoc v0.1.7
     https://gitlab.com/andreyorst/fenneldoc -->

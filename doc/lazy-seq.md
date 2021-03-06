# Lazy-seq.fnl (v0.0.3-dev)
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

- [`cons`](#cons)
- [`first`](#first)
- [`rest`](#rest)
- [`next`](#next)
- [`seq`](#seq)
- [`lazy-seq`](#lazy-seq)
- [`list`](#list)
- [`dorun`](#dorun)
- [`doall`](#doall)
- [`realized?`](#realized)
- [`pack`](#pack)
- [`unpack`](#unpack)
- [`concat`](#concat)
- [`contains?`](#contains)
- [`count`](#count)
- [`cycle`](#cycle)
- [`distinct`](#distinct)
- [`drop`](#drop)
- [`drop-last`](#drop-last)
- [`drop-while`](#drop-while)
- [`empty?`](#empty)
- [`every?`](#every)
- [`filter`](#filter)
- [`interleave`](#interleave)
- [`interpose`](#interpose)
- [`iterate`](#iterate)
- [`keep`](#keep)
- [`keep-indexed`](#keep-indexed)
- [`keys`](#keys)
- [`line-seq`](#line-seq)
- [`list*`](#list-1)
- [`map`](#map)
- [`map-indexed`](#map-indexed)
- [`mapcat`](#mapcat)
- [`nthnext`](#nthnext)
- [`nthrest`](#nthrest)
- [`partition`](#partition)
- [`partition-all`](#partition-all)
- [`partition-by`](#partition-by)
- [`range`](#range)
- [`reduce`](#reduce)
- [`reduced`](#reduced)
- [`reductions`](#reductions)
- [`remove`](#remove)
- [`repeat`](#repeat)
- [`repeatedly`](#repeatedly)
- [`reverse`](#reverse)
- [`rseq`](#rseq)
- [`seq?`](#seq-1)
- [`some?`](#some)
- [`split-at`](#split-at)
- [`split-with`](#split-with)
- [`take`](#take)
- [`take-last`](#take-last)
- [`take-nth`](#take-nth)
- [`take-while`](#take-while)
- [`tree-seq`](#tree-seq)
- [`vals`](#vals)
- [`zipmap`](#zipmap)

## `cons`
Function signature:

```
(cons head tail)
```

Construct a cons cell.
Prepends new `head` to a `tail`, which must be either a table, sequence, or nil.

### Examples

``` fennel
(assert-eq [0 1] (cons 0 [1]))
(assert-eq (list 0 1 2 3) (cons 0 (cons 1 (list 2 3))))
```

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

## `seq`
Function signature:

```
(seq s)
```

Construct a sequence out of a table, string or another sequence `s`.
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

(assert-eq nums num-seq)
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
           (reverse s))
```


Sequences can also be created manually by using `cons` function.

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
(assert-eq [1 2 3 4 5] l)
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

## `contains?`
Function signature:

```
(contains? coll elt)
```

Test if `elt` is in the `coll`.  May be a linear search depending on the type of the collection.

## `count`
Function signature:

```
(count s)
```

Count amount of elements in the sequence.

## `cycle`
Function signature:

```
(cycle coll)
```

Create a lazy infinite sequence of repetitions of the items in the
`coll`.

## `distinct`
Function signature:

```
(distinct coll)
```

Returns a lazy sequence of the elements of the `coll` without
duplicates.  Comparison is done by equality.

## `drop`
Function signature:

```
(drop n coll)
```

Drop `n` elements from collection `coll`, returning a lazy sequence
of remaining elements.

## `drop-last`
Function signature:

```
(drop-last ...)
```

Return a lazy sequence from `coll` without last `n` elements.

## `drop-while`
Function signature:

```
(drop-while pred coll)
```

Drop the elements from the collection `coll` until `pred` returns logical
false for any of the elemnts.  Returns a lazy sequence.

## `empty?`
Function signature:

```
(empty? x)
```

Check if sequence is empty.

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

## `iterate`
Function signature:

```
(iterate f x)
```

Returns an infinete lazy sequence of x, (f x), (f (f x)) etc.

## `keep`
Function signature:

```
(keep f coll)
```

Returns a lazy sequence of the non-nil results of calling `f` on the
items of the `coll`.

## `keep-indexed`
Function signature:

```
(keep-indexed f coll)
```

Returns a lazy sequence of the non-nil results of (f index item) in
the `coll`.  Note, this means false return values will be included.
`f` must be free of side-effects.

## `keys`
Function signature:

```
(keys t)
```

Return a sequence of keys in table `t`.

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

## `list*`
Function signature:

```
(list* ...)
```

Creates a new sequence containing the items prepended to the rest,
the last of which will be treated as a sequence.

### Examples

``` fennel
(local l (list* 1 2 3 [4 5]))
(assert-eq [1 2 3 4 5] l)
```

## `map`
Function signature:

```
(map f ...)
```

Map function `f` over every element of a collection `col`.
`f` should accept as many arguments as there are collections supplied to `map`.
Returns a lazy sequence.

### Examples

```fennel
(map #(+ $ 1) [1 2 3]) ;; => @seq(2 3 4)
(map #(+ $1 $2) [1 2 3] [4 5 6]) ;; => @seq(5 7 9)
(local res (map #(+ $ 1) [:a :b :c])) ;; will raise an error only when realized
```

## `map-indexed`
Function signature:

```
(map-indexed f coll)
```

Returns a lazy sequence consisting of the result of applying `f` to 1
and the first item of `coll`, followed by applying `f` to 2 and the second
item in `coll`, etc, until `coll` is exhausted.

## `mapcat`
Function signature:

```
(mapcat f ...)
```

Apply `concat` to the result of calling `map` with `f` and
collections.

## `nthnext`
Function signature:

```
(nthnext coll n)
```

Returns the nth next of `coll`, (seq coll) when `n` is 0.

## `nthrest`
Function signature:

```
(nthrest coll n)
```

Returns the nth rest of `coll`, `coll` when `n` is 0.

## `partition`
Function signature:

```
(partition ...)
```

Returns a lazy sequence of lists of `n` items each, at offsets `step`
apart. If `step` is not supplied, defaults to `n`, i.e. the partitions do
not overlap. If a `pad` collection is supplied, use its elements as
necessary to complete last partition upto `n` items. In case there are
not enough padding elements, return a partition with less than `n`
items.

## `partition-all`
Function signature:

```
(partition-all ...)
```

Returns a lazy sequence of lists like `partition`, but may include
partitions with fewer than n items at the end.

## `partition-by`
Function signature:

```
(partition-by f coll)
```

Applies `f` to each value in `coll`, splitting it each time `f`
   returns a new value.  Returns a lazy seq of partitions.

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

## `reduce`
Function signature:

```
(reduce ([f coll]) ([f val coll]))
```

`f` should be a function of 2 arguments. If `val` is not supplied,
returns the result of applying `f` to the first 2 items in `coll`,
then applying `f` to that result and the 3rd item, etc. If `coll`
contains no items, f must accept no arguments as well, and reduce
returns the result of calling `f` with no arguments.  If `coll` has
only 1 item, it is returned and `f` is not called.  If `val` is
supplied, returns the result of applying `f` to `val` and the first
item in `coll`, then applying `f` to that result and the 2nd item,
etc. If `coll` contains no items, returns `val` and `f` is not
called. Early termination is supported via `reduced`.

### Examples

``` fennel
(fn add [...]
  "Addition function with multiple arities."
  (match (values (select "#" ...) ...)
    (0) 0
    (1 ?a) ?a
    (2 ?a ?b) (+ ?a ?b)
    (3 ?a ?b) (add (+ ?a ?b) (select 3 ...))))
;; no initial value
(assert-eq 10 (reduce add [1 2 3 4]))
;; initial value
(assert-eq 10 (reduce add 1 [2 3 4]))
;; empty collection - function is called with 0 args
(assert-eq 0 (reduce add []))
(assert-eq 10.3 (reduce math.floor 10.3 []))
;; collection with a single element doesn't call a function unless the
;; initial value is supplied
(assert-eq 10.3 (reduce math.floor [10.3]))
(assert-eq 7 (reduce add 3 [4]))
```

## `reduced`
Function signature:

```
(reduced value)
```

Terminates the `reduce` early with a given `value`.

### Examples

``` fennel
(assert-eq :NaN
           (reduce (fn [acc x]
                     (if (not= :number (type x))
                         (reduced :NaN)
                         (+ acc x)))
                   [1 2 :3 4 5]))
```

## `reductions`
Function signature:

```
(reductions ...)
```

Returns a lazy seq of the intermediate values of the reduction (as
per reduce) of `coll` by `f`, starting with `init`.

## `remove`
Function signature:

```
(remove pred coll)
```

Returns a lazy sequence of the items in the `coll` without elements
for wich `pred` returns logical true.

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

## `reverse`
Function signature:

```
(reverse s)
```

Returns an eager reversed sequence.

## `rseq`
Function signature:

```
(rseq rev)
```

Returns, in possibly-constant time, a seq of the items in `rev` in reverse order.
Input must be traversable with `ipairs`.  Doesn't work in constant
time if `rev` implements a linear-time `__len` metamethod, or invoking
Lua `#` operator on `rev` takes linar time.  If `t` is empty returns
`nil`.

### Examples

``` fennel
(local v [1 2 3])
(local r (rseq v))

(assert-eq (reverse v) r)
```

## `seq?`
Function signature:

```
(seq? x)
```

Check if object is a sequence.

## `some?`
Function signature:

```
(some? pred coll)
```

Check if `pred` returns logical true for any element of a sequence
`coll`.

## `split-at`
Function signature:

```
(split-at n coll)
```

Return a table with sequence `coll` being split at `n`

## `split-with`
Function signature:

```
(split-with pred coll)
```

Return a table with sequence `coll` being split with `pred`

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

## `take-last`
Function signature:

```
(take-last n coll)
```

Return a sequence of last `n` elements of the `coll`.

## `take-nth`
Function signature:

```
(take-nth n coll)
```

Return a lazy sequence of every `n` item in `coll`.

## `take-while`
Function signature:

```
(take-while pred coll)
```

Take the elements from the collection `coll` until `pred` returns logical
false for any of the elemnts.  Returns a lazy sequence.

## `tree-seq`
Function signature:

```
(tree-seq branch? children root)
```

Returns a lazy sequence of the nodes in a tree, via a depth-first walk.

`branch?` must be a function of one arg that returns true if passed a
node that can have children (but may not).  `children` must be a
function of one arg that returns a sequence of the children.  Will
only be called on nodes for which `branch?` returns true.  `root` is
the root node of the tree.

### Examples

For the given tree `["A" ["B" ["D"] ["E"]] ["C" ["F"]]]`:

        A
       / \
      B   C
     / \   \
    D   E   F

Calling `tree-seq` with [`next`](#next) as the `branch?` and [`rest`](#rest) as the
`children` returns a flat representation of a tree:

``` fennel
(assert-eq (map first (tree-seq next rest ["A" ["B" ["D"] ["E"]] ["C" ["F"]]]))
           ["A" "B" "D" "E" "C" "F"])
```

## `vals`
Function signature:

```
(vals t)
```

Return a sequence of values in table `t`.

## `zipmap`
Function signature:

```
(zipmap keys vals)
```

Return an associative table with the `keys` mapped to the
corresponding `vals`.


---

Copyright (C) 2021 Andrey Listopadov

License: [MIT](https://gitlab.com/andreyorst/lazy-seq/-/raw/master/LICENSE)


<!-- Generated with Fenneldoc v0.1.8
     https://gitlab.com/andreyorst/fenneldoc -->

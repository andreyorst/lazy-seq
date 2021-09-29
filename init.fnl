(local lazy {})

;; Lua 5.1 compatibility layer

(local lua-pairs pairs)
(local lua-ipairs ipairs)
(local lua-next next)
(global utf8 _G.utf8)

(fn pairs [t]
  (match (getmetatable t)
    {:__pairs p} (p t)
    _ (lua-pairs t)))

(fn ipairs [t]
  (match (getmetatable t)
    {:__ipairs i} (i t)
    _ (lua-ipairs t)))

(fn length* [t]
  (match (getmetatable t)
    {:__len l} (l t)
    _ (length t)))

(fn table-pack [...]
  (doto [...] (tset :n (select "#" ...))))

(local table-unpack
  (or table.unpack _G.unpack))

;; seq

(var seq nil)
(var cons-iter nil)

(fn first [s]
  "Return first element of a sequence."
  (match (seq s)
    s* (s* true)
    _ nil))

(local empty-cons
  (let [e []]
    (setmetatable e {:__len #0
                     :__fennelview #"@seq()"
                     :__lazy-seq/type :empty-cons
                     :__newindex #(error "cons cell is immutable")
                     :__index #nil
                     :__name "cons"
                     :__pairs #(values lua-next [] nil)
                     :__eq (fn [s1 s2] (rawequal s1 s2))
                     :__call #(if $2 nil e)})))

(fn rest [s]
  "Return the tail of a sequence.

If the sequence is empty, returns empty sequence."
  (match (seq s)
    s* (s* false)
    _ empty-cons))

(fn gettype [x]
  (match (?. (getmetatable x) :__lazy-seq/type)
    t t
    _ (type x)))

(fn realize [c]
  ;; force realize single cons cell
  (match (gettype c)
    :lazy-cons (c))
  c)

(fn next [s]
  "Return the tail of a sequence.

If the sequence is empty, returns nil."
  (seq (realize (rest (seq s)))))

;;; Cons cell

(fn view-seq [list options view indent elements]
  (table.insert elements (view (first list) options indent))
  (let [tail (next list)]
    (when (= :cons (gettype tail))
      (view-seq tail options view indent elements)))
  elements)

(fn pp-seq [list view options indent]
  (let [items (view-seq list options view (+ indent 5) [])
        lines (icollect [i line (ipairs items)]
                (if (= i 1) line (.. "     " line)))]
    (doto lines
      (tset 1 (.. "@seq(" (or (. lines 1) "")))
      (tset (length lines) (.. (. lines (length lines)) ")")))))

(local allowed-types
  {:cons true
   :empty-cons true
   :lazy-cons true
   :nil true
   :string true
   :table true})

(fn cons [...]
  "Construct a cons cell.
Second element must be either a table or a sequence, or nil."
  (assert (= 2 (select "#" ...)) "expected two arguments for cons")
  (let [(h t) ...]
    (assert (. allowed-types (gettype t))
            "expected nil, cons or table as a tail")
    (setmetatable [] {:__call #(if $2 h (match t s s nil empty-cons))
                      :__lazy-seq/type :cons
                      :__index #(if (> $2 0)
                                    (do (var (s i) (values $ 1))
                                        (while (and (not= i $2) s)
                                          (set (s i) (values (next s) (+ i 1))))
                                        (first s))
                                    nil)
                      :__newindex #(error "cons cell is immutable")
                      :__len #(do (var (s len) (values $ 0))
                                  (while s
                                    (set (s len) (values (next s) (+ len 1))))
                                  len)
                      :__pairs #(values (fn [_ s]
                                          (if (not= empty-cons s)
                                              (let [tail (next s)]
                                                (match (gettype tail)
                                                  :cons (values tail (first s))
                                                  _ (values empty-cons (first s))))
                                              nil))
                                        nil $)
                      :__name "cons"
                      :__eq (fn [s1 s2]
                              (if (rawequal s1 s2)
                                  true
                                  (do (var (s1 s2 res) (values s1 s2 true))
                                      (while (and res s1 s2)
                                        (set res (= (first s1) (first s2)))
                                        (set s1 (next s1))
                                        (set s2 (next s2)))
                                      res)))
                      :__fennelview pp-seq})))

(set seq
     (fn [s]
       "Construct a sequence out of a table or another sequence `s`.
Returns `nil` if given an empty sequence or an empty table.

Sequences are immutable and persistent, but their contents are not
immutable, meaning that if a sequence contains mutable references, the
contents of a sequence can change.  Unlike iterators, sequences are
non-destructive, and can be shared.

Sequences support two main operations: `first`, and `rest`.  Being a
single linked list, sequences have linear access time complexity..

# Examples

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


Sequences can also be created manually by using `cons` function."
       (match (gettype s)
         :cons s
         :lazy-cons (seq (realize s))
         :empty-cons nil
         :nil nil
         :table (cons-iter s)
         :string (cons-iter s)
         _ (error (: "expected table or sequence, got %s" :format _) 2))))

(fn lazy-seq [f]
  "Create lazy sequence from the result of calling a function `f`.
Delays execution of `f` until sequence is consumed.

See `lazy-seq` macro from init-macros.fnl for more convenient usage."
  (let [lazy-cons (cons nil nil)
        realize (fn []
                  (let [s (seq (f))]
                    (if (not= nil s)
                        (setmetatable lazy-cons (getmetatable s))
                        (setmetatable lazy-cons (getmetatable empty-cons)))))]
    (setmetatable lazy-cons {:__call #((realize) $2)
                             :__index #(. (realize) $2)
                             :__newindex #(error "cons cell is immutable")
                             :__fennelview #((. (getmetatable (realize)) :__fennelview) $...)
                             :__len #(length* (realize))
                             :__pairs #(pairs (realize))
                             :__name "lazy cons"
                             :__eq (fn [s1 s2] (= (realize) (seq s2)))
                             :__lazy-seq/type :lazy-cons})))

(fn list [...]
  "Create eager sequence of provided values.

# Examples

``` fennel
(local l (list 1 2 3 4 5))
(assert-eq [1 2 3 4 5] [(unpack l)])
```"
  (let [args (table-pack ...)]
    (var l empty-cons)
    (for [i args.n 1 -1]
      (set l (cons (. args i) l)))
    l))

(fn kind [t]
  (match (type t)
    :table (let [len (length* t)
                 (nxt t* k) (pairs t)]
             (if (not= nil (nxt t* (if (= len 0) k len))) :assoc
                 (> len 0) :seq
                 :empty))
    :string :string
    _ :else))

(set cons-iter
     (fn [t]
       (match (kind t)
         :assoc ((fn wrap [nxt t k]
                   (let [(k v) (nxt t k)]
                     (if (not= nil k)
                         (cons [k v] (lazy-seq #(wrap nxt t k)))
                         empty-cons)))
                 (pairs t))
         :seq ((fn wrap [nxt t i]
                 (let [(i v) (nxt t i)]
                   (if (not= nil i)
                       (cons v (lazy-seq #(wrap nxt t i)))
                       empty-cons)))
               (ipairs t))
         :string (let [char (if utf8 utf8.char string.char)]
                   ((fn wrap [nxt t i]
                      (let [(i v) (nxt t i)]
                        (if (not= nil i)
                            (cons (char v) (lazy-seq #(wrap nxt t i)))
                            empty-cons)))
                    (if utf8 (utf8.codes t)
                        (ipairs [(string.byte t 1 (length t))]))))
         :empty nil)))

(fn every? [pred coll]
  "Check if `pred` is true for every element of a sequence `coll`."
  (match (seq coll)
    s (if (pred (first s))
          (match (next s)
            r (every? pred r)
            _ true)
          false)
    _ false))

(fn some? [pred coll]
  "Check if `pred` returns logical true for any element of a sequence
`coll`."
  (match (seq coll)
    s (or (pred (first s))
          (match (next s)
            r (some? pred r)
            _ nil))
    _ nil))

(fn pack [s]
  "Pack sequence into sequential table with size indication."
  (let [res []]
    (var n 0)
    (each [_ v (pairs (seq s))]
      (set n (+ n 1))
      (tset res n v))
    (doto res (tset :n n))))

(fn count [s]
  "Count amount of elements in the sequence."
  (match (seq s)
    s* (length* s*)
    _ 0))

(fn unpack [s]
  "Unpack sequence items to multiple values."
  (let [t (pack s)]
    (table-unpack t 1 t.n)))

(fn concat [...]
  "Return a lazy sequence of concatenated sequences."
  (match (select "#" ...)
    0 (lazy-seq #nil)
    1 (let [(x) ...]
        (lazy-seq #x))
    2 (let [(x y) ...]
        (lazy-seq #(match (seq x)
                     s (cons (first s) (concat (rest s) y))
                     nil y)))
    _ (concat (concat (pick-values 2 ...)) (select 3 ...))))

(fn reverse [s]
  "Returns an eager reversed sequence."
  ((fn helper [s res]
     (match (seq s)
       s* (helper (rest s) (cons (first s) res))
       _ res)) s empty-cons))

(fn map [f ...]
  "Map function `f` over every element of a collection `col`.
Returns lazy sequence.

# Examples

```fennel
(map #(+ $ 1) [1 2 3]) ;; => @seq(2 3 4)
(local res (map #(+ $ 1) [:a :b :c])) ;; will raise an error only when realized
```"
  (match (select "#" ...)
    0 nil
    1 (let [(col) ...]
        (lazy-seq #(match (seq col)
                     x (cons (f (first x)) (map f (seq (rest x))))
                     _ nil)))
    2 (let [(s1 s2) ...]
        (lazy-seq #(let [s1 (seq s1) s2 (seq s2)]
                     (if (and s1 s2)
                         (cons (f (first s1) (first s2)) (map f (rest s1) (rest s2)))
                         nil))))
    3 (let [(s1 s2 s3) ...]
        (lazy-seq #(let [s1 (seq s1) s2 (seq s2) s3 (seq s3)]
                     (if (and s1 s2 s3)
                         (cons (f (first s1) (first s2) (first s3))
                               (map f (rest s1) (rest s2) (rest s3)))
                         nil))))
    _ (let [s (seq [...] (select "#" ...))]
        (lazy-seq #(if (every? #(not= nil (seq $)) s)
                       (cons (f (unpack (map first s)))
                             (map f (unpack (map rest s))))
                       nil)))))

(fn map-indexed [f coll]
  "Returns a lazy sequence consisting of the result of applying f to 1
and the first item of coll, followed by applying f to 2 and the second
item in coll, etc, until coll is exhausted. Thus function f should
accept 2 arguments, index and item."
  (let [mapi (fn mapi [idx coll]
               (lazy-seq
                #(match (seq coll)
                   s (cons (f idx (first s)) (mapi (+ idx 1) (rest s)))
                   _ nil)))]
    (mapi 1 coll)))

(fn mapcat [f ...]
  "Apply `concat` to the result of calling `map` with `f` and
collections."
  (let [step (fn step [colls]
               (lazy-seq
                #(match (seq colls)
                   s (let [c (first s)]
                       (concat c (step (rest colls))))
                   _ nil)))]
    (step (map f ...))))

(fn take [n coll]
  "Take `n` elements from the collection `coll`.
Returns a lazy sequence of specified amount of elements.

# Examples

Take 10 element from a sequential table

```fennel
(take 10 [1 2 3]) ;=> @seq(1 2 3)
(take 5 [1 2 3 4 5 6 7 8 9 10]) ;=> @seq(1 2 3 4 5)
```"
  (lazy-seq #(if (> n 0)
                 (match (seq coll)
                   s (cons (first s) (take (- n 1) (rest s)))
                   _ nil)
                 nil)))

(fn take-while [pred coll]
  "Take the elements from the collection `coll` until `pred` returns logical
false for any of the elemnts.  Returns a lazy sequence."
  (lazy-seq #(match (seq coll)
               s (let [v (first s)]
                   (if (pred v)
                       (cons v (take-while pred (rest s)))
                       nil))
               _ nil)))

(fn drop [n coll]
  "Drop `n` elements from collection `coll`, returning a lazy sequence
of remaining elements."
  (let [step (fn step [n coll]
               (let [s (seq coll)]
                 (if (and (> n 0) s)
                     (step (- n 1) (rest s))
                     s)))]
    (lazy-seq #(step n coll))))

(fn drop-while [pred coll]
  "Drop the elements from the collection `coll` until `pred` returns logical
false for any of the elemnts.  Returns a lazy sequence."
  (let [step (fn [pred coll]
               (let [s (seq coll)]
                 (if (and s (pred (first s)))
                     (step pred (rest s))
                     s)))]
    (lazy-seq #(step pred coll))))

(fn drop-last [...]
  "Return a lazy sequence from `coll` without last `n` elements."
  (match (select "#" ...)
    0 empty-cons
    1 (drop-last 1 ...)
    _ (let [(n coll) ...]
        (map (fn [x] x) coll (drop n coll)))))

(fn take-last [n coll]
  "Return a sequence of last `n` elements of the `coll`."
  ((fn loop [s lead]
     (if lead
         (loop (next s) (next lead))
         s)) (seq coll) (seq (drop n coll))))

(fn take-nth [n coll]
  "Return a lazy sequence of every `n` item in `coll`."
  (lazy-seq
   #(match (seq coll)
      s (cons (first s) (take-nth n (drop n s))))))

(fn split-at [n coll]
  "Return a table with sequence `coll` being split at `n`"
  [(take n coll) (drop n coll)])

(fn split-with [pred coll]
  "Return a table with sequence `coll` being split with `pred`"
  [(take-while pred coll) (drop-while pred coll)])


(fn filter [pred coll]
  "Returns a lazy sequence of the items in the `coll` for which `pred`
returns logical true."
  (lazy-seq
   #(match (seq coll)
      s (let [x (first s) r (rest s)]
          (if (pred x)
              (cons x (filter pred r))
              (filter pred r)))
      _ nil)))

(fn keep [f coll]
  "Returns a lazy sequence of the non-nil results of calling `f` on the
items of the `coll`."
  (lazy-seq #(match (seq coll)
               s (match (f (first s))
                   x (cons x (keep f (rest s)))
                   nil (keep f (rest s)))
               _ nil)))

(fn keep-indexed [f coll]
  "Returns a lazy sequence of the non-nil results of (f index item) in
the `coll`.  Note, this means false return values will be included.
`f` must be free of side-effects."
  (let [keepi (fn keepi [idx coll]
                (lazy-seq
                 #(match (seq coll)
                    s (let [x (f idx (first s))]
                        (if (= nil x)
                            (keepi (+ 1 idx) (rest s))
                            (cons x (keepi (+ 1 idx) (rest s))))))))]
    (keepi 1 coll)))

(fn remove [pred coll]
  "Returns a lazy sequence of the items in the `coll` without elements
for wich `pred` returns logical true."
  (filter #(not (pred $)) coll))

(fn cycle [coll]
  "Create a lazy infinite sequence of repetitions of the items in the
`coll`."
  (lazy-seq #(concat (seq coll) (cycle coll))))

(fn repeat [x]
  "Takes a value `x` and returns an infinite lazy sequence of this value.

# Examples

``` fennel
(assert-eq 10 (accumulate [res 0
                           _ x (pairs (take 10 (repeat 1)))]
                (+ res x)))
```"
  ((fn step [x] (lazy-seq #(cons x (step x)))) x))

(fn repeatedly [f ...]
  "Takes a function `f` and returns an infinite lazy sequence of
function applications.  Rest arguments are passed to the function."
  (let [args (table-pack ...)
        f (fn [] (f (table-unpack args 1 args.n)))]
    ((fn step [f] (lazy-seq #(cons (f) (step f)))) f)))

(fn iterate [f x]
  "Returns an infinete lazy sequence of x, (f x), (f (f x)) etc."
  (let [x* (f x)]
    (cons x (lazy-seq #(iterate f x*)))))

(fn nthnext [coll n]
  "Returns the nth next of `coll`, (seq coll) when `n` is 0."
  ((fn loop [n xs]
     (match (and xs (> n 0))
       false xs
       xs* (loop (- n 1) (next xs*))
       _ xs)) n (seq coll)))

(fn nthrest [coll n]
  "Returns the nth rest of `coll`, `coll` when `n` is 0."
  ((fn loop [n xs]
     (match (and (> n 0) (seq xs))
       false xs
       xs* (loop (- n 1) (rest xs*))
       _ xs)) n coll))

(fn dorun [s]
  "Realize whole sequence for side effects.

Walks whole sequence, realizing each cell.  Use at your own risk on
infinite sequences."
  (match (seq s)
    s* (dorun (next s*))
    _ nil))

(fn doall [s]
  "Realize whole lazy sequence.

Walks whole sequence, realizing each cell.  Use at your own risk on
infinite sequences."
  (doto s (dorun)))

(fn partition [...]
  (match (select "#" ...)
    2 (let [(n coll) ...]
        (partition n n coll))
    3 (let [(n step coll) ...]
        (lazy-seq
         #(match (seq coll)
            s (let [p (take n s)]
                (if (= n (length* p))
                    (cons p (partition n step (nthrest s step)))
                    nil))
            _ nil)))
    4 (let [(n step pad coll) ...]
        (lazy-seq
         #(match (seq coll)
            s (let [p (take n s)]
                (if (= n (length* p))
                    (cons p (partition n step pad (nthrest s step)))
                    (list (take n (concat p pad)))))
            _ nil)))))

(fn partition-by [f coll]
  "Applies `f` to each value in `coll`, splitting it each time `f`
   returns a new value.  Returns a lazy seq of partitions."
  (lazy-seq
   #(match (seq coll)
      s (let [v (first s)
              fv (f v)
              run  (cons f (take-while #(= fv (f $)) (next s)))]
          (cons run (partition-by f (lazy-seq #(drop (length* run) s))))))))

(fn partition-all [...]
  "Returns a lazy sequence of lists like partition, but may include
partitions with fewer than n items at the end."
  (match (select "#" ...)
    2 (let [(n coll) ...]
        (partition n n coll))
    3 (let [(n step coll) ...]
        (lazy-seq
         #(match (seq coll)
            s (let [p (take n s)]
                (cons p (partition n step (nthrest s step))))
            _ nil)))))

(fn reductions [...]
  "Returns a lazy seq of the intermediate values of the reduction (as
per reduce) of `coll` by `f`, starting with `init`."
  (match (select "#" ...)
    2 (let [(f coll) ...]
        (lazy-seq
         #(match (seq coll)
            s (reductions f (first s) (rest s))
            _ (list (f)))))
    3 (let [(f init coll) ...]
        (cons init
              (lazy-seq
               #(match (seq coll)
                  s (reductions f (f init (first s)) (rest s))))))))

(fn contains? [coll elt]
  "Test if `elt` is in the `coll`."
  ((fn loop [coll]
     (match (seq coll)
       s (if (= elt (first s))
             true
             (loop (rest s)))
       nil false)) coll))

(fn distinct [coll]
  "Returns a lazy sequence of the elements of the `coll` without
duplicates.  Comparison is done by equality."
  ((fn step [xs seen]
     (let [loop (fn loop [[f &as xs] seen]
                  (match (seq xs)
                    s (if (contains? seen f)
                          (loop (rest s) seen)
                          (cons f (step (rest s) (cons f seen))))
                    _ nil))]
       (lazy-seq #(loop xs seen))))
   coll empty-cons))

(fn inf-range [x step]
  ;; infinite lazy range builder
  (lazy-seq #(cons x (inf-range (+ x step) step))))

(fn fix-range [x end step]
  ;; fixed lazy range builder
  (lazy-seq #(if (or (and (>= step 0) (< x end))
                     (and (< step 0) (> x end)))
                 (cons x (fix-range (+ x step) end step))
                 (and (= step 0) (not= x end))
                 (cons x (fix-range x end step))
                 nil)))

(fn range [...]
  "Create a possibly infinite sequence of numbers.

If one argument is specified, returns a finite sequence from 0 up to this argument.
If two arguments were specified, returns a finite sequence from lower to, but not included, upper bound.
A third argument provides step interval.

If no arguments were specified, returns an infinite sequence starting at 0.

# Examples

Various ranges:

```fennel
(range 10) ;; => @seq(0 1 2 3 4 5 6 7 8 9)
(range 4 8) ;; => @seq(4 5 6 7)
(range 0 -5 -2) ;; => @seq(0 -2 -4)
(take 10 (range)) ;; => @seq(0 1 2 3 4 5 6 7 8 9)
```"
  (match (select "#" ...)
    0 (inf-range 0 1)
    1 (let [(end) ...]
        (fix-range 0 end 1))
    2 (let [(x end) ...]
        (fix-range x end 1))
    _ (fix-range ...)))

(fn realized? [s]
  "Check if sequence's first element is realized."
  (match (gettype s)
    :lazy-cons false
    :empty-cons true
    :cons true
    _ (error (: "expected a sequence, got: %s" :format _))))

(fn line-seq [file]
  "Accepts a `file` handle, and creates a lazy sequence of lines using
`lines` metamethod.

# Examples

Lazy sequence of file lines may seem similar to an iterator over a
file, but the main difference is that sequence can be shared onve
realized, and iterator can't.  Lazy sequence can be consumed in
iterator style with the `doseq` macro.

Bear in mind, that since the sequence is lazy it should be realized or
truncated before the file is closed:

```fennel
(let [lines (with-open [f (io.open \"init.fnl\" :r)]
              (line-seq f))]
  ;; this errors because only first line was realized, but the file
  ;; was closed before the rest of lines were cached
  (assert-not (pcall next lines)))
```

Sequence is realized with `doall` before file was closed and can be shared:

``` fennel
(let [lines (with-open [f (io.open \"init.fnl\" :r)]
              (doall (line-seq f)))]
  (assert-is (pcall next lines)))
```

Infinite files can't be fully realized, but can be partially realized
with `take`:

``` fennel
(let [lines (with-open [f (io.open \"/dev/urandom\" :r)]
              (doall (take 3 (line-seq f))))]
  (assert-is (pcall next lines)))
```"
  (let [next-line (file:lines)]
    ((fn step [f]
       (let [line (f)]
         (if (= :string (type line))
             (cons line (lazy-seq #(step f)))
             nil)))
     next-line)))

(fn tree-seq [branch? children root]
  "Returns a lazy sequence of the nodes in a tree, via a depth-first walk.

`branch?` must be a fn of one arg that returns true if passed a node
that can have children (but may not).  `children` must be a fn of one
arg that returns a sequence of the children.  Will only be called on
nodes for which `branch?` returns true.  `root` is the root node of
the tree."
  ((fn walk [node]
     (lazy-seq
      #(cons node
             (if (branch? node)
                 (mapcat walk (children node))))))
   root))

(fn iter [s]
  "Transform sequence `s` to a stateful iterator going over its elements.

Provides a safer* iterator that only returns values of a sequence
without the sequence tail. Returns `nil` when no elements left.
Automatically converts its argument to a sequence by calling `seq` on
it.

(* Accidental realization of a tail of an
infinite sequence can freeze your program and eat all memory, as the
sequence is infinite.)"
  (let [s (or (seq s) empty-cons)]
    (var (seq-next _ state) (pairs s))
    #(let [(new-state res) (seq-next s state)]
       (set state new-state)
       res)))

(fn interleave [...]
  "Returns a lazy sequence of the first item in each sequence, then the
second one, until any sequence exhausts."
  (match (values (select "#" ...) ...)
    (0) empty-cons
    (1 ?s) (lazy-seq #?s)
    (2 ?s1 ?s2)
    (lazy-seq #(let [s1 (seq ?s1)
                     s2 (seq ?s2)]
                 (if (and s1 s2)
                     (cons (first s1)
                           (cons (first s2)
                                 (interleave (rest s1) (rest s2))))
                     nil)))
    (_)
    (let [cols (seq [...] (select "#" ...))]
      (lazy-seq #(let [seqs (map seq cols)]
                   (if (every? #(not= nil (seq $)) seqs)
                       (concat (map first seqs)
                               (interleave (unpack (map rest seqs))))))))))

(fn interpose [separator coll]
  "Returns a lazy sequence of the elements of `coll` separated by `separator`."
  (drop 1 (interleave (repeat separator) coll)))

(setmetatable
 {: first
  : rest
  : next
  : cons
  : seq
  : lazy-seq
  : list
  : every?
  : some?
  : pack
  : unpack
  : count
  : concat
  : map
  : map-indexed
  : mapcat
  : take
  : take-while
  : take-last
  : drop
  : drop-while
  : drop-last
  : split-at
  : split-with
  : partition
  : partition-by
  : partition-all
  : filter
  : keep
  : keep-indexed
  : contains?
  : distinct
  : cycle
  : repeat
  : repeatedly
  : range
  : realized?
  : dorun
  : doall
  : line-seq
  : iter
  : interleave
  : interpose}
 {:__index {:_MODULE_NAME "lazy-seq.fnl"
            :_DESCRIPTION "Lazy sequence library for Fennel and Lua.

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
and `lazy-cat`.  These macros are provided for convenience only."}})

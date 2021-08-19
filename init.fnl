(import-macros
 {: lazy-seq}
 (if (= ... :init) :init-macros (or ... :init-macros)))

(fn first [c]
  "Return first element of a sequence."
  (c true))

(fn rest [c]
  "Return the tail of a sequence.
If the sequence is empty, returns empty sequence"
  (c false))

(fn gettype [x]
  (match (?. (getmetatable x) :__type)
    t t
    _ (type x)))

(fn view-seq [list options view indent elements]
  (table.insert elements (view (first list) options indent))
  (let [tail (rest list)]
    (match (type tail)
      (where :table (let [t (gettype tail)]
                      (or (= :cons t)
                          (and (= :lazy-cons t)
                               (do (first tail)
                                   (not= :empty-cons (gettype tail)))))))
      (view-seq tail options view indent elements)))
  elements)

(fn pp-seq [list view options indent]
  (let [items (view-seq list options view (+ indent 5) [])
        lines (icollect [i line (ipairs items)]
                (if (= i 1) line (.. " " line)))]
    (doto lines
      (tset 1 (.. "@seq(" (or (. lines 1) "")))
      (tset (length lines) (.. (. lines (length lines)) ")")))))

(local empty-cons (let [e []]
                    (setmetatable e {:__len 0
                                     :__fennelview #"()"
                                     :__type :empty-cons
                                     :__pairs #(values next [] nil)
                                     :__call #(if $2 nil e)})))

(var seq nil)                   ; forward declaration for seq function

(fn cons [...]
  "Construct a cons cell.
Second element must be either a table or a sequence, or nil."
  (assert (= 2 (select "#" ...)) "expected two arguments for cons")
  (let [(h t) ...]
    (assert (. {:cons true
                :empty-cons true
                :lazy-cons true
                :nil true
                :table true} (gettype t))
            "expected nil or cons as a tail")
    (setmetatable [] {:__call #(if $2 h (match (seq t) s s nil empty-cons))
                      :__type :cons
                      ;; TODO: add ways to iterate and compute length
                      :__fennelview pp-seq})))

(set seq (fn [t]
           "Construct an eager sequence out of a table or another sequence.
Returns `nil` if given empty table, or sequence."
           (match (gettype t)
             :cons t
             :lazy-cons t
             :table (do (var res nil)
                        (for [i (length t) 1 -1]
                          (set res (cons (. t i) res)))
                        res)
             _ (error (: "expected table or sequence, got %s" :format _) 2))))

;;; Sequence generation

;; TODO: make `concat` accept arbitrary amount of collections
(fn concat [x y]
  "Return a lazy sequence of concatenated sequences."
  (lazy-seq
   (match (seq x)
     s (cons (first s) (concat (rest s) y))
     nil (seq y))))

;; TODO: make `map` accept arbitrary amount of collections
(fn map [f col]
  "Map function `f` over every element of a collection `col`.
Returns lazy sequence.

# Examples

```fennel
(map #(+ $ 1) [1 2 3]) ;; => @seq(2 3 4)
(local res (map #(+ $ 1) [:a :b :c])) ;; will blow up when realized
```"
  (lazy-seq
   (match (seq col)
     x (cons (f (first x)) (map f (rest x)))
     _ nil)))

(fn take [n coll]
  "Take `n` elements from the collection `coll`.
Returns a lazy sequence of specified amount of elements.

# Examples

Take 10 element from a sequential table

```fennel
(take 10 [1 2 3]) ;=> @seq(1 2 3)
(take 5 [1 2 3 4 5 6 7 8 9 10]) ;=> @seq(1 2 3 4 5)
```"
  (lazy-seq
   (if (> n 0)
       (match (seq coll)
         s (cons (first s) (take (- n 1) (rest s)))
         _ nil)
       nil)))

;; TODO: add `drop`
;; TODO: add `filter`
;; TODO: add `keep`

;;; Range

(fn inf-range [x step]
  ;; infinite lazy range builder
  (lazy-seq (cons x (inf-range (+ x step) step))))

(fn fix-range [x end step]
  ;; fixed lazy range builder
  (if (or (and (>= step 0) (< x end))
          (and (< step 0) (> x end)))
      (lazy-seq (cons x (fix-range (+ x step) end step)))
      nil))

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

(setmetatable
 {: take
  : range
  : concat
  : map
  : seq
  : cons
  : first
  : rest}
 {:__index {:_DESCRIPTION "Lazy sequence library for Fennel and Lua."
            :_MODULE_NAME "lazy-seq.fnl"}})

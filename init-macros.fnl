(local lseq
  (if (and ... (= ... :init-macros))
      :init
      (or ... :init)))

(fn lazy-seq [...]
  "Create lazy sequence from the result provided by running the body.
Delays the execution until the resulting sequence is consumed.

Same as `lazy-seq`, but doesn't require wrapping the body into an
anonymous function.

# Examples

Infinite* sequence of Fibonacci numbers:

```fennel
(local fib ((fn fib [a b] (lazy-seq (cons a (fib b (+ a b))))) 0 1))

(assert-eq [0 1 1 2 3 5 8]
           [(unpack (take 7 fib))])
```

*Sequence itself is infinite, but the numbers are limited to Lua's VM
number representation.  For true infinite Fibonacci number sequence
arbitrary precision math libraries like lbc or lmapm:

``` fennel
(local (ok? bc) (pcall require :bc))
(when ok?
  (local fib ((fn fib [a b] (lazy-seq (cons a (fib b (+ a b))))) (bc.new 0) (bc.new 1)))
  (assert-eq (bc.new (.. \"4106158863079712603335683787192671052201251086373692524088854309269055842741\"
                         \"1340373133049166085004456083003683570694227458856936214547650267437304544685216\"
                         \"0486606292497360503469773453733196887405847255290082049086907512622059054542195\"
                         \"8897580311092226708492747938595391333183712447955431476110732762400667379340851\"
                         \"9173181099320170677683893476676477873950217447026862782091855384222585830640830\"
                         \"1661862900358266857238210235802504351951472997919676524004784236376453347268364\"
                         \"1526483462458405732142414199379172429186026398100978669423920154046201538186714\"
                         \"25739835074851396421139982713640679581178458198658692285968043243656709796000\"))
             (first (drop 3000 fib))))

```"
  `(let [{:lazy-seq lazy-seq#} (require ,lseq)]
     (lazy-seq# (fn [] ,...))))

(fn lazy-cat [...]
  "Concatenate arbitrary amount of lazy sequences.

# Examples

Lazily concatenate finite sequence with infinite:

```fennel
(local r (lazy-cat (take 10 (range)) (drop 10 (range))))
(assert-eq [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14]
           [(unpack (take 15 r))])
```

Another Fibonacci sequence variant:

```fennel
(global fib (lazy-cat [0 1] (map #(+ $1 $2) (rest fib) fib)))

(assert-eq [0 1 1 2 3 5 8]
           [(unpack (take 7 fib))])
```"
  `(let [{:concat concat# :lazy-seq lazy-seq#} (require ,lseq)]
     (concat# ,(unpack (icollect [_ s (ipairs [...])]
                         `(lazy-seq# (fn [] ,s)))))))


(fn while-body [clauses body]
  (match clauses
    {:while-clause {:body b}}
    `(when ,b
       ,body)
    _ body))

(fn when-body [clause body looper]
  `(if ,clause.body
       (do ,body
           ,looper)
       ,looper))

(fn let-body [clause ...]
  `(let ,clause.body ,...))

;; TODO: rewrite this to be more sequential regarding special clauses
(fn doseq* [first rest clauses binding-vec body]
  (if (= 0 (length binding-vec))
      body
      (let [x (gensym :x) s (gensym :s) loop (gensym :loop)]
        `((fn ,loop [,s]
            (match (,first ,s)
              ,x (let [,(. binding-vec 1) ,x]
                   ,(match clauses
                      {: let-clause : when-clause}
                      (if (< let-clause.weight when-clause.weight)
                          (let-body let-clause
                                    (while-body clauses
                                                (when-body when-clause
                                                           (doseq* first rest clauses [(unpack binding-vec 3)] body)
                                                           `(,loop (,rest ,s)))))
                          (when-body when-clause
                                     (let-body let-clause
                                               (while-body clauses
                                                           `(do ,(doseq* first rest clauses [(unpack binding-vec 3)] body)
                                                                (,loop (,rest ,s)))))))
                      {: let-clause}
                      (let-body let-clause
                                (while-body clauses
                                            `(do ,(doseq* first rest clauses [(unpack binding-vec 3)] body)
                                                 (,loop (,rest ,s)))))
                      {: when-clause}
                      (while-body clauses
                                  (when-body when-clause
                                             (doseq* first rest clauses [(unpack binding-vec 3)] body)
                                             `(,loop (,rest ,s))))
                      _
                      (while-body clauses
                                  `(do ,(doseq* first rest clauses [(unpack binding-vec 3)] body)
                                       (,loop (,rest ,s))))))
              nil nil))
          ,(. binding-vec 2)))))

;; TODO: needs much more testing
(fn doseq [bindings ...]
  "Execute body for side effects with let-like `bindings` for a given
sequences.  Doesn't retain the head of the sequence.  Returns nil.

Supports special clauses: `:let`, `:when`, and `:while`.  `:let` can
introduce new bindings into body form, `:when` controls when the body
is executed, and `:while` will terminate execution once condition
becomes false.  The `:let` and `:when` clauses are evaluated in the
order they appear, `:while` always guards the iteration process.

# Examples

Cartesian product:

```fennel
(local cartesian [])

(doseq [x [:a :b :c]
        y [1 2 3]
        z [:foo :bar]]
  (table.insert cartesian [x y z]))

(assert-eq cartesian
           [[:a 1 :foo] [:a 1 :bar] [:a 2 :foo] [:a 2 :bar] [:a 3 :foo] [:a 3 :bar]
            [:b 1 :foo] [:b 1 :bar] [:b 2 :foo] [:b 2 :bar] [:b 3 :foo] [:b 3 :bar]
            [:c 1 :foo] [:c 1 :bar] [:c 2 :foo] [:c 2 :bar] [:c 3 :foo] [:c 3 :bar]])
```

Using `:let` special clause:

```fennel
(local res [])

(doseq [x [1 2 3]
        :let [y (+ x 1)]]
  (table.insert res [x y]))

(assert-eq res [[1 2] [2 3] [3 4]])
```

Using `:when` special clause:

```fennel
(local res [])

(doseq [x [1 2 3 4 5 6 7 8]
        :when (= 0 (% x 2))]
  (table.insert res x))

(assert-eq res [2 4 6 8])
```

Using `:while` special clause:

```fennel
(local res [])

(doseq [x (range)
        :while (< x 10)]
  (table.insert res x))

(assert-eq res [0 1 2 3 4 5 6 7 8 9])
```
"
  (assert-compile (sequence? bindings) "expected a sequential table with bindings" bindings)
  (assert-compile (= 0 (% (length bindings) 2)) "expected even amount of name/value bindings" bindings)
  (var skip-next? false)
  (let [first (gensym :first)
        rest (gensym :rest)
        binding-vec []
        clauses (collect [i x (ipairs bindings)]
                  (if (or (= x :let) (= x :when) (= x :while))
                      (do (set skip-next? true)
                          (values (.. x "-clause") {:body (. bindings (+ i 1)) :weight i}))
                      skip-next?
                      (set skip-next? false)
                      ;; else
                      (table.insert binding-vec x)))]
    `(let [{:rest ,rest :first ,first} (require ,lseq)]
       ,(doseq* first rest clauses binding-vec `(do ,...)))))

(setmetatable
 {: lazy-seq
  : lazy-cat
  : doseq}
 {:__index {:_DESCRIPTION "Macros for creating lazy sequences."
            :_MODULE_NAME "macros.fnl"}})

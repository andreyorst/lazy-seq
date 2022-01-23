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
           (take 15 r))
```

Another Fibonacci sequence variant:

```fennel
(global fib (lazy-cat [0 1] (map #(+ $1 $2) (rest fib) fib)))

(assert-eq [0 1 1 2 3 5 8]
           (take 7 fib))
```"
  `(let [{:concat concat# :lazy-seq lazy-seq#} (require ,lseq)]
     (concat# ,(unpack (icollect [_ s (ipairs [...])]
                         `(lazy-seq# (fn [] ,s)))))))


;; TODO: implement `doseq'
;; TODO: implement Clojure's `for' as a way to produce lazy sequences

{: lazy-seq
 : lazy-cat}

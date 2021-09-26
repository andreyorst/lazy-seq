(require-macros :fennel-test.test)
(local suit (require :init))

(fn ->vec [s]
  (icollect [_ x (pairs s)]
    x))

(deftest "seq"
  (let [{: seq : rest} suit]
    (testing "creating seqs from tables"
      (assert-is (seq [1 2 3]))
      (assert-is (seq {:a 1 :b 2})))
    (testing "invalid args"
      (assert-not (pcall seq 10)))
    (testing "empty seq returns nil"
      (assert-eq nil (seq []))
      (assert-eq nil (seq (rest (seq [1]))))
      (assert-eq nil (seq (rest (seq {:a 1})))))))

(deftest "printing sequences"
  (let [{: seq : lazy-seq* : rest} suit
        view (require :fennel.view)]
    (testing "seq pretty-printing"
      (assert-eq "@seq(1)" (view (seq [1])))
      (assert-eq "@seq(1 2 3)" (view (seq [1 2 3])))
      (assert-eq "@seq([\"a\" 1])" (view (seq {:a 1})))
      (assert-eq "@seq()" (view (rest (seq [1]))))
      (assert-eq "@seq(1)" (view (lazy-seq* #[1])))
      (assert-eq "@seq(1 2 3)" (view (lazy-seq* #[1 2 3])))
      (assert-eq "@seq([\"b\" 2])" (view (lazy-seq* #{:b 2})))
      (assert-eq "@seq()" (view (rest (lazy-seq* #[1])))))
    (if (: (tostring (setmetatable {} {:__name "foo"})) :match :foo)
        (testing "seq tostring"
          (assert-is (: (tostring (seq [1])) :match "cons"))
          (assert-is (: (tostring (rest (seq [1]))) :match "cons"))
          (assert-is (: (tostring (lazy-seq* #[1])) :match "lazy cons"))
          (assert-is (: (tostring (rest (lazy-seq* #[1]))) :match "cons")))
        (io.stderr:write "info: Skipping tostring test\n"))))

(deftest "equality"
  (if (= (setmetatable {} {:__eq (fn [a b] (rawequal a b))})
         (setmetatable {} {:__eq (fn [a b] (rawequal a b))}))
      (let [{: seq : take : range : drop : map} suit]
        (testing "comparing seqs"
          (assert-is (= (seq [1 2 3]) (seq [1 2 3])))
          (assert-is (= (seq [0 1 2]) (take 3 (range)))))
        (testing "comparing lazy seqs"
          (assert-is (= (seq [0 1 2]) (take 3 (range))))
          (assert-is (= (map #(+ $ 1) [0 1 2]) (drop 1 (take 3 (range))))))
        (testing "comparing seqs and tables"
          (assert-is (= (seq [1 2 3]) [1 2 3]))
          (assert-is (= (take 3 (range)) [0 1 2])))
        (testing "using test suite equality"
          (assert-eq (seq [1 2 3]) (seq [1 2 3]))
          (assert-eq (seq [0 1 2]) (take 3 (range)))
          (assert-eq (seq [0 1 2]) (take 3 (range)))
          (assert-eq (map #(+ $ 1) [0 1 2]) (drop 1 (take 3 (range))))
          (assert-eq (seq [1 2 3]) [1 2 3])
          (assert-eq (take 3 (range)) [0 1 2])))
      (io.stderr:write "info: Skipping equality test\n")))

(deftest "conses"
  (let [{: cons} suit]
    (testing "cons arity"
      (assert-not (pcall cons))
      (assert-not (pcall cons nil)))
    (testing "cons expects table, nil or seq"
      (assert-not (pcall cons 1 2))
      (assert-is (cons 1 nil))
      (assert-is (cons 1 []))
      (assert-is (cons 1 (cons nil nil))))))

(deftest "sequences"
  (let [{: lazy-seq* : dorun : seq : first : rest : cons} suit]
    (testing "seq returns nil"
      (assert-eq nil (seq nil))
      (assert-eq nil (seq []))
      (assert-eq nil (seq (rest [])))
      (assert-eq nil (first nil)))
    (testing "lazy-seq returns lazy "
      (let [se {}
            s (lazy-seq* #(tset se :a 42) [1 2 3])]
        (assert-eq se {})
        (dorun s)
        (assert-eq se {:a 42})))
    (testing "lazy-seq realized on printing"
      (let [se {}
            s (lazy-seq* #(tset se :a 42) [1 2 3])]
        (assert-eq se {})
        ((require :fennel.view) s)
        (assert-eq se {:a 42})))
    (testing "counting"
      (assert-eq 3 (length (seq [1 2 3])))
      (assert-eq 3 (length (lazy-seq* #[1 2 3]))))
    (testing "iteration"
      (assert-eq [1 2 3 4 5]
                 (icollect [_ v (pairs (seq [1 2 3 4 5]))] v))
      (assert-eq [1 2 3 4 5]
                 (icollect [_ v (pairs (lazy-seq* #[1 2 3 4 5]))] v))
      (global s (lazy-seq* #(cons 1 s)))
      (var i 0)
      (assert-eq [1 1 1 1 1]
                 (icollect [_ v (pairs s) :until (= i 5)]
                   (do (set i (+ i 1))
                       v))))))

(deftest "map"
  (let [{: map : dorun} suit]
    (testing "map is lazy"
      (let [se []
            s1 (map #(table.insert se $) [1 2 3])
            s2 (map #(table.insert se $) [4 5 6] [1 2 3])
            s3 (map #(table.insert se $) [7 8 9] [4 5 6] [1 2 3])
            s4 (map #(table.insert se $) [10 11 12] [7 8 9] [4 5 6] [1 2 3])]
        (assert-eq se {})
        (dorun s1)
        (assert-eq [1 2 3] se)
        (dorun s2)
        (assert-eq [1 2 3 4 5 6] se)
        (dorun s3)
        (assert-eq [1 2 3 4 5 6 7 8 9] se)
        (dorun s4)
        (assert-eq [1 2 3 4 5 6 7 8 9 10 11 12] se)))
    (testing "map length"
      (assert-eq 3 (length (map #nil [1 2 3]))))
    (testing "map accepts arbitrary amount of collections"
      (assert-eq (->vec (map #[$...] [:a]))
                 [[:a]])
      (assert-eq (->vec (map #[$...] [:a] [:b]))
                 [[:a :b]])
      (assert-eq (->vec (map #[$...] [:a :d] [:b :e] [:c :f]))
                 [[:a :b :c] [:d :e :f]])
      (assert-eq (->vec (map #[$...] [:a :d] [:b :e] [:c :f] [:x :y :z]))
                 [[:a :b :c :x] [:d :e :f :y]]))))

(deftest "seq packing/unpacking"
  (let [{: seq : seq-pack : seq-unpack} suit]
    (testing "packing seq"
      (assert-eq (seq-pack (seq [1 2 3]))
                 {1 1 2 2 3 3 :n 3}))
    (testing "unpacking seq"
      (assert-eq [1 2 3] [(seq-unpack (seq [1 2 3]))]))))

(deftest "filter"
  (let [{: filter : seq : take : range} suit]
    (testing "filter is lazy"
      (let [se []
            res (filter #(do (table.insert se $) (> $ 0)) [1 -1 2 -2 3 -3])]
        (assert-eq se [])
        (assert-eq [1 2 3] (->vec res))
        (assert-eq se [1 -1 2 -2 3 -3])
        (assert-eq [0 2 4 6 8] (->vec (take 5 (filter #(= 0 (% $ 2)) (range)))))))
    (testing "filtering"
      (assert-eq 0 (length (filter #(< $ 0) [1 2 3])))
      (assert-eq [] (->vec (filter #(< $ 0) [1 2 3])))
      (assert-eq nil (seq (filter #(< $ 0) [1 2 3])))
      (assert-eq [1 2 3] (->vec (filter #(> $ 0) [-1 1 2 -2 -3 -3 -3 -3 3]))))))

(deftest "keep"
  (let [{: keep : take : range} suit]
    (testing "keep is lazy"
      (let [se []
            res (keep #(do (table.insert se $) (if (> $ 0) $ nil))
                      [1 -1 2 -2 3 -3])]
        (assert-eq se [])
        (assert-eq [1 2 3] (->vec res))
        (assert-eq se [1 -1 2 -2 3 -3])
        (assert-eq [true false true false true]
                   (->vec (take 5 (keep #(= 0 (% $ 2)) (range)))))))))

(deftest "concat"
  (let [{: concat : lazy-seq* : range : take} suit]
    (testing "concat arities"
      (assert-is (concat))
      (assert-eq [1 2] (->vec (concat [1] [2])))
      (assert-eq [1 2 3] (->vec (concat [1] [2] [3])))
      (assert-eq [1 2 3 4] (->vec (concat [1] [2] [3] [4])))
      (assert-eq [1 2 3 4 5] (->vec (concat [1] [2] [3] [4] [5]))))
    (testing "concat is lazy"
      (let [se []
            c1 (concat (lazy-seq* #(do (table.insert se 1) [1])))
            c2 (concat (lazy-seq* #(do (table.insert se 1) [1]))
                       (lazy-seq* #(do (table.insert se 2) [2])))
            c3 (concat (lazy-seq* #(do (table.insert se 1) [1]))
                       (lazy-seq* #(do (table.insert se 2) [2]))
                       (lazy-seq* #(do (table.insert se 3) [3])))
            c4 (concat (lazy-seq* #(do (table.insert se 1) [1]))
                       (lazy-seq* #(do (table.insert se 2) [2]))
                       (lazy-seq* #(do (table.insert se 3) [3]))
                       (lazy-seq* #(do (table.insert se 4) [4])))]
        (assert-eq se [])
        (assert-eq [1] (->vec c1))
        (assert-eq se [1])
        (assert-eq [1 2] (->vec c2))
        (assert-eq se [1 1 2])
        (assert-eq [1 2 3] (->vec c3))
        (assert-eq se [1 1 2 1 2 3])
        (assert-eq [1 2 3 4] (->vec c4))
        (assert-eq se [1 1 2 1 2 3 1 2 3 4])
        (assert-eq [-1 0 1 2 3]
                   (->vec (take 5 (concat [-1] (range)))))))))

(deftest "every?"
  (let [{: every?} suit]
    (testing "every?"
      (assert-is (every? #(> $ 0) [1 2 3]))
      (assert-not (every? #(> $ 0) [1 0 3]))
      (assert-not (every? #(> $ 0) [])))))

(deftest "some?"
  (let [{: some?} suit]
    (testing "some?"
      (assert-is (some? #(> $ 0) [-1 2 -3]))
      (assert-not (some? #(> $ 0) [-1 0 -3]))
      (assert-not (some? #(> $ 0) [])))))

(deftest "cycle"
  (let [{: cycle : take : map} suit]
    (testing "cycling a table"
      (assert-eq [1 2 3 1 2 3 1 2 3 1]
                 (->vec (take 10 (cycle [1 2 3])))))
    (testing "cycling a lazy seq"
      (assert-eq [1 2 3 1 2 3 1 2 3 1]
                 (->vec (take 10 (cycle (map #$ [1 2 3]))))))))

(deftest "repeat"
  (let [{: repeat : take} suit]
    (testing "repeating a value"
      (assert-eq [42 42 42 42 42 42 42 42 42 42]
                 (->vec (take 10 (repeat 42)))))))

(deftest "repeatedly"
  (let [{: repeatedly : take} suit]
    (testing "repeating a function call"
      (assert-eq [42 42 42 42 42 42 42 42 42 42]
                 (->vec (take 10 (repeatedly #42)))))))

(deftest "range"
  (let [{: range : take} suit]
    (testing "fixed ranges"
      (assert-eq (->vec (take 10 (range))) [0 1 2 3 4 5 6 7 8 9])
      (assert-eq (->vec (range 10)) [0 1 2 3 4 5 6 7 8 9])
      (assert-eq (->vec (range 1 5)) [1 2 3 4])
      (assert-eq (->vec (range 1 -5)) [])
      (assert-eq (->vec (range -1 5)) [-1 0 1 2 3 4])
      (assert-eq (->vec (range -1 -5)) [])
      (assert-eq (->vec (range -5 -1)) [-5 -4 -3 -2])
      (assert-eq (->vec (range -5 -1 -1)) [])
      (assert-eq (->vec (range -1 -5 -1)) [-1 -2 -3 -4])
      (assert-eq (->vec (take 10 (range -1 -5 0))) [-1 -1 -1 -1 -1 -1 -1 -1 -1 -1])
      (assert-eq (->vec (take 10 (range -5 -1 0))) [-5 -5 -5 -5 -5 -5 -5 -5 -5 -5])
      (assert-eq (->vec (take 10 (range -5 0 0))) [-5 -5 -5 -5 -5 -5 -5 -5 -5 -5])
      (assert-eq (->vec (range 0)) [])
      (assert-eq (->vec (range 0 0)) [])
      (assert-eq (->vec (range 0 0 0)) []))))

(deftest "realized?"
  (let [{: realized? : lazy-seq*} suit]
    (testing "realized?"
      (assert-is (realized? [1 2 3]))
      (assert-not (realized? (lazy-seq* #nil))))))

(deftest "doall and dorun"
  (let [{: doall : dorun : map : seq : seq-pack} suit]
    (testing "doall"
      (let [se []
            s (map #(table.insert se $) [1 2 3])]
        (assert-eq se [])
        (assert-eq {:n 3} (seq-pack (doall s)))
        (assert-eq se [1 2 3])))
    (testing "dorun"
      (let [se []
            s (map #(table.insert se $) [1 2 3])]
        (assert-eq se [])
        (assert-eq nil (dorun s))
        (assert-eq se [1 2 3])))))

(deftest "line sequence"
  (let [{: line-seq : take} suit]
    (testing "line-seq is lazy"
      (let [se []
            f {:lines (fn [] #(do (table.insert se 42) "42"))}
            lines (line-seq f)]
        (assert-eq se [42])
        (assert-eq [:42 :42 :42 :42 :42 :42 :42 :42 :42 :42]
                   (->vec (take 10 lines)))
        (assert-eq [42 42 42 42 42 42 42 42 42 42]
                   se)))))

(deftest "iter"
  (let [{: iter : seq : lazy-seq*} suit]
    (testing "iterator over sequences"
      (let [s (seq [1 2 3])]
        (assert-eq [1 2 3] (icollect [x (iter s)] x)))
      (let [s (lazy-seq* #[1 2 3])]
        (assert-eq [1 2 3] (icollect [x (iter s)] x))))))

(deftest "interleave"
  (let [{: interleave : lazy-seq* : rest} suit]
    (testing "interleave"
      (assert-eq (rest [1]) (interleave))
      (assert-eq [1 2 3] (->vec (interleave [1 2 3])))
      (assert-eq [1 4 2 5 3 6] (->vec (interleave [1 2 3] [4 5 6])))
      (assert-eq [1 4 7 2 5 8 3 6 9] (->vec (interleave [1 2 3] [4 5 6] [7 8 9])))
      (assert-eq [1 4 7] (->vec (interleave [1 2 3] [4 5 6] [7])))
      (assert-eq [1 4 2 5 3 6] (->vec (interleave (lazy-seq* #[1 2 3]) (lazy-seq* #[4 5 6])))))))

(deftest "interpose"
  (let [{: interpose : lazy-seq*} suit]
    (testing "interpose"
      (assert-eq [1 0 2 0 3] (->vec (interpose 0 [1 2 3])))
      (assert-eq [1 0 2 0 3] (->vec (interpose 0 (lazy-seq* #[1 2 3])))))))

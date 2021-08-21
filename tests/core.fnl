(require-macros :fennel-test.test)
(local suit (require :init))

(deftest "conses"
  (let [{: cons} suit]
    (testing "cons arity"
      (assert-not (pcall cons))
      (assert-not (pcall cons nil)))
    (testing "cons expects table or seq"
      (assert-not (pcall cons 1 2))
      (assert-is (cons 1 nil))
      (assert-is (cons 1 []))
      (assert-is (cons 1 (cons nil nil)))))
  )

(deftest "sequences"
  (let [{:lazy-seq* lazy-seq
         : dorun : seq} suit]
    (testing "seq returns nil"
      (assert-eq nil (seq nil))
      (assert-eq nil (seq [])))
    (testing "lazy-seq returns lazy "
      (let [se {}
            s (lazy-seq #(tset se :a 42) [1 2 3])]
        (assert-eq se {})
        (dorun s)
        (assert-eq se {:a 42})))
    (testing "counting"
      (assert-eq 3 (length (seq [1 2 3])))
      (assert-eq 3 (length (lazy-seq #[1 2 3])))
      (assert-eq 3 (length (seq [] 3))))))

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
      (let [->vec #(icollect [_ x (pairs $)] x)]
        (assert-eq (->vec (map #[$...] [:a]))
                   [[:a]])
        (assert-eq (->vec (map #[$...] [:a] [:b]))
                   [[:a :b]])
        (assert-eq (->vec (map #[$...] [:a :d] [:b :e] [:c :f]))
                   [[:a :b :c] [:d :e :f]])
        (assert-eq (->vec (map #[$...] [:a :d] [:b :e] [:c :f] [:x :y :z]))
                   [[:a :b :c :x] [:d :e :f :y]])))))

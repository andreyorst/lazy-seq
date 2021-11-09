(require-macros :fennel-test)
(local suit (require :init))

(local lua-pairs pairs)
(local lua-ipairs ipairs)

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

(fn ->vec [s]
  (icollect [_ x (pairs s)]
    x))

(fn lua53-eq? []
  ;; detect if __eq metamethods work as in Lua 5.3. e.g. doesn't have
  ;; to be identical functions
  (= (setmetatable {} {:__eq #true}) {}))

(fn lua53-unpack? []
  ;; detect if __len metamethods work as in Lua 5.3. e.g. is used in
  ;; unpacking
  (= 1 ((or table.unpack _G.unpack) (setmetatable {} {:__index [1] :__len #1}))))

(fn lua53-tostring? []
  ;; detect if __name is supported by tostring
  (let [s (-> {} (setmetatable {:__name "foo"}) tostring)]
    (= (s:match :foo) :foo)))

(fn fennelrest-supported? []
  (let [[_ & x] (setmetatable [] {:__fennelrest #true})]
    (= x true)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(deftest conses-test
  (let [{: cons} suit]
    (testing "cons expects table, string, nil or seq"
      (assert-not (pcall cons 1 2))
      (assert-is (cons 1 nil))
      (assert-is (cons 1 []))
      (assert-is (cons 1 (cons nil nil)))
      (assert-is (cons 1 "foo")))
    (testing "general consing"
      (assert-eq (->vec (cons 1 nil)) [1])
      (assert-eq (->vec (cons 1 [])) [1])
      (assert-eq (->vec (cons 1 [2])) [1 2])
      (assert-eq (->vec (cons 1 [2])) [1 2])
      (assert-eq (->vec (cons 1 "abc")) [1 "a" "b" "c"])
      (assert-eq (->vec (cons 1 (cons 2 (cons 3 (cons 4 nil))))) [1 2 3 4]))
    (testing "conses are immutable"
      (assert-not (pcall #(tset (cons nil nil) 1 42))))))


(deftest first-test
  (let [{: first : cons} suit]
    (testing "first"
      (assert-eq (first []) nil)
      (assert-eq (first [1 2 3]) 1)
      (assert-eq (first "a") "a")
      (assert-eq (first (cons 1 (cons 2 nil))) 1))))


(deftest rest-test
  (let [{: rest : cons} suit]
    (testing "rest"
      (assert-eq (->vec (rest [])) [])
      (assert-eq (->vec (rest [1 2 3])) [2 3])
      (assert-eq (->vec (rest "abc")) ["b" "c"])
      (assert-eq (->vec (rest (cons 1 (cons 2 nil)))) [2]))
    (testing "rest retunrs empty-cons for empty sequences"
      (assert-eq (->vec (rest [])) [])
      (assert-eq (->vec (rest "")) [])
      (assert-eq (->vec (rest (rest (cons nil nil)))) []))
    (testing "empty-cons is immutable"
      (assert-not (pcall #(tset (rest []) 1 42))))))


(deftest nthrest-test
  (let [{: nthrest} suit]
    (testing "nthrest"
      (assert-eq (->vec (nthrest [1 2 3] 2)) [3])
      (assert-eq (->vec (nthrest [1 2 3] 3)) []))))


(deftest next-test
  (let [{:next snext : rest : cons} suit]
    (testing "next returns nil for empty sequences"
      (assert-eq (snext []) nil)
      (assert-eq (snext "") nil)
      (assert-eq (snext (rest (cons nil nil))) nil))))


(deftest nthnext-test
  (let [{: nthnext} suit]
    (testing "nthnext"
      (assert-eq (->vec (nthnext [1 2 3] 2)) [3])
      (assert-eq (nthnext [1 2 3] 3) nil))))


(deftest list-test
  (let [{: list} suit]
    (testing "list"
      (assert-eq (->vec (list)) [])
      (assert-eq (->vec (list 1 2 3 4 5)) [1 2 3 4 5]))))


(deftest seq-test
  (let [{: seq : rest} suit]
    (testing "creating seqs from tables"
      (assert-is (seq [1 2 3]))
      (assert-is (seq {:a 1 :b 2})))
    (testing "creating seqs from strings"
      (assert-eq (->vec (seq "foo")) ["f" "o" "o"])
      (if _G.utf8
          (assert-eq (->vec (seq "ваыв")) ["в" "а" "ы" "в"])
          (assert-eq (->vec (seq "ваыв"))
                     (icollect [_ c (ipairs [208 178 208 176 209 139 208 178])]
                       (string.char c)))))
    (testing "invalid args"
      (assert-not (pcall seq 10)))
    (testing "empty seq returns nil"
      (assert-eq nil (seq []))
      (assert-eq nil (seq (rest (seq [1]))))
      (assert-eq nil (seq (rest (seq {:a 1})))))))


(deftest seq?-test
  (let [{: seq? : seq : list : cons : lazy-seq} suit]
    (testing "seq?"
      (assert-is (seq? (seq [1])))
      (assert-not (seq? (seq [])))
      (assert-is (seq? (cons 1 [2])))
      (assert-is (seq? (list 1 2 3)))
      (assert-is (seq? (lazy-seq #[1 2 3]))))))


(deftest empty?-test
  (let [{: empty? : seq : list} suit]
    (assert-is (empty? []))
    (assert-is (empty? (list)))
    (assert-not (empty? (list 1 2 3)))
    (assert-not (empty? (seq [1 2 3])))))


(deftest printing-sequences-test
  (let [{: seq : lazy-seq : rest} suit
        view (require :fennel.view)]
    (testing "seq pretty-printing"
      (assert-eq "@seq(1)" (view (seq [1])))
      (assert-eq "@seq(1 2 3)" (view (seq [1 2 3])))
      (assert-eq "@seq([\"a\" 1])" (view (seq {:a 1})))
      (assert-eq "@seq(\"c\" \"h\" \"a\" \"r\")" (view (seq "char")))
      (assert-eq "@seq()" (view (rest (seq [1]))))
      (assert-eq "@seq(1)" (view (lazy-seq #[1])))
      (assert-eq "@seq(1 2 3)" (view (lazy-seq #[1 2 3])))
      (assert-eq "@seq([\"b\" 2])" (view (lazy-seq #{:b 2})))
      (assert-eq "@seq()" (view (rest (lazy-seq #[1]))))
      (assert-eq "@seq(\"c\" \"h\" \"a\" \"r\")" (view (lazy-seq #"char"))))
    (if (lua53-tostring?)
        (testing "seq tostring"
          (assert-is (: (tostring (seq [1])) :match "cons"))
          (assert-is (: (tostring (rest (seq [1]))) :match "cons"))
          (assert-is (: (tostring (lazy-seq #[1])) :match "lazy cons"))
          (assert-is (: (tostring (rest (lazy-seq #[1]))) :match "cons")))
        (io.stderr:write "info: Skipping tostring test\n"))))


(deftest take-test
  (let [{: take : list : lazy-seq} suit]
    (testing "take"
      (assert-eq [1 2 3] (->vec (take 3 [1 2 3 4])))
      (assert-eq [1 2 3] (->vec (take 3 (list 1 2 3 4)))))
    (testing "take is lazy"
      (let [se []
            s (take 3 (lazy-seq #(do (table.insert se 1) [1 2 3 4 5])))]
        (assert-eq se [])
        (assert-eq [1 2 3] (->vec s))
        (assert-eq se [1])))))


(deftest take-while-test
  (let [{: take-while : list : lazy-seq} suit]
    (testing "take-while"
      (assert-eq [1 2 3] (->vec (take-while #(< $ 4) [1 2 3 4])))
      (assert-eq [1 2 3] (->vec (take-while #(< $ 4) (list 1 2 3 4)))))
    (testing "take is lazy"
      (let [se []
            s (take-while #(< $ 4) (lazy-seq #(do (table.insert se 1) [1 2 3 4 5])))]
        (assert-eq se [])
        (assert-eq [1 2 3] (->vec s))
        (assert-eq se [1])))))


(deftest take-last-test
  (let [{: take-last : list} suit]
    (testing "take-last"
      (assert-eq [2 3 4] (->vec (take-last 3 [1 2 3 4])))
      (assert-eq [2 3 4] (->vec (take-last 3 (list 1 2 3 4))))
      (assert-eq [1 2 3 4] (->vec (take-last 10 (list 1 2 3 4))))
      (assert-eq nil (take-last 0 [1 2 3 4])))))


(deftest drop-test
  (let [{: drop : list : lazy-seq} suit]
    (testing "drop"
      (assert-eq [4] (->vec (drop 3 [1 2 3 4])))
      (assert-eq [4] (->vec (drop 3 (list 1 2 3 4)))))
    (testing "drop is lazy"
      (let [se []
            s (drop 3 (lazy-seq #(do (table.insert se 1) [1 2 3 4 5])))]
        (assert-eq se [])
        (assert-eq [4 5] (->vec s))
        (assert-eq se [1])))))


(deftest drop-while-test
  (let [{: drop-while : list : lazy-seq} suit]
    (testing "drop-while"
      (assert-eq [4] (->vec (drop-while #(< $ 4) [1 2 3 4])))
      (assert-eq [4] (->vec (drop-while #(< $ 4) (list 1 2 3 4)))))
    (testing "drop-while is lazy"
      (let [se []
            s (drop-while #(< $ 4) (lazy-seq #(do (table.insert se 1) [1 2 3 4 5])))]
        (assert-eq se [])
        (assert-eq [4 5] (->vec s))
        (assert-eq se [1])))))


(deftest drop-last-test
  (let [{: drop-last : list : lazy-seq} suit]
    (testing "drop-last"
      (assert-eq [1] (->vec (drop-last 3 [1 2 3 4])))
      (assert-eq [1] (->vec (drop-last 3 (list 1 2 3 4))))
      (assert-eq [] (->vec (drop-last 10 (list 1 2 3 4)))))
    (testing "drop-last is lazy"
      (let [se []
            s (drop-last 3 (lazy-seq #(do (table.insert se 1) [1 2 3 4 5])))]
        (assert-eq se [])
        (assert-eq [1 2] (->vec s))
        (assert-eq se [1])))))


(deftest equality-test
  (if (lua53-eq?)
      (let [{: seq : take : range : drop : map : list} suit]
        (testing "comparing seqs"
          (assert-is (= (seq [1 2 3]) (seq [1 2 3])))
          (assert-is (= (seq [0 1 2]) (take 3 (range)))))
        (testing "comparing lazy seqs"
          (assert-is (= (seq [0 1 2]) (take 3 (range))))
          (assert-is (= (map #(+ $ 1) [0 1 2]) (drop 1 (take 3 (range))))))
        (testing "comparing seqs and tables"
          (assert-is (= (seq [1 2 3]) [1 2 3]))
          (assert-is (= (take 3 (range)) [0 1 2])))
        (testing "comparing to empty-list"
          (assert-not (= (list) (list nil)))
          (assert-not (= (list nil) (list)))
          (assert-is (= (list) (map #nil [])))
          (assert-is (= (map #nil []) (list)))
          (assert-not (= (list) (map #nil [1])))
          (assert-not (= (map #nil [1]) (list))))
        (testing "using test suite equality"
          (assert-eq (seq [1 2 3]) (seq [1 2 3]))
          (assert-eq (seq [0 1 2]) (take 3 (range)))
          (assert-eq (seq [0 1 2]) (take 3 (range)))
          (assert-eq (map #(+ $ 1) [0 1 2]) (drop 1 (take 4 (range))))
          (assert-eq (seq [1 2 3]) [1 2 3])
          (assert-eq [1 2 3] (seq [1 2 3]))
          (assert-eq (take 3 (range)) [0 1 2])))
      (io.stderr:write "info: Skipping equality test\n")))


(deftest indexing-test
  (let [{: range : realized? : drop} suit]
    (testing "destructuring"
      (let [[_ a b c & rest] (range 10)]
        (assert-eq 6 (+ a b c))
        (if (or (fennelrest-supported?) (lua53-unpack?))
            (assert-eq [4 5 6 7 8 9] (->vec rest))
            (io.stderr:write "info: Skipping destructuring rest packing test\n"))))
    (testing "destructuring doesn't realize whole collection"
      (let [[_ _ _ _ &as r] (range 10)]
        (assert-not (realized? (drop 4 r)))))))


(deftest sequences-test
  (let [{: lazy-seq : dorun : seq : first : rest : cons} suit]
    (testing "seq returns nil"
      (assert-eq nil (seq nil))
      (assert-eq nil (seq []))
      (assert-eq nil (seq (rest [])))
      (assert-eq nil (first nil)))
    (testing "lazy-seq returns a lazy sequence"
      (let [se {}
            s (lazy-seq #(tset se :a 42) [1 2 3])]
        (assert-eq se {})
        (dorun s)
        (assert-eq se {:a 42})))
    (testing "lazy-seq realized on printing"
      (let [se {}
            s (lazy-seq #(tset se :a 42) [1 2 3])]
        (assert-eq se {})
        ((require :fennel.view) s)
        (assert-eq se {:a 42})))
    (testing "counting"
      (assert-eq 3 (length* (seq [1 2 3])))
      (assert-eq 3 (length* (lazy-seq #[1 2 3]))))
    (testing "iteration"
      (assert-eq [1 2 3 4 5]
                 (icollect [_ v (pairs (seq [1 2 3 4 5]))] v))
      (assert-eq [1 2 3 4 5]
                 (icollect [_ v (pairs (lazy-seq #[1 2 3 4 5]))] v))
      (global s (lazy-seq #(cons 1 s)))
      (var i 0)
      (assert-eq [1 1 1 1 1]
                 (icollect [_ v (pairs s) :until (= i 5)]
                   (do (set i (+ i 1))
                       v))))
    (testing "lazy-seq is immutable"
      (assert-not (pcall #(tset (lazy-seq #[1 2 3]) 1 42))))))


(deftest count-test
  (let [{: count : list : cons : range : take} suit]
    (testing "count"
      (assert-eq 3 (count (list :a :b :c)) 3)
      (assert-eq 10 (count (range 10)))
      (assert-eq 1 (count (cons 1 nil)))
      (assert-eq 0 (count (list)))
      (assert-eq 0 (count (take 0 (range)))))))


(deftest map-test
  (let [{: map : dorun : lazy-seq} suit]
    (testing "map accepts arbitrary amount of collections"
      (assert-eq (->vec (map #[$...] [:a]))
                 [[:a]])
      (assert-eq (->vec (map #[$...] [:a] [:b]))
                 [[:a :b]])
      (assert-eq (->vec (map #[$...] [:a :d] [:b :e] [:c :f]))
                 [[:a :b :c] [:d :e :f]])
      (assert-eq (->vec (map #[$...] [:a :d] [:b :e] [:c :f] [:x :y :z]))
                 [[:a :b :c :x] [:d :e :f :y]]))
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
        (assert-eq [1 2 3 4 5 6 7 8 9 10 11 12] se))
      (let [se []
            s1 (map #[$] (lazy-seq #(do (table.insert se 1) [1 2 3])))
            s2 (map #[$1 $2]
                    (lazy-seq #(do (table.insert se 2) [4 5 6]))
                    (lazy-seq #(do (table.insert se 3) [1 2 3])))
            s3 (map #[$1 $2 $3]
                    (lazy-seq #(do (table.insert se 4) [7 8 9]))
                    (lazy-seq #(do (table.insert se 5) [4 5 6]))
                    (lazy-seq #(do (table.insert se 6) [1 2 3])))
            s4 (map #[$1 $2 $3 $4]
                    (lazy-seq #(do (table.insert se 7) [10 11 12]))
                    (lazy-seq #(do (table.insert se 8) [7 8 9]))
                    (lazy-seq #(do (table.insert se 9) [4 5 6]))
                    (lazy-seq #(do (table.insert se 10) [1 2 3])))]
        (assert-eq se [])
        (assert-eq (->vec s1) [[1] [2] [3]])
        (assert-eq [1] se)
        (assert-eq (->vec s2) [[4 1] [5 2] [6 3]])
        (assert-eq [1 2 3] se)
        (assert-eq (->vec s3) [[7 4 1] [8 5 2] [9 6 3]])
        (assert-eq [1 2 3 4 5 6] se)
        (assert-eq (->vec s4) [[10 7 4 1] [11 8 5 2] [12 9 6 3]])
        (assert-eq [1 2 3 4 5 6 7 8 9 10] se)))
    (testing "map length"
      (assert-eq 3 (length* (map #nil [1 2 3]))))))


(deftest zipmap-test
  (let [{: zipmap : range : list} suit]
    (testing "zipmap combines keys and values into map"
      (assert-eq {:a 1 :b 2 :c 3} (zipmap [:a :b :c] [1 2 3]))
      (assert-eq {:a 1 :c 3} (zipmap (list :a :b :c) (list 1 nil 3))))
    (testing "zipmap accepts lazy sequences"
      (assert-eq {:a 0 :b 1 :c 2} (zipmap [:a :b :c] (range))))))


(deftest map-indexed-test
  (let [{: map-indexed : dorun} suit]
    (testing "map is lazy"
      (let [se []
            s1 (map-indexed #(table.insert se [$1 $2]) [:a :b :c])]
        (assert-eq se {})
        (dorun s1)))
    (testing "map length"
      (assert-eq 3 (length* (map-indexed #nil [1 2 3]))))))


(deftest mapcat-test
  (let [{: mapcat : lazy-seq} suit]
    (testing "mapcat is lazy"
      (let [se []
            s1 (mapcat #(do (table.insert se $) [$]) [1 2 3])
            s2 (mapcat #(do (table.insert se $) [$1 $2]) [4 5 6] [1 2 3])
            s3 (mapcat #(do (table.insert se $) [$1 $2 $3]) [7 8 9] [4 5 6] [1 2 3])
            s4 (mapcat #(do (table.insert se $) [$1 $2 $3 $4]) [10 11 12] [7 8 9] [4 5 6] [1 2 3])]
        (assert-eq se [])
        (assert-eq (->vec s1) [1 2 3])
        (assert-eq [1 2 3] se)
        (assert-eq (->vec s2) [4 1 5 2 6 3])
        (assert-eq [1 2 3 4 5 6] se)
        (assert-eq (->vec s3) [7 4 1 8 5 2 9 6 3])
        (assert-eq [1 2 3 4 5 6 7 8 9] se)
        (assert-eq (->vec s4) [10 7 4 1 11 8 5 2 12 9 6 3])
        (assert-eq [1 2 3 4 5 6 7 8 9 10 11 12] se))
      (let [se []
            s1 (mapcat #[$] (lazy-seq #(do (table.insert se 1) [1 2 3])))
            s2 (mapcat #[$1 $2]
                       (lazy-seq #(do (table.insert se 2) [4 5 6]))
                       (lazy-seq #(do (table.insert se 3) [1 2 3])))
            s3 (mapcat #[$1 $2 $3]
                       (lazy-seq #(do (table.insert se 4) [7 8 9]))
                       (lazy-seq #(do (table.insert se 5) [4 5 6]))
                       (lazy-seq #(do (table.insert se 6) [1 2 3])))
            s4 (mapcat #[$1 $2 $3 $4]
                       (lazy-seq #(do (table.insert se 7) [10 11 12]))
                       (lazy-seq #(do (table.insert se 8) [7 8 9]))
                       (lazy-seq #(do (table.insert se 9) [4 5 6]))
                       (lazy-seq #(do (table.insert se 10) [1 2 3])))]
        (assert-eq se [])
        (assert-eq (->vec s1) [1 2 3])
        (assert-eq [1] se)
        (assert-eq (->vec s2) [4 1 5 2 6 3])
        (assert-eq [1 2 3] se)
        (assert-eq (->vec s3) [7 4 1 8 5 2 9 6 3])
        (assert-eq [1 2 3 4 5 6] se)
        (assert-eq (->vec s4) [10 7 4 1 11 8 5 2 12 9 6 3])
        (assert-eq [1 2 3 4 5 6 7 8 9 10] se)))))


(deftest seq-pack-unpack-test
  (let [{: seq : pack : unpack} suit]
    (testing "packing seq"
      (assert-eq (pack (seq [1 2 3]))
                 {1 1 2 2 3 3 :n 3}))
    (testing "unpacking seq"
      (assert-eq [1 2 3] [(unpack (seq [1 2 3]))]))))


(deftest filter-test
  (let [{: filter : seq : take : range} suit]
    (testing "filter is lazy"
      (let [se []
            res (filter #(do (table.insert se $) (> $ 0)) [1 -1 2 -2 3 -3])]
        (assert-eq se [])
        (assert-eq [1 2 3] (->vec res))
        (assert-eq se [1 -1 2 -2 3 -3])
        (assert-eq [0 2 4 6 8] (->vec (take 5 (filter #(= 0 (% $ 2)) (range)))))))
    (testing "filtering"
      (assert-eq 0 (length* (filter #(< $ 0) [1 2 3])))
      (assert-eq [] (->vec (filter #(< $ 0) [1 2 3])))
      (assert-eq nil (seq (filter #(< $ 0) [1 2 3])))
      (assert-eq [1 2 3] (->vec (filter #(> $ 0) [-1 1 2 -2 -3 -3 -3 -3 3]))))))


(deftest keep-test
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


(deftest keep-indexed-test
  (let [{: keep-indexed : take : range} suit]
    (testing "keep-indexed is lazy"
      (let [se []
            res (keep-indexed #(do (table.insert se $2) (if (> $2 0) [$1 $2] nil))
                              [1 -1 2 -2 3 -3])]
        (assert-eq se [])
        (assert-eq [[1 1] [3 2] [5 3]] (->vec res))
        (assert-eq se [1 -1 2 -2 3 -3])
        (assert-eq [[1 true] [2 false] [3 true] [4 false] [5 true]]
                   (->vec (take 5 (keep-indexed #[$1 (= 0 (% $2 2))] (range)))))))))


(deftest concat-test
  (let [{: concat : lazy-seq : range : take} suit]
    (testing "concat arities"
      (assert-is (concat))
      (assert-eq [1 2] (->vec (concat [1] [2])))
      (assert-eq [1 2 3] (->vec (concat [1] [2] [3])))
      (assert-eq [1 2 3 4] (->vec (concat [1] [2] [3] [4])))
      (assert-eq [1 2 3 4 5] (->vec (concat [1] [2] [3] [4] [5]))))
    (testing "concat is lazy"
      (let [se []
            c1 (concat (lazy-seq #(do (table.insert se 1) [1])))
            c2 (concat (lazy-seq #(do (table.insert se 1) [1]))
                       (lazy-seq #(do (table.insert se 2) [2])))
            c3 (concat (lazy-seq #(do (table.insert se 1) [1]))
                       (lazy-seq #(do (table.insert se 2) [2]))
                       (lazy-seq #(do (table.insert se 3) [3])))
            c4 (concat (lazy-seq #(do (table.insert se 1) [1]))
                       (lazy-seq #(do (table.insert se 2) [2]))
                       (lazy-seq #(do (table.insert se 3) [3]))
                       (lazy-seq #(do (table.insert se 4) [4])))]
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


(deftest every?-test
  (let [{: every?} suit]
    (testing "every?"
      (assert-is (every? #(> $ 0) [1 2 3]))
      (assert-not (every? #(> $ 0) [1 0 3]))
      (assert-not (every? #(> $ 0) [])))))


(deftest some?-test
  (let [{: some?} suit]
    (testing "some?"
      (assert-is (some? #(> $ 0) [-1 2 -3]))
      (assert-not (some? #(> $ 0) [-1 0 -3]))
      (assert-not (some? #(> $ 0) [])))))


(deftest contains?-test
  (let [{: contains? : range} suit]
    (testing "contains?"
      (assert-is (contains? [1 2 3] 3))
      (assert-not (contains? [1 2 3] 4))
      (assert-is (contains? "foobar" "b"))
      (assert-is (contains? (range) 90)))))


(deftest distinct-test
  (let [{: distinct} suit]
    (testing "distinct"
      (assert-eq [1 2 3] (->vec (distinct [1 1 1 2 2 3 3 1 2 3 3]))))))


(deftest cycle-test
  (let [{: cycle : take : map} suit]
    (testing "cycling a table"
      (assert-eq [1 2 3 1 2 3 1 2 3 1]
                 (->vec (take 10 (cycle [1 2 3])))))
    (testing "cycling a lazy seq"
      (assert-eq [1 2 3 1 2 3 1 2 3 1]
                 (->vec (take 10 (cycle (map #$ [1 2 3]))))))))


(deftest repeat-test
  (let [{: repeat : take} suit]
    (testing "repeating a value"
      (assert-eq [42 42 42 42 42 42 42 42 42 42]
                 (->vec (take 10 (repeat 42)))))))


(deftest iterate-test
  (let [{: iterate : take} suit]
    (testing "iterate"
      (assert-eq [1 2 3 4 5] (->vec (take 5 (iterate #(+ $ 1) 1))))
      (assert-eq [1 2 4 8 16] (->vec (take 5 (iterate (partial * 2) 1)))))))


(deftest repeatedly-test
  (let [{: repeatedly : take} suit]
    (testing "repeating a function call"
      (assert-eq [42 42 42 42 42 42 42 42 42 42]
                 (->vec (take 10 (repeatedly #42)))))
    (testing "repeating a function call with additional arguments"
      (assert-eq [[1 2 3] [1 2 3] [1 2 3]]
                 (->vec (take 3 (repeatedly #[$...] 1 2 3)))))))


(deftest reverse-test
  (let [{: reverse} suit]
    (testing "reverse"
      (assert-eq [3 2 1] (->vec (reverse [1 2 3]))))))


(deftest range-test
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


(deftest realized?-test
  (let [{: realized? : lazy-seq : range : doall} suit]
    (testing "realized?"
      (assert-is (realized? (doall (range 10))))
      (assert-not (realized? (lazy-seq #nil))))))


(deftest doall-and-dorun-test
  (let [{: doall : dorun : map : pack} suit]
    (testing "doall"
      (let [se []
            s (map #(table.insert se $) [1 2 3])]
        (assert-eq se [])
        (assert-eq {:n 3} (pack (doall s)))
        (assert-eq se [1 2 3])))
    (testing "dorun"
      (let [se []
            s (map #(table.insert se $) [1 2 3])]
        (assert-eq se [])
        (assert-eq nil (dorun s))
        (assert-eq se [1 2 3])))))


(deftest line-sequence-test
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


(deftest interleave-test
  (let [{: interleave : lazy-seq : rest} suit]
    (testing "interleave"
      (assert-eq (rest [1]) (interleave))
      (assert-eq [1 2 3] (->vec (interleave [1 2 3])))
      (assert-eq [1 4 2 5 3 6] (->vec (interleave [1 2 3] [4 5 6])))
      (assert-eq [1 4 7 2 5 8 3 6 9] (->vec (interleave [1 2 3] [4 5 6] [7 8 9])))
      (assert-eq [1 4 7] (->vec (interleave [1 2 3] [4 5 6] [7])))
      (assert-eq [1 4 2 5 3 6] (->vec (interleave (lazy-seq #[1 2 3]) (lazy-seq #[4 5 6])))))))


(deftest interpose-test
  (let [{: interpose : lazy-seq} suit]
    (testing "interpose"
      (assert-eq [1 0 2 0 3] (->vec (interpose 0 [1 2 3])))
      (assert-eq [1 0 2 0 3] (->vec (interpose 0 (lazy-seq #[1 2 3])))))))


(deftest partitions-test
  (let [{: partition : partition-all : partition-by : map : lazy-seq} suit
        vectorize #(->vec (map ->vec $))]
    (testing "partition"
      (assert-not (pcall partition))
      (assert-not (pcall partition 1))
      (assert-eq (vectorize (partition 1 [1 2 3 4])) [[1] [2] [3] [4]])
      (assert-eq (vectorize (partition 1 2 [1 2 3 4])) [[1] [3]])
      (assert-eq (vectorize (partition 3 2 [1 2 3 4 5])) [[1 2 3] [3 4 5]])
      (assert-eq (vectorize (partition 3 3 [0 -1 -2 -3] [1 2 3 4])) [[1 2 3] [4 0 -1]]))
    (testing "partition is lazy"
      (let [se []
            p1 (partition 1 (lazy-seq #(do (table.insert se 1) [1 2 3 4])))
            p2 (partition 1 2 (lazy-seq #(do (table.insert se 2) [1 2 3 4])))
            p3 (partition 3 2 (lazy-seq #(do (table.insert se 3) [1 2 3 4 5])))
            p4 (partition 3 3 (lazy-seq #(do (table.insert se 4) [0 -1 -2 -3])) [1 2 3 4])]
        (assert-eq se [])
        (assert-eq (vectorize p1) [[1] [2] [3] [4]])
        (assert-eq se [1])
        (assert-eq (vectorize p2) [[1] [3]])
        (assert-eq se [1 2])
        (assert-eq (vectorize p3) [[1 2 3] [3 4 5]])
        (assert-eq se [1 2 3])
        (assert-eq (vectorize p4) [[1 2 3] [4 0 -1]])
        (assert-eq se [1 2 3 4])))
    (testing "partition-all"
      (assert-not (pcall partition-all))
      (assert-not (pcall partition-all 1))
      (assert-not (pcall partition-all 1 2 3 4 5))
      (assert-eq (vectorize (partition-all 1 [1 2 3 4])) [[1] [2] [3] [4]])
      (assert-eq (vectorize (partition-all 1 2 [1 2 3 4])) [[1] [3]])
      (assert-eq (vectorize (partition-all 3 2 [1 2 3 4 5])) [[1 2 3] [3 4 5] [5]])
      (assert-eq (vectorize (partition-all 3 3 [1 2 3 4])) [[1 2 3] [4]]))
    (testing "partition-all is lazy"
      (let [se []
            p1 (partition-all 1 (lazy-seq #(do (table.insert se 1) [1 2 3 4])))
            p2 (partition-all 1 2 (lazy-seq #(do (table.insert se 2) [1 2 3 4])))
            p3 (partition-all 3 2 (lazy-seq #(do (table.insert se 3) [1 2 3 4 5])))
            p4 (partition-all 3 3 (lazy-seq #(do (table.insert se 4) [1 2 3 4])))]
        (assert-eq se [])
        (assert-eq (vectorize p1) [[1] [2] [3] [4]])
        (assert-eq se [1])
        (assert-eq (vectorize p2) [[1] [3]])
        (assert-eq se [1 2])
        (assert-eq (vectorize p3) [[1 2 3] [3 4 5] [5]])
        (assert-eq se [1 2 3])
        (assert-eq (vectorize p4) [[1 2 3] [4]])
        (assert-eq se [1 2 3 4])))
    (testing "partition-by"
      (assert-eq (vectorize (partition-by #(= 3 $) [1 2 3 4 5])) [[1 2] [3] [4 5]])
      (assert-eq (vectorize (partition-by #(not= 0 (% $ 2)) [1 1 1 2 2 3 3])) [[1 1 1] [2 2] [3 3]])
      (assert-eq (vectorize (partition-by #(= 0 (% $ 2)) [1 1 1 2 2 3 3])) [[1 1 1] [2 2] [3 3]])
      (assert-eq (vectorize (partition-by #$ "foobar")) [["f"] ["o" "o"] ["b"] ["a"] ["r"]]))
    (testing "partition-by is lazy"
      (let [se []
            p1 (partition-by #(= 3 $) (lazy-seq #(do (table.insert se 1) [1 2 3 4 5])))
            p2 (partition-by #(not= 0 (% $ 2)) (lazy-seq #(do (table.insert se 2) [1 1 1 2 2 3 3])))
            p3 (partition-by #(= 0 (% $ 2)) (lazy-seq #(do (table.insert se 3) [1 1 1 2 2 3 3])))
            p4 (partition-by #$ (lazy-seq #(do (table.insert se 4) "foobar")))]
        (assert-eq se [])
        (assert-eq (vectorize p1) [[1 2] [3] [4 5]])
        (assert-eq se [1])
        (assert-eq (vectorize p2) [[1 1 1] [2 2] [3 3]])
        (assert-eq se [1 2])
        (assert-eq (vectorize p3) [[1 1 1] [2 2] [3 3]])
        (assert-eq se [1 2 3])
        (assert-eq (vectorize p4) [["f"] ["o" "o"] ["b"] ["a"] ["r"]])
        (assert-eq se [1 2 3 4])))))


(deftest remove-test
  (let [{: remove : lazy-seq : range : take} suit]
    (testing "remove"
      (assert-eq [1 3 5] (->vec (remove #(= 0 (% $ 2)) [1 2 3 4 5])))
      (assert-eq [1 2 3 4 5] (->vec (remove #false [1 2 3 4 5])))
      (assert-eq [] (->vec (remove #true [1 2 3 4 5]))))
    (testing "remove is lazy"
      (let [se []
            res (remove #(= 0 (% $ 2)) (lazy-seq #(do (table.insert se 1) [1 2 3 4 5])))]
        (assert-eq se [])
        (assert-eq [1 3 5] (->vec res))
        (assert-eq se [1]))
      (assert-eq (->vec (take 5 (remove #(= 0 (% $ 2)) (range))))
                 [1 3 5 7 9]))))


(deftest splits-test
  (let [{: split-at : split-with : map} suit
        vectorize #(->vec (map ->vec $))]
    (testing "split-at"
      (assert-eq (vectorize (split-at 3 [1 2 3 4 5 6]))
                 [[1 2 3] [4 5 6]])
      (assert-eq (vectorize (split-at 10 [1 2 3 4 5 6]))
                 [[1 2 3 4 5 6] []])
      (assert-eq (vectorize (split-at 0 [1 2 3 4 5 6]))
                 [[] [1 2 3 4 5 6]]))
    (testing "split-with"
      (assert-eq (vectorize (split-with #(< $ 3) [1 2 3 4 5 6]))
                 [[1 2] [3 4 5 6]])
      (assert-eq (vectorize (split-with #(< $ 10) [1 2 3 4 5 6]))
                 [[1 2 3 4 5 6] []])
      (assert-eq (vectorize (split-with #(< $ 0) [1 2 3 4 5 6]))
                 [[] [1 2 3 4 5 6]]))))


(deftest tree-seq-test
  (let [{: tree-seq : seq? : map : first : next : rest} suit]
    (assert-eq [[[1 2 [3]] [4]]] (->vec (tree-seq seq? #$ [[1 2 [3]] [4]])))
    (assert-eq [:A :B :D :E :C :F] (->vec (map first (tree-seq next rest [:A [:B [:D] [:E]] [:C [:F]]]))))
    (assert-eq [[1 2 [3]] 4] (->vec (map first (tree-seq next rest [[1 2 [3]] [4]]))))))


(deftest keys-test
  (let [{: keys} suit]
    (testing "keys"
      (assert-eq [:a :b :c] (doto (->vec (keys {:a 1 :b 2 :c 3}))
                              (table.sort)))
      (assert-eq [1 2 3 :n] (doto (->vec (keys {1 1 2 2 3 3 :n 4}))
                              (table.sort #(< (tostring $1) (tostring $2))))))
    (testing "keys expects a map"
      (assert-not (pcall keys [1 2 3]))
      (assert-not (pcall keys "foo"))
      (assert-not (pcall keys 1)))))


(deftest vals-test
  (let [{: vals} suit]
    (testing "vals"
      (assert-eq [1 2 3] (doto (->vec (vals {:a 1 :b 2 :c 3}))
                           (table.sort)))
      (assert-eq [1 2 3 4] (doto (->vec (vals {1 1 2 2 3 3 :n 4}))
                             (table.sort))))
    (testing "vals expects a map"
      (assert-not (pcall vals [1 2 3]))
      (assert-not (pcall vals "foo"))
      (assert-not (pcall vals 1)))))

(deftest reductions-test
  (let [{: reductions} suit]
    (testing "reductions"
      (assert-eq [1 3 6 10 15] (->vec (reductions #(+ $1 $2) [1 2 3 4 5])))
      (assert-eq [10 11 13 16 20 25] (->vec (reductions #(+ $1 $2) 10 [1 2 3 4 5]))))))

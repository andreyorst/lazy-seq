(local lseq
  (if (and ... (= ... :init-macros))
      :init
      (or ... :init)))

(fn lazy-seq [...]
  "Return a lazy sequence, that lazily evaluates the body, and returns a sequence."
  `(let [{:seq seq#} (require ,lseq)
         gettype# #(match (?. (getmetatable $) :__type)
                     t# t#
                     ,(sym :_) (type $))
         proxy# []
         realize# (fn []
                    (let [s# (seq# (do ,...))]
                      (if (not= nil s#)
                          (setmetatable proxy# {:__call #(s# $2)
                                                :__type :cons
                                                :__fennelview (. (getmetatable s#) :__fennelview)
                                                :__index {:realized? true}})
                          (setmetatable proxy# {:__call #(if $2 nil proxy#)
                                                :__fennelview #"()"
                                                :__type :empty-cons
                                                :__index {:realized? true}}))))]
     (setmetatable proxy# {:__call #((realize#) $2)
                           :__index {:realized? false}
                           :__fennelview #((. (getmetatable (realize#)) :__fennelview) $...)
                           :__type :lazy-cons})))

(fn lazy-cat [...]
  "Concatenate arbitrary amount of lazy sequences."
  `(let [{:concat concat#} (require ,lseq)]
     (concat# ,(unpack (icollect [_ s (ipairs [...])]
                         `(lazy-seq ,s))))))

{: lazy-seq
 : lazy-cat}

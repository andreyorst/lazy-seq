(local lseq
  (if (and ... (= ... :init-macros))
      :init
      (or ... :init)))

(fn lazy-seq [...]
  "Create lazy sequence from the result provided by running the body.
Delays the execution until the resulting sequence is consumed.

Same as `lazy-seq*`, but doesn't require wrapping the body into an
anonymous function."
  `(let [{:lazy-seq* lazy-seq#} (require ,lseq)]
     (lazy-seq# (fn [] ,...))))

(fn lazy-cat [...]
  "Concatenate arbitrary amount of lazy sequences."
  `(let [{:concat concat# :lazy-seq* lazy-seq#} (require ,lseq)]
     (concat# ,(unpack (icollect [_ s (ipairs [...])]
                         `(lazy-seq# (fn [] ,s)))))))

(setmetatable
 {: lazy-seq
  : lazy-cat}
 {:__index {:_DESCRIPTION "Macros for creating lazy sequences."
            :_MODULE_NAME "macros.fnl"}})

## lazy-seq v0.0.2 (2021-10-09)

- Fixed equality bugs.
- Fixed bugs in `partition-all`, and `partition-by`.
- Implement sequence indexing and destructuring.
- `realized?` now only checks first element of a sequence.
- Rename `next*` function to `next`.
- Rename `lazy-seq*` function to `lazy-seq`.
- `seq` now works on strings.
- `seq` no longer accepts additional size argument, as it wraps an iterator.
- `seq` now supports associative tables.
- `seq` now produces lazy sequences when given a table by wrapping an iterator.

## lazy-seq v0.0.1 (2021-09-26)

Initial release of lazy-seq library.

<!--  LocalWords:  destructuring
 -->

# Everything testing

## Scanner

Scanner tests are just to make sure that a program is tokenized correctly. It doesn't check for any semantic errors.

### Extremely Basic Tests

Just make sure we're getting something

 - [x] Empty file
 - [x] Empty file with whitespace
 - [x] Empty file with comments
 - [x] Empty file with whitespace and comments
 - [x] Empty statement (just a semicolon)

### Constants

These are simple tests to make sure that constants are tokenized correctly. An example file would be:

```
0;
```
Which just makes sure that `0` is tokenized correctly.

 - [x] Integer tests (zero, non-zero)
 - [ ] String tests (empty, non-empty, escape sequences, `\ddd` escape sequences)
 - [ ] Failing string tests (unterminated string, invalid escape sequences)
 - [ ] Character tests (empty, non-empty, escape sequences, `\ddd` escape sequences)
 - [ ] Failing character tests (unterminated character, invalid escape sequences)
 - [ ] Boolean tests (true, false)
 - 
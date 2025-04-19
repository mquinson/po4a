``` ruby
puts <<~END_STRING
``
END_STRING
```

The document concludes with an incorrect number of backticks used as the
ending fence for a code block:

``` python
repr("some")
``

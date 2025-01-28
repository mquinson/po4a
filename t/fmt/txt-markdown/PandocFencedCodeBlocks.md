~~~~~~~
if (a > 3) {
  moveShip(5 * gravity, DOWN);
}
~~~~~~~

~~~~~~~~~~~~~~~~
~~~~~~~~~~
code including tildes
line2
~~~~~~~~~~
~~~~~~~~~~~~~~~~

~~~~ {#mycode .haskell .numberLines startFrom="100"}
qsort []     = []
qsort (x:xs) = qsort (filter (< x) xs) ++ [x] ++
               qsort (filter (>= x) xs)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

~~~haskell
qsort []     = []
qsort (x:xs) = qsort (filter (< x) xs) ++ [x] ++
               qsort (filter (>= x) xs)
~~~

```````
if (a > 3) {
  moveShip(5 * gravity, DOWN);
}
```````

````````````````
``````````
code including backticks
line2
``````````
````````````````

```` {#mycode .haskell .numberLines startFrom="100"}
qsort []     = []
qsort (x:xs) = qsort (filter (< x) xs) ++ [x] ++
               qsort (filter (>= x) xs)
`````````````````````````````````````````````````

```haskell
qsort []     = []
qsort (x:xs) = qsort (filter (< x) xs) ++ [x] ++
               qsort (filter (>= x) xs)
```

```diff
- Code block that includes bullet-like text.
- Ensure that it doesn't get interpreted.
```

This first pandoc fenced_div is non-nested.

::::: {#special .sidebar}
Here is a paragraph.

And another.
:::::
The second pandoc fenced div is nested.

::: Warning ::::::
This is a warning.

::: Danger
This is a warning within a warning.
:::
::::::::::::::::::

Some extra text.

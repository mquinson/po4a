Nothing will be considered here...
=begin RD
= List test

One textblock...
  * this is an item of an itemlist
     * first sublist item
     * second sublist item
  * this is a second
    item for the same
    itemlist
     (1) item 1 of an enumlist nested inside
     (2) item 2 of the
         enumlist
     (5) item 3
     (4)   item 4
  *   a third item with different indentation
          verbatim
          block
          nested
          inside
          the
          item
      some more text for the item

      This is another textblock inside the itemlist item. Since I need to
      test how indentation works for multi-line output, this textblock
      is a bit long...

  :  odd word

     this is an explanation of the odd word

       * further clarification

       * another long long clarification (this is so long that it will
         end up taking more than one line in the output...)

     a final note

  : weird word
       this is an explanation of
       the weird
       word

  : awkward word
     (1) this word cannot be explained
     (2) see previous point

 ---  MyClass#mymethod(val)
        This method operates on val and turns it into magic!
 ---  MyClass#othermethod1()
 ---  MyClass#othermethod2()
        These methods are useless.

Bye.
=end RD
No more text will be considered.

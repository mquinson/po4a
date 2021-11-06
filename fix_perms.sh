#! /bin/bash

# This tiny little script is useful when you interrupt the tests, as the permissions may not be restored as they should

chmod 755 t/cfg
chmod 755 `find t/add t/cfg -maxdepth 1 -type d`
chmod 755 `find t/add t/cfg -maxdepth 2 -type d`
chmod 755 `find t/add t/cfg -type d`
chmod 644 `find t -type f`

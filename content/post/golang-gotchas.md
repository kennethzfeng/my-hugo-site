+++
Categories = ["Development", "GoLang"]
Tags = ["Go", "Development", "golang"]
date = "2015-09-06T10:24:00-04:00"
title = "Golang Gotcha"
+++

A few days ago, I ran into a Go gotcha which took me a while to figure it out.  Basically, I have the following code that prints out an item from a list of integers.  The item is being closed by a function closure inside the for loop.

As you can see, this code looks perfectly normal for a Go beginner like me.

<script src="https://gist.github.com/kennethzfeng/7ea387e3a3b5c7ca67c8.js?file=wrong.go"></script>

Apparently, it was wrong because the temporary variable, ```v``` used in the for loop is being reused by the loop itself for Every iteration.  If you ran the code, you would get 7 three times.  It looks like the closure picked up the variable whose value is 7 at the end.

To fix this issue, the solution is actually very simple.  You can simple re-declare the v inside the loop which shadows the v declared by the for loop although this approach might harm readability a bit.

```
v := v
```
Alternatively, you might be better off do a this, ```vcopy := v```.

<script src="https://gist.github.com/kennethzfeng/7ea387e3a3b5c7ca67c8.js?file=right.go"></script>

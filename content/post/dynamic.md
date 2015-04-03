+++
date = "2014-08-12T22:13:48-04:00"
title = "Dynamically Create Javascript Classes"

+++
#### Problem

Recently, I was asked to think of a way to dynamically create classes, which have static methods that are slightly different among dynamically created classes.

#### Solution
<script src="https://gist.github.com/kennethzfeng/c9d65c3b736c787414b5.js"></script>
I used a factory-like function to generate class with a static method that closes on the parameter name.

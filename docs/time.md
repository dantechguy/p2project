# Time module

A completely separate module from the rest of the system. It's implementation is hidden from the Core module (it exposes and cosumes a consistent interface), but not the programmer (usage code may need to change if implementation does).

This implementation's client will communicate with the server by inserting and intercepting events via the Core module. Therefore it be a layer wrapped around both inputs and outputs.

It must be 
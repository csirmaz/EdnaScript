# EdnaScript

EdnaScript is a simple extension to JavaScript that makes it
easy to write object-oriented code, define classes, constructors,
and inheritance between classes.

This script is a prepocessor that converts source written in
EdnaScript into JavaScript (ECMAScript).

EdnaScript is Copyright (C) 2014 Elod Csirmaz

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.

## Usage

ednascript.pl < INFILE.edna > OUTFILE.js

## EdnaScript Syntax

EdnaScript extends JavaScript by defining shortcuts to class and method
definitions. These shortcuts are full lines starting with a hash
(and optionally, whitespace before the hash). The following outline
lists all shortcuts:

```
#class <CLASSNAME> --- begins a class
#base <CLASSNAME> --- determines the parent class (optional)

  #constructor(arguments) --- begins the constructor method
    <JAVASCRIPT CODE>
    #super(arguments); --- calls the super constructor
    #nosuper --- add this line if the super constructor should not be called automatically
  #-constructor --- end the constructor method

  #method <METHODNAME>(arguments) --- begins a method
    <JAVASCRIPT CODE>
    #sup(...); --- calls the overridden method
    #retsup(...); --- calls the overridden method and returns its return value
  #-method --- ends the method

#-class --- ends the class
```

## Notes

The compiler also allows type declarations before method names and argument names,
which are simply deleted during preprocessing. For example:
#method bool hasprop(string property)

The compiler aborts if neither #super nor #nosuper is used in a constructor
of a class that has a parent class.

A file can include multiple classes.

## Example

```
#class MyPoint

   #constructor(float x, float y)
      this._x = x;
      this._y = y;
   #-constructor

   #method string info()
      return ('('+this._x+','+this._y+')');
   #-method

#-class
```
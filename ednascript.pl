#!/usr/bin/perl -w

use strict;

=pod

EdnaScript
==========

Version 1.4

EdnaScript is a simple extension to JavaScript that makes it
easy to write object-oriented code, define classes, constructors,
and inheritance between classes.

This script is a prepocessor that converts source written in
EdnaScript into JavaScript (ECMAScript).

Copyright (c) 2014 Elod Csirmaz

The MIT License (MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

Usage
-----

ednascript.pl < INFILE.edna > OUTFILE.js

EdnaScript Syntax
-----------------

EdnaScript extends JavaScript by defining shortcuts to class and method
definitions. These shortcuts are full lines starting with a hash
(and optionally, whitespace before the hash). The following outline
lists all shortcuts:

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

Notes
-----

The compiler also allows type declarations before method names and argument names,
which are simply deleted during preprocessing. For example:
#method bool hasprop(string property)

The compiler aborts if neither #super nor #nosuper is used in a constructor
of a class that has a parent class.

A file can include multiple classes.

Example
-------

#class MyPoint

   #constructor(float x, float y)
      this._x = x;
      this._y = y;
   #-constructor

   #method string info()
      return ('('+this._x+','+this._y+')');
   #-method

#-class

=cut

my $class;
my $base;
my $supercalled = 0; # super constructor called? 0-no 1-called 2-marked as not called
my $method;
my $constructor = 0; # 0-before 1-inside 2-after

# Convert "int a, int b" into "a, b"
sub stripargs {
   my $a = shift;
   my @a = split(/,/,$a);
   $a = '';
   foreach my $b (@a){
      $b =~ s/\s+$//;
      $b =~ /([^\s]*)$/;
      $a .= ', ' if length($a);
      $a .= $1;
   }
   return $a;
}

while(<STDIN>){
   my $l = $_;
   $l =~ /^(\s*)(.*)$/;
   my $lstrip = $2;
   my $lindent = $1;
   $lstrip =~ s/^\s+//;
   if(substr($lstrip,0,1) eq '#'){
      if($lstrip =~ /^#class\s+([^\s]+)\s*$/){
         die "'$l' inside class '$class'" if $class;
         die "'$l' inside method '$method'" if $method;
         die "'$l' inside constructor" if $constructor==1;
         $class = $1;
         $constructor = 0;
         print "/* Class $class */\n";
      }
      elsif($lstrip =~ /^#-class\s*$/){
         die "'$l' outside class" unless $class;
         die "'$l' inside method '$method'" if $method;
         die "'$l' inside constructor" if $constructor==1;
         die "Class '$class' has no constructor" unless $constructor==2;
         print "/* End of class $class */\n";
         $class = undef;
         $base = undef;
         $constructor = 0;
      }
      elsif($lstrip =~ /^#base\s+([^\s]+)\s*$/){
         die "'$l' outside class" unless $class;
         die "'$l' inside method '$method'" if $method;
         die "'$l' inside constructor" if $constructor==1;
         die "'$l' after constructor" if $constructor==2;
         $base = $1;
      }
      elsif($lstrip =~ /^#constructor\s*\(([^\)]*)\)\s*$/){
         my $args = $1;
         die "'$l' outside class" unless $class;
         die "'$l' inside method '$method'" if $method;
         die "Multiple constructors in class '$class'" if $constructor;
         $constructor = 1;
         $supercalled = 0;
         print $lindent.$class.' = function('.stripargs($args)."){\n";
      }
      elsif($lstrip =~ /^#-constructor\s*$/){
         die "'$l' outside class" unless $class;
         die "'$l' inside method '$method'" if $method;
         die "'$l' outside constructor" unless $constructor;
         die "'$l' after constructor" if $constructor==2;
         $constructor = 2;
         ## print $base.'.call(this); // call super constructor'."\n" if $base;
         # Seal the object
         print $lindent."   Object.seal(this);\n" unless $supercalled == 1;
         print $lindent."}\n";
         if($base){
            die "Constructor of superclass not called in class '$class'" unless $supercalled;
            print $lindent.$class.'.prototype = Object.create('.$base.'.prototype);'."\n";
            print $lindent.$class.'.prototype.constructor = '.$class.";\n";
         }
      }
      elsif($lstrip =~ /^#super\s*\(([^\)]*)\)\s*;?(.*)$/){
         die "'$l' outside class" unless $class;
         die "'$l' inside method '$method'" if $method;
         die "'$l' outside constructor" unless $constructor == 1;
         $supercalled = 1;
         my $args = $1;
         $args = ', '.$args if $args;
         print $lindent.$base.'.call(this'.$args.'); '.$2." // call super constructor\n";
      }
      elsif($lstrip =~ /^#nosuper\s*$/){
         die "'$l' outside class" unless $class;
         die "'$l' inside method '$method'" if $method;
         die "'$l' outside constructor" unless $constructor == 1;
         $supercalled = 2;
      }
      elsif($lstrip =~ /^#method\s+(?:[^\s]+\s+)?([^\s\(]+)\(([^\)]*)\)\s*$/){
         die "'$l' outside class" unless $class;
         die "'$l' inside method '$method'" if $method;
         die "'$l' before constructor" unless $constructor==2;
         $method = $1;
         print $lindent.$class.'.prototype.'.$method.' = function('.stripargs($2)."){\n";
      }
      elsif($lstrip =~ /^#-method\s*$/){
         die "'$l' outside class" unless $class;
         die "'$l' outside method" unless $method;
         die "'$l' before constructor" unless $constructor==2;
         $method = undef;
         print $lindent."};\n";
      }
      elsif($lstrip =~ /^#(ret)?sup\s*\(([^\)]*)\)\s*;?(.*)$/){
         die "'$l' outside class" unless $class;
         die "'$l' outside method" unless $method;
         my $isret = $1;
         my $args = $2;
         my $post = $3;
         $args = ', '.$args if $args;
         print $lindent;
         print 'return ' if $isret;
         print $base.'.prototype.'.$method.'.call(this'.$args.'); '.$post." // call super constructor\n";
      }
      else{
         die "'$l' unrecognised in class '$class'";
      }
   }else{
      print $l;
   }
}

die "EOF in class '$class'" if $class;
die "EOF in constructor" if $constructor==1;
die "EOF in method" if $method;

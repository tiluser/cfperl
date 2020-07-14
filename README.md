Creole Forth for Perl
---------------------

Intro
-----

This is a Forth-like scripting language built in Perl and is preceded by similar languages that were built in
Delphi/Lazarus, Excel VBA, JavaScript, Python, and C#.  It can be used either standalone or as a DSL embedded 
as part of a larger application. 

Methodology
-----------
Primitives are defined as Perl subroutines attached to objects. They are roughly analagous to core words defined 
in assembly language in some Forth compilers. They are then passed to the buildPrimitive method in the CreoleForthBundle 
class, which assigns them a name, vocabulary, and integer token value, which is used as an address. 

High-level or colon definitions are assemblages of primitives and previously defined high-level definitions.
They are defined by the colon compiler. 



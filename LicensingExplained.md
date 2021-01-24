# Licensing Explained

## What Is Meant By Unlicensed?

The [Unlicense](https://unlicense.org/) is a convenient way of ensuring that code intended to be *Public Domain* can be used as such.

## What Is Meant By Public Domain?

Some countries do not have a concept of public domain (or in some cases like Australia the government don't understand what the phrase means but use it anyway like absolute fools), but for everyone else it means "anyone is equally free to use, improve upon and redistribute this". It's only due to countries like Australia which have fuck all in the way of sensible legal structure that it becomes necessary to make these terms so damn explicit.

## The Text Of The License

    This is free and unencumbered software released into the public domain.
   
    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.
    
    In jurisdictions that recognize copyright laws, the author or authors
    of this software dedicate any and all copyright interest in the
    software to the public domain. We make this dedication for the benefit
    of the public at large and to the detriment of our heirs and
    successors. We intend this dedication to be an overt act of
    relinquishment in perpetuity of all present and future rights to this
    software under copyright law.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
    OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
    ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
    OTHER DEALINGS IN THE SOFTWARE.
    
    For more information, please refer to <http://unlicense.org/>

## Additional Clarification

These freedoms apply not only to the logical code ("software") itself but also to the design, structure, interfaces and organisation of the system, and in particular the instruction set. These freedoms cannot be revoked (anyone could produce a more-restricted version later, but you'd still be totally free to build on this version instead).

If there is any further need for clarity: I do not believe these things to be distinct from Mathematical Formulae, and since they are stored digitally (as an arbitrary-length sequance of binary digits combined with a fixed-length size number) they are certainly equivalent to natural numbers (since the size could be considered the first 64 digits and the rest of the data would be the rest of the digits). Since the natural numbers (and anything equivalent) are countable, it is categorically impossible to uniquely invent them (since they have been formally described already with Guisepe Peano and others providing clear prior art), and for this reason copyright cannot be applied to mathematical formulae unless it's produced by an idiot, marketed by an idiot, and (this is the most important part) sold to an idiot.

This might *not* apply to things like Trademarks. (Trademarks would allow me to e.g. have certified partners who are able to sell versions using special trademarks. In such cases the trademark would be more of a "seal of quality" than a part of the processor itself, in that a trademarked versus non-trademarked version would not necessarily operate any differently besides that extra level of quality control implied by the trademark. A trademark is an _identity_ as opposed to just data, so using a trademark wrong would be a lie whereas using data right or wrong is just maths either way.)

## A Clear Policy On Patents

I do not, have not ever, and never will recognise the validity of software patents, hardware patents, or any other form of patents.

That being said, I have taken some care to try to avoid incorporating anything which might already be patented into the design:

* The instruction set is entirely custom-designed, using the most obvious encodings and hexadecimal puns, just in case any more-clever/more-efficient ways of encoding instructions have been patented
* Built-in devices like the Timer and Real-Time Memory Management Unit are designed in the most straightforward possible ways and are free from any non-obvious optimisations
* I've taken care not to specifically add any instructions or features aimed at being directly equivalent to those in other processors (for example the MMU doesn't work anything like an x86 one, there is no special zero register like on some RISC processors, the GPIO system doesn't have built-in masking like on Propeller)

I accept that there may initially be some patented technologies involved in the manufacturing process, and it may be necessary to include components released under different terms in order to sell useful hardware development kits. These issues can be eliminated in the long term but are not a major concern in the short term.

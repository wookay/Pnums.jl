# Pnums

[![Build Status](https://travis-ci.org/jwmerrill/Pnums.jl.svg?branch=master)](https://travis-ci.org/jwmerrill/Pnums.jl)

Pnums are a prototype Julia implementation of Gustafson's [Unums 2.0 [PDF]](http://www.johngustafson.net/presentations/Unums2.0.pdf).

The "P" in Pnums stands either for "prototype" or "projective," I haven't totally decided yet. There are currently several [limitations and differences](#current-limitations) from the Unums 2.0 proposal, which is part of the reason for the "P" in the name.

See the [tutorial introduction](/example/Tutorial.ipynb) for a tutorial; the remainder of the README is closer to reference documentation.

### Installation

This package isn't registered with METADATA yet, but if you want to try it out, you can manually add it with `Pkg.clone`:

```julia
Pkg.clone("https://github.com/jwmerrill/Pnums.jl")
```

### Unums 2.0 background

Unums are an alternative to floating point numbers that allow representing and computing with entire subsets of the real line at once, instead of doing rounded computations on point values. Unlike floating point arithmetic, they explicitly track bounds on numerical error throughout a computation. In this way, they are similar to other forms of [Interval Arithmetic](https://en.wikipedia.org/wiki/Interval_arithmetic), but there are also some important differences:

1. Explicit representation of open/closed endpoints. This enables proper set operations like complement and intersection.
2. A single "projective" infinite value is included (floating point arithmetic includes separate +∞ and -∞ values). This means that the reciprocal (1/x) of intervals that span 0 can be explicitly represented as single intervals that span infinity.
3. The reciprocal of every exact value is also included as an exact value. This means that division can be easily implemented as multiplication by a reciprocal.
4. A nicer set of "exceptional" numbers: a single ∞, "everything" (the whole real line plus ∞), and "empty" (the empty set). There is no -0, no NaN, and no subnormal numbers.
5. (Not implemented here) Unums 2.0 encourages working with arbitrary subsets of the real line (or R^n), not just contiguous intervals.
6. (Not implemented here) When a variable shows up in multiple parts of a computation, Unums 2.0 encourages (requires?) splitting intervals into pieces (individual Unums), doing computations on the pieces separately, and forming the union of the results at the end. This is a strategy for combatting overly pessimistic bounds that commonly occur in interval arithmetic ([the dependency problem](https://en.wikipedia.org/wiki/Interval_arithmetic#Dependency_problem)).

## Usage:

The basic unit of computation is the Pnum. Each Pnum represents either an exact value, or the open subset between neighboring exact values. Several different precisions are implemented here:

| Type    | Literal  |
|---------|----------|
| `Pnum3` | `pn3"1"` |
| `Pnum4` | `pn4"1"` |
| `Pnum8` | `pn8"1"` |
| `Pnum16`| `pn16"1"`|

This is analogous to the different precisions of integers or floating point numbers, like `Int8`, `Int32`, `Float16`, or `Float64`. The lowest precision Pnum, the 3-bit `Pnum3`, can represent -1, 0, 1, /0, and the open subsets between these values (/0 is Gustafson's notation for projective ∞; the notation means "reciprocal of 0"). `Pnum4` adds ±2 and ±1/2. `Pnum8` has enough exact values for 1/4 of a decimal of precision between 10^-3 and 224. `Pnum16` has 2-3 decimal digits of precision between 10^-9 and 10^9.

Note, the exact values used here don't precisely match Gustafson's proposal (I haven't tried to include simple decimals in the exact values), but it's reasonably easy to create new types using whatever exact values you want.

Open or closed intervals are represented by Pbounds composed of a pair Pnum endpoints (inexact or exact for open or closed endpoints, respectively), plus a flag to indicate whether the bound is empty. Pbounds are parametrized by the Pnum type of their endpoints, with aliases for the existing types:

| Type           | Alias      | Literal       |
|----------------|------------|---------------|
|`Pbound{Pnum3}` | `Pbound3`  | `pb3"(0, 1]"` |
|`Pbound{Pnum4}` | `Pbound4`  | `pb4"(0, 1]"` |
|`Pbound{Pnum8}` | `Pbound8`  | `pb8"(0, 1]"` |
|`Pbound{Pnum16}`| `Pbound16` | `pb16"(0, 1]"`|

Pbounds represent all values on the projective circle between their first and second endpoints, always moving clockwise. The distinction is relevant for bounds that span infinity.

For example, `pb8"(-1, 1)"` represents all reals with magnitude strictly less than 1, but `pb8"(1, -1)"` represents all reals with magnitude strictly larger than 1 (and infinity).

### Construction

Pnums are created by calling the type constructor on other numerical values, or using the `pn*""` string macro literals. The constructor rounds as necessary, but literals must be written exactly and do no rounding.

Similarly, Pbounds can be created by calling the type constructor with one or two other numerical values (which rounds as necessary), or using the `pb*""` string macro literals for exact values.

### Special Pbound values:

| Type           | Example Literal       |
|----------------|-----------------------|
|`/0` (Infinity) | `pb8"/0"`             |
|`everything`    | `pb8"everything"`     |
|`empty`         | `pb8"empty"`          |

### Arithmetic

Arithmetic (`+`, `-`, `*`, `/`) on Pnums produces Pbound outputs. Pbounds are closed under arithmetic.

### Other Implemented functions

* `^` (Integer powers only)
* `exp`
* `sqrt`

### Iteration

* `eachpnum(x::Pbound)`
* `nextpnum(x::AbstractPnum)`
* `prevpnum(x::AbstractPnum)`

You can iterate through all the Pnums contained in a Pbound using eachpnum. For example:

```julia
collect(eachpnum(pb4"[0, /0)"))
# 8-element Array{Pnums.Pnum4,1}:
#        pn4"0"
#  pn4"(0, /2)"
#       pn4"/2"
#  pn4"(/2, 1)"
#        pn4"1"
#   pn4"(1, 2)"
#        pn4"2"
#  pn4"(2, /0)"
```

Given a Pnum, you can find the neighboring Pnums with `nextpnum` (counterclockwise) and `prevpnum` (clockwise). For example:

```julia
nextpnum(pn8"0")  # pn8"(0, /224)"
prevpnum(pn8"/0") # pn8"(224, /0)"
nextpnum(pn8"/0") # pn8"(/0, -224)"

nextpnum(nextpnum(pn4"1")) # pn4"2"
```

The neighbors of exact values are always inexact, and vice versa.

### Combining Pbounds

* `shortestcover(x::Pbound, y::Pbound)`

`shortestcover` returns the smallest Pbound that contains all the Pnums in both of its inputs.

### Root and maximum finding

* `findroots(fn::Function, rng::Pbound)`
* `findmaximum(fn::Function, rng::Pbound)`

Root finding and optimization (1D only) are implemented through `findroots` and `findmaximum`. Both of these are global methods.

`findroots` returns an array of disjoint Pbounds; all the roots of the function within the input range are guaranteed to lie within one of the returned Pbounds (but there is no guarantee of how many roots (if any) each interval actually contains). For example:

```julia
findroots(x->x*(x*x - 1), pb3"everything")
# 3-element Array{Pnums.Pbound{Pnums.Pnum3},1}:
#  pb3"-1"
#   pb3"0"
#   pb3"1"
```

`findmaximum` returns an array of disjoint Pbounds; the global maximum of the function within the input range is guaranteed to lie within one of the returned Pbounds. For example:

```julia
findmaximum(x->-(x-4)^2 + 3, pb8"everything")
# 1-element Array{Pnums.Pbound{Pnums.Pnum8},1}:
#  pb8"4"
```

The results of root finding and maximization aren't always as clean as the above examples. The [dependency problem](https://en.wikipedia.org/wiki/Interval_arithmetic#Dependency_problem) may make it impossible to eliminate some ranges that contain no actual solutions:

```julia
findmaximum(x->x-exp(x), pb8"everything")
# 7-element Array{Pnums.Pbound{Pnums.Pnum8},1}:
#  pb8"(-1/2, -2/5)"
#  pb8"(-1/3, -1/5)"
#    pb8"(-1/5, /4)"
#      pb8"(/4, /2)"
#     pb8"(/2, 4/7)"
#    pb8"(2/3, 4/5)"
#     pb8"(192, /0]"
```

The actual solution is `0`, but this algorithm fails to eliminate some regions that don't include `0`, and a region that contains infinity.

### Current Limitations

##### Missing arbitrary sets of Pnums (partially implemented)

The Unums 2.0 proposal suggests doing most computations on arbitrary sets of Unums, and not just contiguous intervals. These sets are called SORNs for "Sets Of Real Numbers".

This library contains an unexported type, `Pnums.Sopn` that implements a dense representation of sets of Pnums (backed by Julia's `IntSet`). It is currently used internally for testing, but I haven't built a lot of conveniences for it yet (like nice display and convenient constructors).

I have chosen to focus on contiguous intervals (Pbounds), because it seems that dense representations won't be able to scale well to higher precisions and multiple dimensions. For example, a dense bitset for 32-bit Pnums would require 2^32 bits ≈ 500MB to represent a single set. The storage requirements for a dense 2D set over 16-bit Pnums would be the same.

Contiguous intervals should be a useful building block for *sparse* represetations of sets; indeed, the results returned by `findroots` and `findmaximum` are exactly this kind of sparse representation.

##### No lookup tables
My implementation strategy means performance can't be competitive with floats or traditional intervals.

Gustafson suggests implementing arithmetic and functions using lookup tables. I have not implemented lookup tables; instead, operations are done internally on higher precision representations and then the results are looked up in the table of exact values dynamically using binary search.

Lookup tables would be trivial to implement, and would probably improve the performance of 3-, 4-, and 8-bit Pnums, but a lookup table for multiplication of 16-bit Pnums would require (`2^16*2^16*32/2` bits ≈ 8.5 GB) of storage. Doing a lookup into a table that large for every arithmetic operation does not seem practical for a software implementation.

If the exact Pnum values were all representable as floating point numbers, then lookup tables would not be necessary; however, this would require abandoning reciprocal closure (the property that the reciprocal of every exact value is also an exact value). My personal conclusion is that reciprocal closure is not worth this cost (unless some alternative way of doing fast arithmetic without lookup tables can be found).

##### No automatic subdivision
The Unums 2.0 proposal suggests a way to partially address the dependency problem: when an interval-valued (or set-valued) variable shows up more than once in a computation, run the computation separately on each individual Unum contained in the interval/set, and then form the union of the results at the end. I have not implemented this as an automated strategy, but you can simulate it manually using `eachpnum` and `shortestcover`

For example:

```julia
f(x) = x - x

# Ideally, we'd like f to return 0 for any finite input,
# but Pbounds don't automatically track dependencies
# between different uses of the same variable.
f(pb8"[1, 2]")
# pb8"[-1, 1]"

# You can manually address the problem using a split-apply-combine
# strategy. Notice that the bound is tighter, but not perfectly
# tight.
let out = pb8"empty"
  for x in eachpnum(pb8"[1,2]")
    out = shortestcover(out, f(x))
  end
  out
end
# pb8"(-1/4, /4)"

# Same thing as a one-liner
mapreduce(f, shortestcover, eachpnum(pb8"[1, 2]"))
# pb8"(-1/4, /4)"
```

Again, it may make sense to apply this strategy automatically to 3-, 4-, or 8-bit Pnums, but for higher precision arithmetic, I believe it will be necessary to have more control over when intervals are and aren't split.

### Other relevant work

Julia implementations of Unums 1.0:

* [JuliaComputing/Unums.jl](https://github.com/JuliaComputing/Unums.jl)
* [tbreloff/Unums.jl](https://github.com/tbreloff/Unums.jl)
* [REX-Computing/unumjl](https://github.com/REX-Computing/unumjl)
* [dpsanders/SimpleUnums.jl](https://github.com/dpsanders/SimpleUnums.jl)

Julia implementations of traditional interval arithmetic:

* https://github.com/dpsanders/ValidatedNumerics.jl
* https://github.com/andrioni/MPFI.jl
* https://github.com/andrioni/Intervals.jl

Unums Resources:
* [Book](https://www.amazon.com/End-Error-Computing-Chapman-Computational/dp/1482239868) (covers Unums 1.0 only)
* [Gustafson's Presentations](http://www.johngustafson.net/unums.html) (I recommend downloading the powerpoint versions and looking at the presenters' notes).
* [Unum Computing Mailing list](https://groups.google.com/forum/#!forum/unum-computing)


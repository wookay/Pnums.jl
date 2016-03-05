using Pnums
using Base.Test

# Conversion from reals
@test Pnum(0) == pn"0"
@test Pnum(1) == pn"1"
@test Pnum(Inf) == pn"/0"
@test Pnum(-1) == pn"-1"
@test Pnum(0.5) == pn"(0, 1)"
@test Pnum(10) == pn"(1, /0)"
@test Pnum(-10) == pn"(/0, -1)"
@test Pnum(-0.5) ==  pn"(-1, 0)"

@test Pbound(0) == pb"0"
@test Pbound(1) == pb"1"
@test Pbound(Inf) == pb"/0"
@test Pbound(-1) == pb"-1"
@test Pbound(0.5) == pb"(0, 1)"
@test Pbound(10) == pb"(1, /0)"
@test Pbound(-10) == pb"(/0, -1)"
@test Pbound(-0.5) ==  pb"(-1, 0)"

# Negating Pnums
@test -pn"0" == pn"0"
@test -pn"(0, 1)" == pn"(-1, 0)"
@test -pn"1" == pn"-1"
@test -pn"(1, /0)" == pn"(/0, -1)"
@test -pn"/0" == pn"/0"
@test -pn"(/0, -1)" == pn"(1, /0)"
@test -pn"-1" == pn"1"
@test -pn"(-1, 0)" == pn"(0, 1)"

# Reciprocating Pnums
@test recip(pn"0") == pn"/0"
@test recip(pn"(0, 1)") == pn"(1, /0)"
@test recip(pn"1") == pn"1"
@test recip(pn"(1, /0)") == pn"(0, 1)"
@test recip(pn"/0") == pn"0"
@test recip(pn"(/0, -1)") == pn"(-1, 0)"
@test recip(pn"-1") == pn"-1"
@test recip(pn"(-1, 0)") == pn"(/0, -1)"

# isexact
@test isexact(pn"0") == true
@test isexact(pn"(0, 1)") == false
@test isexact(pn"1") == true
@test isexact(pn"(1, /0)") == false
@test isexact(pn"/0") == true
@test isexact(pn"(/0, -1)") == false
@test isexact(pn"-1") == true
@test isexact(pn"(-1, 0)") == false

# next
@test Pnums.next(pn"0") == pn"(0, 1)"
@test Pnums.next(pn"(0, 1)") == pn"1"
@test Pnums.next(pn"1") == pn"(1, /0)"
@test Pnums.next(pn"(1, /0)") == pn"/0"
@test Pnums.next(pn"/0") == pn"(/0, -1)"
@test Pnums.next(pn"(/0, -1)") == pn"-1"
@test Pnums.next(pn"-1") == pn"(-1, 0)"
@test Pnums.next(pn"(-1, 0)") == pn"0"

# prev
@test Pnums.prev(pn"0") == pn"(-1, 0)"
@test Pnums.prev(pn"(0, 1)") == pn"0"
@test Pnums.prev(pn"1") == pn"(0, 1)"
@test Pnums.prev(pn"(1, /0)") == pn"1"
@test Pnums.prev(pn"/0") == pn"(1, /0)"
@test Pnums.prev(pn"(/0, -1)") == pn"/0"
@test Pnums.prev(pn"-1") == pn"(/0, -1)"
@test Pnums.prev(pn"(-1, 0)") == pn"-1"

for v1 in 0x00:0x07, v2 in 0x00:0x07
  x1, x2 = Pnums.rawpnum(v1), Pnums.rawpnum(v2)
  x = Pbound(x1, x2)
  @test -(-x) == x
  if pn"0" in x
    @test pn"0" in -x
  end
  if pn"/0" in x
    @test pn"/0" in -x
  end
  if pn"1" in x
    @test pn"-1" in -x
  end
  if pn"-1" in x
    @test pn"1" in -x
  end

  @test recip(recip(x)) == x
  if pn"0" in x
    @test pn"/0" in recip(x)
  end
  if pn"/0" in x
    @test pn"0" in recip(x)
  end
  if pn"1" in x
    @test pn"1" in recip(x)
  end
  if pn"-1" in x
    @test pn"-1" in recip(x)
  end
end

for v1 in 0x00:0x07, v2 in 0x00:0x07, v3 in 0x00:0x07
  x1, x2, x3 = Pnums.rawpnum(v1), Pnums.rawpnum(v2), Pnums.rawpnum(v3)
  x = Pbound(x1, x2)
  if x3 in x
    @test !(x3 in complement(x))
  end
end

@test pn"[0, 0]" + pn"[0, 0]" == pb"[0, 0]"
@test pn"[0, 0]" + pn"[/0, /0]" == pb"[/0, /0]"
@test pn"[/0, /0]" + pn"[0, 0]" == pb"[/0, /0]"
@test pn"[/0, /0]" + pn"[/0, /0]" == pb"everything"

@test pn"(0, 1)" + pn"(0, 1)" == pb"(0, /0)"
@test pn"(0, 1)" + pn"(1, /0)" == pb"(1, /0)"
@test pn"(0, 1)" + pn"(/0, -1)" == pb"(/0, 0)"
@test pn"(0, 1)" + pn"(-1, 0)" == pb"(-1, 1)"
@test pn"(1, /0)" + pn"(1, /0)" == pb"(1, /0)"
@test pn"(1, /0)" + pn"(/0, -1)" == pb"(/0, /0)"
@test pn"(1, /0)" + pn"(-1, 0)" == pb"(0, /0)"
@test pn"(/0, -1)" + pn"(/0, -1)" == pb"(/0, -1)"
@test pn"(/0, -1)" + pn"(-1, 0)" == pb"(/0, -1)"
@test pn"(-1, 0)" + pn"(-1, 0)" == pb"(/0, 0)"

@test pn"[0, 0]" * pn"[0, 0]" == pb"[0, 0]"
@test pn"[0, 0]" * pn"[/0, /0]" == pb"everything"
@test pn"[/0, /0]" * pn"[0, 0]" == pb"everything"
@test pn"[/0, /0]" * pn"[/0, /0]" == pb"[/0, /0]"

@test pn"(0, 1)" * pn"(0, 1)" == pb"(0, 1)"
@test pn"(0, 1)" * pn"(1, /0)" == pb"(0, /0)"
@test pn"(0, 1)" * pn"(/0, -1)" == pb"(/0, 0)"
@test pn"(0, 1)" * pn"(-1, 0)" == pb"(-1, 0)"
@test pn"(1, /0)" * pn"(1, /0)" == pb"(1, /0)"
@test pn"(1, /0)" * pn"(/0, -1)" == pb"(/0, -1)"
@test pn"(1, /0)" * pn"(-1, 0)" == pb"(/0, 0)"
@test pn"(/0, -1)" * pn"(/0, -1)" == pb"(1, /0)"
@test pn"(/0, -1)" * pn"(-1, 0)" == pb"(0, /0)"
@test pn"(-1, 0)" * pn"(-1, 0)" == pb"(0, 1)"

@test pn"[0, 0]" - pn"[0, 0]" == pb"[0, 0]"
@test pn"[0, 0]" - pn"[/0, /0]" == pb"[/0, /0]"
@test pn"[/0, /0]" - pn"[0, 0]" == pb"[/0, /0]"
@test pn"[/0, /0]" - pn"[/0, /0]" == pb"everything"

@test pn"(0, 1)" - pn"(0, 1)" == pb"(-1, 1)"
@test pn"(0, 1)" - pn"(1, /0)" == pb"(/0, 0)"
@test pn"(0, 1)" - pn"(/0, -1)" == pb"(1, /0)"
@test pn"(0, 1)" - pn"(-1, 0)" == pb"(0, /0)"
@test pn"(1, /0)" - pn"(1, /0)" == pb"(/0, /0)"
@test pn"(1, /0)" - pn"(/0, -1)" == pb"(1, /0)"
@test pn"(1, /0)" - pn"(-1, 0)" == pb"(1, /0)"
@test pn"(/0, -1)" - pn"(/0, -1)" == pb"(/0, /0)"
@test pn"(/0, -1)" - pn"(-1, 0)" == pb"(/0, 0)"
@test pn"(-1, 0)" - pn"(-1, 0)" == pb"(-1, 1)"

@test pn"[0, 0]" / pn"[0, 0]" == pb"everything"
@test pn"[0, 0]" / pn"[/0, /0]" == pb"[0, 0]"
@test pn"[/0, /0]" / pn"[0, 0]" == pb"[/0, /0]"
@test pn"[/0, /0]" / pn"[/0, /0]" == pb"everything"

@test pn"(0, 1)" / pn"(0, 1)" == pb"(0, /0)"
@test pn"(0, 1)" / pn"(1, /0)" == pb"(0, 1)"
@test pn"(0, 1)" / pn"(/0, -1)" == pb"(-1, 0)"
@test pn"(0, 1)" / pn"(-1, 0)" == pb"(/0, 0)"
@test pn"(1, /0)" / pn"(1, /0)" == pb"(0, /0)"
@test pn"(1, /0)" / pn"(/0, -1)" == pb"(/0, 0)"
@test pn"(1, /0)" / pn"(-1, 0)" == pb"(/0, -1)"
@test pn"(/0, -1)" / pn"(/0, -1)" == pb"(0, /0)"
@test pn"(/0, -1)" / pn"(-1, 0)" == pb"(1, /0)"
@test pn"(-1, 0)" / pn"(-1, 0)" == pb"(0, /0)"

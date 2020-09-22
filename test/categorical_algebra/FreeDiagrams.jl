module TestFreeDiagrams
using Test

using Catlab.Theories, Catlab.CategoricalAlgebra

A, B, C, D = Ob(FreeCategory, :A, :B, :C, :D)

# General diagrams
##################

f, g, h = Hom(:f, A, C), Hom(:g, B, C), Hom(:h, A, B)
diagram = FreeDiagram([A,B,C], [(1,3,f),(2,3,g),(1,2,h)])
@test ob(diagram) == [A,B,C]
@test hom(diagram) == [f,g,h]
@test src(diagram) == [1,2,1]
@test tgt(diagram) == [3,3,2]
@test_throws Exception FreeDiagram([A,B,C], [(1,2,f),(2,3,g),(1,2,h)])

# Diagrams of fixed shape
#########################

# Empty diagrams.
@test isempty(EmptyDiagram{FreeCategory.Ob}())

# Object pairs.
pair = ObjectPair(A,B)
@test length(pair) == 2
@test first(pair) == A
@test last(pair) == B

# Discrete diagrams.
discrete = DiscreteDiagram([A,B,C])
@test length(discrete) == 3
@test ob(discrete) == [A,B,C]

diagram = FreeDiagram(discrete)
@test ob(diagram) == [A,B,C]
@test isempty(hom(diagram))

# Spans.
f, g = Hom(:f, C, A), Hom(:g, C, B)
span = Span(f,g)
@test apex(span) == C
@test legs(span) == [f,g]
@test left(span) == f
@test right(span) == g

f = Hom(:f, A, B)
@test_throws ErrorException Span(f,g)

# Multispans.
f, g, h = Hom(:f, C, A), Hom(:g, C, B), Hom(:h, C, A)
span = Multispan([f,g,h])
@test apex(span) == C
@test legs(span) == [f,g,h]

diagram = FreeDiagram(span)
@test ob(diagram) == [C,A,B,A]
@test hom(diagram) == [f,g,h]
@test src(diagram) == [1,1,1]
@test tgt(diagram) == [2,3,4]

# Cospans.
f, g = Hom(:f, A, C), Hom(:g, B, C)
cospan = Cospan(f,g)
@test base(cospan) == C
@test legs(cospan) == [f,g]
@test left(cospan) == f
@test right(cospan) == g

f = Hom(:f, A ,B)
@test_throws ErrorException Cospan(f,g)

# Multicospans.
f, g, h = Hom(:f, A, C), Hom(:g, B, C), Hom(:h, A, C)
cospan = Multicospan([f,g,h])
@test base(cospan) == C
@test legs(cospan) == [f,g,h]

diagram = FreeDiagram(cospan)
@test ob(diagram) == [A,B,A,C]
@test hom(diagram) == [f,g,h]
@test src(diagram) == [1,2,3]
@test tgt(diagram) == [4,4,4]

# Parallel pairs.
f, g = Hom(:f, A, B), Hom(:g, A, B)
pair = ParallelPair(f,g)
@test dom(pair) == A
@test codom(pair) == B
@test first(pair) == f
@test last(pair) == g

# Parallel morphisms.
f, g, h = Hom(:f, A, B), Hom(:g, A, B), Hom(:h, A, B)
para = ParallelMorphisms([f,g,h])
@test dom(para) == A
@test codom(para) == B
@test hom(para) == [f,g,h]

diagram = FreeDiagram(para)
@test ob(diagram) == [A,B]
@test hom(diagram) == [f,g,h]
@test src(diagram) == [1,1,1]
@test tgt(diagram) == [2,2,2]


# double category of squares

l, t, b, r = Hom(:lef, A,B), Hom(:top, A, C), Hom(:bot, B, D), Hom(:rht, C,D)
sq1 = SquareDiagram(t, b, l, r)

@test_throws AssertionError hcompose(sq1, sq1)
@test hom(FreeDiagram(sq1))[1] == t
@test hom(FreeDiagram(sq1))[2] == b
@test hom(FreeDiagram(sq1))[3] == l
@test hom(FreeDiagram(sq1))[4] == r

l, t, b, r = Hom(:lef, A,B), Hom(:top, A, A), Hom(:bot, B, B), Hom(:rht, A,B)
rr = Hom(:rr, A,B)
sq2 = SquareDiagram(t, b, l, r)
sq3 = hcompose(sq2, SquareDiagram(t, b, r, rr))
@test left(sq3)   == l
@test top(sq3)    == compose(t,t)
@test bottom(sq3) == compose(b,b)
@test right(sq3)  == rr


@test_throws AssertionError vcompose(sq2, sq2)

ll = Hom(:ll, B, A)
rr = Hom(:rr, B, A)
sq4 = vcompose(sq2, SquareDiagram(b, t, ll, rr))
@test left(sq4)    == compose(l, ll)
@test right(sq4)  == compose(r, rr)
@test top(sq4)   == t
@test bottom(sq4) == t

@test hom(sq4) == [top(sq4), bottom(sq4), left(sq4), right(sq4)]
end

""" Free diagrams in a category.

A [free diagram](https://ncatlab.org/nlab/show/free+diagram) in a category is a
diagram whose shape is a free category. Examples include the empty diagram,
pairs of objects, discrete diagrams, parallel morphisms, spans, and cospans.
Limits and colimits are most commonly taken over free diagrams.
"""
module FreeDiagrams
export AbstractFreeDiagram, FreeDiagram, FixedShapeFreeDiagram, DiscreteDiagram,
  EmptyDiagram, ObjectPair, Span, Cospan, Multispan, Multicospan,
  SMultispan, SMulticospan, ParallelPair, ParallelMorphisms,
  ob, hom, dom, codom, apex, base, legs, left, right,
  nv, ne, src, tgt, vertices, edges, has_vertex, has_edge,
  add_vertex!, add_vertices!, add_edge!, add_edges!,
  DecoratedCospan, AbstractFunctor, AbstractLaxator, LaxMonoidalFunctor,
  decorator, decoration, undecorate,
  SquareDiagram, hcompose, vcompose

using AutoHashEquals
using StaticArrays: StaticVector, SVector, @SVector

import ...Theories: ob, hom, dom, codom, ⋅, top, bottom, left, right
using ...Present, ..CSets, ..Graphs
using ..Graphs: TheoryGraph

# Diagrams of fixed shape
#########################

""" Abstract type for free diagram of fixed shape.
"""
abstract type FixedShapeFreeDiagram{Ob} end

""" Discrete diagram: a diagram whose only morphisms are identities.
"""
@auto_hash_equals struct DiscreteDiagram{Ob,Objects<:AbstractVector{Ob}} <:
    FixedShapeFreeDiagram{Ob}
  objects::Objects
end

const EmptyDiagram{Ob} = DiscreteDiagram{Ob,<:StaticVector{0}}
const ObjectPair{Ob} = DiscreteDiagram{Ob,<:StaticVector{2}}

EmptyDiagram{Ob}() where Ob = DiscreteDiagram(@SVector Ob[])
ObjectPair(first, second) = DiscreteDiagram(SVector(first, second))

ob(d::DiscreteDiagram) = d.objects

Base.iterate(d::DiscreteDiagram, args...) = iterate(d.objects, args...)
Base.eltype(d::DiscreteDiagram) = eltype(d.objects)
Base.length(d::DiscreteDiagram) = length(d.objects)
Base.getindex(d::DiscreteDiagram, i) = d.objects[i]
Base.firstindex(d::DiscreteDiagram) = firstindex(d.objects)
Base.lastindex(d::DiscreteDiagram) = lastindex(d.objects)

""" Multispan of morphisms in a category.

A [multispan](https://ncatlab.org/nlab/show/multispan) is like a [`Span`](@ref)
except that it may have a number of legs different than two. A colimit of this
shape is a pushout.
"""
@auto_hash_equals struct Multispan{Ob,Legs<:AbstractVector} <:
    FixedShapeFreeDiagram{Ob}
  apex::Ob
  legs::Legs
end

function Multispan(legs::AbstractVector)
  !isempty(legs) || error("Empty list of legs but no base given")
  allequal(dom.(legs)) || error("Legs $legs do not have common domain")
  Multispan(dom(first(legs)), legs)
end

const SMultispan{N,Ob} = Multispan{Ob,<:StaticVector{N}}

SMultispan(legs...) = Multispan(SVector(legs...))
SMultispan{N}(legs::Vararg{T,N}) where {T,N} = Multispan(SVector(legs...))
SMultispan{0}(apex) = Multispan(apex, SVector{0,Any}())

""" Span of morphims in a category.

A common special case of [`Multispan`](@ref). See also [`Cospan`](@ref).
"""
const Span{Ob} = SMultispan{2,Ob}

apex(span::Multispan) = span.apex
legs(span::Multispan) = span.legs
left(span::Span) = span.legs[1]
right(span::Span) = span.legs[2]

Base.iterate(span::Multispan, args...) = iterate(span.legs, args...)
Base.eltype(span::Multispan) = eltype(span.legs)
Base.length(span::Multispan) = length(span.legs)

""" Multicospan of morphisms in a category.

A multicospan is like a [`Cospan`](@ref) except that it may have a number of
legs different than two. A limit of this shape is a pullback.
"""
@auto_hash_equals struct Multicospan{Ob,Legs<:AbstractVector} <:
    FixedShapeFreeDiagram{Ob}
  base::Ob
  legs::Legs
end

function Multicospan(legs::AbstractVector)
  !isempty(legs) || error("Empty list of legs but no base given")
  allequal(codom.(legs)) || error("Legs $legs do not have common codomain")
  Multicospan(codom(first(legs)), legs)
end

const SMulticospan{N,Ob} = Multicospan{Ob,<:StaticVector{N}}

SMulticospan(legs...) = Multicospan(SVector(legs...))
SMulticospan{N}(legs::Vararg{T,N}) where {T,N} = Multicospan(SVector(legs...))
SMulticospan{0}(base) = Multicospan(base, SVector{0,Any}())

""" Cospan of morphisms in a category.

A common special case of [`Multicospan`](@ref). See also [`Span`](@ref).
"""
const Cospan{Ob} = SMulticospan{2,Ob}

base(cospan::Multicospan) = cospan.base
legs(cospan::Multicospan) = cospan.legs
left(cospan::Cospan) = cospan.legs[1]
right(cospan::Cospan) = cospan.legs[2]

Base.iterate(cospan::Multicospan, args...) = iterate(cospan.legs, args...)
Base.eltype(cospan::Multicospan) = eltype(cospan.legs)
Base.length(cospan::Multicospan) = length(cospan.legs)

""" Parallel morphims in a category.

[Parallel morphisms](https://ncatlab.org/nlab/show/parallel+morphisms) are just
morphisms with the same domain and codomain. A (co)limit of this shape is a
(co)equalizer.

For the common special case of two morphisms, see [`ParallelPair`](@ref).
"""
@auto_hash_equals struct ParallelMorphisms{Ob,Homs<:AbstractVector} <:
    FixedShapeFreeDiagram{Ob}
  dom::Ob
  codom::Ob
  homs::Homs
end

function ParallelMorphisms(homs::AbstractVector)
  @assert !isempty(homs) && allequal(dom.(homs)) && allequal(codom.(homs))
  ParallelMorphisms(dom(first(homs)), codom(first(homs)), homs)
end

""" Pair of parallel morphisms in a category.

A common special case of [`ParallelMorphisms`](@ref).
"""
const ParallelPair{Ob} = ParallelMorphisms{Ob,<:StaticVector{2}}

function ParallelPair(first, last)
  dom(first) == dom(last) ||
    error("Domains of parallel pair do not match: $first vs $last")
  codom(first) == codom(last) ||
    error("Codomains of parallel pair do not match: $first vs $last")
  ParallelMorphisms(dom(first), codom(first), SVector(first, last))
end

dom(para::ParallelMorphisms) = para.dom
codom(para::ParallelMorphisms) = para.codom
hom(para::ParallelMorphisms) = para.homs

Base.iterate(para::ParallelMorphisms, args...) = iterate(para.homs, args...)
Base.eltype(para::ParallelMorphisms) = eltype(para.homs)
Base.length(para::ParallelMorphisms) = length(para.homs)
Base.getindex(para::ParallelMorphisms, i) = para.homs[i]
Base.firstindex(para::ParallelMorphisms) = firstindex(para.homs)
Base.lastindex(para::ParallelMorphisms) = lastindex(para.homs)

allequal(xs::AbstractVector) = all(isequal(x, xs[1]) for x in xs[2:end])

# SquareDiagrams form a Double category
#######################################
"""    SquareDiagram(top, bottom, left, right)

creates a square diagram in a category, which forms the 2-cells of the double category Sq(C).
The four 1-cells are given in top, bottom, left, right order, to match the GAT of a double category.
"""
@auto_hash_equals struct SquareDiagram{Ob,Homs<:AbstractVector} <:
    FixedShapeFreeDiagram{Ob}
  corners::Vector{Ob}
  sides::Homs
end

function SquareDiagram(homs::AbstractVector)
  length(homs) == 4 || error("Square diagrams accept exactly 4 homs, in order top, bottom, left, right")
  obs = [dom(homs[1]), dom(homs[2]), dom(homs[4]), codom(homs[4])]

  # checking well-formedness
  # top-left share domains
  @assert dom(homs[1]) == dom(homs[3])
  # bottom-right share codomains
  @assert codom(homs[2]) == codom(homs[4])
  # left-bottom intersection
  @assert codom(homs[3]) == dom(homs[2])
  # top-right intersection
  @assert codom(homs[1]) == dom(homs[4])

  SquareDiagram(obs, homs)
end

SquareDiagram(top, bottom, left, right) = SquareDiagram([top, bottom, left, right])

ob(sq::SquareDiagram) = sq.corners
hom(sq::SquareDiagram) = sq.sides

top(sq::SquareDiagram) = sq.sides[1]
bottom(sq::SquareDiagram) = sq.sides[2]
left(sq::SquareDiagram) = sq.sides[3]
right(sq::SquareDiagram) = sq.sides[4]


"""    hcompose(s₁, s₂)

compose two squares horizontally as shown below:
    1   -f->   3  -g->   5
    |          |         |
    |          |         |
    v          v         v
    2  -f'->   4  -g'->  6
"""
function hcompose(s₁::SquareDiagram, s₂::SquareDiagram)
    @assert ob(s₁)[3] == ob(s₂)[1]
    @assert ob(s₁)[4] == ob(s₂)[2]
    @assert right(s₁) == left(s₂)

    f = top(s₁)
    f′= bottom(s₁)
    g = top(s₂)
    g′= bottom(s₂)
    return SquareDiagram(f⋅g, f′⋅g′, left(s₁), right(s₂))
end
"""    vcompose(s₁, s₂)

compose two squares vertically as shown below:
    1   -->  3
    |        |
    |        |
    v        v
    2  -->   4
    |        |
    |        |
    v        v
    5  -->   6
"""
function vcompose(s₁::SquareDiagram, s₂::SquareDiagram)
    @assert ob(s₁)[2] == ob(s₂)[1]
    @assert ob(s₁)[4] == ob(s₂)[3]
    @assert bottom(s₁) == top(s₂)

    f = left(s₁)
    f′= right(s₁)
    g = left(s₂)
    g′= right(s₂)
    return SquareDiagram(top(s₁), bottom(s₂), f⋅g, f′⋅g′)
end


# Decorated cospans
#------------------

# FIXME: Types and structs for functors do not belong here.
abstract type AbstractFunctor end
abstract type AbstractLaxator end

struct LaxMonoidalFunctor{Ftr <: AbstractFunctor, Lxr <: AbstractLaxator} <: AbstractFunctor
  F::Ftr
  L::Lxr
end

""" Decorate Cospan of morphisms for representing open networks.
"""
struct DecoratedCospan{Decorator <: AbstractFunctor,Decoration}
  cospan::Cospan
  decorator::Decorator
  decoration::Decoration
end

decorator(m::DecoratedCospan) = m.decorator
decoration(m::DecoratedCospan) = m.decoration
undecorate(m::DecoratedCospan) = m.cospan
base(m::DecoratedCospan) = base(m.cospan)
left(m::DecoratedCospan) = left(m.cospan)
right(m::DecoratedCospan) = right(m.cospan)

# General diagrams
##################

@present TheoryFreeDiagram <: TheoryGraph begin
  Ob::Data
  Hom::Data
  ob::Attr(V,Ob)
  hom::Attr(E,Hom)
end

const FreeDiagram = ACSetType(TheoryFreeDiagram, index=[:src,:tgt])

# XXX: This is needed because we cannot control the supertype of C-set types.
const _AbstractFreeDiagram = AbstractACSetType(TheoryFreeDiagram)
const AbstractFreeDiagram{Ob} =
  Union{_AbstractFreeDiagram{Ob},FixedShapeFreeDiagram{Ob}}

ob(d::FreeDiagram, args...) = subpart(d, args..., :ob)
hom(d::FreeDiagram, args...) = subpart(d, args..., :hom)

function FreeDiagram(obs::Vector{Ob},
                     homs::Vector{Tuple{Int,Int,Hom}}) where {Ob,Hom}
  @assert all(obs[s] == dom(f) && obs[t] == codom(f) for (s,t,f) in homs)
  d = FreeDiagram{Ob,Hom}()
  add_vertices!(d, length(obs), ob=obs)
  add_edges!(d, getindex.(homs,1), getindex.(homs,2), hom=last.(homs))
  return d
end

# Conversion of fixed shapes
#---------------------------

function FreeDiagram(discrete::DiscreteDiagram{Ob}) where Ob
  d = FreeDiagram{Ob,Nothing}()
  add_vertices!(d, length(discrete), ob=collect(discrete))
  return d
end

function FreeDiagram(span::Multispan{Ob}) where Ob
  d = FreeDiagram{Ob,eltype(span)}()
  v0 = add_vertex!(d, ob=apex(span))
  vs = add_vertices!(d, length(span), ob=codom.(legs(span)))
  add_edges!(d, fill(v0, length(span)), vs, hom=legs(span))
  return d
end

function FreeDiagram(cospan::Multicospan{Ob}) where Ob
  d = FreeDiagram{Ob,eltype(cospan)}()
  vs = add_vertices!(d, length(cospan), ob=dom.(legs(cospan)))
  v0 = add_vertex!(d, ob=base(cospan))
  add_edges!(d, vs, fill(v0, length(cospan)), hom=legs(cospan))
  return d
end

function FreeDiagram(para::ParallelMorphisms{Ob}) where Ob
  d = FreeDiagram{Ob,eltype(para)}()
  add_vertices!(d, 2, ob=[dom(para), codom(para)])
  add_edges!(d, fill(1,length(para)), fill(2,length(para)), hom=hom(para))
  return d
end

function FreeDiagram(sq::SquareDiagram{Ob}) where Ob
    top, bottom, left, right = sq.sides
    # check that the domains and codomains match
    #   1   -top->   3
    #   |            |
    # left         right
    #   v            v
    #   2  -bottom-> 4

    @assert codom(top) == dom(right)
    @assert dom(top) == dom(left)
    @assert dom(bottom) == codom(left)
    @assert codom(bottom) == codom(right)

    V = [dom(left), codom(left), dom(right), codom(right)]
    E = [(1,3, top), (2,4, bottom), (1,2, left), (3,4, right)] 
    return FreeDiagram(V, E)
end
end

nlevels(c::CategoricalValue) = length(levels(c.pool))
nlevels(c::CategoricalString) = length(levels(c.pool))

abstract type Found end
    abstract type Known <: Found end
        struct Continuous <: Known end 
        abstract type Discrete <: Known end
            struct Multiclass{N} <: Discrete end
            abstract type OrderedFactor <: Discrete end
                struct FiniteOrderedFactor{N} <: OrderedFactor end
                struct Count <: OrderedFactor end
    struct Unknown <: Found end 

# aliases:
const Other = Unknown # TODO: depreciate:
const Binary = Multiclass{2}

"""
    scitype(x)

Return the scientific type for scalar values that object `x` can
represent. If `x` is a tuple, then `Tuple{scitype.(x)...}` is returned. 

    julia> scitype(4.5)
    Continous

    julia> scitype("book")
    Unknown

    julia> scitype((1, 4.5))
    Tuple{Count,Continuous}

    julia> using CategoricalArrays
    julia> v = categorical([:m, :f, :f])
    julia> scitype(v[1])
    Multiclass{2}

""" 
scitype(::Any) = Unknown     
scitype(::Missing) = Missing
scitype(::AbstractFloat) = Continuous
scitype(::Integer) = Count
scitype(c::CategoricalValue) =
    c.pool.ordered ? FiniteOrderedFactor{nlevels(c)} : Multiclass{nlevels(c)}
scitype(c::CategoricalString) = 
    c.pool.ordered ? FiniteOrderedFactor{nlevels(c)} : Multiclass{nlevels(c)}

scitype(t::Tuple) = Tuple{scitype.(t)...}

"""
    scitype_union(A)

Return the type union, over all elements `x` generated by the iterable
`A`, of `scitype(x)`.

"""
scitype_union(A) = reduce((a,b)->Union{a,b}, (scitype(el) for el in A))

"""
    scitypes(X)

Returns a named tuple keyed on the column names of the table `X` with
values the corresponding scitype unions over a column's entries.

"""
function scitypes(X)
    container_type(X) in [:table, :sparse] ||
        throw(ArgumentError("Container should be a table or sparse table. "))
    names =    schema(X).names
    return NamedTuple{names}(scitype_union(selectcols(X, c)) for c in names)
end





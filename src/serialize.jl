using MemPool
import MemPool: mmwrite, mmread, MMSer

#### DataValueArray

function mmwrite(io::AbstractSerializer, xs::DataValueArray)
    Base.serialize_type(io, MMSer{DataValueArray})
    
    mmwrite(io, BitArray(xs.isnull))
    mmwrite(io, xs.values)
end

function mmread(::Type{DataValueArray}, io, mmap)
    isnull = deserialize(io)
    vals = deserialize(io)
    DataValueArray(vals, isnull)
end

using PooledArrays

function mmwrite(io::AbstractSerializer, xs::PooledArray)
    Base.serialize_type(io, MMSer{PooledArray})
    
    mmwrite(io, xs.pool)
    mmwrite(io, xs.refs)
end

function mmread(::Type{PooledArray}, io, mmap)
    pool = deserialize(io)
    refs = deserialize(io)
    PooledArray(PooledArrays.RefArray(refs), pool)
end

# Columns, NDSparse

function mmwrite(io::AbstractSerializer, xs::Columns)
    Base.serialize_type(io, MMSer{Columns})
    
    if eltype(xs) <: NamedTuple
        fnames = fieldnames(eltype(xs))
    else
        fnames = length(columns(xs))
    end

    serialize(io, fnames)
    for c in columns(xs)
        mmwrite(io, c)
    end
end

function mmread(::Type{Columns}, io, mmap)
    fnames = deserialize(io)
    if isa(fnames, Int)
        cols = [deserialize(io) for i=1:fnames]
        Columns(cols...)
    else
        cols = [deserialize(io) for i=1:length(fnames)]
        Columns(cols...; names=fnames)
    end
end

function mmwrite(io::AbstractSerializer, xs::NDSparse)
    Base.serialize_type(io, MMSer{NDSparse})

    flush!(xs)
    mmwrite(io, xs.index)
    mmwrite(io, xs.data)
end

function mmread(::Type{NDSparse}, io, mmap)
    idx = deserialize(io)
    data = deserialize(io)
    NDSparse(idx, data, presorted=true, copy=false)
end

function mmwrite(io::AbstractSerializer, xs::NextTable)
    Base.serialize_type(io, MMSer{NextTable})

    #flush!(xs)
    mmwrite(io, rows(xs))
    mmwrite(io, xs.pkey)
    mmwrite(io, xs.perms)
end

function mmread(::Type{NextTable}, io, mmap)
    data = deserialize(io)
    pkey = deserialize(io)
    perms = deserialize(io)
    table(data, pkey=pkey, perms=perms, presorted=true, copy=false)
end

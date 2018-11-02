"""
    fileext(filepath::AbstractString)

Extracts lowercase file extension from given filepath.
Extension is defined as "everything after the last dot".
"""
function fileext(filepath::AbstractString)
    filename = basename(filepath)
    return lowercase(filename[end-something(findfirst(isequal('.'), reverse(filename)), 0)+2:end])
end
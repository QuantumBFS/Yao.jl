export sequence

"""

Returns a `Sequential` block. This factory method can be called lazily if you
missed the total number of qubits.

This is the loose version of sequence, that does not support the `mat` related interfaces.
"""
function sequence end

sequence() = Sequential([])
sequence(blocks::AbstractBlock...) = Sequential(blocks...)
sequence(blocks) = sequence(blocks...)

# lazy constructors
sequence(blocks...) = n->sequence([parse_block(n, each) for each in blocks])

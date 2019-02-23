export projector

"""
    projector(x)

Return projector on `0` or projector on `1`.
"""
projector(x) = code==0 ? mat(P0) : mat(P1)

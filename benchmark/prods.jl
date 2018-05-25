⊗ = kron

function gen_jg_op(n, i)
    speye(1 << (i-1)) ⊗ rand(2, 2) ⊗ speye(1 << (n - i))
end

function gen_direct_op(n)
    op = rand(2, 2)
    for i = 2:n
        op = op ⊗ rand(2, 2)
    end
    op
end

function gen_reshape_op(n, i)
    kron(speye(1 << (i - 1)), rand(2, 2))
end

reshape_ops(n) = [gen_reshape_op(n, i) for i=1:n]
jg_ops(n) = [gen_jg_op(n, i) for i=1:n]
direct_op(n) = gen_direct_op(n)

function jg_prod(s, n, ops)
    for op in ops
        s .= op * s
    end
    s
end

function reshape_prod(s, n, ops)
    for (i, op) in enumerate(ops)
        s = reshape(s, 1<<i, 1<<(n-i))
        s .= op * s
    end
    vec(s)
end

function focus_prod(s, n, ops)
    st = reshape(s, 2, 1<<(n-1))
    st .= first(ops) * st

    for i = 2:n
        s = reshape(s, ntuple(x->2, Val{n}))
        perm = collect(1:n)
        perm[1] = i
        perm[i] = 1
        permutedims!(s, s, perm)
        st = reshape(s, 2, 1<<(n-1))
        st .= ops[i] * st
        permutedims!(s, s, perm)
    end
    s
end

function direct_prod(s, n, op)
    s .= op * s
    s
end

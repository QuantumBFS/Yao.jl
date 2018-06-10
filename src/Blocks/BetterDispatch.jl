using Yao, Yao.Blocks

dispatch!(+, chain(4, kron(1=>phase(0.1), 3=>phase(0.2)), kron(3=>phase(0.2))), [0.1, 0.2])

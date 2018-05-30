using Yao

macro compose(args...)
    if isa(first(args), Integer)
        parse_static_circuit(args[2])
    else
        parse_dynamic_circuit(first(args))
    end
end

macro line(ex)
end


function parse_static_circuit(ex)
    println("parse fixed size")
end

function parse_dynamic_circuit(ex)
    println("parse dynamic")
end

TEST = kron(4, X, 3=>Z)

new_block = @compose 8 begin

    @line begin
        2=>X; 3=>Y; 5=>Z
    end
    3=>kron(X, Y, Z)
    Z # will parse directly
    roll(X)
    X(1:2:4)
    X(3) |> C(1, 2)
end

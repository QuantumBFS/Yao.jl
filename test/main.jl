function main(N, a)
    for i=1:N
        for j=1:N
            a .*= 1.0
        end
    end
end

@time main(1000, ones(Complex128, 30, 30))

export Array_QuEuler, prepare_init_state, solve_QuEuler

"""
    Based on : arxiv.org/abs/1010.2745v2

    QuArray_Euler(N_t,N,h,A)
    prepare_init_state(b,x,h,N_t)

    x' = Ax + b

    * A - input matrix.
    * b - input vector.
    * x - inital vector
    * N - dimension of b (as a power of 2).
    * h - step size.
    * tspan - time span.
"""
function prepare_init_state(tspan::Tuple,x::Vector,h::Float64,g::Function)
  init_state = x;
  N_t = round(2*(tspan[2] - tspan[1])/h + 3)
  b = similar(g(1))
  for i = 1:N_t
   if i < (N_t+1)/2
      b = g(h*i + tspan[1])
      init_state = [init_state;h*b]
    else
      init_state = [init_state;zero(b)]
   end

  end
  init_state = [init_state;zero(init_state)]
  init_state
end

function Array_QuEuler(tspan::Tuple,h::Float64,g::Function)
  N_t = round(2*(tspan[2] - tspan[1])/h + 3)
  I_mat = Matrix{Float64}(I, size(g(1)));
  A_ = I_mat;
  zero_mat = zero(I_mat);
  tmp_A = Array{Float64,2}(undef,size(g(1)))

  for j = 2: N_t +1
    A_ = [A_ zero_mat]
  end

  for i = 2 : N_t+1
    tmp_A =  g(i*h + tspan[1])
    tmp_A = -1*(I_mat + h*tmp_A)
    tA_ = copy(zero_mat)
    if i<3
      tA_ = [tmp_A I_mat]
    else
      for j = 1:i-3
        tA_ = [tA_ zero_mat]
      end
      if i < (N_t + 1)/2 + 1
        tA_ = [tA_ tmp_A I_mat]
      else
        tA_ = [tA_ -1*I_mat I_mat]
      end
    end
    if i< N_t+1
      for j = i+1: N_t+1
        tA_ = [tA_ zero_mat]
      end
    end
    A_ = [A_;tA_]

  end
    A_ = [zero(A_) A_;A_' zero(A_)]
    A_
end

function solve_QuEuler(A::Function, b::Function, x::Vector,tspan::Tuple, h::Float64)

  mat = Array_QuEuler(tspan,h,A)
  state = prepare_init_state(tspan,x,h,b)
  λ = maximum(eigvals(mat))
  C_value = minimum(eigvals(mat) .|> abs)*0.1;
  n_reg = 12;
  mat = 1/(λ*2)*mat
  state = state*1/(2*λ) |> normalize!
  res = hhlsolve(mat,state, n_reg, C_value)
  res = res/λ
  res
end

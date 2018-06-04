export Signal

struct Signal
    sig::UInt
end

export signal
signal(x::Int) = Signal(UInt(x))

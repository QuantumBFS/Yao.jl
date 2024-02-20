"""
    BlochStyles

The module to define the default styles for bloch sphere drawing.
To change the default styles, you can modify the values in this module, e.g.
```julia
using YaoPlots
YaoPlots.BlochStyles.lw[] = 2.0
```

### Style variables
#### Generic
- `lw`: the line width of the drawing
- `textsize`: the size of the text
- `fontfamily`: the font family of the text
- `background_color`: the background color of the drawing
- `color`: the color of the drawing

#### Sphere
- `ball_size`: the size of the ball
- `dot_size`: the size of the dot
- `eye_point`: the eye point of the drawing

#### Axis
- `axes_lw`: the line width of the axes
- `axes_colors`: the colors of the axes
- `axes_texts`: the texts of the axes, default to `["x", "y", "z"]`

#### State display
- `show_projection_lines`: whether to show the projection lines
- `show_angle_texts`: whether to show the angle texts
- `show_line`: whether to show the line
- `show01`: whether to show the 0 and 1 states
"""
module BlochStyles
    using Luxor
    # generic config
    const lw = Ref(1.0)
    const textsize = Ref(16.0)
    const fontfamily = Ref("monospace")
    const background_color = Ref("transparent")
    const color = Ref("#000000")

    # bloch sphere config
    const ball_size = Ref(100)
    const dot_size = Ref(3)
    const eye_point = Ref((500, 200, 200))

    # axes config
    const axes_lw = Ref(1.0)
    const axes_colors = ["#000000", "#000000", "#000000"]
    const axes_texts = ["x", "y", "z"]

    # state display config
    const show_projection_lines = Ref(false)
    const show_angle_texts = Ref(false)
    const show_line = Ref(true)
    const show01 = Ref(false)
end

"""
$TYPEDSIGNATURES

Draw a bloch sphere, with the inputs being a list of `string => state` pairs,
where the string is a label for the state and a state can be a complex vector of size 2, a Yao register or `DensityMatrix`.
If you want to get a raw drawing, use `draw_bloch_sphere` instead.

### Keyword Arguments
Note: The default values can be specified in submodule `BlochStyles`.

- `textsize`: the size of the text
- `color`: the color of the drawing
- `drawing_size`: the size of the drawing
- `offset_x`: the offset of the drawing in x direction
- `offset_y`: the offset of the drawing in y direction
- `filename`: the filename of the output file, if not specified, a temporary file will be used
- `format`: the format of the output file, if not specified, the format will be inferred from the filename
- `fontfamily`: the font family of the text
- `background_color`: the background color of the drawing
- `lw`: the line width of the drawing
- `eye_point`: the eye point of the drawing
- `extra_kwargs`: extra keyword arguments passed to `draw_bloch_sphere`
    - `dot_size`: the size of the dot
    - `ball_size`: the size of the ball
    - `show_projection_lines`: whether to show the projection lines
    - `show_angle_texts`: whether to show the angle texts
    - `show_line`: whether to show the line
    - `show01`: whether to show the 0 and 1 states
    - `colors`: the colors of the states
    - `axes_lw`: the line width of the axes
    - `axes_textsize`: the size of the axes texts
    - `axes_colors`: the colors of the axes
    - `axes_texts`: the texts of the axes

### Examples

```jldoctest
julia> using YaoPlots, YaoArrayRegister

julia> bloch_sphere("|ψ⟩"=>rand_state(1), "ρ"=>density_matrix(rand_state(2), 1));
```
"""
function bloch_sphere(states...;
        textsize=BlochStyles.textsize[],
        color = BlochStyles.color[],
        drawing_size = 300,
        offset_x = 0,
        offset_y = 0,
        filename = nothing,
        format = :svg,
        fontfamily = BlochStyles.fontfamily[],
        background_color = BlochStyles.background_color[],
        lw = BlochStyles.lw[],
        eye_point = BlochStyles.eye_point[],
        extra_kwargs...)

    # file format
    if filename === nothing
        if format == :pdf
            _format = tempname()*".pdf"
        else
            _format = format
        end
    else
        _format = filename
    end
    # Set up the drawing canvas
    Luxor.Drawing(drawing_size, drawing_size, _format)
    Luxor.origin(drawing_size/2 + offset_x, drawing_size/2 + offset_y)
    Luxor.background(background_color)
    Luxor.sethue(color)
    Luxor.fontsize(textsize)
    fontfamily !== nothing && Luxor.fontface(fontfamily)
    Luxor.setline(lw)
    Thebes.eyepoint(eye_point...)

    draw_bloch_sphere(states...; eye_point, extra_kwargs...)

    # Save the drawing to a file
    Luxor.finish()
    Luxor.preview()
end

# draw bloch sphere at the origin
function draw_bloch_sphere(states::Pair{<:AbstractString}...;
        dot_size=BlochStyles.dot_size[],
        ball_size=BlochStyles.ball_size[],
        eye_point=BlochStyles.eye_point[],
        show_projection_lines = BlochStyles.show_projection_lines[],
        show_angle_texts = BlochStyles.show_angle_texts[],
        show_line = BlochStyles.show_line[],
        show01 = BlochStyles.show01[],
        colors = fill(BlochStyles.color[], length(states)),
        extra_kwargs...
    )
    # get coordinate of a state
    getcoo(x) = Point3D(ball_size .* state_to_cartesian(x))

    # ball
    Luxor.circle(Point(0, 0), ball_size, :stroke)

    # equator
    nstep = 100
    equator_points = map(LinRange(0, 2π*(1-1/nstep), nstep)) do ϕ
        project(Point3D(ball_size .* polar_to_cartesian(1.0, π/2, ϕ)))
    end
    Luxor.line.(equator_points[1:2:end], equator_points[2:2:end], :stroke)

    # show axes
    axes3D(ball_size*3 ÷ 2; extra_kwargs...)

    # show 01 states
    if show01
        for (txt, point) in [("|0⟩", [1, 0.0im]), ("|1⟩", [0.0im, 1])]
            p = getcoo(point)
            @layer begin
                Luxor.sethue(BlochStyles.color[])
                if Thebes.distance(Point3D(0, 0, 0), Point3D(eye_point...)) < Thebes.distance(p, Point3D(eye_point...))
                    Luxor.setopacity(0.3)
                end
                show_point(txt, project(p); dot_size, text_offset=Point(10, 0), show_line=false)
            end
        end
    end

    # show points
    for ((txt, point), color) in zip(states, colors)
        p = getcoo(point)
        @layer begin
            Luxor.sethue(color)
            if Thebes.distance(Point3D(0, 0, 0), Point3D(eye_point...)) < Thebes.distance(p, Point3D(eye_point...))
                Luxor.setopacity(0.3)
            end
            show_point(txt, project(p); dot_size, text_offset=Point(10, 0), show_line=show_line)
        end
        if show_projection_lines
            # show θ
            ratio = 0.2
            sz = project(Point3D(0, 0, ball_size*ratio))
            if show_angle_texts
                Luxor.move(sz)
                Luxor.arc2r(Point(0, 0), sz, project(p) * ratio, :stroke)
                Luxor.text("θ", sz - Point(0, ball_size*0.07))
            end
            # show equator projection and ϕ
            equatorp = Point3D(p[1], p[2], 0)
            sx = project(Point3D(ball_size*ratio, 0, 0))
            
            if show_angle_texts
                Luxor.move(sx)
                Luxor.carc2r(Point(0, 0), sx, project(equatorp) * ratio, :stroke)
                Luxor.text("ϕ", sx - Point(ball_size*0.12, 0))
            end

            @layer begin
                Luxor.setdash("dot")
                Luxor.setline(1)
                Luxor.line(project(p), project(equatorp), :stroke)
                Luxor.line(Point(0, 0), project(equatorp), :stroke)
            end
        end
    end
end

function show_point(txt, p; dot_size, text_offset, show_line)
    Luxor.circle(p, dot_size, :fill)
    Luxor.text(txt, p + text_offset)
    show_line && Luxor.line(Point(0, 0), p, :stroke)
end

function polar_to_cartesian(r, θ, ϕ)
    x = r * sin(θ) * cos(ϕ)
    y = r * sin(θ) * sin(ϕ)
    z = r * cos(θ)
    return x, y, z
end

function cartesian_to_polar(x, y, z)
    r = sqrt(x^2 + y^2 + z^2)
    θ = acos(z/r)
    ϕ = atan(y, x)
    return r, θ, ϕ
end

function state_to_polar(state::AbstractVector{Complex{T}}) where T
    @assert length(state) == 2
    r = norm(state)
    ϕ = iszero(state[1]) ? zero(T) : angle(state[2]/state[1])
    θ = 2 * atan(abs(state[2]), abs(state[1]))
    return r, θ, ϕ
end
state_to_cartesian(state) = polar_to_cartesian(state_to_polar(state)...)

# Draw labelled 3D axes with length `n`.
function axes3D(n::Int;
        axes_lw = BlochStyles.axes_lw[],
        axes_textsize = BlochStyles.textsize[],
        axes_colors = BlochStyles.axes_colors,
        axes_texts = BlochStyles.axes_texts,
        )
    @layer begin
        Luxor.fontsize(axes_textsize)
        Luxor.setline(axes_lw)
        for i = 1:3
            axis1 = project(Point3D(0.1, 0.1, 0.1))
            axis2 = [0.1, 0.1, 0.1]
            axis2[i] = n
            axis2 = project(Point3D(axis2...))
            Luxor.sethue(axes_colors[i])
            if (axis1 !== nothing) && (axis2 !== nothing) && !isapprox(axis1, axis2)
                Luxor.arrow(axis1, axis2)
                Luxor.label(axes_texts[i], :N, axis2, offset=10)
            end
        end
    end
end

# Interace to Yao
function state_to_polar(reg::AbstractRegister{2})
    @assert nqudits(reg) == 1 "Only single qubit register is allowed to plot on bloch sphere. If you want to plot a subsystem as a mixed state, please construct a density matrix first with `density_matrix`."
    @assert nbatch(reg) == 1 || nbatch(reg) == YaoBlocks.NoBatch() "Only single batch register is allowed to plot on bloch sphere."
    return state_to_polar(statevec(reg))
end

function state_to_cartesian(reg::DensityMatrix{2})
    @assert nqudits(reg) == 1 "Only single qubit density matrix is allowed to plot on bloch sphere"
    return real(tr(reg.state * mat(X))), real(tr(reg.state * mat(Y))), real(tr(reg.state * mat(Z)))
end

# Programming Guide

The programming style of Julia is quite different from
other OOP languages, since Julia does not fully support
OO.

Before you read this programming guide, reading through
the [official documentation](https://docs.julialang.org/)
is highly recommended.

## Style Guide

This style guide is not finished yet, and we will polish our code in future versions.

#### Julia

check the official style guide first: [Style Guide](https://docs.julialang.org/en/stable/manual/style-guide/)

Besides the suggestions from official style guide:

- 4-space intendent;

```julia
# function
function foo(x)
    x
end

# control flow
if cond
    # do something
end

# loop
for i in itr
    # do something
end

# expression
begin
    # do something
end
```

- modules spanning entire files should not be indented, but modules that have surrounding code should;

```julia
module Foo

# no intendent

end
```

- no blank lines at the start or end of files;
- do not manually align syntax such as = or :: over adjacent lines;
- use `function ... end` when a method definition contains more than one toplevel expression;


## Programming Guide

#### Abstraction

Julia's type system is completely different from other OOP programming languages. Therefore, keep in mind that there is no inheriting.

> Describing Julia in the lingo of type systems, it is: dynamic, nominative and parametric. Generic types can be parameterized, and the hierarchical relationships between types are explicitly declared, rather than implied by compatible structure. 

> One particularly distinctive feature of Julia's type system is that concrete types may not subtype each other: all concrete types are final and may only have abstract types as their supertypes. While this might at first seem unduly restrictive, it has many beneficial consequences with surprisingly few drawbacks. It turns out that being able to inherit behavior is much more important than being able to inherit structure, and inheriting both causes significant difficulties in traditional object-oriented languages. 

By example, in tranditional OOP language like Python, when we want to inherit

```python
class Animal:

    def __init__(self):
        super(self, Animal).__init__()
        self.name = ""

    def show(self):
        print(self.name)

class Kitty(Animal):
    pass

class Cat(Animal):

    def __init__(self):
        super(self, Cat).__init__()
        self.sex = 0

```

This is a classical example to show how inheriting works in Python. But in Julia, we will implement this in a different approach.

```julia
abstract type Animal end

name(x::Animal) = ""

struct Kitty <: Animal end

struct Cat <: Animal
    sex::Int
end
```

**Wait, but what about we need each subtype contain a specific member?**

here we requires all subtype `AbstractContainer` has a member `data`.

```julia
abstract type AbstractContainer end
```

Then, you may write

```julia
struct ConA
    data
    some_new_data_A
end

struct ConB
    data
    some_new_data_B
end

# ...
```

This is defintely not clean. And that is why we need inheriting in tranditional OOP, in Python you will just write

```python
class Container:

    def __init__(self)
        self.data = None

class ConA(Container):

    def __init__(self):
        super(self, ConA).__init__()
        self.some_new_data_A = None

class ConB(Container):

    def __init__(self):
        super(self, ConA).__init__()
        self.some_new_data_B = None
```

However, you can make it much cleaner in Julia, once you get familar with Julia'
s style.

As the documentation says:

> it is more important to inherit behaviour

We can seperate the behaviour related to this common member `data` by another type (remember **type** is not **class**)

```julia
abstract type ContainerType end

struct Container{T <: ContainerType}
    con_type::T
    data
end

struct ConA <: ContainerType
    some_new_data_A
end

struct ConB <: ContainerType
    some_new_data_B
end

```

Then we can treat `Container{ConA}` and `Container{ConB}` seperately (or just inherit ContainerType's interface manually) by using **multiple dispatch**.

A possible advantage of this style is that it force you to seperate more related data together and deal with them seperately, which would be more clear sometimes.

module Default

import ..Const: SYM_LIST, TYPE_LIST
using Compat

for (NAME, MAT) in SYM_LIST

    @eval begin
        const $NAME = $MAT
    end

end

end
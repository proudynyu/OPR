package reader

import "core:strings"
import "core:os"
import "core:strconv"

get_obj :: proc(offset: string, xref: ^XREF_TYPE, file: ^os.Handle) -> (string, bool) {
    if len(offset) <= 0 {
        return "", false
    }
    content := read_xref(file,xref,strconv.atoi(offset))
    lines := strings.split_lines(content)
    obj := [dynamic]string{}
    for line in lines {
        if strings.contains(line, "endobj") { break }
        append(&obj, line)
    }
    return strings.join(obj[:], "\n"), true
}

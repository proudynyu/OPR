package reader

import "core:strings"
import "core:text/regex"
import "core:strconv"
import "core:fmt"
import "core:log"
import "core:os"

Trailer :: struct {
    root:   string,
    info:   string,
}

Parsed_Trailer :: struct {
    root:   []string,
    info:   []string,
}

Trailer_Obj :: struct {
    root: RootObj,
    info: InfoObj
}

ROOT    :: "/Root"
INFO    :: "/Info"

Pattern :: enum {
    ROOT,
    INFO,
}

@(private)
get_line_value :: proc(line: string, pattern: string) -> string {
    v := strings.split(line, pattern)
    if len(v) <= 1 {
        return ""
    }
    return strings.trim_space(v[1])
}

new_trailer_obj :: proc(lines: []string) -> Trailer {
    trailer := Trailer{}
    for line, i in lines {
        if strings.contains(line, ROOT) {
            trailer.root = get_line_value(line, ROOT)
            continue
        }

        if strings.contains(line, INFO) {
            trailer.info = get_line_value(line, INFO)
            continue
        }
    }
    return trailer
}

treat_trailer :: proc(trailer: ^Trailer) -> Parsed_Trailer {
    root :=     parse_trailer(trailer, Pattern.ROOT)
    info :=     parse_trailer(trailer, Pattern.INFO)

    return Parsed_Trailer {
        root,
        info,
    }
} 

parse_trailer :: proc(trailer: ^Trailer, pattern: Pattern) -> []string {
    v := make([]string, 3)
    switch pattern {
    case .ROOT:
        value := strings.split(trailer.root, " ")
        v[0] = value[0]
        v[1] = value[1]
        v[2] = value[2]
        break

    case .INFO:
        value := strings.split(trailer.info, " ")
        
        v[0] = value[0]
        v[1] = value[1]
        v[2] = value[2]
        break
    }

    return v
}

read_trailer :: proc(file: ^os.Handle, xref: ^XREF_TYPE, trailer: ^Parsed_Trailer) -> Trailer_Obj {
    root_offset := trailer.root[0]
    root, found_root     := get_obj(root_offset, xref, file)
    if !found_root {
        log.fatalf("Was not possible to read Root")
    }

    info_offset := trailer.info[0]
    info, found_info     := get_obj(info_offset, xref, file)
    if !found_info {
        log.fatalf("Was not possible to read Info")
    }

    return Trailer_Obj{
        root = read_root(strings.split_lines(root)),
        info = read_info(strings.split_lines(info)),
    }
}

package reader

import "core:strings"
import "core:text/regex"
import "core:strconv"
import "core:fmt"

Trailer :: struct {
    root:   string,
    info:   string,
}

Parsed_Trailer :: struct {
    root:   []string,
    info:   []string,
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
        // pages
    }
} 

parse_trailer :: proc(trailer: ^Trailer, pattern: Pattern) -> []string {
    v := make([]string, 3)
    switch pattern {
    // case .PAGES: 
    //     break

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

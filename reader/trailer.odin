package reader

import "core:strings"
import "core:text/regex"

Trailer :: struct {
    root: string,
    pages: string,
    info: string,
    id: string
}

ID      :: "/ID"
ROOT    :: "/Root"
INFO    :: "/Info"
PAGES   :: "/Pages"

Pattern :: enum {
    ID,
    ROOT,
    INFO,
    PAGES
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
    for line in lines {
        if strings.contains(line, ROOT) {
            trailer.root = get_line_value(line, ROOT)
        }

        if strings.contains(line, PAGES) {
            trailer.pages = get_line_value(line, PAGES)
        }

        if strings.contains(line, ID) {
            trailer.id = get_line_value(line, ID)
        }

        if strings.contains(line, INFO) {
            trailer.info = get_line_value(line, INFO)
        }
    }

    return trailer
}

parse_trailer :: proc(trailer: ^Trailer, pattern: Pattern) {
    value: string;
    switch pattern {
    case .ID: 
        break
    case .PAGES: 
        break
    case .ROOT:
        break
    case .INFO:
        break
    }
}

package reader

import "core:strings"

Trailer :: struct {
    root: string,
    pages: string,
    info: string,
    id: string
}

new_trailer_obj :: proc(lines: []string) -> Trailer {
    trailer := Trailer{}
    for line in lines {
        if strings.contains(line, "Root") {
            trailer.root = line
        }

        if strings.contains(line, "Page") {
            trailer.pages = line
        }

        if strings.contains(line, "ID") {
            trailer.id = line
        }

        if strings.contains(line, "Info") {
            trailer.info = line
        }
    }

    return trailer
}

parse_trailer :: proc(trailer: ^Trailer) {
}

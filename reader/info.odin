package reader

import "core:strings"

InfoObj :: struct {
    creator: string,
    producer: string,
    author: string,
    creation_date: string
}

read_info :: proc(values: []string) -> (info: InfoObj) {
    for line in values {
        if strings.contains(line, "Creator") {
            info.creator = line
            continue
        }
        if strings.contains(line, "Producer") {
            info.producer = line
            continue
        }
        if strings.contains(line, "Author") {
            info.author = line
            continue
        }
        if strings.contains(line, "CreationDate") {
            info.creation_date = line
            continue
        }
    }
    return info
}

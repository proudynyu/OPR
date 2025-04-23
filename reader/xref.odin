package reader

import "core:os"
import "core:io"
import "core:bytes"
import "core:log"
import "core:strconv"
import "core:strings"
import "core:fmt"

XREF_TYPE :: map[int]i64

find_startxref :: proc(file: os.Handle) -> (i64, io.Error) {
    chunk_size: i64 = 1024
    startxref_token := "startxref"
    token_size := transmute(i64)len(startxref_token)
    offset: i64 = 0
    file_size, _ := os.file_size(file)
    buffer := make([]byte, chunk_size)
    defer delete(buffer)

    found_offset: i64 = 0
    for offset = file_size - chunk_size; offset >= 0; offset = offset - chunk_size {
        os.seek(file, offset, os.SEEK_SET)
        n, _ := os.read(file, buffer)
        index := bytes.last_index(buffer[:n], transmute([]byte)startxref_token)

        if index != -1 {
            found_offset = offset + i64(index)
            break
        }
        buffer = make([]byte, 1024)
    }

    if found_offset != 0 {
        os.seek(file, found_offset, os.SEEK_SET)

        buffer = make([]byte, 32)
        n, _ := os.read(file, buffer)
        line := transmute(string)(buffer[:n])
        lines := strings.split(line, "\n")
        xref_offset := strconv.atoi(lines[1])
        return i64(xref_offset), nil
    } 
    return -1, .EOF
}

find_xref :: proc(file: os.Handle, ref: i64) -> (xref_map: XREF_TYPE, trailer_part: []string) {
    os.seek(file, ref, os.SEEK_SET)
    buffer := make([]byte, 1024)
    n, err := os.read(file, buffer)
    if err != nil {
        log.fatalf("Was not possible to read the file in the xref reference: %s", err)
    }

    lines := strings.split_lines(transmute(string)buffer[:n])
    i := 1
    for i < len(lines) {
        if strings.contains(lines[i], "trailer") {
            trailer_part = lines[i:]
            break
        }
        
        range_parts := strings.split(lines[i], " ")
        if len(range_parts) != 2 {
            log.fatalf("Unexpected xref header line: %s", lines[i])
        }
        start := strconv.atoi(range_parts[0])
        end := strconv.atoi(range_parts[1])

        i = i + 1
        fmt.println(i, start, end)
        for j := 0; j < end; j = j + 1 {
            entry_parts := strings.split(lines[i + j], " ")
            if len(entry_parts) >= 3 {
                offset := strconv.atoi(entry_parts[0])
                generation := strconv.atoi(entry_parts[1])
                in_use := entry_parts[2] == "n"
                if in_use {
                    xref_map[start + j] = i64(offset)
                }
            }
        }
        i = i + end
    }
    return xref_map, trailer_part
}

read_trailer :: proc(file: ^os.Handle, xref: ^XREF_TYPE, trailer: ^Parsed_Trailer) {
    root_offset := trailer.root[0]
    root, ok    := read_root(root_offset, xref, file)
    if !ok {
        log.fatalf("Could not read Root offset")
    }
    fmt.printf(root)
    // pages_offset := strconv.atoi(trailer.pages[0])
    // id_offset := strconv.atoi(trailer.id[0])
    // info_offset := strconv.atoi(trailer.info[0])

    // pages   := read_pages()
    // info    := read_info()
}

read_root :: proc(offset: string, xref: ^XREF_TYPE, file: ^os.Handle) -> (string, bool) {
    if len(offset) <= 0 {
        return "", false
    }
    value := read_xref(file,xref,strconv.atoi(offset))
    lines := strings.split_lines(value)
    catalog := [dynamic]string{}
    for line in lines {
        if strings.contains(line, "endobj") { break }
        append(&catalog, line)
    }
    return strings.join(catalog[:], "\n"), true
}

read_xref :: proc(file: ^os.Handle, xref: ^map[int]i64, trailer_n: int) -> string {
    offset := xref[trailer_n]
    os.seek(file^, offset, os.SEEK_SET)

    buffer := make([]byte, 1024)
    n, err := os.read(file^, buffer)
    if err != nil {
        log.fatalf("Error trying to read the offset: %i", offset)
    }
    return transmute(string)buffer[:n]
}

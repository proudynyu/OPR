package reader

import "core:strings"
import "core:strconv"
import "core:os"
import "core:fmt"
import "core:log"
import "core:compress/zlib"
import "core:bytes"

RootObj :: struct {
    catalog: string,
    page_mode: string,
    open_action: string,
    struct_tree_root: string,
    lang: string,
    mark_info: string,
}

read_root :: proc(values: []string) -> (root: RootObj) {
    for line in values {
        if strings.contains(line, "Pages") {
            root.catalog = line
            continue
        }

        if strings.contains(line, "PageMode") {
            root.page_mode = line
            continue
        }

        if strings.contains(line, "OpenAction") {
            root.open_action = line
            continue
        }

        if strings.contains(line, "StructTreeRoot") {
            root.struct_tree_root = line
            continue
        }

        if strings.contains(line, "MarkInfo") {
            root.mark_info = line
            continue
        }
    }
    return root
}

// <</Type/Catalog/Pages 9 0 R
get_and_read_pages :: proc(file: ^os.Handle, xref: ^XREF_TYPE, catalog: string) -> bool {
    if !strings.contains(catalog, "Pages") {
        return false
    }
    values := strings.split(catalog, "/Pages")[1]
    values = strings.trim_space(values)
    offset := strings.split(values, " ")[0]
    obj, _ := get_obj(offset, xref, file)
    kids: string
    for line in strings.split_lines(obj) {
        if strings.contains(line, "/Kids") {
            kids = strings.split_multi(line, []string{"/Kids[", "]"})[1]
            kids = strings.trim_space(kids)
        }
    }

    unparsed_obj, _ := get_obj(strings.split(kids, " ")[1], xref, file)
    idx := -1
    lines := strings.split_lines(unparsed_obj)

    for line, i in lines {
        n := strings.index(line, "obj")
        if n != -1 {
            idx = i
            break
        }
    }
    assert(idx > 0, "Was not possible to find the obj for the contents")

    content := [dynamic]string{}
    for i := idx; i < len(lines); i = i + 1 {
        if strings.contains(lines[i], "endobj") { break }
        append(&content, lines[i])
    }

    stream_idx := -1
    for l, i in content {
        has_stream := strings.index(l, "stream")
        if has_stream != -1 { stream_idx = i + 1; break }
    }

    stream := [dynamic]u8{}
    for i := stream_idx; i <  len(content); i = i+1 {
        if strings.contains(content[i], "endstream") { break }
        append(&stream, content[i])
    }

    output := make([]u8, 4096)
    compressed := stream[:]
    buf := bytes.Buffer{}

    err := zlib.inflate(compressed, buf=&buf)
    if err != nil {
        fmt.printf("Decompression error: %v\n", err)
        return false
    }

    decompressed := bytes.buffer_to_string(&buf)
    fmt.printf("Decompressed output:\n%v\n", decompressed)

    return true
}


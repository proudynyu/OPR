package reader

import "core:strings"
import "core:strconv"
import "core:os"
import "core:fmt"
import "core:log"
import "core:compress/zlib"
import "core:bytes"
import "core:text/regex"

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
    defer free(&content)

    for i := idx; i < len(lines); i = i + 1 {
        if strings.contains(lines[i], "endobj") { break }
        append(&content, lines[i])
    }

    stream_idx := -1
    for l, i in content {
        has_stream := strings.index(l, "stream")
        if has_stream != -1 { stream_idx = i + 1; break }
    }

    stream := [dynamic]string{}
    defer free(&stream)
    for i := stream_idx; i <  len(content); i = i+1 {
        if strings.contains(content[i], "endstream") { break }
        append(&stream, content[i])
    }

    s := transmute([]u8)strings.join(stream[:], "\n")
    buf := bytes.Buffer{}
    defer free(&buf)

    err := zlib.inflate(s, buf=&buf)
    if err != nil {
        fmt.printf("Decompression error: %v\n", err)
        return false
    }

    decompressed := bytes.buffer_to_string(&buf)
    encoded_lines := extract_bt_and_et(decompressed)

    coded_text := [dynamic]string{}
    defer free(&coded_text)

    for line in encoded_lines {
        l := get_encoded_text(line)
        if len(l) != 0 {
            append(&coded_text, l)
        }
    }

    t := [dynamic]string{}
    defer free(&t)

    for line in coded_text {
        append(&t, decode_hex(line))
    }

    fmt.println(t[:])

    return true
}

extract_bt_and_et :: proc(s: string) -> []string {
    splitted := strings.split_lines(s)
    size := len(splitted) - 1
    idx := 0

    texts := [dynamic]string{}
    for {
        if idx == size {
            break
        }
        bt := strings.index(splitted[idx], "BT")
        if bt == -1 {

            idx = idx + 1
            continue
        }
        current_text := idx + 1
        append(&texts, splitted[current_text])
        idx=idx+1
    }

    return texts[:]
}

get_encoded_text :: proc(s: string) -> string {
    encoded, err := strings.split_multi(s, []string{"<", ">"})
    if err != nil {
        return ""
    }
    return encoded[1]
}

hex_to_bytes :: proc(hex: string) -> []u8 {
}

bytes_to_string :: proc(bytes: []u8) -> string {
    return string(bytes)
}

// TODO
decode_hex :: proc(s: string) -> string {
}


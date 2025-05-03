package reader

import "core:os"
import "core:strings"
import "core:compress/zlib"
import "core:bytes"
import "core:fmt"

get_kids_obj :: proc(file: ^os.Handle, xref: ^XREF_TYPE, catalog: string) -> string {
    if !strings.contains(catalog, "Pages") {
        return ""
    }
    values := strings.split(catalog, "/Pages")[1]
    values = strings.trim_space(values)
    offset := strings.split(values, " ")[0]
    obj, _ := get_obj(file, xref, offset)
    kids: string
    for line in strings.split_lines(obj) {
        if strings.contains(line, "/Kids") {
            kids = strings.split_multi(line, []string{"/Kids[", "]"})[1]
            kids = strings.trim_space(kids)
        }
    }
    kids_obj, _ := get_obj(file, xref, strings.split(kids, " ")[1])
    return kids_obj
}

read_kids_to_content :: proc(file: ^os.Handle, xref: ^XREF_TYPE, kids_obj: string) -> []string {
    idx := -1
    lines := strings.split_lines(kids_obj)
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
    return content[:]
}

get_and_read_pages :: proc(file: ^os.Handle, xref: ^XREF_TYPE, catalog: string) -> bool {
    kids := get_kids_obj(file, xref, catalog)
    assert(kids != "", "Was not found any kids offset")

    content := read_kids_to_content(file, xref, kids)
    assert(len(content) > 0, "Was not found any content")

    stream_idx := -1
    for l, i in content {
        has_stream := strings.index(l, "stream")
        if has_stream != -1 { stream_idx = i + 1; break }
    }

    stream := [dynamic]string{}
    // defer free(&stream)
    for i := stream_idx; i <  len(content); i = i+1 {
        if strings.contains(content[i], "endstream") { break }
        append(&stream, content[i])
    }

    s := transmute([]u8)strings.join(stream[:], "\n")
    buf := bytes.Buffer{}
    // defer free(&buf)

    err := zlib.inflate(s, buf=&buf)
    if err != nil {
        fmt.printf("Decompression error: %v\n", err)
        return false
    }

    decompressed := bytes.buffer_to_string(&buf)
    fmt.println(decompressed)

    encoded_lines := extract_bt_and_et(decompressed)
    coded_text := [dynamic]string{}
    offsets := [dynamic]string{}
    for line in encoded_lines {
        l := get_encoded_text(line)
        font_offset := get_font_offset(line)
        if len(l) != 0 {
            append(&coded_text, l)
            append(&offsets, font_offset)
        }
    }
    
    o, _ := get_obj(file, xref, offsets[0])
    fmt.println(offsets[:], o)
    // decode_hex(coded_text[0])

    return true
}

package reader

import "core:strings"
import "core:text/regex"
import "core:strconv"
import "core:fmt"
import "core:log"
import "core:os"
import "core:compress/zlib"
import "core:bytes"
import "core:io"

PDFArena :: struct {
    root: Root,
    info: Info,
    xref_table: XREF_TYPE,
    kids: Kids
}

Root :: struct {
    catalog: string,
    page_mode: string,
    open_action: string,
    struct_tree_root: string,
    lang: string,
    mark_info: string,
}

Info :: struct {
    creator: string,
    producer: string,
    author: string,
    creation_date: string
}

Kids :: struct {
    offset: string,
    obj: string
}

Trailer :: struct {
    root:   []string,
    info:   []string,
}

ROOT    :: "/Root"
INFO    :: "/Info"

XREF_TYPE :: map[int]i64

Pattern :: enum {
    ROOT,
    INFO,
}

get_root_obj :: proc(values: []string) -> (root: Root) {
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

get_info_obj :: proc(values: []string) -> (info: Info) {
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

@(private)
get_line_value :: proc(line: string, pattern: string) -> string {
    v := strings.split(line, pattern)
    if len(v) <= 1 {
        return ""
    }
    return strings.trim_space(v[1])
}

new_trailer :: proc(lines: []string) -> Trailer {
    trailer := Trailer{}
    root: string
    info: string
    for line, i in lines {
        if strings.contains(line, ROOT) {
            root = get_line_value(line, ROOT)
            continue
        }

        if strings.contains(line, INFO) {
            info = get_line_value(line, INFO)
            continue
        }
    }
    trailer.root = parse_trailer(root, Pattern.ROOT)
    trailer.info = parse_trailer(info, Pattern.INFO)
    return trailer
}

@(private)
parse_trailer :: proc(s: string, pattern: Pattern) -> []string {
    v := make([]string, 3)
    switch pattern {
    case .ROOT:
        value := strings.split(s, " ")
        v[0] = value[0]
        v[1] = value[1]
        v[2] = value[2]
        break

    case .INFO:
        value := strings.split(s, " ")
        
        v[0] = value[0]
        v[1] = value[1]
        v[2] = value[2]
        break
    }
    return v
}

alloc_trailer_in_arena :: proc(file: ^os.Handle, arena: ^PDFArena, trailer: ^Trailer) {
    root_offset := trailer.root[0]
    root, found_root := get_obj(file, &arena.xref_table, root_offset)
    if !found_root {
        log.fatalf("Was not possible to read Root")
    }

    info_offset := trailer.info[0]
    info, found_info     := get_obj(file, &arena.xref_table, info_offset)
    if !found_info {
        log.fatalf("Was not possible to read Info")
    }

    arena.root = get_root_obj(strings.split_lines(root))
    arena.info = get_info_obj(strings.split_lines(info))
}

// get_kids_obj :: proc(file: ^os.Handle, arena: ^PDFArena) -> (Kids, io.Error) {
//     if !strings.contains(arena.root.catalog, "Pages") {
//         return {}, io.Error.EOF
//     }
//     values := strings.split(arena.root.catalog, "/Pages")[1]
//     values = strings.trim_space(values)
//     offset_n := strings.split(values, " ")[0]
//     stream_obj, _ := get_obj(file, &arena.xref_table, offset_n)
//
//     offset: string
//     for line in strings.split_lines(stream_obj) {
//         if strings.contains(line, "/Kids") {
//             offset = strings.split_multi(line, []string{"/Kids[", "]"})[1]
//             offset = strings.trim_space(offset)
//         }
//     }
//     obj, _ := get_obj(file, &arena.xref_table, strings.split(offset, " ")[1])
//     return Kids{ offset, obj }, nil
// }
//
// read_kids_to_content :: proc(file: ^os.Handle, xref: ^XREF_TYPE, kids_obj: string) -> []string {
//     idx := -1
//     lines := strings.split_lines(kids_obj)
//     for line, i in lines {
//         n := strings.index(line, "obj")
//         if n != -1 {
//             idx = i
//             break
//         }
//     }
//     assert(idx > 0, "Was not possible to find the obj for the contents")
//     content := [dynamic]string{}
//     for i := idx; i < len(lines); i = i + 1 {
//         if strings.contains(lines[i], "endobj") { break }
//         append(&content, lines[i])
//     }
//     return content[:]
// }
//
// get_and_read_pages :: proc(file: ^os.Handle, arena: ^PDFArena) -> io.Error {
//     kids := get_kids_obj(file, arena) or_return
//
//     content := read_kids_to_content(file, xref, kids)
//     assert(len(content) > 0, "Was not found any content")
//
//     stream_idx := -1
//     for l, i in content {
//         has_stream := strings.index(l, "stream")
//         if has_stream != -1 { stream_idx = i + 1; break }
//     }
//
//     stream := [dynamic]string{}
//     // defer free(&stream)
//     for i := stream_idx; i <  len(content); i = i+1 {
//         if strings.contains(content[i], "endstream") { break }
//         append(&stream, content[i])
//     }
//
//     s := transmute([]u8)strings.join(stream[:], "\n")
//     buf := bytes.Buffer{}
//     // defer free(&buf)
//
//     err := zlib.inflate(s, buf=&buf)
//     if err != nil {
//         fmt.printf("Decompression error: %v\n", err)
//         return false
//     }
//
//     decompressed := bytes.buffer_to_string(&buf)
//     fmt.println(decompressed)
//
//     encoded_lines := extract_bt_and_et(decompressed)
//     coded_text := [dynamic]string{}
//     offsets := [dynamic]string{}
//     for line in encoded_lines {
//         l := get_encoded_text(line)
//         font_offset := get_font_offset(line)
//         if len(l) != 0 {
//             append(&coded_text, l)
//             append(&offsets, font_offset)
//         }
//     }
//
//     o, _ := get_obj(file, xref, offsets[0])
//     fmt.println(offsets[:], o)
//     // decode_hex(coded_text[0])
//
//     return true
// }

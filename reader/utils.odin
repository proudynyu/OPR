package reader

import "core:strings"
import "core:os"
import "core:strconv"
import "core:fmt"
import "core:io"

@(private)
get_obj :: proc(file: ^os.Handle, xref: ^XREF_TYPE, offset: string) -> (string, bool) {
    if len(offset) <= 0 {
        return "", false
    }
    content := read_xref(file,xref,strconv.atoi(offset))
    lines := strings.split_lines(content)
    obj := [dynamic]string{}
    defer delete(obj)

    for line in lines {
        if strings.contains(line, "endobj") { break }
        append(&obj, line)
    }
    return strings.join(obj[:], "\n"), true
}

@(private)
get_font_offset :: proc(s: string) -> string {
    splitted := strings.split(s, " ")
    offset: string = ""
    for word, i in splitted {
        if strings.index(word, "/F1") != -1 {
            offset = splitted[i + 1]
            break
        }
    }
    return strings.trim_space(offset)
}

@(private)
get_encoded_text :: proc(s: string) -> string {
    encoded, err := strings.split_multi(s, []string{"<", ">"})
    fmt.println(encoded)
    if err != nil {
        return ""
    }
    return encoded[1]
}

@(private)
hex_char_to_val :: proc(c: rune) -> int {
    if c >= '0' && c <= '9' {
        return int(c - '0');
    } else if c >= 'A' && c <= 'F' {
        return int(c - 'A' + 10);
    } else if c >= 'a' && c <= 'f' {
        return int(c - 'a' + 10);
    }
    return -1;
}

@(private)
hex_to_bytes :: proc(hex: string) -> []u8 {
    result := [dynamic]u8{}
    for i := 0; i < len(hex); i = i + 2 {
        hi := hex_char_to_val(rune(hex[i]))
        lo := hex_char_to_val(rune(hex[i+1]))
        if hi == -1 && lo == -1 {
            continue
        }

        v := (hi << 4 | lo)
        append(&result, u8(v))
    }

    return result[:]
}

@(private)
bytes_to_string :: proc(bytes: []u8) -> string {
    return string(bytes)
}

@(private)
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

@(private)
get_offset_pattern :: proc(stream_obj: string, pattern: string) -> (offset: string) {
    for line in strings.split_lines(stream_obj) {
        if strings.index(line, pattern) != -1 {
            offset = strings.trim_space(strings.split(line, pattern)[1])
            break
        }
    }
    return offset
}

@(private)
object_from_offset :: proc(
    file: ^os.Handle,
    arena: ^PDFArena,
    stream_obj: string, 
    pattern: string
) -> (string, io.Error) {
    offset: string = get_offset_pattern(stream_obj, pattern)
    if offset == "" {
        return "", io.Error.Invalid_Offset
    }

    obj, ok := get_obj(file, &arena.xref_table, offset)
    if !ok {
        return "", io.Error.Invalid_Offset
    }

    return obj, nil
}

@(private)
get_line_value :: proc(line: string, pattern: string) -> string {
    v := strings.split(line, pattern)
    if len(v) <= 1 {
        return ""
    }
    return strings.trim_space(v[1])
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

@(private)
get_data_stream :: proc(obj: []string) -> ([]string, io.Error) {
    idx := -1
    for l, i in obj {
        has_stream := strings.index(l, "stream")
        if has_stream != -1 { idx = i + 1; break }
    }
    if idx < 0 {
        fmt.println("Was not possible to get the content")
        return {}, io.Error.Invalid_Offset
    }

    content := [dynamic]string{}
    for i := idx; i < len(obj); i = i + 1 {
        if strings.index(obj[i], "endstream") != -1 { break }
        append(&content, obj[i])
    }

    return content[:], nil
}

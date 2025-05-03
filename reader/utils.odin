package reader

import "core:strings"
import "core:os"
import "core:strconv"
import "core:fmt"

get_obj :: proc(file: ^os.Handle, xref: ^XREF_TYPE, offset: string) -> (string, bool) {
    if len(offset) <= 0 {
        return "", false
    }
    content := read_xref(file,xref,strconv.atoi(offset))
    lines := strings.split_lines(content)
    obj := [dynamic]string{}
    for line in lines {
        if strings.contains(line, "endobj") { break }
        append(&obj, line)
    }
    return strings.join(obj[:], "\n"), true
}

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

get_encoded_text :: proc(s: string) -> string {
    encoded, err := strings.split_multi(s, []string{"<", ">"})
    fmt.println(encoded)
    if err != nil {
        return ""
    }
    return encoded[1]
}

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

bytes_to_string :: proc(bytes: []u8) -> string {
    return string(bytes)
}

// TODO
decode_hex :: proc(s: string) {
    // "01 02 03 01 04 05 06 07 08 09 0a"
    hex := hex_to_bytes(s)
    fmt.println(string(hex))
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

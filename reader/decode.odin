package reader

import "core:os"
import "core:compress/zlib"
import "core:bytes"
import "core:strings"
import "core:fmt"
import "core:strconv"

zlib_decode :: proc(s: []u8) -> (string, bool) {
    buf := bytes.Buffer{}
    err := zlib.inflate(s, buf=&buf)
    if err != nil {
        b := strings.Builder{}
        defer free(&b)
        message := fmt.sbprintf(&b, "Decompression error: %v\n", err)
        return message, false
    }
    return bytes.buffer_to_string(&buf), true
}

decode_stream :: proc(arena: ^PDFArena) -> (string, bool) {
    stream := arena.content.stream
    s := transmute([]u8)strings.join(stream[:], "\n")
    return zlib_decode(s)
}

decode_unicode_stream :: proc(obj: string) -> (unicode: string) {
    stream := strings.split_lines(obj)
    content, _ := get_data_stream(stream)
    s := transmute([]u8)strings.join(content[:], "\n")
    unicode, _ = zlib_decode(s)
    return unicode
}

create_unicode_map :: proc(unicode_string: string) -> map[string]string {
    lines := strings.split_lines(unicode_string)
    should_parse := false
    hex_map := map[string]string{}

    for line in lines {
        if strings.index(line, "beginbfchar") != -1 { should_parse = true }
        if strings.index(line, "endbfchar") != -1 { should_parse = false }

        if should_parse {
            parts := strings.fields(line)
            key := strings.trim(parts[0], "<>")
            value := strings.trim(parts[1], "<>")

            hex_map[key] = value
        }
    }

    return hex_map
}

alloc_unicode_map :: proc(arena: ^PDFArena) {
    has_unicode := len(arena.unicode.obj) > 0
    unicode: string = has_unicode ? decode_unicode_stream(arena.unicode.obj) : ""
    unicode_map := create_unicode_map(unicode)
    arena.unicode.unicode_map = unicode_map

    decode_hex_text(arena)
}


decode_hex_text :: proc(arena: ^PDFArena) {
    content := strings.join(arena.content.stream, "\n")
    encoded, ok := zlib_decode(transmute([]u8)content)
    if !ok {
        fmt.printf("Something went wrong decoding zlib the content stream")
        return
    }

    bt_and_et := extract_bt_and_et(encoded)

    hex_values := [dynamic]string{}
    defer delete(hex_values)
    for line in bt_and_et {
        l := strings.split_multi(line, []string{"<",">"})
        append(&hex_values, l[1])
    }

    // string_builder := strings.Builder{}
    // strings.write_rune
    mapped := arena.unicode.unicode_map
    hex_strings := [dynamic]string{}
    for hex in hex_values {
        str := strings.Builder{}
        for i := 0; i < len(hex); i = i + 2 {
                s := hex[i:i+2]
                c := mapped[s] 
                b := hex_to_bytes(c)
                codepoint := u16(b[0]) << 8 | u16(b[1])
                strings.write_rune(&str, rune(codepoint))
        }
        fmt.println(str.buf[:])
        // append(&hex_strings, str.buf[:])
    }
    // fmt.println(hex_strings)
}

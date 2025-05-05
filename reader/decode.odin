package reader

import "core:os"
import "core:compress/zlib"
import "core:bytes"
import "core:strings"
import "core:fmt"

zlib_decode :: proc(s: []u8) -> (string, bool) {
    buf := bytes.Buffer{}
    err := zlib.inflate(s, buf=&buf)
    if err != nil {
        b := strings.Builder{}
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

decode_hex :: proc(file: ^os.Handle, arena: ^PDFArena) {
    has_unicode := len(arena.unicode.obj) > 0
    unicode: string = has_unicode ? decode_unicode_stream(arena.unicode.obj) : ""

    // "01 02 03 01 04 05 06 07 08 09 0a"
    unicode_hex := hex_to_bytes(unicode)
}

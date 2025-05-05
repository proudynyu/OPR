package reader

import "core:strings"
import "core:text/regex"
import "core:strconv"
import "core:fmt"
import "core:log"
import "core:os"
import "core:io"

PDFArena :: struct {
    root: Root,
    info: Info,
    xref_table: XREF_TYPE,
    kids: Kids,
    content: Content,
    font: Font,
    pages: Pages,
    unicode: Unicode
}

Pages :: struct {
    offset: string,
    obj: string
}

Content :: struct {
    stream: []string
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
    obj: string
}

Trailer :: struct {
    root:   []string,
    info:   []string,
}

Font :: struct { obj: string }
Unicode :: struct { obj: string }

ROOT    :: "/Root"
INFO    :: "/Info"

XREF_TYPE :: map[int]i64

Pattern :: enum {
    ROOT,
    INFO,
}

get_root_obj :: proc(values: []string) -> (root: Root) {
    for line in values {
        if strings.index(line, "Pages") != -1 {
            root.catalog = line
            continue
        }

        if strings.index(line, "PageMode") != -1 {
            root.page_mode = line
            continue
        }

        if strings.index(line, "OpenAction") != -1 {
            root.open_action = line
            continue
        }

        if strings.index(line, "StructTreeRoot") != -1 {
            root.struct_tree_root = line
            continue
        }

        if strings.index(line, "MarkInfo") != -1 {
            root.mark_info = line
            continue
        }
    }
    return root
}

get_info_obj :: proc(values: []string) -> (info: Info) {
    for line in values {
        if strings.index(line, "Creator") != -1 {
            info.creator = line
            continue
        }
        if strings.index(line, "Producer") != -1 {
            info.producer = line
            continue
        }
        if strings.index(line, "Author") != -1 {
            info.author = line
            continue
        }
        if strings.index(line, "CreationDate") != -1 {
            info.creation_date = line
            continue
        }
    }
    return info
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

alloc_trailer_in_arena :: proc(file: ^os.Handle, arena: ^PDFArena, trailer: ^Trailer) -> io.Error {
    root_offset := trailer.root[0]
    root, found_root := get_obj(file, &arena.xref_table, root_offset)
    if !found_root {
        fmt.println("Was not possible to read Root")
        return io.Error.Invalid_Offset
    }

    info_offset := trailer.info[0]
    info, found_info     := get_obj(file, &arena.xref_table, info_offset)
    if !found_info {
        fmt.println("Was not possible to read Info")
        return io.Error.Invalid_Offset
    }

    arena.root = get_root_obj(strings.split_lines(root))
    arena.info = get_info_obj(strings.split_lines(info))
    return nil
}

alloc_pages_in_arena :: proc(file: ^os.Handle, arena: ^PDFArena) -> io.Error {
    if !strings.contains(arena.root.catalog, "Pages") {
        return io.Error.EOF
    }
    values := strings.split(arena.root.catalog, "/Pages")[1]
    values = strings.trim_space(values)
    offset_n: string = strings.split(values, " ")[0]
    stream_obj, ok := get_obj(file, &arena.xref_table, offset_n)
    if !ok {
        return io.Error.Invalid_Offset
    }

    arena.pages = Pages{
        offset = offset_n,
        obj = stream_obj
    }
    return nil
}

alloc_kids_in_arena :: proc(file: ^os.Handle, arena: ^PDFArena) -> io.Error {
    stream_obj := arena.pages.obj
    kids_obj := object_from_offset(
        file,
        arena,
        stream_obj,
        "/Kids"
    ) or_return

    idx := -1
    lines := strings.split_lines(kids_obj)
    for line, i in lines {
        n := strings.index(line, "obj")
        if n != -1 {
            idx = i
            break
        }
    }
    if idx < 0 {
        return io.Error.Invalid_Offset
    }

    content := [dynamic]string{}
    for i := idx; i < len(lines); i = i + 1 {
        if strings.contains(lines[i], "endobj") { break }
        append(&content, lines[i])
    }

    obj := strings.join(content[:], "\r\n")
    arena.kids = Kids{ obj }

    return nil
}

alloc_content_stream :: proc(arena: ^PDFArena) -> io.Error {
    kids_list := strings.split(arena.kids.obj, "\r\n")
    content, err := get_data_stream(kids_list)
    arena.content.stream = content
    return nil
}

alloc_font_in_arena :: proc(file: ^os.Handle, arena: ^PDFArena) -> io.Error {
    stream_obj := arena.pages.obj

    resource_obj := object_from_offset(
        file,
        arena,
        stream_obj,
        "/Resources"
    ) or_return

    font_obj := object_from_offset(
        file,
        arena,
        resource_obj,
        "/Font"
    ) or_return

    obj := object_from_offset(
        file,
        arena,
        font_obj,
        "/F1"
    ) or_return

    arena.font = Font{ obj }
    return nil
}

alloc_unicode_in_arena :: proc(file: ^os.Handle, arena: ^PDFArena) {
    font := arena.font.obj
    obj, err := object_from_offset(
        file,
        arena,
        font,
        "/ToUnicode"
    )

    if err != nil {
        arena.unicode.obj = ""
        return
    }

    arena.unicode.obj = obj
}

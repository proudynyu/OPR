package main

import "core:os"
import "core:io"
import "core:fmt"
import "core:log"
import "core:mem"

import "reader"

read_file :: proc(path: string) -> os.Handle {
    file, err := os.open(path)
    if  err != nil {
        log.fatal("Was not possible to read the file")
        os.exit(1)
    }
    return file
}

main :: proc() {
    path := "./testing_pdf.pdf"
    file := read_file(path)
    defer os.close(file)

    arena := reader.PDFArena{}
    defer free(&arena)

    startxref, _ := reader.find_startxref(file)
    xref_table, trailer_list := reader.find_xref(file, startxref)
    arena.xref_table = xref_table

    tmp_trailer := reader.new_trailer(trailer_list)
    defer free(&tmp_trailer)

    reader.alloc_trailer_in_arena(&file, &arena, &tmp_trailer)
    fmt.println(arena)
}

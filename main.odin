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

    startxref, _ := reader.find_startxref(file)
    xref_table, trailer_list := reader.find_xref(file, startxref)
    arena.xref_table = xref_table

    tmp_trailer := reader.new_trailer(trailer_list)

    err := reader.alloc_trailer_in_arena(&file, &arena, &tmp_trailer)
    if err != nil {
        log.fatalf("Was not possible to allocate the trailer in the arena: %s", err)
    }

    err = reader.alloc_pages_in_arena(&file, &arena)
    if err != nil {
        log.fatalf("Was not possible to allocate the pages in the arena: %s", err)
    }
    
    err = reader.alloc_kids_in_arena(&file, &arena)
    if err != nil {
        log.fatalf("Was not possible to allocate the kids in the arena: %s", err)
    }

    err = reader.alloc_content_stream(&arena)
    if err != nil {
        log.fatalf("Was not possible to allocate the content in the arena: %s", err)
    }

    err = reader.alloc_font_in_arena(&file, &arena)
    if err != nil {
        log.fatalf("Was not possible to allocate the font in the arena: %s", err)
    }

    reader.alloc_unicode_in_arena(&file, &arena)
    reader.alloc_unicode_map(&arena)
}

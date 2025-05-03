package main

import "core:os"
import "core:io"
import "core:fmt"

import "reader"

PDFArena :: struct {
    trailer: reader.Trailer_Obj,
    xref_table: reader.XREF_TYPE
}

main :: proc() {
    path := "./testing_pdf.pdf"
    file := reader.read_file(path)
    defer os.close(file)

    startxref, _ := reader.find_startxref(file)

    // TODO -> alloc arena and push this to there
    xref_table, trailer_list := reader.find_xref(file, startxref)

    // TODO -> alloc arena and push this to there and unify this under one proc
    trailer := reader.new_trailer(trailer_list)
    treated_trailer := reader.treat_trailer(&trailer)
    trailer_obj := reader.get_trailer_obj(&file, &xref_table, &treated_trailer)

    _ = reader.get_and_read_pages(
        &file, &xref_table,
        trailer_obj.root.catalog
    )
}

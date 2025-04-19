package main

import "core:os"
import "core:io"
import "core:fmt"

import "reader"

main :: proc() {
    path := "./testing_pdf.pdf"
    file := reader.read_file(path)
    defer os.close(file)

    xref_n, _ := reader.find_startxref(file)

    xref_table, trailer_list := reader.find_xref(file, xref_n)
    trailer := reader.new_trailer_obj(trailer_list)
    fmt.println(xref_table)
    fmt.println(trailer)
}

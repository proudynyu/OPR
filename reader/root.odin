package reader

import "core:strings"

RootObj :: struct {
    catalog: string,
    page_mode: string,
    open_action: string,
    struct_tree_root: string,
    lang: string,
    mark_info: string,
}

get_root_obj :: proc(values: []string) -> (root: RootObj) {
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


package reader

import "core:os"
import "core:log"

read_file :: proc(path: string) -> os.Handle {
    file, err := os.open(path)
    if  err != nil {
        log.fatal("Was not possible to read the file")
        os.exit(1)
    }
    return file
}

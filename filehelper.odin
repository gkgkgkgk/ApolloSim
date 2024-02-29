package main
import "core:fmt"
import "core:os"
import "core:strings"

readInput :: proc(input: os.Handle) -> string {
	buf: [256]byte
	n, err := os.read(os.stdin, buf[:])
	if err < 0 {
		// Handle error
		return ""
	}

	str := strings.clone_from_bytes(buf[:n]);

	return strings.trim(str, "\n\r");
}

appendLine :: proc(file: os.Handle, str: string) {
    offset, err := os.file_size(file)
    newStr := strings.concatenate({str, "\n"});
    num, _ := os.write_at(file, transmute([]u8) newStr, offset);
}

createBlankFile :: proc(file : string) -> os.Handle{
    os.remove(file);
	when ODIN_OS == .Windows {
		f, err := os.open(file, os.O_CREATE);
	    return f;
    } else when ODIN_OS == .Linux {
		f, err := os.open(file, os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0o777);
		return f;
    }
}

getEntireFile :: proc (file : string) -> Maybe(string) {
	f, b := os.read_entire_file_from_filename(file)
    
	if (b){
		return string(f);
	} else {
		return nil;
	}
}
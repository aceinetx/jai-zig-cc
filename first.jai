build :: () {
    set_build_options_dc(.{do_output = false});

    w := compiler_create_workspace("main");
    options := get_build_options(w);
    options.output_executable_name = "main";
    options.cpu_target = .X64;
    options.os_target = .WINDOWS;
    set_build_options(options, w);
    jai_zig_cc_setup_options(w);

    zig_cc_options := Zig_Cc_Options.{};
    defer free(zig_cc_options);

    array_add(*zig_cc_options.additional_files, "c_interop.c");

    compiler_begin_intercept(w);

    add_build_file("main.jai", w);

    while true {
        message := compiler_wait_for_message();
        if !message  break;
        if message.kind == .COMPLETE  break;

        jai_zig_cc_handle_message(message, w, zig_cc_options);
    }

    compiler_end_intercept(w);
}

#run build();

#import "Compiler";
#import "Basic";
#import "Jai_Zig_Cc";

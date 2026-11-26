build :: () {
    set_build_options_dc(.{do_output = false});

    w := compiler_create_workspace("main");
    options := get_build_options(w);
    options.output_executable_name = "main";
    options.use_custom_link_command = true;
    options.backend = .LLVM;
    options.cpu_target = .X64;
    options.os_target = .LINUX;
    set_build_options(options, w);
    jai_crossplatform_setup_options(w);

    compiler_begin_intercept(w);

    add_build_file("main.jai", w);

    while true {
        message := compiler_wait_for_message();
        if !message  break;
        if message.kind == .COMPLETE  break;

        jai_crossplatform_handle_message(message, w);
    }

    compiler_end_intercept(w);
}

#run build();

#import "Compiler";
#import "Jai_Crossplatform";

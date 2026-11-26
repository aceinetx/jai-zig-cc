build :: () {
    set_build_options_dc(.{do_output = false});

    w := compiler_create_workspace("main");
    options := get_build_options(w);
    options.output_executable_name = "main";
    options.use_custom_link_command = true;
    options.backend = .LLVM;
    options.llvm_options.target_system_triple = "x86_64-pc-windows-gnu";
    options.os_target = .WINDOWS;
    set_build_options(options, w);

    compiler_begin_intercept(w);

    add_build_file("main.jai", w);

    while true {
        message := compiler_wait_for_message();
        if !message  break;
        if message.kind == .COMPLETE  break;

        if message.kind == .PHASE {
            phase := cast(*Message_Phase) message;
            if phase.phase == .READY_FOR_CUSTOM_LINK_COMMAND {
                cmd: [..] string;
                array_add(*cmd, "zig");
                array_add(*cmd, "cc");
                array_add(*cmd, "-target");
                array_add(*cmd, "x86_64-windows-gnu");
                array_add(*cmd, "-no-pie");
                array_add(*cmd, "-ldbghelp");
                array_add(*cmd, tprint("-o%", options.output_executable_name));

                for phase.compiler_generated_object_files array_add(*cmd, it);
                for phase.support_object_files {
                    if it == "/lib/crt1.o"  continue;
                    if it == "/lib/crti.o"  continue;
                    if it == "/lib/crtn.o"  continue;
                    array_add(*cmd, it);
                }

                array_add(*cmd, "fix.c");

                print("%", cmd);
                result := run_command(..cmd);
                if result.exit_code != 0 {
                    print("Custom link failed!\n");
                }

                compiler_custom_link_command_is_complete(w);
            }
        }
    }

    compiler_end_intercept(w);
}

#run build();

#import "Compiler";
#import "Basic";
#import "Process";

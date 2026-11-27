jai_zig_cc_setup_options :: (w: Workspace) {
    options := get_build_options(w);

    if options.os_target == {
        case .ANDROID;
            #through;
        case .WASM;
            options.backtrace_on_crash = .OFF;
        case;
    }

    options.backend = .LLVM;
    options.llvm_options.target_system_triple = get_triple(options, true); // This leaks, but it should be fine...
    options.use_custom_link_command = true;

    set_build_options(options, w);
}

Zig_Cc_Options :: struct {
    additional_files: [..]string;
    additional_flags: [..]string;
    link_paths: [..]string;
    include_paths: [..]string;
};

free :: (zig_cc_options: Zig_Cc_Options) {
    array_free(zig_cc_options.additional_files);
    array_free(zig_cc_options.additional_flags);
    array_free(zig_cc_options.link_paths);
    array_free(zig_cc_options.include_paths);
}

jai_zig_cc_handle_message :: (message: *Message, w: Workspace, zig_cc_options: Zig_Cc_Options) {
    if message.kind == .PHASE {
        phase := cast(*Message_Phase) message;
        if phase.phase == .READY_FOR_CUSTOM_LINK_COMMAND {
            options := get_build_options(w);

            cmd: [..] string;
            array_add(*cmd, "zig");
            array_add(*cmd, "cc");
            array_add(*cmd, "-no-pie");

            target := get_triple(options);
            defer free(target);

            array_add(*cmd, "-target");
            array_add(*cmd, target);

            if options.os_target == .WINDOWS {
                array_add(*cmd, "-ldbghelp");
            }

            array_add(*cmd, tprint("-o%", options.output_executable_name));

            for phase.compiler_generated_object_files array_add(*cmd, it);
            for phase.support_object_files {
                if it == "/lib/crt1.o"  continue;
                if it == "/lib/crti.o"  continue;
                if it == "/lib/crtn.o"  continue;
                array_add(*cmd, it);
            }

            for zig_cc_options.link_paths {
                array_add(*cmd, "-L");
                array_add(*cmd, it);
            }

            for zig_cc_options.include_paths {
                array_add(*cmd, "-I");
                array_add(*cmd, it);
            }

            for zig_cc_options.additional_flags {
                array_add(*cmd, it);
            }

            for zig_cc_options.additional_files {
                array_add(*cmd, it);
            }

            array_add(*cmd, "modules/Jai_Zig_Cc.c");

            print("%", cmd);
            result := run_command(..cmd);
            if result.exit_code != 0 {
                print("Custom link failed!\n");
            }

            compiler_custom_link_command_is_complete(w);
        }
    }
}

#scope_file

get_triple :: (options: Build_Options, llvm: bool = false) -> string {
    sb: String_Builder;
    init_string_builder(*sb);
    defer free_buffers(*sb);

    if options.cpu_target == {
        case .X64;
            append(*sb, "x86_64");
        case .ARM64;
            append(*sb, "aarch64");
    }

    if options.os_target == {
        case .WINDOWS;
            if llvm  append(*sb, "-pc");
            append(*sb, "-windows-gnu");
        case .LINUX;
            if llvm  append(*sb, "-pc");
            append(*sb, "-linux-gnu");
        case .MACOS;
            append(*sb, "-macos");
    }

    return builder_to_string(*sb);
}

#import "Compiler";
#import "Basic";
#import "Process";

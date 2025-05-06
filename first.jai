#import "Basic";
#import "Compiler";
#import "File";
#import "File_Utilities";
#import "String";

Process :: #import "Process";

PROJECT_NAME           :: "flappyjai";
BUILD_OUTPUT_DIRECTORY :: "run_tree/";

run_game: bool;
release: bool;
track_allocations: bool;

jails_diagnostics: bool;

output_executable_name: string = ---;

build :: () {
    make_directory_if_it_does_not_exist(BUILD_OUTPUT_DIRECTORY, recursive = true);

    w := compiler_create_workspace(tprint("Target Program: %", PROJECT_NAME));
    if !w {
        print("Workspace creation failed.\n");
        return;
    }


    options := get_build_options(w);
    copy_commonly_propagated_fields(get_build_options(), *options);

    options.output_path = BUILD_OUTPUT_DIRECTORY;

    args := options.compile_time_command_line;
    run_game = array_find(args, "run");
    release = array_find(args, "release");
    track_allocations = array_find(args, "track_allocations");

    if release {
        if track_allocations print("####################\nTracking allocations in release build!\n####################\n");
        set_optimization(*options, .VERY_OPTIMIZED, false);
        output_executable_name = PROJECT_NAME;
    } else {
        output_executable_name = tprint("%_debug", PROJECT_NAME);
    }
    options.output_executable_name = output_executable_name;

    #if #exists(JAILS_DIAGNOSTICS_BUILD)
    {
        options.output_type = .NO_OUTPUT;
        jails_diagnostics = true;
    }

    set_build_options(options, w);

    compiler_begin_intercept(w);

    if track_allocations add_build_string(tprint("TRACK_ALLOCATIONS :: true;\n"), w);
    else add_build_string(tprint("TRACK_ALLOCATIONS :: false;\n"), w);

    if release {
        add_build_string(tprint("DEBUG :: false;\n"), w);

        if file_exists(".env") {
            add_build_file(".env", w);
        }
    } else {
        add_build_string(tprint("DEBUG :: true;\n"), w);

        if file_exists(".env.dev") {
            add_build_file(".env.dev", w);
        }
    }

    add_build_file("source/main.jai", w);

    message_loop();

    compiler_end_intercept(w);

    set_build_options_dc(.{do_output = false});
}

clean_build_dir :: () {
    print("Cleaning output dir...\n");

    debug_exe_path := tprint("%0%_debug", BUILD_OUTPUT_DIRECTORY, PROJECT_NAME);
    release_exe_path := tprint("%0%", BUILD_OUTPUT_DIRECTORY, PROJECT_NAME);

    if file_exists(debug_exe_path) {
        print("Deleting %\n", debug_exe_path);
        file_delete(debug_exe_path);
        delete_directory(tprint("%.dSYM", debug_exe_path));
    }

    if file_exists(release_exe_path) {
        print("Deleting %\n", release_exe_path);
        file_delete(release_exe_path);
        delete_directory(tprint("%.dSYM", release_exe_path));
    }

    exit(0);
}

message_loop :: () {
    while true {
        message := compiler_wait_for_message();
        if message.kind == {
            case .ERROR;
                exit(1);
            case .COMPLETE;
                if run_game && !jails_diagnostics {
                    print("\n");
                    Process.run_command(tprint("%/%", BUILD_OUTPUT_DIRECTORY, output_executable_name));
                }
                break;
        }
    }
}

#run {
    options := get_build_options();
    copy_commonly_propagated_fields(get_build_options(), *options);

    args := options.compile_time_command_line;
    clean := array_find(args, "clean");
    if clean {
        clean_build_dir();
    } else {
        build();
    }
}


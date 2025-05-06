#import "Basic"()(MEMORY_DEBUGGER = TRACK_ALLOCATIONS);
#import "File";
#import "String";
#import "System";
#import "Text_File_Handler";
#import "Random";
#import "Math";
#import "raylib";

#load "config.jai";
#load "time.jai";
#load "input.jai";
#load "utils.jai";
#load "entities.jai";
#load "player.jai";
#load "particles.jai";
#load "sprite.jai";

MAX_DELTA :: 0.2;

window_width: s32 = 1920;
window_height: s32 = 1080;

playfield_width := 32;
playfield_height := 18;

playfield_scale: float;

config: Config_State;
input: Input_State;
time: Time_State;

data_folder: string;

contrail_map: Texture2D;

live_emitters: [..]*Particle_Emitter;

player: Player;

game_camera: Camera2D;

editor_font: *Font;
button_font: *Font;

main :: () {
    #if DEBUG {
        defer print("Program exited gracefully.\n");
    }

    #if OS == .WINDOWS {
        Windows :: #import "Windows";
        Windows.SetProcessDPIAware();

        // Windows is very bad at thread-switching by default unless you do this. Sad.
        Windows.timeBeginPeriod(1);
    }

    executable_path := path_strip_filename(get_path_of_running_executable());
    set_working_directory(executable_path);
    print("Working directory is %\n", executable_path);

    data_folder = join(executable_path, "data");
    print("data_folder is '%'\n", data_folder);

    InitWindow(window_width, window_height, "flappyjai");
    defer CloseWindow();

    playfield_scale = min(window_width / cast(float)playfield_width, window_height / cast(float)playfield_height);

    time_init(60);
    config_init();
    init_input();
    defer deinit_input();

    init_player(*player, 0, 0);

    game_camera.target = player.position;
    game_camera.offset = .{window_width / 2.0, window_height / 2.0};
    // game_camera.zoom = 1.0;
    game_camera.zoom = playfield_scale;

    random_seed(cast(u64) to_milliseconds(current_time_monotonic()));
    print("Random seed is %\n\n", context.random_state.high);

    contrail_map = LoadTexture("data/sprites/contrail.png");

    while !WindowShouldClose() {
        time_update();
        if time.delta < MAX_DELTA {
            game_simulate();
        }
        render_one_frame();

        reset_temporary_storage();
    }

    #if TRACK_ALLOCATIONS {
        report_memory_leaks();
    }
}

game_simulate :: () {
    update_input();
    // game_camera.target.x = player.position.x;

    for live_emitters update_emitter(it);

    update_player(*player);
}

render_one_frame :: () {
    PushDrawing();
    ClearBackground(BLACK);

    { 
        PushMode2D(game_camera);

        {
            PushBlendMode(.BLEND_ADDITIVE);
            for live_emitters draw_emitter(it);
        }

        draw_player(*player);
    }
}


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

blocks: [20]Rectangle;
block_index: int;

timer: float = 2;

score: int = 0;
score_remainder: float = -4.125;

game_over: bool;

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

    for * blocks {
        pos_x := it_index / 2;
        it.* = Rectangle.{xx -playfield_width, 4, 2, 12};
        if it_index % 2 == 0 {
            it.y = 4;
        } else {
            it.y = -4 - 9;
        }
    }

    game_camera.target = player.position;
    game_camera.offset = .{window_width / 2.0, window_height / 2.0};
    // game_camera.zoom = 1.0;
    game_camera.zoom = playfield_scale;

    random_seed(cast(u64) to_milliseconds(current_time_monotonic()));
    print("Random seed is %\n\n", context.random_state.high);

    contrail_map = LoadTexture("data/sprites/contrail.png");

    while !WindowShouldClose() {
        time_update();

        if time.unscaled_delta < MAX_DELTA {
            game_simulate();
        }
        render_one_frame();

        if game_over && IsKeyPressed(.KEY_R) {
            game_over = false;
            player.position = .{0, 0};
            player.speed = .{0, 0};

            timer = 2.0;
            score = 0;
            score_remainder = -4.125;
            for * blocks {
                pos_x := it_index / 2;
                it.* = Rectangle.{xx -playfield_width, 4, 2, 12};
                if it_index % 2 == 0 {
                    it.y = 4;
                } else {
                    it.y = -4 - 9;
                }
            }
        }

        reset_temporary_storage();
    }

    #if TRACK_ALLOCATIONS {
        report_memory_leaks();
    }
}

game_simulate :: () {
    update_input();
    if IsKeyPressed(.KEY_F) {
        ifx time.time_scale == 1.0 then time.time_scale = 0.1 else time.time_scale = 1.0;
    }
    game_camera.target.x = player.position.x;

    for live_emitters update_emitter(it);

    if !game_over {
        for * blocks {
            it.x -= move_speed * time.delta;
        }
        timer -= time.delta;

        score_remainder += time.delta;
        while score_remainder > 1 {
            score_remainder -= 1;
            score += 1;
        }
    }
    if timer <= 0 {
        timer += 1.0;

        block1 := *blocks[block_index];
        block2 := *blocks[block_index+1];

        block1.x = playfield_width / 2 + block1.width;
        block2.x = playfield_width / 2 + block2.width;

        height := random_get_within_range(-4, 4);
        gap_size := 6;
        block1.y = height + gap_size / 2;
        block2.y = height - block2.height - gap_size / 2;

        block_index += 2;
        block_index %= blocks.count;
    }

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

        for blocks {
            DrawRectangleRec(it, BLUE);
        }
    }

    if game_over {
        y: s32;
        font_size: s32 = cast(s32)(window_height * .1);
        text_width := MeasureText("GAME OVER!", font_size);
        DrawText("GAME OVER!", window_width / 2 - text_width/2, window_height / 2 - font_size / 2, font_size, WHITE);
        y += font_size;

        font_size = cast(s32)(window_height * .05);
        score_text := to_c_string(tprint("Final score: %", score),, temp);
        text_width = MeasureText(score_text, font_size);
        DrawText(score_text, window_width / 2 - text_width/2, window_height / 2 - font_size / 2 + y, font_size, WHITE);
        y += font_size;

        font_size = cast(s32)(window_height * .04);
        text_width = MeasureText("Press R to restart", font_size);
        c := Fade(RED, sin(time.now * TAU / 2.0) / 2.0 + 0.5);
        DrawText("Press R to restart", window_width / 2 - text_width/2, window_height / 2 - font_size / 2 + y, font_size, c);
    } else {
        font_size: s32 = cast(s32)(window_height * .06);
        text_width := MeasureText("GAME OVER!", font_size);
        DrawText(to_c_string(tprint("Score: %", score),, temp), window_width / 2 - text_width/2, font_size / 2, font_size, WHITE);
    }
}


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

window_width: s32 = 1920/2;
window_height: s32 = 1080/2;

playfield_width := 32;
playfield_height := 18;

playfield_scale: float;

config: Config_State;
input: Input_State;
time: Time_State;

data_folder: string;

contrail_map: Texture2D;
pipe_map: Texture2D;
ground_map: Texture2D;
bg_map: Texture2D;

ground_rect: Rectangle;

ground_x_offset: float = 0;
bg_x_offset: float = 0;

live_emitters: [..]*Particle_Emitter;

player: Player;

game_camera: Camera2D;

editor_font: *Font;
button_font: *Font;

pipes: [20]Rectangle;
pipe_index: int;

timer: float = 2;

score: int = 0;
score_remainder: float = -4.125;

game_over: bool;

swoosh_sound: Sound;
wing\ _sound: Sound;
point\_sound: Sound;
hit\  _sound: Sound;
die\  _sound: Sound;

my_font: Font;

init_blocks :: () {
    for * pipes {
        pos_x := it_index / 2;
        it.* = Rectangle.{xx -playfield_width, 4, 2, 12};
        if it_index % 2 == 0 {
            it.y = 4;
        } else {
            it.y = -4 - 9;
        }
    }
}

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

    #if DEBUG {
        SetTraceLogLevel(.LOG_WARNING);
    } else {
        SetTraceLogLevel(.LOG_ERROR);
    }

    InitWindow(window_width, window_height, "flappyjai");
    defer CloseWindow();

    InitAudioDevice();
    defer CloseAudioDevice();

    playfield_scale = min(window_width / cast(float)playfield_width, window_height / cast(float)playfield_height);

    time_init(60);
    config_init();
    init_input();
    defer deinit_input();

    init_player(*player, 0, 0);
    
    init_blocks();

    ground_rect = Rectangle.{-playfield_width / 2.0, playfield_height / 2.0 - 1.5, xx playfield_width, playfield_width * 0.333};

    game_camera.target = player.position;
    game_camera.offset = .{window_width / 2.0, window_height / 2.0};
    // game_camera.zoom = 1.0;
    game_camera.zoom = playfield_scale;

    random_seed(cast(u64) to_milliseconds(current_time_monotonic()));
    print("Random seed is %\n\n", context.random_state.high);

    my_font = LoadFontEx("data/fonts/flappy-font.ttf", 32, cast(*void)0, 250);

    contrail_map = LoadTexture("data/sprites/contrail.png");
    pipe_map = LoadTexture("data/sprites/pipe-green.png");
    ground_map = LoadTexture("data/sprites/base.png");
    bg_map = LoadTexture("data/sprites/background-day.png");
    defer UnloadTexture(contrail_map);
    defer UnloadTexture(pipe_map);
    defer UnloadTexture(ground_map);
    defer UnloadTexture(bg_map);

    swoosh_sound = LoadSound("data/sound/swoosh.ogg");
    wing\ _sound = LoadSound("data/sound/wing.ogg");
    point\_sound = LoadSound("data/sound/point.ogg");
    hit\  _sound = LoadSound("data/sound/hit.ogg");
    die\  _sound = LoadSound("data/sound/die.ogg");
    defer UnloadSound(swoosh_sound);
    defer UnloadSound(wing\ _sound);
    defer UnloadSound(point\_sound);
    defer UnloadSound(hit\  _sound);
    defer UnloadSound(die\  _sound);

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
            for * pipes {
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
    #if DEBUG {
        if IsKeyPressed(.KEY_F) {
            ifx time.time_scale == 1.0 then time.time_scale = 0.1 else time.time_scale = 1.0;
        }
    }

    for live_emitters update_emitter(it);

    if !game_over {
        for * pipes {
            it.x -= move_speed * time.delta;
        }
        timer -= time.delta;

        score_remainder += time.delta;
        while score_remainder > 1 {
            PlaySound(point_sound);
            score_remainder -= 1;
            score += 1;
        }
    }
    if timer <= 0 {
        timer += 1.0;

        block1 := *pipes[pipe_index];
        block2 := *pipes[pipe_index+1];

        block1.x = playfield_width / 2 + block1.width;
        block2.x = playfield_width / 2 + block2.width;

        height := random_get_within_range(-4, 4);
        gap_size := 5.5;
        block1.y = height + gap_size / 2;
        block2.y = height - block2.height - gap_size / 2;

        pipe_index += 2;
        pipe_index %= pipes.count;
    }

    update_player(*player);
}

render_one_frame :: () {
    PushDrawing();
    ClearBackground(BLACK);

    { 
        PushMode2D(game_camera);

        // Render background
        {
            if !game_over bg_x_offset += time.delta * move_speed;
            repeat := cast(float)(bg_map.width / playfield_width/2.0);
            src_rect := Rectangle.{bg_x_offset, 0, xx bg_map.width * repeat, xx bg_map.height};
            dst_rect := Rectangle.{-playfield_width / 2.0, -playfield_height / 2.0, xx playfield_width, xx playfield_height};
            DrawTexturePro(
                bg_map,
                src_rect,
                dst_rect,
                .{0, 0},
                0,
                WHITE
            );
        }

        for pipes {
            src_rect := Rectangle.{0, 0, xx pipe_map.width, xx pipe_map.height};
            if it_index % 2 != 0 then src_rect.height *= -1;
            dst_rect := Rectangle.{it.x, it.y, it.width, it.height};
            DrawTexturePro(
                pipe_map,
                src_rect,
                dst_rect,
                .{0, 0},
                0,
                WHITE
            );
            // DrawRectangleLinesEx(it, 0.1, BLUE);
        }

        // Render ground texture
        {
            if !game_over ground_x_offset += time.delta * move_speed * 21;
            src_rect := Rectangle.{ground_x_offset, 0, xx ground_map.width * 2.0, xx ground_map.height * 2.0};
            dst_rect := ground_rect;
            DrawTexturePro(
                ground_map,
                src_rect,
                dst_rect,
                .{0, 0},
                0,
                WHITE
            );
        }


        for live_emitters draw_emitter(it);


        draw_player(*player);
    }

    if game_over {
        y: s32;
        font_size: s32 = cast(s32)(window_height * .1);
        text_width := MeasureTextEx(my_font, "GAME OVER!", cast(float)font_size, 0).x;
        DrawTextEx(my_font, "GAME OVER!", .{window_width / 2.0 - text_width / 2.0, window_height / 2.0 - font_size / 2.0}, cast(float)font_size, 0, WHITE);
        y += font_size;

        font_size = cast(s32)(window_height * .05);
        score_text := to_c_string(tprint("Final score: %", score),, temp);
        text_width = MeasureTextEx(my_font, score_text, cast(float)font_size, 0).x;
        DrawTextEx(my_font, score_text, .{window_width / 2.0 - text_width / 2.0, window_height / 2.0 - font_size / 2.0 + y}, cast(float)font_size, 0, WHITE);
        y += font_size;

        font_size = cast(s32)(window_height * .04);
        text_width = MeasureTextEx(my_font, "Press R to restart", cast(float)font_size, 0).x;
        c := Fade(RED, sin(time.now * TAU / 2.0) / 2.0 + 0.5);
        DrawTextEx(my_font, "Press R to restart", .{window_width / 2.0 - text_width / 2.0, window_height / 2.0 - font_size / 2.0 + y}, cast(float)font_size, 0, c);
    } else {
        font_size: s32 = cast(s32)(window_height * .06);
        text_width := MeasureText("GAME OVER!", font_size);
        DrawTextEx(my_font, to_c_string(tprint("Score: %", score),, temp), Vector2.{ window_width / 2.0 - text_width/2.0, font_size / 2.0 }, cast(float)my_font.baseSize, 0, WHITE);
    }
}


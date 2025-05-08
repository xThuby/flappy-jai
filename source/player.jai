
Player :: struct {
    #as using base: Entity;
    speed: Vector2;
    sprite: Sprite;
    rotation: float;

    emitter: *Particle_Emitter;

    anim_index: int;

    move_started: bool;
    radius: float;
}

init_player :: (player: *Player, x: float, y: float) {
    player.x = x;
    player.y = y;

    player.sprite = make_sprite("data/sprites/bird.png");
    player.sprite.origin = .{.5, .5};
    player.radius = .3;

    {
        player.emitter = New(Particle_Emitter);
        using player.emitter;

        position = player.position;

        fadeout_period = .2;
        particles_per_second = 20;

        speed0 = .2;
        speed1 = .5;

        size0 = 0.20;
        size1 = 0.35;

        lifetime0 = 0.2;
        lifetime1 = 1.4;

        color0 = ColorLerp(BLACK, WHITE, 0.75);
        color1 = ColorLerp(BLACK, WHITE, 0.25);

        array_add(*live_emitters, player.emitter);
    }
}

update_player :: (using player: *Player) {
    if game_over {
        emitter.velocity.x = 0;
        approach(*speed.y, fast_fall_speed, gravity * time.delta);

        position += speed * time.delta;

        rotation -= time.delta * 90;
    } else {
        player_move(player);
    }

    emitter.position = position;
}

kill_player :: (using player: *Player) {
    speed.y = jump_speed / 1.5;
    speed.x = -2;
    game_over = true;
    PlaySound(die_sound);
    PlaySound(hit_sound);
}

player_move :: (using player: *Player) {
    max_fall_speed := fall_speed;
    if input.down.held {
        max_fall_speed = fast_fall_speed;
    } else if input.up.held {
        max_fall_speed = slow_fall_speed;
    }
    approach(*speed.y, max_fall_speed, gravity * time.delta);

    position += speed * time.delta;

    rotation_target := lerp(-45, 45, (speed.y + abs(jump_speed)) / (abs(jump_speed) + fast_fall_speed));
    rotation = rotation_target;

    if input.jump.down {
        consume_buffer(*input.down);
        speed.y = jump_speed;
        jump_effect(player);
        PlaySound(swoosh_sound);
        PlaySound(wing_sound);
    }

    window := 1.9;
    if speed.y < xx -window {
        anim_index = 0;
    } else if speed.y > xx window {
        anim_index = 2;
    } else {
        anim_index = 1;
    }

    approach(*emitter.velocity.x, -move_speed, accel * time.delta);

    for pipes {
        if CheckCollisionCircleRec(position, radius, it) {
            kill_player(player);
        }
    }

    if position.y > ground_rect.y || position.y < -playfield_height / 2.0 {
        kill_player(player);
    }
}

draw_player :: (using player: *Player) {
    src_rect := Rectangle.{sprite.width / 3.0 * anim_index, 0, xx sprite.width / 3.0, xx sprite.height};
    dst_rect := Rectangle.{position.x, position.y, 1, 1};
    DrawTexturePro(
        sprite.texture,
        src_rect,
        dst_rect,
        sprite.origin,
        rotation,
        WHITE
    );
}

jump_effect :: (player: *Player) {
    emitter := New(Particle_Emitter);
    using emitter;

    position = player.position;

    fadeout_period = .2;
    particles_per_second = 800;

    emitter_lifetime = 0.05;
    speed0 = 2.0;
    speed1 = 3.0;

    size0 = 0.20;
    size1 = 0.35;

    velocity.x = player.emitter.velocity.x;

    theta0 = PI/2;
    theta1 = PI;

    lifetime0 = 0.2;
    lifetime1 = 1.4;

    color1 = BLACK;
    color1 = GREEN; //ColorLerp(YELLOW, RED, 0.75);

    array_add(*live_emitters, emitter);
}

move_speed:     float : 6;

#scope_file

accel:          float : 3;
jump_speed:     float : -18;
gravity:        float : 30;
fall_speed:     float : 8;
fast_fall_speed:     float : 15;
slow_fall_speed:     float : 2;

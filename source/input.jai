
INPUT_BUFFER_TIME  :: 0.15;
GAMEPAD_INDEX :: 0;
DEADZONE      :: 0.6;

REPEAT_DELAY    :: 0.4;
REPEAT_INTERVAL :: 0.05;

Input_State :: struct {
    move_x: float;
    move_y: float;
    up:     Input_Button;
    down:   Input_Button;
    left:   Input_Button;
    right:  Input_Button;
    jump:   Input_Button;
}

Input_Node :: struct {
    type: Type;
    key_code: KeyboardKey;

    // #place scancode;
    // gamepad_axis: GamepadAxis;
    //
    // #place scancode;
    // gamepad_button: GamepadButton;
}

Axis_Contribution :: enum s32 {
    NONE     ::  0;
    POSITIVE ::  1;
    NEGATIVE :: -1;
}

Input_Button :: struct {
    down:              bool;
    up:                bool;
    held:              bool;
    repeat:            bool;
    held_time:         float;
    buffer:            float;
    buffer_length:     float = INPUT_BUFFER_TIME;
    has_buffer:        bool = false;

    // if node is an axis, determines which side should contribute
    axis_contribution: Axis_Contribution;
    nodes:             [..]Input_Node;
    repeat_counter:    float;
}

input_create_node :: (input: *Input_Button, key_code: KeyboardKey) {
    node := array_add(*input.nodes);
    node.type = KeyboardKey;
    node.key_code = key_code;
}

init_input :: () {

    input_create_node(*input.left, .KEY_A);
    input_create_node(*input.left, .KEY_LEFT);
    input.left.axis_contribution = .NEGATIVE;

    input_create_node(*input.right, .KEY_D);
    input_create_node(*input.right, .KEY_RIGHT);
    input.right.axis_contribution = .POSITIVE;

    input_create_node(*input.up, .KEY_W);
    input_create_node(*input.up, .KEY_UP);
    input.up.axis_contribution = .NEGATIVE;

    input_create_node(*input.down, .KEY_S);
    input_create_node(*input.down, .KEY_DOWN);
    input.down.axis_contribution = .POSITIVE;

    input_create_node(*input.jump, .KEY_SPACE);
}

update_input_button :: (button: *Input_Button) {

    // has_gamepad := IsGamepadAvailable(GAMEPAD_INDEX);

    value: bool;
    for node: button.nodes {
        if node.type == {
            // case GamepadAxis;
            //           if !has_gamepad continue;
            // 	value ||=
            // 		(rl.GetGamepadAxisMovement(GAMEPAD_INDEX, node.(rl.GamepadAxis)) *
            // 			f32(button.axis_contribution)) >
            //                   DEADZONE;
            // case rl.GamepadButton;
            //           if !has_gamepad continue;
            //           value ||= rl.IsGamepadButtonDown(GAMEPAD_INDEX, node.(rl.GamepadButton));
        case KeyboardKey;
            value ||= IsKeyDown(node.key_code);
        }
    }

    if button.buffer > 0 {
        button.buffer -= time.delta;
    }

    down := value && !button.held;
    up := !value && button.held;

    if down {
        button.buffer = button.buffer_length;
        button.repeat_counter = 0;
    }

    if !value {
        button.buffer = 0;
    }

    button.down = down || (button.buffer > 0 && button.has_buffer);
    button.held = value;
    button.up = up;

    button.repeat = false;

    if button.held {
        button.held_time += time.delta;
    } else {
        button.held_time = 0;
        button.repeat_counter = 0;
    }

    if button.held_time > REPEAT_DELAY {
        button.repeat_counter -= time.delta;

        if button.repeat_counter < 0 {
            button.repeat_counter = REPEAT_INTERVAL;
            button.repeat = true;
        }
    }
}

consume_buffer :: (button: *Input_Button) {
    button.buffer = 0;
}

deinit_input :: () {
    array_free(input.up.nodes);
    array_free(input.down.nodes);
    array_free(input.left.nodes);
    array_free(input.right.nodes);

    array_free(input.jump.nodes);
}

update_input :: () {
    update_input_button(*input.up);
    update_input_button(*input.down);
    update_input_button(*input.left);
    update_input_button(*input.right);

    update_input_button(*input.jump);

    input.move_x = 0;
    input.move_y = 0;

    if input.left.held {
        input.move_x -= 1;
    }
    if input.right.held {
        input.move_x += 1;
    }

    if input.up.held {
        input.move_y -= 1;
    }
    if input.down.held {
        input.move_y += 1;
    }
}
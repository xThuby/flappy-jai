// Most of this file is unused since we don't support input rebinding yet

Config_State :: struct {
    keybinds: [5]u8;
}

CONFIG_DEFAULT :: #string END
/rendering
fullscreen:     false
window_scale:   4

/controls
left:       A
right:      D
up:         W
down:       S
escape:     Escape
END;

CONFIG_FILEPATH :: "data/config.ini";

config_init :: () {
    // if config_load() {
    //     return;
    // }
    //
    // print("Creating config file with defaults.\n");
    // write_entire_file(CONFIG_FILEPATH, CONFIG_DEFAULT);
    //
    // if !config_load() {
    //     print("Error: Could not load or create config file.\n");
    // }
}

config_load :: (loc := #caller_location) -> bool {
    file_data, success := read_entire_file(CONFIG_FILEPATH);
    if !success {
        print("Error: Failed to open file %. %\n", CONFIG_FILEPATH, loc);
        return false;
    }

    free(file_data.data);

    return true;
}

config_get_value :: (config_buffer: string, value_name: string) -> (result: string, success: bool) {
    // Get to the [controls] bit of the config file
    while true {
        line, found := consume_next_line(*config_buffer);
        if !found {
            print("Could not fine config value: %.\n", value_name);
            print("Try deleting config.ini and reload.\n");
            break;
        }
        if contains(line, "[controls]") then break;
    }

    while true {
        line, found := consume_next_line(*config_buffer);
        if !contains(line, value_name) then continue;
        if !line break;

        // Find ":"
        while line[0] != #char ":" {
            if line.count == 0 then return "", false;
            advance(*line);
        }

        // Consume ":"
        advance(*line);
        line = eat_spaces(line);

        return line, true;
    }

    return "", false;
}

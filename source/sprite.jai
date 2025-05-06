
Sprite :: struct {
    texture : Texture2D;
    width   : int;
    height  : int;
    origin  : Vector2;
    flip_x  : bool;
}

make_sprite :: (path: string) -> Sprite {
    texture := LoadTexture(to_c_string(path));

    result: Sprite;
    result.texture = texture;
    result.width = texture.width;
    result.height = texture.height;

    return result;
}

draw_sprite :: (sprite: Sprite, position: Vector2, size: Vector2) {
    src_rect := Rectangle.{0, 0, xx sprite.width, xx sprite.height};
    dst_rect := Rectangle.{position.x, position.y, size.x, size.y};
    DrawTexturePro(
        sprite.texture,
        src_rect,
        dst_rect,
        size * sprite.origin,
        0,
        WHITE
    );
}

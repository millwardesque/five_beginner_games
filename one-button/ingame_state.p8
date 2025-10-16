local default_gravity = -1.4
local force_obstacle_height_to_zero = true
local skip_gravity = true
local ground_tile_width = 8
local obstacle_width = 16
local jump_impulse = 10.0
local slowdown_factor = 0.6
local ground_tiles = {}
local obstacle_pairs = {}
local was_pressed = false
local player_has_started = false
local GROUND_TILE_SPR = 4
local PLAYER_SPR = 3
local PLAYER_UP_SPR = PLAYER_SPR + 16
local PLAYER_DOWN_SPR = PLAYER_UP_SPR + 16
local OBSTACLE_LEFT_SPR = 1
local OBSTACLE_RIGHT_SPR = 2
local OBSTACLE_LEFT_CAP_SPR = OBSTACLE_LEFT_SPR + 16
local OBSTACLE_RIGHT_CAP_SPR = OBSTACLE_RIGHT_SPR + 16
local PIPE_GAP_HEIGHT = 32
local COLUMN_SPACING = 64
local MAX_GAP_SIZE = 64
local debug_draw_colliders = true

ingame_state = {
    init = function()
        reset_game()
    end,

    update = function()
        if (btn(2)) then
            if (was_pressed == false) then
                player.speed = jump_impulse
                was_pressed = true
                sfx(0)

                if (player_has_started == false) then
                    force_obstacle_height_to_zero = false
                    player.gravity = default_gravity
                    player_has_started = true
                end
            end
        else
            was_pressed = false
        end

        player.speed = player.speed * slowdown_factor
        player.y -= player.speed + player.gravity

        foreach(ground_tiles, update_ground_tile)
        foreach(obstacle_pairs, update_obstacle_pair)

        if (player_has_started) then
            score += scroll_speed
        end

        for o in all(obstacles) do
            if check_player_obstacle_collision(player, o) then
                set_state('gameover')
                debug_collider = o
                break
            end
        end
    end,

    draw = function()
        cls(sky_colour)

        map(0, 0, 0, 0, 16, 16)

        foreach(obstacles, draw_obstacle)
        foreach(ground_tiles, draw_ground_tile)
        draw_player(player)

        draw_score(score)
    end
}

function draw_score(s)
    rectfill(0, 0, 127, 7, 1)
    print("Score: "..s, 1, 1, 7)
end

function update_ground_tile(t)
    t.x -= scroll_speed

    local is_offscreen = t.x + ground_tile_width <= 0
    if (is_offscreen) then
        t.x = 128
    end
end

function update_obstacle_pair(p)
    local top = p.top
    local bottom = p.bottom
    top.x -= scroll_speed
    bottom.x -= scroll_speed

    local is_offscreen = top.x + top.w <= 0

    -- If we've scrolled offscreen, wrap to the beginning and generate new heights
    if (is_offscreen) then
        top.x = 128
        bottom.x = 128
        calculate_obstacle_pair_height(p)
    end
end

function calculate_obstacle_pair_height(p)
    local top = p.top
    local bottom = p.bottom
    if (force_obstacle_height_to_zero) then
        top.h = 0
        bottom.y = 128
        bottom.h = 0
        return
    end

    -- Leave room for pipe, min-top-height, terrain, and full gap
    local max_top_y = 128 - 8 - 16 - 8 - PIPE_GAP_HEIGHT
    local gap_y = 16 + flr(rnd() * max_top_y)
    local prev_y = top.prev.y
    local prev_gap = top.y - prev_y

    if prev_gap > MAX_GAP_SIZE then
        gap_y = prev_y + MAX_GAP_SIZE
    elseif prev_gap < -MAX_GAP_SIZE then
        gap_y = prev_y - MAX_GAP_SIZE
    end

    top.h = gap_y
    bottom.y = gap_y + PIPE_GAP_HEIGHT
    bottom.h = 128 - bottom.y
end

function draw_obstacle(o)
    local num_to_draw = 1 + (o.h / 8)
    for i = 0, num_to_draw do
        local start_y = o.y
        local is_cap = (i == 0)
        if (o.is_top) then
            start_y += o.h - 8 * (i + 1)
        else
            start_y += 8 * i
        end

        local flip_y = o.is_top == false
        local left_spr = OBSTACLE_LEFT_SPR
        local right_spr = OBSTACLE_RIGHT_SPR
        if (is_cap) then
            left_spr = OBSTACLE_LEFT_CAP_SPR
            right_spr = OBSTACLE_RIGHT_CAP_SPR
        end

        spr(left_spr, o.x, start_y, 1, 1, false, flip_y)
        spr(right_spr, o.x + 8, start_y, 1, 1, false, flip_y)
    end

    if debug_draw_colliders then
        rect(o.x, o.y, o.x + o.w, o.y + o.h, 8)
    end
end

function draw_ground_tile(t)
    spr(GROUND_TILE_SPR, t.x, t.y)
end

function sprite_center(s)
    return {
        x = s.x + 4,
        y = s.y + 4
    }
end

function draw_player(p)
    local sprite = PLAYER_SPR
    local level_threshold = 0.2
    local net_speed = p.speed + p.gravity
    if (net_speed > level_threshold) then
        sprite = PLAYER_UP_SPR
    elseif (net_speed < -level_threshold) then
        sprite = PLAYER_DOWN_SPR
    end

    spr(sprite, p.x, p.y)

    if debug_draw_colliders then
        local p_centre = sprite_center(p)
        pset(p_centre.x, p_centre.y, 7)
        circ(p_centre.x, p_centre.y, p.r, 7)
    end
end

function reset_game()
    was_pressed = false
    player_has_started = false
    force_obstacle_height_to_zero = true
    skip_gravity = true

    scroll_speed = 1
    sky_colour = 12

    player = {
        x = 64,
        y = 64,
        r = 2,
        speed = 0,
        gravity = 0,
        acceleration = 0
    }

    score = 0

    -- Generate ground
    ground_tiles = {}
    local num_ground_tiles = 128 / ground_tile_width
    local ground_tile_y = 128 - 8;
    for i = 0, num_ground_tiles do
        local x = i * ground_tile_width
        local new_tile = {
            x = x,
            y = ground_tile_y
        }
        add(ground_tiles, new_tile)
    end

    -- Generate obstacles
    obstacles = {}
    obstacle_pairs = {}
    local columns = max(1, (128 / COLUMN_SPACING))
    for i = 1, columns do
        local x = (i - 1) * COLUMN_SPACING
        local new_obstacle_top = {
            x = x,
            w = obstacle_width,
            y = 0,
            h = 0,
            is_top = true,
            prev = nil,
            index = i
        }

        local new_obstacle_bottom = {
            x = x,
            y = 128,
            w = obstacle_width,
            h = 0,
            is_top = false,
            prev = nil,
            index = i
        }

        if i > 1 then
            new_obstacle_bottom.prev = obstacle_pairs[i - 1].bottom
            new_obstacle_top.prev = obstacle_pairs[i - 1].top
        end

        local obstacle_pair = {top = new_obstacle_top, bottom = new_obstacle_bottom}
        add(obstacles, new_obstacle_top)
        add(obstacles, new_obstacle_bottom)
        add(obstacle_pairs, obstacle_pair)
    end

    obstacle_pairs[1].top.prev = obstacle_pairs[columns].top
    obstacle_pairs[1].bottom.prev = obstacle_pairs[columns].bottom
end

function check_player_obstacle_collision(p, o, debug)
    local p_centre = sprite_center(p)

    local test_x = p_centre.x
    local test_y = p_centre.y

    if p_centre.x > o.x + o.w then
        test_x = o.x + o.w
    elseif p_centre.x < o.x then
        test_x = o.x
    end

    if p_centre.y > o.y + o.h then
        test_y = o.y + o.h
    elseif p_centre.y < o.y then
        test_y = o.y
    end

    local dist_x = p_centre.x - test_x
    local dist_y = p_centre.y - test_y
    local distance = sqrt((dist_x * dist_x) + (dist_y * dist_y))

    if debug then
        print(test_x..", "..test_y..", "..dist_x..", "..dist_y..", "..distance..", "..p.r)
    end

    return distance <= p.r
end

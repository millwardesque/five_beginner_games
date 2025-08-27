obstacle_width = 8

ingame_state = {
    init = function()
        reset_game()
    end,

    update = function()
        if (btn(2)) then
            player.y -= player.speed
        else
            player.y += player.gravity
        end

        foreach(obstacles, update_obstacle)

        score += scroll_speed

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

        foreach(obstacles, draw_obstacle)
        draw_player(player)

        rectfill(0, 0, 127, 7, 0)
        print("Score: "..score, 1, 1, 7)
    end
}


function update_obstacle(o)
    o.x -= scroll_speed

    -- If we've scrolled offscreen, wrap to the beginning and generate a new height
    if (o.x + o.w <= 0) then
        o.x = 128

        local is_bottom = o.y + o.h == 128
        local new_height = calc_obstacle_height(is_bottom)

        o.h = new_height
        if is_bottom then
            o.y = 128 - new_height
        end
    end
end

function draw_obstacle(o)
    rectfill(o.x, o.y, o.x + o.w - 1, o.y + o.h - 1, o.c)
    rect(o.x, o.y, o.x + o.w - 1, o.y + o.h - 1, 0)
end

function draw_player(p)
    circfill(p.x, p.y, p.r, p.c)
end

function reset_game()
    scroll_speed = 1
    sky_colour = 12

    player = {
        x = 64,
        y = 64,
        r = 3,
        r_collision = 2,
        c = 7,
        speed = 2,
        gravity = 1
    }

    score = 0

    -- Generate obstacles
    obstacles = {}
    local columns = 128 / obstacle_width
    for i = 0, columns do
        local new_obstacle_top = {
            x = i * obstacle_width,
            w = obstacle_width,
            y = 0,
            h = calc_obstacle_height(false),
            c = i % 16
        }

        local bottom_h = calc_obstacle_height(true)
        local new_obstacle_bottom = {
            x = i * obstacle_width,
            y = 128 - bottom_h,
            w = obstacle_width,
            h = bottom_h,
            c = i % 16
        }

        add(obstacles, new_obstacle_top)
        add(obstacles, new_obstacle_bottom)
    end
end

function calc_obstacle_height(is_bottom)
    local max_h = 6
    if is_bottom then
        max_h = 6
    end
    return 16 + flr(rnd(max_h)) * 7
end

function check_player_obstacle_collision(p, o, debug)
    local test_x = p.x
    local test_y = p.y

    if p.x > o.x + o.w then
        test_x = o.x + o.w
    elseif p.x < o.x then
        test_x = o.x
    end

    if p.y > o.y + o.h then
        test_y = o.y + o.h
    elseif p.y < o.y then
        test_y = o.y
    end

    local dist_x = p.x - test_x
    local dist_y = p.y - test_y
    local distance = sqrt((dist_x * dist_x) + (dist_y * dist_y))

    if debug then
        print(test_x..", "..test_y..", "..dist_x..", "..dist_y..", "..distance..", "..p.r_collision)
    end

    return distance <= p.r_collision
end
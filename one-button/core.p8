debug = false
debug_collider = {}
high_scores = {}
max_scores = 5
states = {}

function set_state(new_state_name)
    local new_state = states[new_state_name]
    assert(new_state ~= nil, "State '"..new_state_name.."' doesn't exist")

    active_state = new_state
    active_state.init()
end

function _init()
    states = {
        gameover = gameover_state,
        ingame = ingame_state
    }

    set_state("ingame")
end

function _update()
    active_state:update()
end

function _draw()
    active_state:draw()
end

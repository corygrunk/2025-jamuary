-- Jamuary 2025 - 01
-- norns explorations

g = grid.connect() -- if no argument is provided, defaults to port 1

engine.name = 'Autumn'

hs = include('lib/halfsecond')

_lfos = require 'lfo'

TAB = require('tabutil')
MusicUtil = require('musicutil')

s = require 'sequins'

local playing = true
local step = 1
local alt_mode = false
local mode = 'lfo1'

local note = s{60,62,65,67,70,72}
local current_note_name = '_'

local prob = 80
local att = 0.01
local rel = 0.2

local lfo1_depth = 0.5
local lfo1_period = 4


-- local times = {1}
local times = {1.5,1,1/2,1/4}

function init()
  engine.attack(0.01)
  engine.release(0.1)
  engine.cutoff(2000)

  hs.init()

  -- establish an LFO variable for a specific purpose:
  release_lfo = _lfos:add{
    shape = 'tri', -- shape
    min = 0.01, -- min
    max = 5, -- max
    depth = lfo1_depth, -- depth (0 to 1)
    mode = 'clocked', -- mode
    period = lfo1_period, -- period (in 'clocked' mode, represents beats)
    -- pass our 'scaled' value (bounded by min/max and depth) to the engine:
    action = function(scaled, raw) rel = scaled end -- action, always passes scaled and raw values
  }

  release_lfo:start() -- start our LFO, complements ':stop()'

  clock.run(seq_clock)
  clock.run(redraw_clock)
  screen_dirty = true
end


function seq_clock()
  while true do
    clock.sync(times[math.random(1,TAB.count(times))])
    if playing then
      if math.random(0,99) < prob then
        step = math.random(1,#note)
        note:step(step)
        local note = note()
        current_note_name = MusicUtil.note_num_to_name(note,true)
        engine.attack(att)
        engine.release(rel)
        engine.hz(MusicUtil.note_num_to_freq(note))     
      end
      screen_dirty = true
    end
  end
end

function key(n,z)
  if n == 1 and z == 1 then
    alt_mode = true
    print('ALT MODE')
  elseif n == 1 and z == 0 then
    alt_mode = false
  elseif n == 2 and z == 1 then -- KINDA HACKY WAY TO MOVE THROUGH MODES
    if mode == 'env' then
      mode = 'lfo1'
    elseif mode == 'lfo1' then
      mode = 'env'
    end
  elseif n == 3 and z == 1 then
    if playing then playing = false else playing = true end
  end
  screen_dirty = true
end


function enc(n,d)
  if n == 1 then
    prob = util.clamp(prob + d,0,100)
  elseif n == 2 and alt_mode == false then

    if mode == 'env' then
      att = util.clamp(att + d*0.1, 0.01, 10)
    end

    if mode == 'lfo1' then
      lfo1_depth = util.clamp(lfo1_depth + d/10, 0, 1)
      release_lfo.depth = lfo1_depth
    end

  elseif n == 3 and alt_mode == false then

    if mode == 'env' then
      rel = util.clamp(rel + d/10, 0.01, 10)
    end

    if mode == 'lfo1' then
      lfo1_period = util.clamp(lfo1_period + d, 1, 20)
      release_lfo.period = lfo1_period
    end
  end
  screen_dirty = true
end


function redraw()
  if playing then
    play_text = 'playing'
  else
    play_text = 'paused'
  end
  screen.clear() --------------- clear space
  screen.aa(1) ----------------- enable anti-aliasing
  screen.font_face(1) ---------- set the font face to "04B_03"
  screen.font_size(8) ---------- set the size to 8
  screen.level(4) --------------
  screen.move(127, 60)
  if playing then
    screen.text_right(step) 
  else
     screen.text_right(play_text) 
  end
  

  screen.move(0, 10)
  screen.text('prob: ' .. prob)
  
  if mode == "env" then screen.level(10) else screen.level(1) end
  screen.move(0, 25)
  screen.text('attack: ' .. string.format('%.1f',att))
  screen.move(0, 35)
  screen.text('release: ' .. string.format('%.1f',rel))

  if mode == "lfo1" then screen.level(10) else screen.level(1) end
  screen.move(0, 50)
  screen.text('lfo level: ' .. string.format('%.1f',lfo1_depth))
  screen.move(0, 60)
  screen.text('lfo time: ' .. string.format('%.1f',lfo1_period))
  
  screen.level(15)
  screen.move(70,40)
  screen.font_size(24)
  screen.text(current_note_name)
  

  screen.fill() ---------------- fill the termini and message at once
  screen.update() -------------- update space

  screen_dirty = false
end


function redraw_clock()
  while true do
    clock.sleep(1/15)
    if screen_dirty then
      redraw()
      screen_dirty = false
    end
  end
end



-- UTILITY TO RESTART SCRIPT FROM MAIDEN
function r()
  norns.script.load(norns.state.script)
end

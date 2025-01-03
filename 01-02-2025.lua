-- Jamuary 2025 - 02
-- norns explorations

g = grid.connect() -- if no argument is provided, defaults to port 1

engine.name = 'Autumn'

hs = include('lib/halfsecond')
TAB = require('tabutil')
MusicUtil = require('musicutil')

s = require 'sequins'

steps = {1,0,3,0,1,0,6,0,0,2,0,0,0,0,3,0}
counter = 0
position = 0

local playing = true
local step = 1
local alt_mode = false
local mode = 'env'
local sound_src = 'internal'

local note = s{60,62,65,67,70,72}
local current_note_name = '_'

local prob = 100
local att = 0.01
local rel = 0.1
local lfo1_time = 5
local lfo1_level = 3

function init()
  engine.attack(0.01)
  engine.release(0.5)

  crow.output[2].action = "ar(dyn{attack = 0.01},dyn{release = 3},8,'expo')"
  crow.output[2].dyn.attack = att
  crow.output[2].dyn.release = rel
  
  crow.output[3].action = "lfo(dyn{time=2},dyn{level=0})"
  crow.output[3]()
  crow.output[3].dyn.time = lfo1_time
  crow.output[3].dyn.level = lfo1_level

  hs.init()

  -- for i=1,16 do
  --   table.insert(steps,1) -- every step starts at position 1
  -- end

  clock.run(seq_clock)
  clock.run(redraw_clock)
  screen_dirty = true
end


function seq_clock()
  while true do
    clock.sync(1/2)
    if playing then

      counter = counter + 1
      position = position + 1
      if position > 16 then position = 1 end
      if counter > 16 then counter = 1 end

      if math.random(0,99) < prob then
        step = math.random(1,#note)
        note:step(step)
        local note = note()
        current_note_name = MusicUtil.note_num_to_name(note,true)
        if sound_src == 'internal' then
          if steps[counter] ~= 0 then
            engine.hz(MusicUtil.note_num_to_freq(note))
          end
          engine.attack(att)
          engine.release(rel)
          -- engine.hz(MusicUtil.note_num_to_freq(note))          
        elseif sound_src == 'crow' then
          crow.output[1].volts = (note - 60)/12
          crow.output[2]() 
        end
      end
      grid_redraw()
      screen_dirty = true
    end
  end
end

function grid_redraw()
  g:all(0) -- turn all the LEDs off...

  for i = 1, 16 do
    for n = 1, 8 do

      if steps[i] == n then
        g:led(i,n,15)
      else
        g:led(i,n,0)
      end

    end
  end

  for i=1,16 do
    g:led(counter,i,4) -- set step positions to brightness 4
  end
  g:refresh() -- refresh the grid
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
      crow.output[2].dyn.attack = att
    end

    if mode == 'lfo1' then
      lfo1_level = util.clamp(lfo1_level + d/10, 0, 10)
      crow.output[3].dyn.level = lfo1_level
    end

  elseif n == 2 and alt_mode == true then -- SELECT SOUNDS SOURCE
        if d < 0 then sound_src = 'internal' end
    if d > 0 then sound_src = 'crow' end

  elseif n == 3 and alt_mode == false then

    if mode == 'env' then
      rel = util.clamp(rel + d/10, 0.01, 10)
      crow.output[2].dyn.release = rel
    end

    if mode == 'lfo1' then
      lfo1_time = util.clamp(lfo1_time + d/10, 0.1, 20)
      crow.output[3].dyn.time = lfo1_time
    end

  elseif n == 3 and alt_mode == true then -- SELECT SOUNDS SOURCE
    if d < 0 then sound_src = 'internal' end
    if d > 0 then sound_src = 'crow' end
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
  

  if alt_mode == false then
    screen.move(0, 10)
    screen.text('prob: ' .. prob)
    
    if mode == "env" then screen.level(10) else screen.level(1) end
    screen.move(0, 25)
    screen.text('attack: ' .. att)
    screen.move(0, 35)
    screen.text('release: ' .. rel)

    if mode == "lfo1" then screen.level(10) else screen.level(1) end
    screen.move(0, 50)
    screen.text('lfo level: ' .. lfo1_level)
    screen.move(0, 60)
    screen.text('lfo time: ' .. lfo1_time)
    
    screen.level(15)
    screen.move(70,40)
    screen.font_size(24)
    if steps[counter] ~= 0 then
      screen.text(current_note_name)
    else
      screen.text('')
    end
    
  else
    screen.level(6)
    screen.font_size(8)
    screen.move(62,25)
    screen.text_center('sound source')
    screen.move(62,35)
    if sound_src == "internal" then screen.level(10) else screen.level(1) end
    screen.text_center('internal')
    screen.move(62,45)
    if sound_src == "crow" then screen.level(10) else screen.level(1) end
    screen.text_center('crow 1/2')
  end
  

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

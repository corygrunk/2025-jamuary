-- Jamuary 2025 - 04
---
--- crow sequencer
--- probably need a grid
--- K2 to toggle glitch mode

g = grid.connect() -- if no argument is provided, defaults to port 1

TAB = require('tabutil')
MusicUtil = require('musicutil')
hs = include('lib/halfsecond')

scale_names = {}

steps = {8,0,0,5,0,0,0,0,8,5,0,3,4,5,5,8}
scale = {}
counter = 0

playing = true
alt_mode = false

att = 0.1
rel = 1

glitch = false
held_note = 0
glitch_rel = 0.08 -- glitch release time hard coded - boo
glitch_syncs = {1/32, 1/16, 1/8, 1/4, 1/2, 1}


function init()

  hs.init()

  for i = 1, #MusicUtil.SCALES do
    table.insert(scale_names, string.lower(MusicUtil.SCALES[i].name))
  end

  params:add_separator("JAMUARY 2025 - 04")

  params:add{type = "option", id = "scale_mode", name = "scale mode",
  options = scale_names, default = 5,
  action = function() build_scale() end}

  params:add{type = "number", id = "root_note", name = "root note",
    min = 0, max = 127, default = 60, formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end,
    action = function() build_scale() end}

  build_scale() -- builds initial scale

  crow.output[2].action = "ar(dyn{attack = " .. att .."},dyn{release = " .. rel .. "},8,'expo')"
  
  crow.output[3].action = "lfo(dyn{time=4},dyn{level=0.25})"
  crow.output[3]()

  clock.run(seq_clock)
  clock.run(glitch_clock)
  clock.run(redraw_clock)
  screen_dirty = true
end

function build_scale()
  scale = MusicUtil.generate_scale_of_length(params:get("root_note"), params:get("scale_mode"), 16)
  local num_to_add = 16 - #scale
  for i = 1, num_to_add do
    table.insert(scale, scale[16 - num_to_add])
  end
end


function seq_clock()
  while true do
    clock.sync(1/4)
    
    if playing then

      counter = util.wrap(counter + 1, 1, 16) -- increment the position by 1, wrap it as 1 to 16

      if scale[steps[counter]] ~= nil then
        held_note = scale[steps[counter]]
      end
      
      if steps[counter] ~= 0 and glitch == false then
        crow.output[1].volts = (scale[steps[counter]] - 60)/12
        crow.output[2]()
      end

      grid_redraw()
      screen_dirty = true
    end
  end
end

function glitch_clock()
  while true do
    clock.sync(glitch_syncs[math.random(1,TAB.count(glitch_syncs))])
    if counter % 6 == 0 then held_note = scale[math.random(1,8)] end -- randomizing the held note - maybe keep, maybe not?
    if playing and glitch then
      crow.output[2].dyn.attack = 0.01
      crow.output[2].dyn.release = glitch_rel
      crow.output[1].volts = (held_note - 60)/12
      crow.output[2]()
    end
  end
end

function glitch_on()
  glitch = true
end

function glitch_off()
  glitch = false
  crow.output[2].dyn.attack = att
  crow.output[2].dyn.release = rel
end

function g.key(x,y,z)
  -- print(x .. ',' .. y .. ',' .. z)

  if z == 1 then
    if steps[x] == y then
      steps[x] = 0
    else
      steps[x] = y
    end

  end

  grid_redraw()
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
    g:led(counter,i,3) -- set step positions to brightness 4
  end

  g:refresh() -- refresh the grid
end

function key(n,z)
  if n == 1 and z == 1 then
    alt_mode = true
    print('ALT MODE')
  elseif n == 1 and z == 0 then
    alt_mode = false
  elseif n == 2 and z == 1 then
    if glitch then glitch_off() else glitch_on()
    end
  elseif n == 3 and z == 1 then
    if alt_mode then
      steps = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
      counter = 1
      grid_redraw()
    else
      if playing then 
        playing = false
      else
        counter = 0
        playing = true
      end
    end
  end
  screen_dirty = true
end


function enc(n,d)
  if n == 1 then
    print('enc 1')
  end
  if n == 2 then
    att = util.clamp(att + d/100, 0.01, 10)
    crow.output[2].dyn.attack = att
  end
  if n == 3 then
    rel = util.clamp(rel + d/100, 0.01, 10)
    crow.output[2].dyn.release = rel
  end
  screen_dirty = true
end


function redraw()
  if playing then
    play_text = 'playing'
  else
    play_text = 'paused'
  end

  if glitch then
    glitch_text = 'glitching'
  else
    glitch_text = 'k2 to glitch'
  end
  screen.clear()
  screen.aa(1)
  screen.font_face(1)
  screen.font_size(8)
  screen.level(3)
  screen.move(127, 60)
  screen.text_right(play_text)
  
  screen.move(0, 10)
  screen.text(glitch_text)

  screen.level(10)
  screen.move(0, 30)
  screen.text('att: ' .. string.format('%.2f',att))

  screen.move(0, 40)
  screen.text('rel: ' .. string.format('%.2f',rel))

  screen.fill()
  screen.update()

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

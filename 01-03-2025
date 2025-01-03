-- Jamuary 2025 - 03
-- norns explorations

g = grid.connect() -- if no argument is provided, defaults to port 1

hs = include('lib/halfsecond')
TAB = require('tabutil')
MusicUtil = require('musicutil')


-- steps = {}
steps = {1,0,0,0,4,0,0,0,8,6,3,4,0,0,0,0}
scale = {77,74,72,70,67,65,62,60}
counter = 0

playing = true
alt_mode = false

att = 0.01
rel = 0.3

function init()

  -- for i=1,16 do
  --   table.insert(steps,0) -- every step starts at position 1
  -- end

  crow.output[2].action = "ar(dyn{attack = 0.01},dyn{release = 3},8,'expo')"
  crow.output[2].dyn.attack = 0.01
  crow.output[2].dyn.release = 0.3
  
  crow.output[3].action = "lfo(dyn{time=10},dyn{level=1})"
  crow.output[3]()

  hs.init()

  clock.run(seq_clock)
  clock.run(redraw_clock)
  screen_dirty = true
end


function seq_clock()
  while true do
    clock.sync(1/4)
    if playing then

      counter = util.wrap(counter + 1, 1, 16) -- increment the position by 1, wrap it as 1 to 16

      if steps[counter] ~= 0 then
        crow.output[1].volts = (scale[steps[counter]] - 60)/12
        crow.output[2]()
      end
      -- current_note_name = MusicUtil.note_num_to_name(note,true)
      -- crow.output[1].volts = (note - 60)/12
      -- crow.output[2]() 

      grid_redraw()
      screen_dirty = true
    end
  end
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

  screen_dirty = true
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
  elseif n == 3 and z == 1 then
    if playing then 
      playing = false
    else
      counter = 0
      playing = true
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
  screen.clear()
  screen.aa(1)
  screen.font_face(1)
  screen.font_size(8)
  screen.level(3)
  screen.move(127, 60)
  screen.text_right(play_text)
  
  screen.move(0, 10)
  screen.text('sequencing crow')

  if alt_mode == false then

    screen.level(10)
    screen.move(0, 30)
    screen.text('att: ' .. string.format('%.2f',att))

    screen.move(0, 40)
    screen.text('rel: ' .. string.format('%.2f',rel))
  end
  

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

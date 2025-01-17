-- Jamuary 2025 - 16
--- Softcut loops w/ waveforms
--
-- K2 start/stop rec
-- K3 clear

Tab = require('tabutil')

sc = softcut
level = 1.0

length = 10
start = 1

rec_msg = ''
recording = false

position = 0 -- initialize position to avoid nil

function init()
  sc.buffer_clear()

  audio.level_cut(0.6)
  audio.level_adc_cut(1)
  sc.level_input_cut(1, 1, 1.0)
  sc.rec(1, 0)
  sc.rec_level(1, 1)
  sc.pre_level(1, 1)
  sc.enable(1,1)
  sc.buffer(1,1)
  sc.level(1,1.0)
  sc.loop(1,1)
  sc.loop_start(1,start)
  sc.loop_end(1,1 + length) -- you have to add 1 to make it count correctly???
  sc.position(1,1)
  sc.rate(1,1)
  sc.play(1,0)
  sc.fade_time(1,0)

  sc.phase_quant(1,0.01)
  sc.event_phase(update_positions)
  sc.poll_start_phase()
  softcut.event_render(on_render)

  clock.run(redraw_clock)
  screen_dirty = true
end

function update_positions(i,pos)
  position = pos - 1
  screen_dirty = true
end

-- WAVEFORMS
local interval = 0
waveform_samples = {}
scale = 30

function on_render(ch, start, i, s)
  waveform_samples = s
  interval = i
  screen_dirty = true
end

function update_content(buffer,winstart,winend,samples)
  softcut.render_buffer(buffer, winstart, winend - winstart, 128)
end
--/ WAVEFORMS

function key(n,z)
  if n == 1 and z == 1 then
    print('K1')
  elseif n == 2 and z == 1 then
    if not recording then
      recording = true
      sc.rec(1,1)
      sc.play(1,1)
      rec_msg = 'rec'
    else
      recording = false
      sc.rec(1,0)
      length = position
      sc.loop_end(1,1 + length)
      rec_msg = ''
      update_content(1,1,1 + length,128) -- do i need the 1+position here? -- yes
    end
  elseif n == 3 and z == 1 then
    -- clear
    length = 10
    sc.buffer_clear_channel(1)
    sc.play(1,0)
    sc.loop_end(1,1 + length) -- do i need the 1+position here? -- yes
    sc.position(1,1)
    position = 0
    update_content(1,1,length,128)
  end
  screen_dirty = true
end

function enc(n,d)
  if n == 1 then
    level = util.clamp(level+d/100,0,2)
    softcut.level(1,level)
  elseif n == 2 then
    start = util.clamp(start+d/10,1,length)
    sc.loop_start(1,start)
    update_content(1,start,1 + length,128)
  elseif n == 3 then
    length = util.clamp(length+d/10,0.1,10)
    sc.loop_end(1,1 + length)
    update_content(1,start,1 + length,128)
  end
  screen_dirty = true
end

function redraw()
  screen.clear()

  if recording then
    update_content(1,start,1 + length,128)
  end

  -- waveform
  screen.move(62,10)
  screen.level(4)
  local x_pos = 0
  for i,s in ipairs(waveform_samples) do
    local height = util.round(math.abs(s) * (scale*level))
    screen.move(util.linlin(0,128,10,120,x_pos), 35 - height)
    screen.line_rel(0, 2 * height)
    screen.stroke()
    x_pos = x_pos + 1
  end

  -- playhead
  screen.level(15)
  screen.move(util.linlin(0,length,10,120,position),18)
  screen.line_rel(0, 35)
  screen.stroke()

  -- start marker
  screen.level(15)
  screen.move(10,30)
  screen.line_rel(0, 10)
  screen.stroke()

  -- end marker
  screen.level(15)
  screen.move(120,30)
  screen.line_rel(0, 10)
  screen.stroke()

  -- start text
  screen.level(6)
  screen.move(10,10)
  screen.text(string.format('%.2f', start or 0)) -- Avoid nil error

  -- end text
  screen.level(6)
  screen.move(120,10)
  screen.text_right(string.format('%.2f', length or 0)) -- Avoid nil error

  -- rec
  screen.level(6)
  screen.move(10,60)
  screen.text(rec_msg)
  
  screen.update()
end


function redraw_clock()
  while true do
    clock.sleep(1/30)
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

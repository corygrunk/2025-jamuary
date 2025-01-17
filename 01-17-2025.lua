-- Jamuary 2025 - 17
--- Softcut looper - WORKING!
--
-- K2 rec
-- K3 clear
-- E1 level
-- E2 move loop start
-- E3 move loop end
-- ALT + E2 rate (hold K1 for alt)
-- ALT + E3 fade time (hold K1 for alt)

Tab = require('tabutil')

sc = softcut
level = 1.0
fade_time = 0.01
rate = 1.0

default_loop_length = 15
length = default_loop_length
start = 1

alt_mode = false

rec_msg = ''
recording = false
overdub = false
buffer_is_clear = true

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
  sc.rate(1,rate)
  sc.play(1,0)
  sc.fade_time(1,fade_time)
  sc.rate_slew_time(1,0)
  sc.recpre_slew_time(1,0)

  sc.phase_quant(1,0.01)
  sc.event_phase(update_positions)
  sc.poll_start_phase()
  softcut.event_render(on_render)

  clock.run(redraw_clock)
  screen_dirty = true
end

function update_positions(i,pos)
  position = pos - 1
  -- Check if we're recording and have reached the end of the loop
  if recording and position >= (length - 1) then
    recording = false
    sc.rec(1,0)
    sc.loop_end(1,1 + length)
    update_content(1,1,1 + length,128)
    rec_msg = ''
  end
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
    alt_mode = true
    print('alt_mode')
  elseif n == 1 and z == 0 then
    alt_mode = false
  elseif n == 2 and z == 1 then
    if not recording and not overdub then
      -- Start initial recording if nothing recorded yet
      if buffer_is_clear then
        recording = true
        local current_pos = position
        sc.position(1, current_pos)
        sc.rec(1,1)
        sc.play(1,1)
        rec_msg = 'rec'
        buffer_is_clear = false
      -- Start overdub if we already have something recorded
      else
        overdub = true
        local current_pos = position + 1
        sc.position(1, current_pos)
        sc.rec(1,1)
        rec_msg = 'dub'
      end
    -- Stop either recording or overdubbing
    else
      if recording then
        recording = false
        sc.rec(1,0)
        length = position
        sc.loop_end(1,1 + length)
        update_content(1,1,1 + length,128)
      elseif overdub then
        overdub = false
        sc.rec(1,0)
      end
      rec_msg = ''
    end
  elseif n == 3 and z == 1 then
    -- clear
    start = 1
    length = default_loop_length
    position = 0
    recording = false
    overdub = false
    buffer_is_clear = true
    rec_msg = ''
    sc.buffer_clear_channel(1)
    sc.loop_start(1,start)
    sc.loop_end(1,1 + length)
    sc.position(1,start)
    sc.rec(1,0)
    sc.play(1,0)
    update_content(1,1,length,128)
  end
  screen_dirty = true
end

function enc(n,d)
  if n == 1 then
    level = util.clamp(level+d/100,0,2)
    softcut.level(1,level)
  elseif n == 2 and not alt_mode then
    if not buffer_is_clear then
      start = util.clamp(start+d/10,0.1,length)
      if start > length then
        start = length
      end
      sc.loop_start(1,start)
      sc.loop_end(1,1 + length)
      update_content(1,start,1 + length,128)
    end
  elseif n == 2 and alt_mode then
    rate = util.clamp(rate+d/100,-4,4)
    sc.rate(1,rate)
  elseif n == 3  and not alt_mode then
    if not buffer_is_clear then
      length = util.clamp(length+d/100,0.1,default_loop_length)
      if length < start then
        length = start
      end
      sc.loop_start(1,start)
      sc.loop_end(1,1 + length)
      update_content(1,start,1 + length,128)
    end
  elseif n == 3 and alt_mode then
    fade_time = util.clamp(fade_time+d/100,0,1)
    sc.fade_time(1,fade_time)
  end
  screen_dirty = true
end

function redraw()
  screen.clear()

  if recording or overdub then
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
  screen.move(util.linlin(start - 1,length,10,120,position),18)
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

  -- rate
  if alt_mode then screen.level(15) else screen.level(6) end
  screen.move(10,10)
  screen.text(string.format('%.2f', rate or 0)) -- Avoid nil error

  -- fade time
  if alt_mode then screen.level(15) else screen.level(6) end
  screen.move(120,10)
  screen.text_right(string.format('%.2f', fade_time or 0)) -- Avoid nil error

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

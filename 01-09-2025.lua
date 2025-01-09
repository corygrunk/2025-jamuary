-- Jamuary 2025 - 09
-- sc explore
-- based on study 3
-- 
-- E1 loop level
-- E2 fade time
-- E3 clock time (random cut)

TAB = require('tabutil')

rec_armed = false
recording = false
counter = 0

sc = softcut

fade_time = 0.25
loop_levels = 0.25

positions = {0,0,0,0}
timings = {0.0625,0.125,0.25,0.5,1,2,4}
timings_text = {'1/16','1/8','1/4','1/2','1','2','4'}
sel_timing = 3

function update_positions(i,pos)
  positions[i] = pos - 1
  redraw()
end

function init()
  sc.buffer_clear()

    -- configure softcut
    audio.level_cut(0.6)
    audio.level_adc_cut(1)
    audio.level_eng_cut(1)
    sc.level_input_cut(1, 1, 1.0)
    sc.level_input_cut(2, 1, 1.0)
    sc.rec(1, 0) --[[ 0_0 ]]--
    sc.rec_level(1, 1)
    sc.pre_level(1, 0.6) --[[ 0_0 ]]--

  for i=1,4 do -- create 4 voices and use buffer 1 for contents
    sc.enable(i,1)
    sc.buffer(i,1)
    sc.level(i,loop_levels)
    sc.pan(i,(i-2.5)*0.5)
    sc.rate(i,i*0.25)
    sc.loop(i,1)
    sc.loop_start(i,1)
    sc.loop_end(i,3)
    sc.position(i,1)
    sc.play(i,1)
    sc.fade_time(i,fade_time)
    sc.phase_quant(i,0.125)
  end

  sc.event_phase(update_positions)
  sc.poll_start_phase()

  clock.run(seq_clock)
end

function seq_clock()
  while true do
    clock.sleep(timings[sel_timing])
    counter = counter + 1
    if counter % 8 == 0 and not recording then
      if rec_armed then record('start') end
    elseif counter % 8 == 0 and recording then
      record('stop')
    end
    for i=1,4 do
      sc.position(i,1+math.random(8)*0.25)
    end
  end
end

function record(status) -- status = 'start' or 'stop'
  if status == 'start' then
    rec_armed = false
    recording = true
    sc.rec(1,1)
  elseif status == 'stop' then
    recording = false
    sc.rec(1,0)
  end

end

function key(n,z)
  if n == 2 and z == 1 then
    if rec_armed then
      rec_armed = false
    else
      rec_armed = true
    end
  elseif n == 3 and z ==1 then
    sc.buffer_clear()
  end
end

function enc(n,d)
  if n==1 then
    loop_levels = util.clamp(loop_levels+d/100,0,1)
    for i=1,4 do
      sc.level(i,loop_levels)
    end
  elseif n==2 then
    fade_time = util.clamp(fade_time+d/100,0,1)
    for i=1,4 do
      sc.fade_time(i,fade_time)
    end
  elseif n==3 then
    sel_timing = util.wrap(sel_timing+d,1,TAB.count(timings))
  end
  redraw()
end

function redraw()
  screen.clear()
  screen.move(10,20)
  screen.line_rel(positions[1]*8,0)
  screen.move(40,20)
  screen.line_rel(positions[2]*8,0)
  screen.move(70,20)
  screen.line_rel(positions[3]*8,0)
  screen.move(100,20)
  screen.line_rel(positions[4]*8,0)
  screen.stroke()

  screen.move(10,10)
  screen.level(5)
  if rec_armed then screen.text('armed')
  elseif recording then screen.level(15); screen.text('recording')
  else screen.text('k2 to rec') end
  screen.level(5)
  screen.move(120,10)
  local level_text = loop_levels*100
  screen.text_right(string.format('%.0f',level_text) .. '%')
  screen.level(15)
  screen.move(10,40)
  screen.text('fade time:')
  screen.move(118,40)
  screen.text_right(string.format('%.2f',fade_time))
  screen.move(10,50)
  screen.text('timing:')
  screen.move(118,50)
  screen.text_right(timings_text[sel_timing])
  screen.update()
end




-- UTILITY TO RESTART SCRIPT FROM MAIDEN
function r()
  norns.script.load(norns.state.script)
end

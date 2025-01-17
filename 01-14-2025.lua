-- Jamuary 2025 - 14 - NOT WORKING YET
-- sc explore
--
-- 

TAB = require('tabutil')
s = require('sequins')

sc = softcut

rate = 1
loop_length = 2
rec_pos = 0

positions = {0}

function init()

    sc.buffer_clear()
    -- configure softcut
    audio.level_cut(1.0)
    audio.level_adc_cut(1)
    audio.level_eng_cut(1)
    sc.level_input_cut(1, 1, 1.0)
    sc.level_input_cut(2, 1, 1.0)
    sc.rec(1, 0) --[[ 0_0 ]]--
    sc.rec_level(1, 1)
    sc.pre_level(1, 0.5) --[[ 0_0 ]]--

    sc.enable(1, 1)
    sc.buffer(1, 1)
    sc.level(1, 1)
    sc.pan(1, 0.5)
    sc.rate(1, 0.5)
    sc.loop(1, 1)
    sc.loop_start(1, 1)
    sc.loop_end(1, loop_length)
    sc.position(1, 1)
    sc.play(1, 1)
    sc.fade_time(1, 0.1)
    sc.phase_quant(1, 0.01)

    sc.event_phase(update_positions)
    sc.poll_start_phase()

    clock.run(seq_clock)
end

function update_positions(i,pos)
  positions[i] = pos - 1
  redraw()
end

function seq_clock()
  while true do
    clock.sleep(1/2)

  end
end

function key(n,z)
  if n == 1 and z == 1 then
  
  elseif n == 2 and z == 1 then
    sc.rec(1,1)
    rec_pos = positions[1]
  elseif n == 2 and z == 0 then
    sc.rec(1,0) 
  elseif n == 3 and z ==1 then
    sc.buffer_clear()
    rec_pos = 0
  end
  redraw()
end

function enc(n,d)
  if n==1 then

  elseif n==2 then
    rate = util.clamp(rate+d/100,-2,2)
    sc.rate(1,rate)
    -- fade_time = util.clamp(fade_time+d/10,0,1)
    -- for i=1,4 do
    --   sc.fade_time(i,fade_time)
    -- end
  elseif n==3 then
    -- sel_timing = util.wrap(sel_timing+d,1,TAB.count(timings))
    -- pre_level = util.clamp(pre_level+d/10,0,1)
    -- rate = util.clamp(rate+d/10,-4,4)
    -- sc.rate(1,rate)
  end
  redraw()
end

function redraw()
  screen.clear()

  screen.level(3)
  screen.move(10,25)
  screen.line(120,25)
  screen.stroke()

  scaled_pos = util.linlin(0, loop_length, 10, 120, positions[1])

  rec_marker = util.linlin(0, loop_length, 10, 120, rec_pos)

  if rec_pos > 0 then
    screen.level(3)
    screen.move(rec_marker, 20)
    screen.line(rec_marker, 28)
    screen.stroke()
  end

  screen.level(15)
  screen.move(scaled_pos, 20)
  screen.line(scaled_pos, 28)
  screen.stroke()

  screen.level(5)

  screen.move(10,10)
  screen.text(string.format('%.2f',rate))

  screen.move(105,10)
  screen.text(string.format('%.2f',positions[1]))

  screen.update()
end




-- UTILITY TO RESTART SCRIPT FROM MAIDEN
function r()
  norns.script.load(norns.state.script)
end

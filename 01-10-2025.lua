-- Jamuary 2025 - 10
-- sc explore
--
-- 

TAB = require('tabutil')
s = require('sequins')

sc = softcut
counter = 0

-- file = _path.dust.."/code/softcut-studies/lib/whirl1.aif"
file = _path.code.."/2025-jamuary/lib/120_Pad_JF_Microcosm.aif"
channels, file_length, rate = audio.file_info(file)
file_length = file_length / 100000

rate = 1
fade_time = 0.6
loop_levels = 0.8
pre_level = 1

positions = {0,0,0,0}

tunings = s{1.0,0.94,1.0,0.95}

function init()
  sc.buffer_clear()
  -- Get file info
  
  sc.buffer_read_mono(file,0,1,-1,1,1)

    -- configure softcut
    audio.level_cut(0.6)
    audio.level_adc_cut(1)
    audio.level_eng_cut(1)
    sc.level_input_cut(1, 1, 1.0)
    sc.level_input_cut(2, 1, 1.0)
    sc.rec(1, 0) --[[ 0_0 ]]--
    sc.rec_level(1, 1)
    sc.pre_level(1, pre_level) --[[ 0_0 ]]--

    for i = 1, 4 do
      sc.enable(i, 1)
      sc.buffer(i, 1)
      sc.level(i, loop_levels / i)
      sc.pan(i,(i-2.5)*0.5)
      sc.rate(i,i*0.5)
      sc.loop(i, 1)
      sc.loop_start(i, 1)
      sc.loop_end(i, file_length)
      sc.position(i, 1)
      sc.play(i, 1)
      sc.fade_time(i, fade_time)
      sc.phase_quant(i, 0.01)
    end

    -- some manual tweaks
    sc.rate_slew_time(1,0.3)
    sc.rate_slew_time(2,0.2)
    sc.rate_slew_time(3,0.3)
    sc.level(2,0.6)
    sc.level(3,0.5)
    sc.rate(4,1.25)
    sc.level(4,0.3)

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
    counter = counter + 1
    if counter % 8 == 0 then
      rate = tunings()
      sc.rate(1,rate)
    end
    sc.rate(2,0.5*(math.random(4)-2))
    sc.position(2,1+math.random(4)*0.25)
    sc.position(4,1+math.random(4)*0.3)
  end
end

function key(n,z)
  if n == 2 and z == 1 then
  
  elseif n == 3 and z ==1 then
    sc.position(1,1+math.random(8)*0.25)
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

  for i = 1, 4 do
    screen.level(3)
    screen.move(10,15+(i*10))
    screen.line(120,15+(i*10))
    screen.stroke()

    scaled_pos = util.linlin(0, file_length, 10, 120, positions[i])

    screen.level(15)
    screen.move(scaled_pos, 10+(i*10))
    screen.line(scaled_pos, 10+(i*10)+8)
    screen.stroke()
  end

  screen.level(5)

  screen.move(10,10)
  screen.text(string.format('%.2f',rate))

  -- screen.move(120,10)
  -- screen.text_right(string.format('%.2f',fade_time))

  screen.update()
end




-- UTILITY TO RESTART SCRIPT FROM MAIDEN
function r()
  norns.script.load(norns.state.script)
end

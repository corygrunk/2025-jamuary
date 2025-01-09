-- Jamuary 2025 - 08
--- Softcut noob


sc = softcut

MusicUtil = require 'musicutil'
Tab = require('tabutil')
s = require('sequins')

rec = 0
playing = false

local enc1 = 1.0 -- rate
local enc2 = 0.0 -- lp filer
local enc3 = 0.8 -- pre level

function init()

  -- configure softcut
  audio.level_cut(0.6)
  audio.level_adc_cut(1)
  audio.level_eng_cut(1)
  sc.level(1,1.0)
  sc.level_slew_time(1,0.25)
  sc.level_input_cut(1, 1, 1.0)
  sc.level_input_cut(2, 1, 1.0)
  sc.pan(1, 0.0)
  sc.play(1, 0.7)
  sc.rate(1, 1.0) --[[ 0_0 ]]--
  sc.rate_slew_time(1,1.0)
  sc.loop_start(1, 0)
  sc.loop_end(1, 1) --[[ 0_0 ]]-- TINY TINY TINY
  sc.loop(1, 1)
  sc.fade_time(1, 0.5)
  sc.rec(1, rec) --[[ 0_0 ]]--
  sc.rec_level(1, 1)
  sc.pre_level(1, 0.8) --[[ 0_0 ]]--
  sc.position(1, 0)
  sc.enable(1, 1)
  sc.filter_dry(1, 0);
  sc.filter_lp(1, 2.0);
  sc.filter_bp(1, 1.0);
  sc.filter_hp(1, 1.0);
  sc.filter_fc(1, 300);
  sc.filter_rq(1, 2.0);
  
  clock.run(redraw_clock)
  screen_dirty = true
end


function key(n,z)
  if n == 1 and z == 1 then
    print('Key 1')
  elseif n == 2 and z == 1 then
    rec = 1
    sc.rec(1, rec)
  elseif n == 2 and z == 0 then
    rec = 0
    sc.rec(1, rec)
  elseif n == 3 and z == 1 then
    sc.buffer_clear()
  end
  screen_dirty = true
end


function enc(n,d)
  if n == 1 then
    enc1 = util.clamp(enc1 + d/10,-2,2)
    sc.rate(1,enc1)
    print(enc1)
  elseif n == 2 then
    enc2 = util.clamp(enc2 + d,0,10)
    print(enc2)
  elseif n == 3 then
    enc3 = util.clamp(enc3 + d/10,0,1)
    sc.pre_level(1,enc3)
    print(enc3)
  end
  screen_dirty = true
end


function redraw()
  screen.clear()
  screen.aa(1)
  screen.font_face(1) 
  screen.font_size(8)
  -- screen.pixel(0, 0) ----------- make a pixel at the north-western most terminus
  -- screen.pixel(127, 0) --------- and at the north-eastern
  -- screen.pixel(127, 63) -------- and at the south-eastern
  -- screen.pixel(0, 63) ---------- and at the south-western

  screen.level(6)
  screen.move(60, 30)
  if rec == 1 then
    screen.text_center('recording...')
  else
    screen.text_center('exploring softcut')
  end
  screen.level(15)
  screen.move(0, 55)
  screen.text('rate: ' .. string.format('%.1f',enc1))
  screen.move(64, 55)
  screen.text_center('hmmm: ' .. string.format('%.1f',enc2))
  screen.move(127, 55)
  screen.text_right('fdbk: ' .. string.format('%.1f',enc3))

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

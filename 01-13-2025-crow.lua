-- 01-13-2025
-- mannequines helper

function init()
    input[1].mode('change', 1.0, 0.1, 'rising')
    output[1].action = ar(0.01, 0.1, 2, 'expo')
    output[2].action = lfo(3, 2, 'sine')
    output[3].action = ramp(1,0,10)
    output[4].action = lfo(3, 10, 'sine')
    output[2]()
    output[3]()
    output[4]()
end

input[1].change = function()
    output[1]() -- ar envelope
end

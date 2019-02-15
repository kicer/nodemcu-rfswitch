-- https://github.com/sui77/rc-switch/blob/master/RCSwitch.cpp

local rfswitch = {}

local Protocol = {
  -- pulseLength, syncFactor, zero, one, invertedSignal
  { 350, {  1, 31 }, {  1,  3 }, {  3,  1 }, false }, -- protocol 1
  { 650, {  1, 10 }, {  1,  2 }, {  2,  1 }, false }, -- protocol 2
  { 100, { 30, 71 }, {  4, 11 }, {  9,  6 }, false }, -- protocol 3
  { 380, {  1,  6 }, {  1,  3 }, {  3,  1 }, false }, -- protocol 4
  { 500, {  6, 14 }, {  1,  2 }, {  2,  1 }, false }, -- protocol 5
  { 450, { 23,  1 }, {  1,  2 }, {  2,  1 },  true }, -- protocol 6 (HT6P20B)
  { 150, {  2, 62 }, {  1,  6 }, {  6,  1 }, false }  -- protocol 7 (HS2303-PT, i. e. used in AUKEY Remote)
}

rfswitch.send = function(protocol_id, pulse_length, repeat_count, pin, value, length, callback)
  local pro = Protocol[protocol_id]
  local pulse_length = pro[1]
  local start_level = pro[5] and gpio.LOW or gpio.HIGH
  local delay_times = pro[2]
  for i=1,length do
    if bit.isclear(value, length-i) then
      delay_times[#delay_times+1] = pulse_length*pro[3][1]
      delay_times[#delay_times+1] = pulse_length*pro[3][2]
    else
      delay_times[#delay_times+1] = pulse_length*pro[4][1]
      delay_times[#delay_times+1] = pulse_length*pro[4][2]
    end
  end
  gpio.mode(pin, gpio.OUTPUT)
  gpio.serout(pin, start_level, delay_times, repeat_count, callback or 0)
end

rfswitch.recv = function(pin, callback)
  local pulse1 = 0
  local changeCount,repeatCount = 0,0
  local timings = {0}

  local function pincb(level, pulse2)
    local duration = pulse2 - pulse1
    if duration > 4300 then -- RCSwitch::nSeparationLimit
      if math.abs(duration-timings[1]) < 200 then
        repeatCount = repeatCount + 1
        -- use 2nd as valid data
        if repeatCount == 3 then
          for i=1,#Protocol do
            local value,err = 0,false
            local pro = Protocol[i]
            local delay = timings[1] / math.max(pro[2][1],pro[2][2])
            local delayTolerance = delay * 60 / 100 -- RCSwitch::nReceiveTolerance
            local firstDataTiming = pro[5] and 3 or 2
            for k=firstDataTiming,changeCount-1,2 do
              value = bit.lshift(value, 1)
              if math.abs(timings[k]-delay*pro[3][1]) < delayTolerance and
                math.abs(timings[k+1]-delay*pro[3][2]) < delayTolerance then
              elseif math.abs(timings[k]-delay*pro[4][1]) < delayTolerance and
                math.abs(timings[k+1]-delay*pro[4][2]) < delayTolerance then
                value = bit.set(value, 0)
              else
                err = true
                break
              end
            end
            if not err and changeCount > 8 then
              callback(i, value, math.floor((changeCount-1)/2))
              break
            end
          end
          repeatCount = 0
        end
      end
      changeCount = 0
    end
    if changeCount>67 then -- RCSWITCH_MAX_CHANGES
      changeCount = 0
      repeatCount = 0
    end
    changeCount = changeCount + 1
    timings[changeCount] = duration
    pulse1 = pulse2
    gpio.trig(pin, level == gpio.HIGH  and "down" or "up")
  end

  if callback then
    gpio.mode(pin, gpio.INT)
    gpio.trig(pin, "down", pincb)
  else
    gpio.mode(pin, gpio.INPUT)
    gpio.trig(pin, "none")
  end
end

_G.rfswitch = rfswitch

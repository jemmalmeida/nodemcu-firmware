--------------------------------------------------------------------------------
-- HC-SR04 module via SPI for NODEMCU
-- LICENCE: http://opensource.org/licenses/MIT
-- Arnim Laeuger
--------------------------------------------------------------------------------

local moduleName = ...
local M = {}
_G[moduleName] = M


local trigger_bits = 1
local dummy_bits = 1
-- number of bits in sample buffer
local sample_bits = 512

--
-- Helper functions to convert fractional results to appropriate integers.
--
-- detect float or integer build
local fraction = 1 / 2
--
local function round(x)
    return x+fraction - (x+fraction) % 1
end
--
local function ceil(x)
    return round(x + fraction)
end
--
local function floor(x)
    return round(x - fraction)
end


--
-- Generic initialization function
--
-- sound_speed : speed of sound in metric or imperial units
-- res_1       : resolution multiplier
--               defaults to 10 if omitted
--
local function generic_init(sound_speed, res_1)
    local spiclk_div_1 = round(80000000 / sound_speed) * 2
    local spiclk_div
    -- resolution in mm or 100mil
    local resolution

    if res_1 then
        resolution = res_1
    else
        -- 1cm / 1inch default resolution
        resolution = 10
    end
    spiclk_div = spiclk_div_1 * resolution

    -- trigger phase needs to skip ~10 us, which translates into 800 clocks @ 80 MHz
    trigger_bits = ceil(800 / spiclk_div) + 1
    -- dummy phase needs to skip ~450 us, which translates into 36000 clocks @ 80 MHz
    dummy_bits = floor(36000 / spiclk_div) - 1
    if dummy_bits > 256 then dummy_bits = 256 end
    -- sample buffer needs to cover ~18 ms, which translates to 1440000 clocks @ 80 MHz
    sample_bits = ceil(1440000 / spiclk_div) + 1
    if sample_bits > 512 then sample_bits = 512 end

    -- CPOL_HIGH avoids intermediate low-level on HSPICLK pin
    spi.setup(1, spi.MASTER, spi.CPOL_HIGH, spi.CPHA_LOW, 8, spiclk_div)

    -- revert unused HSPICLK back to GPIO functionality
    gpio.mode(5, gpio.INPUT, gpio.PULLUP)
    -- revert unused /HSPICS back to GPIO functionality
    gpio.mode(8, gpio.INPUT, gpio.PULLUP)
end

-- ****************************************************************************
-- Initialize module with imperial units
--
-- res_100mil : resolution multiplier in 100 mil
--              defaults to 10 (= 1 inch) if omitted
--
function M.init_imperial(res_100mil)
    -- speed of sound in 100mil/s
    local sound_speed = 135118

    generic_init(sound_speed, res_100mil)
end
--
-- ****************************************************************************

-- ****************************************************************************
-- Initialize module with metric units.
--
-- res_1mm : resolution mutiplier in 1 mm
--              defaults to 10 (= 1 cm) if omitted
--
function M.init_metric(res_1mm)
    -- speed of sound in mm/s
    local sound_speed = 343200

    generic_init(sound_speed, res_1mm)
end
--
-- ****************************************************************************


--
-- Generic measurement function
--
local function generic_measure()
    spi.transaction(1, trigger_bits, 0xFFFF, 0, 0, 0, dummy_bits, sample_bits)
end

-- ****************************************************************************
-- Execute one measurement cycle.
--
-- Returns
--   > 0: distance to object in selected imperial or metric resolution
--   = 0: object is outside of detection range
--   < 0: internal timing error
--
function M.measure()
    generic_measure()

    local pos = 0
    local rise

    -- search rising edge
    while pos < sample_bits and
          spi.get_miso(1, pos, 1, 1) == 0 do
        pos = pos + 1
    end

    rise = pos

    -- search falling edge
    while pos < sample_bits and
          spi.get_miso(1, pos, 1, 1) == 1 do
        pos = pos + 1
    end

    if rise == 0 then
        -- report error in case rising edge cannot be detected reliably
        return -1
    elseif pos == sample_bits then
        -- report range overflow in case faling edge is outside of measurement window
        return 0
    else
        return pos - rise
    end
end
--
-- ****************************************************************************

-------------Return Index------------------------------------
return M

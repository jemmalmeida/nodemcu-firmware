# HC-SR04 Module
This module drives a [HC-SR04 sonar](http://www.micropik.com/PDF/HCSR04.pdf), an ultrasonic ranging device for non-contact measurements.

## Connection
The device is operated via SPI and thus needs to be connected to the HSPI MOSI and MISO pins of the ESP8266. A resistor network is required to shift the 5V level at the `ECHO` pin down to ~3V3 for the ESP.
```
                                 5V0
                                  |
                                  \--- VCC

PIN7/GPIO13 -------------------------- TRIG

PIN6/GPIO12 --------+---[ 1k2 ]------- ECHO
                    |
                   ---            /--- GND
                   2k2            |
                   ---           GND
                    |
                   GND
```

## Example
```lua
sonar = require("hc-sr04")

sonar.init_metric(10)
print(sonar.measure())
7    -- 7 cm distance to object

sonar.init_metric(1)
print(sonar.measure()
76   -- 76 mm distance to object
```

## Functions

### init_imperial()
Initialize the module for imperial units.
The maximum detection range is ~118 inch for resolution 10 and ~11.8 inch for resolution 1.

#### Syntax
`init_imperial(res)`

#### Parameters
`res` resolution multiplier. `1` for 100mil ... `10` for 1 inch (default if omitted)

#### Returns
`nil`

### init_metric()
Initialize the module for metric units.
The maximum detection range is ~300 cm for resolution 10 and ~30 cm for resolution 1.

#### Syntax
`init_metric(res)`

#### Parameters
`res` resolution multiplier. `1` for 1 mm ... `10` for 1 cm (default if omitted)

#### Returns
`nil`

### measure()
Perform a single measurement.

#### Syntax
`measure()`

#### Parameters
None

#### Returns
`distance`
* > 0: distance to object in selected imperial or metric resolution
* = 0: object is outside of detection range
* < 0: internal timing error

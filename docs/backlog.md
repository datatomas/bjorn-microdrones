# Open checks for agents and pilot

## Bjorn 2.5-inch

- Pilot reports Receiver throttle span approximately 989–2012. Recheck the full-low value and `status` arming flags on live hardware; the earlier supplied `status` showed `Arming disable flags: THROTTLE CLI MSP`. CLI/MSP are expected during USB configurator connection; determine whether THROTTLE persists with the stick fully low.
- With props removed, determine whether all four motors spin at armed idle and identify which motor numbers stop only when throttle is raised. Verify Setup 3D orientation and Motors-tab motor order/direction before considering PID changes.
- Check whether AUX4 is above 1700 and Flip Over After Crash is active during the intermittent no-throttle/two-motor symptom. If active, move the assigned radio switch off and verify the mode indicator clears; record the AUX value and result.
- Verify ARM and mode switch AUX values in Receiver and Modes with props removed.
- Identify motors, KV, prop model, all-up weight, ESC firmware, and RPM filtering before changing PIDs. Begin with Betaflight defaults and inspect motor temperature after a short flight.
- Verify Rush Tiny Tank exact variant, antenna, 5 V supply, SmartAudio TX pad/UART, and permitted channel selection. Analog video requires the planned camera and compatible analog receiver/goggles; DJI O4 video is separate.
- Confirm whether DJI O4 is installed, its supply and MSP DisplayPort UART. The RP1 is the radio receiver, so CRSF is appropriate.
- Obtain a sanitized current `diff all` after live checks; the first supplied export reported `NO CUSTOM DEFAULTS FOUND` and `NO CONFIG FOUND`.

## Mobula 7

- Confirm physical gyro and firmware image provenance before flashing. See its source README.
- Verify VTX power labels against actual onboard VTX hardware.
- Confirm radio AUX1/AUX3 mapping on the live receiver.

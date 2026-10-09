# Apex 3-inch quad

## Reported hardware

- Apex 3-inch aircraft; the latest Betaflight screenshot identifies target `MAMBAF722_2022A`, STM32F722, and firmware 2026.6.2. An earlier screenshot showed 4.5.1. The precise flight-controller revision is still unverified.
- The latest Motors screenshot shows QUAD X and "Motor direction is reversed" enabled. The owner reports the motor order is now correct and uses CCW props on motors 1/4 and CW props on motors 2/3. Physical motor direction has not been independently verified.
- ExpressLRS receiver is reported on UART4. Its signal protocol should be CRSF.
- The owner reports that VTX control worked with UART1 selected in Betaflight. The requested mapping now assigns SmartAudio to UART5; confirm its control wire is physically connected to TX5 before applying.

These are owner reports and screenshot observations. The owner reports motor order is corrected and has attempted flights, but no successful Apex flight or independent motor-spin verification is documented.

## Proposed configuration

| File | Purpose |
| --- | --- |
| [ports.cli](config/ports.cli) | Clear UART1, enable Serial RX on UART4 (CRSF), and assign SmartAudio VTX control to UART5 |
| [modes.cli](config/modes.cli) | Bjorn-25 switch plan plus AUX4 high Altitude Hold and AUX5 high Flip Over After Crash; requires a compatible firmware build, working altitude data, and hover-throttle setup |
| [motor-direction-props-out.cli](config/motor-direction-props-out.cli) | Set `yaw_motors_reversed = ON`, matching the shown props-out setting; does not change ESC motor direction or order |
| [throttle-response.cli](config/throttle-response.cli) | Proposed rate-profile 0 throttle curve with `thr_mid = 50` and `thr_expo = 20`; not a PID change and not flight-tested |
| [rush-tank-mini-vtx.cli](config/rush-tank-mini-vtx.cli) | Rush Tank Mini SmartAudio 2.1 37-channel table, with 25/200/500/800 power labels; table only, no channel or power selection |

The mode file is a proposed switch plan, not an observed Apex mode map. Check all AUX values and Modes indicators with propellers removed before applying it. AUX4 high selects Altitude Hold and forces Angle mode; AUX5 high selects Flip Over After Crash. Keep crash flip inactive during normal flight and activate it only after a crash when intentionally using turtle mode. Betaflight 2025.12 or later must be built with `ALTITUDE_HOLD`, the altitude source must work, and `hover_throttle` must be calibrated from flight data before relying on Altitude Hold. Do not guess `hover_throttle`: an incorrect value can cause an immediate climb or drop when Altitude Hold engages. This mode holds altitude, not horizontal position; Position Hold additionally needs a reliable GPS fix.

For props-out, the motor direction file records the Betaflight yaw-mixer setting only. ESC motor spin direction and motor order must independently match the Motors-tab diagram. With the reverse setting enabled, the owner reports CW props on motors 2/3 and CCW props on 1/4; verify actual motor spin with props removed. Confirm the target is `MAMBAF722_2022A`. Betaflight's 2025.12 release notes call out checking board alignment after upgrade; confirm the FC arrow points forward and alignment is 0 when that is the board orientation. The SmartAudio wire must run to TX5 for this mapping to work. Confirm the altitude sensor appears and changes consistently in the Sensors tab before using Altitude Hold.

Before applying any CLI file, save a private backup of the current Apex configuration. Apply only after confirming the board target and firmware accept the commands, VTX variant and regional channels, and radio AUX mapping. Do not set VTX power or test motors from this repository. With propellers removed, a person should verify receiver movement, arming switch, mode indicators, failsafe, and video control on the aircraft.

The throttle-response file is a proposed rate-profile adjustment, not a PID tune or measured flight tune. No PID, motor, battery, or broader flight tune is proposed; those require Apex-specific hardware and flight evidence.

## References

- [Betaflight Serial documentation](https://betaflight.com/docs/wiki/guides/current/Serial)
- [Betaflight setup guide](https://betaflight.com/docs/wiki/getting-started/setup-guide)
- [Betaflight SmartAudio documentation](https://betaflight.com/docs/wiki/guides/current/SmartAudio)
- [Betaflight motor direction guidance](https://betaflight.com/docs/wiki/guides/current/Reversed-motor-direction)
- [Betaflight Rush SA 2.1 preset](https://github.com/betaflight/firmware-presets/blob/master/presets/4.3/vtx/rush_sa2.1_vtx_tables.txt)

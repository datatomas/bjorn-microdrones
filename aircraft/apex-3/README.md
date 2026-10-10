# Apex 3-inch quad

## Reported hardware

- Apex 3-inch aircraft; the recorded target is `MAMBAF722_2022A` on an STM32F722. The selected firmware download is Betaflight 2026.6.2 at `Warfare Analytics/firmware/betaflight_2026.6.2_STM32F722_MAMBAF722_2022A_1dba3fa9.hex`. The latest CLI backup found (2026-10-08) reports 4.5.1, so installation of 2026.6.2 is unverified. The precise flight-controller revision is still unverified.
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
| [throttle-response.cli](config/throttle-response.cli) | Proposed rate-profile 0 throttle curve; no pitch-rate or PID changes; not flight-tested |
| [rates-config.cli](config/rates-config.cli) | The only Apex pitch settings file: reduces center sensitivity (`pitch_rc_rate = 5`) and maximum rotation (`pitch_srate = 50`); ACTUAL rates only, apply only if live values exceed the proposed values; not flight-tested |
| [rush-tank-mini-vtx.cli](config/rush-tank-mini-vtx.cli) | Rush Tank Mini SmartAudio 2.1 37-channel table, with 25/200/500/800 power labels; table only, no channel or power selection |

The mode file is a proposed switch plan, not an observed Apex mode map. Check all AUX values and Modes indicators with propellers removed before applying it. AUX4 high selects Altitude Hold and forces Angle mode; AUX5 high selects Flip Over After Crash. Keep crash flip inactive during normal flight and activate it only after a crash when intentionally using turtle mode. Betaflight 2025.12 or later must be built with `ALTITUDE_HOLD`, the altitude source must work, and `hover_throttle` must be calibrated from flight data before relying on Altitude Hold. Do not guess `hover_throttle`: an incorrect value can cause an immediate climb or drop when Altitude Hold engages. This mode holds altitude, not horizontal position; Position Hold additionally needs a reliable GPS fix.

For props-out, the motor direction file records the Betaflight yaw-mixer setting only. ESC motor spin direction and motor order must independently match the Motors-tab diagram. With the reverse setting enabled, the owner reports CW props on motors 2/3 and CCW props on 1/4; verify actual motor spin with props removed. Confirm the target is `MAMBAF722_2022A`. Betaflight's 2025.12 release notes call out checking board alignment after upgrade; confirm the FC arrow points forward and alignment is 0 when that is the board orientation. The SmartAudio wire must run to TX5 for this mapping to work. Confirm the altitude sensor appears and changes consistently in the Sensors tab before using Altitude Hold.

Before applying any CLI file, save a private backup of the current Apex configuration. Apply only after confirming the board target and firmware accept the commands, VTX variant and regional channels, and radio AUX mapping. Do not set VTX power or test motors from this repository. With propellers removed, a person should verify receiver movement, arming switch, mode indicators, failsafe, and video control on the aircraft.

These rate files are proposals, not PID changes or measured flight tunes. In ACTUAL rates, lowering `pitch_rc_rate` reduces pitch sensitivity around stick center, while lowering `pitch_srate` reduces maximum pitch rotation. The proposed values are 5 and 50. Confirm `rates_type = ACTUAL`, the selected profile, and live values before applying; do not apply a setting if its live value is already at or below the proposal. The selected firmware download is identified above, but the last available CLI backup still reports 4.5.1. Keep firmware flashing and physical flight checks human-operated. No PID, motor, battery, or broader flight tune is proposed.

## References

- [Betaflight Serial documentation](https://betaflight.com/docs/wiki/guides/current/Serial)
- [Betaflight setup guide](https://betaflight.com/docs/wiki/getting-started/setup-guide)
- [Betaflight SmartAudio documentation](https://betaflight.com/docs/wiki/guides/current/SmartAudio)
- [Betaflight motor direction guidance](https://betaflight.com/docs/wiki/guides/current/Reversed-motor-direction)
- [Betaflight Rush SA 2.1 preset](https://github.com/betaflight/firmware-presets/blob/master/presets/4.3/vtx/rush_sa2.1_vtx_tables.txt)

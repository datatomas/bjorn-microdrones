# Bjorn 2.5-inch quad

Observed flight controller: `SPEEDYBEEF405MINI`, Betaflight 4.4.2, ICM42688P gyro. RadioMaster RP1 V2 ExpressLRS receiver uses CRSF. Supplied status showed a 3S pack and `THROTTLE CLI MSP` arming disable flags while in the configurator. The throttle issue remains unresolved; do not attempt to bypass it with a lower arming threshold.

The pilot later reported a Receiver-tab throttle span of approximately 989–2012 and that all four motors run individually in the Motors tab, while only two appear to run during radio-throttle testing. It is not yet known whether all four spin at armed idle or which two stop. These observations do not establish a PID fault or a flight tune.

## Intermittent throttle check

With propellers removed, inspect Receiver and Modes while moving every radio switch. In this profile, AUX4 above 1700 activates **Flip Over After Crash**. If that mode is active, normal throttle behavior is replaced by crash-flip stick control; turn its switch off and verify its Modes indicator goes inactive before testing normal arming. AUX1 above 1700 arms; AUX2 selects Angle (middle) or Horizon (high), and AUX3 high activates the beeper. Record the AUX values and active mode indicators when the symptom occurs. This is a candidate explanation, not yet verified on the aircraft.

If crash flip is inactive and throttle still does not respond, check the OSD arming warning after disconnecting the configurator and capture a fresh `status` with the throttle fully low. The earlier `THROTTLE` flag may indicate an arming condition; `CLI` and `MSP` flags are expected while using the configurator. Do not change PID values or bypass arming protections to diagnose this.

## Incremental CLI files

Rates are aircraft-specific. This profile has no proposed rate changes because the throttle and arming behavior still need diagnosis. For read-only rate inspection commands, see the [rates guide](../../README.md#inspecting-and-changing-rates).

| File | Assumptions |
| --- | --- |
| [modes.cli](config/modes.cli) | AUX1 ARM high; AUX2 Acro low / Angle middle / Horizon high; AUX3 beeper high; AUX4 crash flip high |
| [rush-tiny-tank-vtx.cli](config/rush-tiny-tank-vtx.cli) | Rush Tiny Tank SmartAudio 2.1, 37-channel variant; SmartAudio port still needs verification |

No PID CLI is provided. The supplied `diff all` listed no profile overrides, and motor/prop/weight data are missing. Use Betaflight defaults for an initial controlled flight once arming and hardware checks pass.

The Baby Ratel 2 camera does not affect the Tiny Tank VTX table. It was not connected when this profile was recorded. The DJI O4 Air Unit is a separate digital video system; verify power, wiring, receiver/goggles compatibility, and selected video path before flight.

## Evidence

- Supplied `aux`: `aux 0 0 0 1700 2100 0 0`, `aux 1 1 1 1300 1700 0 0`, `aux 2 13 2 1700 2100 0 0`, `aux 3 35 3 1700 2100 0 0`, `aux 4 2 1 1700 2100 0 0`.
- Supplied `status`: RX rate 255, 3S voltage OK, ICM42688P gyro, `Arming disable flags: THROTTLE CLI MSP`.
- [Betaflight modes](https://betaflight.com/docs/wiki/guides/current/Modes), [Betaflight VTX guide](https://betaflight.com/docs/wiki/guides/current/VTX), [Rush Tiny Tank](https://rushfpv.net/products/tank-tiny-vtx), [Betaflight Rush preset](https://github.com/betaflight/firmware-presets/blob/master/presets/4.3/vtx/rush_sa2.1_vtx_tables.txt).

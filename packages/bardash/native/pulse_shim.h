/**
 * pulse_shim.h — Stable C API for bardash PulseAudio / PipeWire-Pulse volume.
 *
 * Implementation in pulse_shim.c (libpulse). Dart bindings are generated with
 * ffigen from this header (see native/ffigen_pulse.yaml).
 */
#ifndef BARDASH_PULSE_SHIM_H_
#define BARDASH_PULSE_SHIM_H_

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Start the threaded PulseAudio mainloop and connect.
 * Returns 0 on success, -1 on failure.
 */
int pulse_shim_start(void);

/** Disconnect and free the mainloop. Safe to call if not started. */
void pulse_shim_stop(void);

/**
 * Read cached default sink/source state.
 * Returns 1 if the context is ready, 0 otherwise.
 * Out-params may be NULL.
 */
int pulse_shim_get(int *sink_pct, int *sink_muted, int *source_pct,
                   int *source_muted);

/**
 * 1 if volume/mute/server state changed since the last call (clears the flag).
 */
int pulse_shim_take_dirty(void);

/** Request an async refresh of server/sink/source info. */
void pulse_shim_refresh(void);

/**
 * Change default sink volume by delta percent points (e.g. +5 or -5).
 * Returns 0 on success, -1 on failure.
 */
int pulse_shim_sink_volume_step(int delta_pct);

/**
 * Toggle mute on the default sink.
 * Returns 0 on success, -1 on failure.
 */
int pulse_shim_toggle_mute(void);

#ifdef __cplusplus
}
#endif

#endif /* BARDASH_PULSE_SHIM_H_ */

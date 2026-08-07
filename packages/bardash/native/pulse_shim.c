/**
 * pulse_shim.c — libpulse helpers for bardash volume (matches pactl %).
 *
 * Public API: pulse_shim.h (ffigen entry point).
 * PipeWire-Pulse exposes the same API. Volume percent is
 *   round(100 * pa_cvolume_avg / PA_VOLUME_NORM)
 * which matches `pactl get-sink-volume` (NOT cbrt of wpctl linear).
 *
 * Prefer native assets (`hook/build.dart`). Manual:
 *   gcc -shared -fPIC -o libpulse_shim.so pulse_shim.c $(pkg-config --cflags --libs libpulse)
 */
#include "pulse_shim.h"

#include <pulse/pulseaudio.h>
#include <pulse/thread-mainloop.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

typedef struct {
  pa_threaded_mainloop *ml;
  pa_context *ctx;
  int ready; /* 0=init, 1=ready, -1=failed */

  /* Cached default sink/source state */
  char default_sink[256];
  char default_source[256];
  int sink_pct;
  int sink_muted;
  int source_pct;
  int source_muted;
  uint32_t sink_index;
  uint32_t source_index;
  int dirty; /* set on subscribe / info callbacks */
} pulse_state;

static pulse_state g;

void pulse_shim_stop(void);

static int vol_to_pct(const pa_cvolume *v) {
  if (!v || v->channels == 0) return 0;
  uint32_t avg = pa_cvolume_avg(v);
  /* Match pactl: integer percent of PA_VOLUME_NORM */
  int pct = (int)lround((100.0 * (double)avg) / (double)PA_VOLUME_NORM);
  if (pct < 0) pct = 0;
  if (pct > 150) pct = 150; /* allow soft boost up to ~150% */
  return pct;
}

static void on_sink_info(pa_context *c, const pa_sink_info *i, int eol, void *userdata) {
  (void)c;
  (void)userdata;
  if (eol || !i) return;
  if (g.default_sink[0] && strcmp(i->name, g.default_sink) != 0) return;
  g.sink_index = i->index;
  g.sink_pct = vol_to_pct(&i->volume);
  g.sink_muted = i->mute ? 1 : 0;
  g.dirty = 1;
}

static void on_source_info(pa_context *c, const pa_source_info *i, int eol, void *userdata) {
  (void)c;
  (void)userdata;
  if (eol || !i) return;
  if (g.default_source[0] && strcmp(i->name, g.default_source) != 0) return;
  /* Skip monitors */
  if (i->monitor_of_sink != PA_INVALID_INDEX) return;
  g.source_index = i->index;
  g.source_pct = vol_to_pct(&i->volume);
  g.source_muted = i->mute ? 1 : 0;
  g.dirty = 1;
}

static void on_server_info(pa_context *c, const pa_server_info *i, void *userdata) {
  (void)userdata;
  if (!i) return;
  if (i->default_sink_name) {
    strncpy(g.default_sink, i->default_sink_name, sizeof(g.default_sink) - 1);
  }
  if (i->default_source_name) {
    strncpy(g.default_source, i->default_source_name, sizeof(g.default_source) - 1);
  }
  pa_operation *op;
  if (g.default_sink[0]) {
    op = pa_context_get_sink_info_by_name(c, g.default_sink, on_sink_info, NULL);
    if (op) pa_operation_unref(op);
  }
  if (g.default_source[0]) {
    op = pa_context_get_source_info_by_name(c, g.default_source, on_source_info, NULL);
    if (op) pa_operation_unref(op);
  }
}

static void refresh_all(pa_context *c) {
  pa_operation *op = pa_context_get_server_info(c, on_server_info, NULL);
  if (op) pa_operation_unref(op);
}

static void on_subscribe(pa_context *c, pa_subscription_event_type_t t, uint32_t idx, void *userdata) {
  (void)idx;
  (void)userdata;
  pa_subscription_event_type_t facility = t & PA_SUBSCRIPTION_EVENT_FACILITY_MASK;
  if (facility == PA_SUBSCRIPTION_EVENT_SINK ||
      facility == PA_SUBSCRIPTION_EVENT_SOURCE ||
      facility == PA_SUBSCRIPTION_EVENT_SERVER) {
    refresh_all(c);
  }
}

static void on_state(pa_context *c, void *userdata) {
  (void)userdata;
  switch (pa_context_get_state(c)) {
    case PA_CONTEXT_READY:
      g.ready = 1;
      pa_context_set_subscribe_callback(c, on_subscribe, NULL);
      pa_operation *op = pa_context_subscribe(
          c,
          (pa_subscription_mask_t)(PA_SUBSCRIPTION_MASK_SINK |
                                   PA_SUBSCRIPTION_MASK_SOURCE |
                                   PA_SUBSCRIPTION_MASK_SERVER),
          NULL, NULL);
      if (op) pa_operation_unref(op);
      refresh_all(c);
      pa_threaded_mainloop_signal(g.ml, 0);
      break;
    case PA_CONTEXT_FAILED:
    case PA_CONTEXT_TERMINATED:
      g.ready = -1;
      pa_threaded_mainloop_signal(g.ml, 0);
      break;
    default:
      break;
  }
}

/** Start threaded mainloop + context. 0 = ok, -1 = error. */
int pulse_shim_start(void) {
  if (g.ml) return g.ready == 1 ? 0 : -1;

  memset(&g, 0, sizeof(g));
  g.ml = pa_threaded_mainloop_new();
  if (!g.ml) return -1;

  pa_mainloop_api *api = pa_threaded_mainloop_get_api(g.ml);
  g.ctx = pa_context_new(api, "bardash");
  if (!g.ctx) {
    pa_threaded_mainloop_free(g.ml);
    g.ml = NULL;
    return -1;
  }

  pa_context_set_state_callback(g.ctx, on_state, NULL);
  if (pa_threaded_mainloop_start(g.ml) < 0) {
    pa_context_unref(g.ctx);
    pa_threaded_mainloop_free(g.ml);
    g.ctx = NULL;
    g.ml = NULL;
    return -1;
  }

  pa_threaded_mainloop_lock(g.ml);
  if (pa_context_connect(g.ctx, NULL, PA_CONTEXT_NOFLAGS, NULL) < 0) {
    pa_threaded_mainloop_unlock(g.ml);
    pulse_shim_stop();
    return -1;
  }
  while (g.ready == 0) {
    pa_threaded_mainloop_wait(g.ml);
  }
  int ok = g.ready == 1 ? 0 : -1;
  pa_threaded_mainloop_unlock(g.ml);
  return ok;
}

void pulse_shim_stop(void) {
  if (!g.ml) return;
  pa_threaded_mainloop_lock(g.ml);
  if (g.ctx) {
    pa_context_disconnect(g.ctx);
    pa_context_unref(g.ctx);
    g.ctx = NULL;
  }
  pa_threaded_mainloop_unlock(g.ml);
  pa_threaded_mainloop_stop(g.ml);
  pa_threaded_mainloop_free(g.ml);
  memset(&g, 0, sizeof(g));
}

/** Snapshot current cached state. Returns 1 if ready. */
int pulse_shim_get(int *sink_pct, int *sink_muted, int *source_pct, int *source_muted) {
  if (!g.ml || g.ready != 1) return 0;
  pa_threaded_mainloop_lock(g.ml);
  if (sink_pct) *sink_pct = g.sink_pct;
  if (sink_muted) *sink_muted = g.sink_muted;
  if (source_pct) *source_pct = g.source_pct;
  if (source_muted) *source_muted = g.source_muted;
  pa_threaded_mainloop_unlock(g.ml);
  return 1;
}

/** 1 if subscribe/info updated state since last call (clears flag). */
int pulse_shim_take_dirty(void) {
  if (!g.ml) return 0;
  pa_threaded_mainloop_lock(g.ml);
  int d = g.dirty;
  g.dirty = 0;
  pa_threaded_mainloop_unlock(g.ml);
  return d;
}

/** Force a refresh from the server (async; results via dirty flag). */
void pulse_shim_refresh(void) {
  if (!g.ml || g.ready != 1 || !g.ctx) return;
  pa_threaded_mainloop_lock(g.ml);
  refresh_all(g.ctx);
  pa_threaded_mainloop_unlock(g.ml);
}

static void on_success(pa_context *c, int success, void *userdata) {
  (void)c;
  (void)success;
  (void)userdata;
  if (g.ml) pa_threaded_mainloop_signal(g.ml, 0);
}

/** Adjust default sink volume by delta percent points (±5 etc). */
int pulse_shim_sink_volume_step(int delta_pct) {
  if (!g.ml || g.ready != 1 || !g.ctx || !g.default_sink[0]) return -1;

  pa_threaded_mainloop_lock(g.ml);

  /* Read current volume via a one-shot get — use cached avg. */
  int cur = g.sink_pct;
  int next = cur + delta_pct;
  if (next < 0) next = 0;
  if (next > 150) next = 150;

  pa_cvolume vol;
  pa_cvolume_init(&vol);
  /* Use 2 channels stereo; set_volume overwrites all channels. */
  pa_cvolume_set(&vol, 2, (pa_volume_t)lround((next / 100.0) * PA_VOLUME_NORM));

  pa_operation *op =
      pa_context_set_sink_volume_by_name(g.ctx, g.default_sink, &vol, on_success, NULL);
  if (op) {
    while (pa_operation_get_state(op) == PA_OPERATION_RUNNING) {
      pa_threaded_mainloop_wait(g.ml);
    }
    pa_operation_unref(op);
  }
  /* Unmute when changing volume (desktop convention). */
  if (g.sink_muted) {
    op = pa_context_set_sink_mute_by_name(g.ctx, g.default_sink, 0, on_success, NULL);
    if (op) {
      while (pa_operation_get_state(op) == PA_OPERATION_RUNNING) {
        pa_threaded_mainloop_wait(g.ml);
      }
      pa_operation_unref(op);
    }
  }
  g.sink_pct = next;
  g.sink_muted = 0;
  g.dirty = 1;
  pa_threaded_mainloop_unlock(g.ml);
  return 0;
}

int pulse_shim_toggle_mute(void) {
  if (!g.ml || g.ready != 1 || !g.ctx || !g.default_sink[0]) return -1;
  pa_threaded_mainloop_lock(g.ml);
  int new_mute = g.sink_muted ? 0 : 1;
  pa_operation *op =
      pa_context_set_sink_mute_by_name(g.ctx, g.default_sink, new_mute, on_success, NULL);
  if (op) {
    while (pa_operation_get_state(op) == PA_OPERATION_RUNNING) {
      pa_threaded_mainloop_wait(g.ml);
    }
    pa_operation_unref(op);
  }
  g.sink_muted = new_mute;
  g.dirty = 1;
  pa_threaded_mainloop_unlock(g.ml);
  return 0;
}

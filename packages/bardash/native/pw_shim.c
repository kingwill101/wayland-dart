/**
 * pw_shim.c — Thin C wrappers for PipeWire `static inline` functions.
 */
#include <pipewire/pipewire.h>
#include <pipewire/core.h>
#include <pipewire/loop.h>

struct pw_registry *pw_shim_core_get_registry(struct pw_core *core) {
    return pw_core_get_registry(core, PW_VERSION_REGISTRY, 0);
}

int pw_shim_registry_add_listener(struct pw_registry *reg,
                                   struct spa_hook *listener,
                                   const struct pw_registry_events *events,
                                   void *data) {
    return pw_registry_add_listener(reg, listener, events, data);
}

int pw_shim_loop_iterate(struct pw_loop *loop, int timeout) {
    return pw_loop_iterate(loop, timeout);
}

const char *pw_shim_dict_lookup(const struct spa_dict *dict, const char *key) {
    return spa_dict_lookup(dict, key);
}

void pw_shim_hook_remove(struct spa_hook *hook) {
    spa_hook_remove(hook);
}

/**
 * icon_shim.h — GTK icon theme + librsvg helpers for bardash
 *
 * Native shim replacing manual Dart index.theme parsing + rsvg-convert subprocess.
 * Uses GtkIconTheme (Papirus-Dark → Inherits handling identical to swaybar/gtk)
 * and librsvg + cairo for SVG → PNG raster.
 *
 * API is minimal and ffigen-friendly (no GObject varargs).
 */

#ifndef ICON_SHIM_H_
#define ICON_SHIM_H_

#ifdef __cplusplus
extern "C" {
#endif

/* Returns heap-allocated string (g_strdup) with absolute icon path or NULL.
 * Caller must free with g_free / icon_shim_free_string.
 * - icon_name: e.g. "blueman-tray"
 * - size: preferred pixel size (24, 32 …) — 0 = any
 * - theme_name: optional GTK theme (e.g. "Papirus-Dark"), NULL = default
 */
char *icon_shim_lookup(const char *icon_name, int size, const char *theme_name);

/* Raster SVG at svg_path to png_path at w×h. Returns 0 on success, -1 on error.
 * Requires librsvg + Cairo. Handles any SVG (including Papirus panel icons).
 */
int icon_shim_raster_svg(const char *svg_path, const char *png_path, int w, int h);

/* Free string returned by icon_shim_lookup */
void icon_shim_free_string(char *str);

/* Version for diagnostics */
const char *icon_shim_version(void);

#ifdef __cplusplus
}
#endif

#endif // ICON_SHIM_H_

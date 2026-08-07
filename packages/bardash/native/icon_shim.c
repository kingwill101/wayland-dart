/**
 * icon_shim.c — GTK + librsvg implementation for bardash
 * Replaces manual _parseIndexTheme / _findIconInDirs / rsvg-convert.
 */

#include "icon_shim.h"

#include <cairo/cairo.h>
#include <gdk-pixbuf/gdk-pixbuf.h>
#include <gtk/gtk.h>
#include <librsvg/rsvg.h>

#include <stdlib.h>
#include <string.h>

const char *icon_shim_version(void) { return "bardash-icon-shim 1"; }

void icon_shim_free_string(char *str) {
  if (str) g_free(str);
}

char *icon_shim_lookup(const char *icon_name, int size, const char *theme_name) {
  if (!icon_name || !*icon_name) return NULL;

  if (!gtk_init_check(NULL, NULL)) {
    // Headless / no display — still try icon theme via GtkSettings default
  }

  GtkIconTheme *theme = gtk_icon_theme_get_default();
  if (!theme) theme = gtk_icon_theme_new();

  if (theme_name && *theme_name) {
    // Force theme like swaybar does via gsettings; fallback keeps Inherit chain
    gtk_icon_theme_set_custom_theme(theme, theme_name);
  }

  // GTK handles Inherits, Directories, @2x automatically
  GtkIconInfo *info = gtk_icon_theme_lookup_icon(
      theme, icon_name, size > 0 ? size : 48, 0);
  if (!info) {
    // Try stripping -symbolic / -tray variants manually (sway fallback)
    // Already handled by Dart _iconNameVariants, but keep one fallback
    char *alt = g_strdup(icon_name);
    const char *sufs[] = {"-symbolic", "-tray", NULL};
    for (int i = 0; sufs[i]; i++) {
      size_t n = strlen(sufs[i]);
      size_t al = strlen(alt);
      if (al > n && strcmp(alt + al - n, sufs[i]) == 0) {
        alt[al - n] = '\0';
        GtkIconInfo *alt_info = gtk_icon_theme_lookup_icon(theme, alt, size > 0 ? size : 48, 0);
        if (alt_info) {
          g_free(alt);
          info = alt_info;
          break;
        }
      }
    }
    if (!info) {
      g_free(alt);
      return NULL;
    }
    g_free(alt);
  }

  const char *path = gtk_icon_info_get_filename(info);
  char *ret = path ? g_strdup(path) : NULL;
  g_object_unref(info);
  return ret;
}

int icon_shim_raster_svg(const char *svg_path, const char *png_path, int w, int h) {
  if (!svg_path || !png_path || w <= 0 || h <= 0) return -1;

  GError *err = NULL;
  RsvgHandle *handle = rsvg_handle_new_from_file(svg_path, &err);
  if (!handle) {
    if (err) g_error_free(err);
    return -1;
  }

  cairo_surface_t *surf = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, w, h);
  cairo_t *cr = cairo_create(surf);

  // Clear transparent
  cairo_set_source_rgba(cr, 0, 0, 0, 0);
  cairo_paint(cr);

  // Scale SVG to target w×h preserving aspect (rsvg 2.58 viewport)
  RsvgRectangle viewport = {0, 0, (double)w, (double)h};
  if (!rsvg_handle_render_document(handle, cr, &viewport, &err)) {
    cairo_destroy(cr);
    cairo_surface_destroy(surf);
    g_object_unref(handle);
    if (err) g_error_free(err);
    return -1;
  }

  cairo_destroy(cr);
  // Write PNG via cairo (no gdk-pixbuf needed for RGBA)
  cairo_status_t st = cairo_surface_write_to_png(surf, png_path);
  cairo_surface_destroy(surf);
  g_object_unref(handle);
  if (err) g_error_free(err);
  return (st == CAIRO_STATUS_SUCCESS) ? 0 : -1;
}

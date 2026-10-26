{{flutter_js}}
{{flutter_build_config}}

// Custom bootstrap:
//
// * `serviceWorkerSettings: null` stops Flutter from registering its deprecated
//   worker, which only unregisters older registrations and would race with
//   `web/sw.js` (one registration per scope). Offline caching is handled there.
// CanvasKit and the web fonts are served from this origin because the build
// uses --no-web-resources-cdn (see README); anything fetched from a CDN cannot
// be cached by web/sw.js and would break offline rendering.
_flutter.loader.load({
  serviceWorkerSettings: null,
});

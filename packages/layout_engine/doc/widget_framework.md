# Widget framework

Optional Element/State layer for configuration and rebuilds — independent of
render objects.

- `ElementWidget` — base configuration object  
- `StatelessWidget` / `StatefulWidget` / `State` — build + local state  
- `InheritedWidget` — ambient data  
- `ElementTree` / `BuildOwner` — mount, dirty tracking, rebuild  

Host toolkits map `State.build` output into paintables and schedule frames via
`BuildOwner.onNeedsBuild`.

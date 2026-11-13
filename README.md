# AnyProgress

Three configurable Apple Health progress rings for iPhone, Apple Watch, and widgets, with 11 shapes and 18 named color palettes. The app preserves metric selection, goals, reversed progress, aggregation, tracking periods, gradients, glows, and color palettes.

The app called AnyRing, but Apple Review folks said after a while it's no longer allowed.

## Appearance and progress

Choose a shape under **Visualization → Shape**. Rounded squares are the default; circles, squircles, capsules, triangles, diamonds, pentagons, hexagons, stars, hearts, and sharp squares are also available. The chosen shape persists and syncs to the Watch and widgets. The **Color Palettes** section previews each palette in the selected shape.

Rings sweep in on appearance and animate health-value changes from their current displayed value. A display timeline redraws the stroke, gradient, and shaded tip together, then stops when the animation finishes. Gradients follow contour distance without segment seams; progress beyond 100% keeps a full ring with the tip advancing through another lap. Glow stays around the tube and tip, leaving the center clear. Reduce Motion and widget/palette previews show the final state immediately.

Circular Watch complications and Lock Screen accessories fit the chosen shape inside the system's circular mask, with room for strokes, tips, and glow. Square corners remain visible instead of being cropped by the circle.

Metric cards separate the current value from its goal, show whether higher or lower values advance progress, and label a nonzero starting value. Units use familiar symbols such as `ms`, `bpm`, `kcal`, and `steps`. The header shows the last confirmed sync time, persisted across launches. Replaying an offline cache does not advance that timestamp; live acknowledgements and successful background transfers do.

- [App architecture, Lock Screen widgets, and device checks](docs/APP.md)
- [CI and TestFlight delivery](ci/README.md)

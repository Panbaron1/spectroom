# Pictograms — Mulberry Symbols (CC BY-SA)

Drop Mulberry Symbol SVGs here, named `<name>.svg`. Reference them from a
challenge via `PictogramRef.mulberry('<name>')` — the renderer
(widgets/pictogram_view.dart) loads `assets/pictograms/<name>.svg`.

**License:** Mulberry Symbols are CC BY-SA 4.0 — commercial use allowed with
attribution + share-alike. This is the commercial-safe path (unlike ARASAAC,
which is non-commercial). Keep attribution in the app's About screen before
shipping a paid build.

Source: https://github.com/straight-street/mulberry-symbols

Until SVGs are added, seeds use emoji pictograms (always render). Swapping a
seed to Mulberry = change its `PictogramRef.emoji('x')` → `PictogramRef.mulberry('name')`.

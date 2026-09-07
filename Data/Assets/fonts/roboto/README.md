# Roboto

`Roboto-Regular.ttf`, vendored from Raptor's `Data/Assets/fonts/roboto` so the font tests
have a real typeface to parse and bake.

- **License:** Apache License 2.0
- **Source:** https://fonts.google.com/specimen/Roboto

A real font rather than a synthesised one: the parsing paths under test are the name table,
the glyph tables and the kerning tables, and a hand-built fixture would only exercise the
shapes it was built to have. What it costs is that the tests assert RELATIONS between
metrics rather than exact numbers, since the numbers belong to this typeface.

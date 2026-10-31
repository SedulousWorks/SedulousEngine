using System;

namespace Sedulous.UI.Toolkit;

/// The toolkit's styling fragments, authored as real style sheets and embedded as strings.
///
/// TWO sheets rather than one with variables, because dark and light chrome derive in
/// DIFFERENT directions per control: a dark bar recedes by darkening the surface and separates
/// by lightening it, and the light branch runs the other way. No variable swap expresses that.
///
/// The same embedding rationale as the core's [[EmbeddedThemes]]: theming the editor before a
/// project is open cannot depend on cooked assets, and loose files on disk repeat a staging
/// problem. Read at COMPILE time, so the `.sss` files beside this one are the single source and
/// editing one rebuilds.
static class EmbeddedToolkitThemes
{
	public const String Dark = Compiler.ReadText("src/Themes/toolkit-dark.sss");
	public const String Light = Compiler.ReadText("src/Themes/toolkit-light.sss");
}

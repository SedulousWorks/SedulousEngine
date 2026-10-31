using System;

namespace Sedulous.UI;

/// The built in themes, authored as real style sheets and embedded as strings.
///
/// They are authored as `.sss` rather than built in code because a cooked asset is chicken
/// and egg for theming the editor before a project is open, and loose files on disk repeat a
/// staging problem the shader sidecars already taught. The same files double as asset
/// templates.
///
/// Beef reads them at COMPILE time through Compiler.ReadText, so the .sss files beside this
/// one are the single source and editing one rebuilds; no configure-time substitution step.
static class EmbeddedThemes
{
	public const String Dark = Compiler.ReadText("src/Styling/Themes/dark.sss");
	public const String Light = Compiler.ReadText("src/Styling/Themes/light.sss");
	public const String RoundedDark = Compiler.ReadText("src/Styling/Themes/rounded-dark.sss");
}

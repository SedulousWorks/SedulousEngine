using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Core;

/// The editor level FONT preferences, a settings section: explicit .ttf paths for the UI and
/// mono families. Empty, the default, is the built in resolution chain.
[Serializable(1)]
class EditorFontSettings
{
	/// The UI family override; empty is the built in chain.
	public String FontPath = new .() ~ delete _;
	/// The mono family override.
	public String MonoFontPath = new .() ~ delete _;
}

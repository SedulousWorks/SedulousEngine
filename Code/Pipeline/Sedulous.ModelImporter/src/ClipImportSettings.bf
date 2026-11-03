using System;
using Sedulous.Core;

namespace Sedulous.ModelImporter;

/// One clip's own settings in an import (IFileImporter.PartSettings): which of its root's motion
/// moves the character rather than playing in place. Reflected, drawn in the import window's clip
/// details; the import applies them to the clip (ModelImportSkeleton).
[Reflect(.NonStaticFields | .DefaultConstructor)]
class ClipImportSettings : RefCounted
{
	/// The ground-plane translation.
	[DisplayName("Root travel"), Description("The root's travel on the ground moves the character; the clip plays in place")]
	public bool Travel = false;
	/// Height: a climb; off for a walk, which keeps its bob.
	[DisplayName("Root height"), Description("The root's rise and fall moves the character too (a climb; off for a walk, which keeps its bob)")]
	public bool Vertical = false;
	/// The turn about up.
	[DisplayName("Root turn"), Description("The root's turn about up turns the character")]
	public bool Turn = false;
}

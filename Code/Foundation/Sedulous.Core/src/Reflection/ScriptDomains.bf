using System;

namespace Sedulous.Core;

/// The domain names Core knows about, for [[TypeDomainAttribute]].
///
/// CONSTANTS rather than an enum, because the set is open: a layer names its own domain
/// with a string and needs no change here. These exist so the common ones are spelled one
/// way, not to enumerate what is allowed.
static class ScriptDomains
{
	/// What the player runs. The DEFAULT: a type with no domain attribute is this, so a
	/// generator targeting the runtime takes everything unmarked.
	public const String Runtime = "Runtime";

	/// Editor only. Present when the editor is running and absent from a shipped player,
	/// so a runtime script module must leave these out or bind something that will not
	/// exist.
	public const String Editor = "Editor";

	/// Content pipeline only: importers, cookers and what they carry. Present in the tools
	/// and absent from both the player and the editor's runtime surface.
	public const String Pipeline = "Pipeline";
}

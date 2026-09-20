using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Navigation;

/// The navigation domain's per-user editor settings section, in the user store the app owns;
/// the domain owns the shape, the first domain-contributed settings category.
[Serializable(1)]
class NavigationEditorSettings
{
	/// Bakes tiles across workers; the output is byte-identical.
	public bool ParallelBake = true;
}

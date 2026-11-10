using System;

namespace Sedulous.Editor.Project;

/// Why an instance seeds the reachable closure.
enum ExportRootReason
{
	/// ProjectSettings.DefaultSceneId.
	case DefaultScene;
	/// An instance flagged "Always Export".
	case Flag;
	/// An instance under a group flagged "Always export contents".
	case Group;
	/// A manifest default reference: input map, bus layout, UI font, loading screen.
	case ManifestDefault;

	public StringView Name
	{
		get
		{
			switch (this)
			{
			case .DefaultScene: return "default-scene";
			case .Flag: return "always-export";
			case .Group: return "always-export-group";
			case .ManifestDefault: return "manifest-default";
			}
		}
	}
}

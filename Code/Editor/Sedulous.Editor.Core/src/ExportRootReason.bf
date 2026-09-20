using System;

namespace Sedulous.Editor.Core;

/// Why an instance seeds the reachable closure.
enum ExportRootReason
{
	/// ProjectSettings.DefaultSceneId.
	case DefaultScene;
	/// The startup script's own imported asset; the script file ships regardless.
	case StartupScript;
	/// An instance flagged "Always Export".
	case Flag;
	/// An instance under a group flagged "Always export contents".
	case Group;
	/// A manifest default reference: input map, bus layout, UI theme, UI font.
	case ManifestDefault;

	public StringView Name
	{
		get
		{
			switch (this)
			{
			case .DefaultScene: return "default-scene";
			case .StartupScript: return "startup-script";
			case .Flag: return "always-export";
			case .Group: return "always-export-group";
			case .ManifestDefault: return "manifest-default";
			}
		}
	}
}

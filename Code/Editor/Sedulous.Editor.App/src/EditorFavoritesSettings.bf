using System;
using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.App;

/// The pinned asset guids (EditorContext favorites), a per-project section.
[Serializable(1)]
class EditorFavoritesSettings
{
	public List<Guid> Favorites = new .() ~ delete _;
}

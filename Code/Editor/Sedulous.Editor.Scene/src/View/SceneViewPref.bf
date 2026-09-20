using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Scene;

/// One scene's stored view state, keyed by the scene asset's guid.
[Serializable(1)]
class SceneViewPref
{
	public Guid Scene = .();
	public bool ShowGrid = true;
	public bool ShowLodOverlay = false;
	public bool ShowColliders = false;

	public SceneViewState State => .(ShowGrid, ShowLodOverlay, ShowColliders);

	public void Set(Guid scene, SceneViewState state)
	{
		Scene = scene;
		ShowGrid = state.ShowGrid;
		ShowLodOverlay = state.ShowLodOverlay;
		ShowColliders = state.ShowColliders;
	}
}

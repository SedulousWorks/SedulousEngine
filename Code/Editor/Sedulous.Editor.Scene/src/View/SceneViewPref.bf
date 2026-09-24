using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Scene;

/// One scene's stored view state, keyed by the scene asset's guid.
///
/// Version 2 adds the editor CAMERA and the entity SELECTION, so a scene reopens where it was
/// left rather than at the default framing with nothing picked; version 3 adds the entity
/// marker toggle. An older file is read by the gates below and re-saved at the current
/// version.
/// HAND WRITTEN rather than generated: the body has to branch on the stored version, which a
/// field walk cannot.
class SceneViewPref : ISerializable
{
	/// The same identity the generated attribute would have emitted, from the qualified name.
	public static readonly uint64 TypeId =
		Sedulous.Core.Serialization.TypeIdOf("Sedulous.Editor.Scene.SceneViewPref");
	public const uint32 DataVersion = 3;
	/// The oldest layout the reader below still understands.
	public const uint32 MinReadDataVersion = 1;

	public Guid Scene = .();
	public bool ShowGrid = true;
	public bool ShowLodOverlay = false;
	public bool ShowColliders = false;
	public bool ShowMarkers = true;

	/// False until a page has saved one; the camera then keeps its default framing.
	public bool HasCamera = false;
	public SceneViewCamera Camera = .();

	/// The entities selected at close, by PERSISTENT id. One the scene no longer has is
	/// dropped on restore rather than failing the load.
	public List<Guid> Selection = new .() ~ delete _;

	public SceneViewState State => .(ShowGrid, ShowLodOverlay, ShowColliders, ShowMarkers);

	public void Set(Guid scene, SceneViewState state)
	{
		Scene = scene;
		ShowGrid = state.ShowGrid;
		ShowLodOverlay = state.ShowLodOverlay;
		ShowColliders = state.ShowColliders;
		ShowMarkers = state.ShowMarkers;
	}

	public void Serialize(ISerializer ar)
	{
		Sedulous.Core.Serialization.BeginVersionedPayload(ar, TypeId, DataVersion, MinReadDataVersion);
		ar.BeginObject();

		SerializeValue(ar, "scene", ref Scene);
		SerializeValue(ar, "showGrid", ref ShowGrid);
		SerializeValue(ar, "showLodOverlay", ref ShowLodOverlay);
		SerializeValue(ar, "showColliders", ref ShowColliders);

		// The version 2 keys. A keyed reader FAILS a section on a missing key, so a version 1
		// file must never be asked for them.
		if (ar.Version >= 2)
		{
			SerializeValue(ar, "hasCamera", ref HasCamera);
			ar.Key("cameraPosition");
			Sedulous.Core.Serialization.Serialize(ar, ref Camera.Position);
			SerializeValue(ar, "cameraYaw", ref Camera.Yaw);
			SerializeValue(ar, "cameraPitch", ref Camera.Pitch);
			SerializeValue(ar, "cameraFocusDistance", ref Camera.FocusDistance);
			ar.Key("selection");
			SerializeList(ar, Selection);
		}
		if (ar.Version >= 3)
			SerializeValue(ar, "showMarkers", ref ShowMarkers);

		ar.EndObject();
		Sedulous.Core.Serialization.EndVersionedPayload(ar);
	}
}

using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.PropertyAnimation;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.PropertyAnimation.Tests;

/// A panel over a scene, a fresh stack and a selection, all owned here; the panel borrows.
/// Preview, keying and seeding target the bound entity, so the pre-set selection is bound,
/// the fixture equivalent of clicking "Use Selected".
class PanelFixture
{
	public Scene Scene ~ delete _;
	public Selection<Guid> Selection = new .() ~ delete _;
	public EditorContext EditorCtx = new .() ~ delete _;
	public EditorCommandStack Stack = new .() ~ delete _;
	public PropertyAnimationPanel Panel = null ~ _?.ReleaseRef();

	public this(StringView sceneName)
	{
		Scene = new Scene(sceneName);
	}

	public void Build()
	{
		Panel = new PropertyAnimationPanel(EditorCtx, Scene, Stack, Selection);
		Panel.BindSelectedEntity();
	}

	public static CurveKey Kv(float t, float v)
	{
		var k = CurveKey();
		k.Time = t;
		k.Value = v;
		return k;
	}

	/// A constant Float3 track, a single key per channel, at the path on the component.
	public static PropertyTrack MakeFloat3TrackOn(StringView comp, StringView path, float x, float y, float z)
	{
		let track = new PropertyTrack();
		track.ComponentType.Set(comp);
		track.PropertyPath.Set(path);
		track.Kind = .Float3;
		track.Channels[0].AddKey(Kv(0.0f, x));
		track.Channels[1].AddKey(Kv(0.0f, y));
		track.Channels[2].AddKey(Kv(0.0f, z));
		return track;
	}

	public static PropertyTrack MakePositionTrackOn(StringView comp, float x, float y, float z) => MakeFloat3TrackOn(comp, "Position", x, y, z);
	public static PropertyTrack MakePositionTrack(float x, float y, float z) => MakePositionTrackOn("PreviewComp", x, y, z);

	/// A Float3 position track on PreviewComp whose X ramps 0 to x1 over [0,1]: two keys, so
	/// the duration is 1 and the playhead position is observable.
	public static PropertyTrack MakeRampTrack(float x1)
	{
		let track = new PropertyTrack();
		track.ComponentType.Set("PreviewComp");
		track.PropertyPath.Set("Position");
		track.Kind = .Float3;
		track.Channels[0].AddKey(Kv(0.0f, 0.0f));
		track.Channels[0].AddKey(Kv(1.0f, x1));
		track.Channels[1].AddKey(Kv(0.0f, 0.0f));
		track.Channels[2].AddKey(Kv(0.0f, 0.0f));
		return track;
	}
}

/// A panel over a scene with one PreviewComp entity selected and a ramp track loaded.
class RampFixture : PanelFixture
{
	public ComponentManager<PreviewComp> Manager;
	public EntityHandle Entity;

	public this() : base("xport")
	{
		Manager = Scene.AddSystem<ComponentManager<PreviewComp>>();
		Entity = Scene.CreateEntity("e0");
		Manager.Add(Entity).Position = .(0.0f, 0.0f, 0.0f);
		Selection.Set(Scene.GetEntityId(Entity));
		Build();
		Panel.Clip.Tracks.Add(MakeRampTrack(10.0f)); // duration 1
	}

	public float X => Manager.Get(Entity).Position.X;
}

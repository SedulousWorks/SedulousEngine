using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Gameplay;

namespace PaperKid;

/// On the block's top-down camera, which draws the Minimap texture the HUD shows. Places the HUD's
/// markers over that image from world positions: a dot per subscriber (dimmed once it has its
/// paper) and the bike, turned to its heading. The camera is orthographic and looks straight
/// down, so world to map is a scale and an offset: map right is +X, map up is -Z.
[Behaviour("paperkid.map_markers")]
[DisplayName("Map Markers"), Category("PaperKid")]
[Description("Places the HUD's minimap markers: a dot per subscriber, dimmed once served, and the bike's arrow.")]
class MapMarkers : Behaviour
{
	/// The HUD has this many subscriber dots (map-sub-0 ...).
	private const int cDots = 8;

	[Description("The bike")]
	public EntityRef Bike = .();
	[Description("World metres the map spans (the camera's orthoHeight)")]
	public float Span = 84.0f;
	[Description("The map view's size in pixels")]
	public float MapSize = 200.0f;
	[Description("The delivery zones' collision group")]
	public int32 ZoneGroup = 2;

	/// The entity Bike names in this scene, found as it starts.
	private EntityHandle mBike = .Invalid;
	private List<EntityHandle> mZones = new .() ~ delete _;
	/// Each dot's state shown: 1 waiting, 0 delivered, -1 not yet shown.
	private List<int32> mWaiting = new .() ~ delete _;
	private bool mFound = false;

	protected override void OnStart()
	{
		mBike = Scene.FindEntity(Bike.Id);
	}

	protected override void OnUpdate(float dt)
	{
		// The zones are static triggers, there once physics has built them, so look on the first
		// update that finds them.
		if (!mFound)
			FindZones();
		for (int i < mZones.Count)
		{
			let dot = Hud.Find(Run, scope $"map-sub-{i}");
			if (dot == null)
				continue;
			let marker = Scene.FindChildByName(mZones[i], "Marker");
			int32 waiting = (Scene.IsValid(marker) && Scene.IsActive(marker)) ? 1 : 0;
			if (waiting != mWaiting[i]) // the sheet's 0 until placed, then full or dimmed
			{
				mWaiting[i] = waiting;
				Hud.Snap(dot, "opacity", (waiting == 1) ? "1" : "0.3");
			}
		}
		if (!Scene.IsValid(mBike))
			return;
		let arrow = Hud.Find(Run, "map-bike");
		if (arrow == null)
			return;
		// The bike faces its local +Z; on the map that points (x, z) with z down the screen, and a
		// view turns clockwise from up. Set every frame (a tween of no length replaces the last).
		let bike = Scene.GetLocalTransform(mBike);
		let f = RotateVector(bike.Rotation, .(0.0f, 0.0f, 1.0f));
		let transform = At(bike.Position, 10.0f, 16.0f, .. scope .());
		transform.AppendF(" rotate({}deg)", RadiansToDegrees(Atan2(f.X, -f.Z)));
		Hud.Snap(arrow, "transform", transform);
		Hud.Snap(arrow, "opacity", "1");
	}

	private void FindZones()
	{
		let physics = Scene.GetSystem<PhysicsSceneSystem>();
		if (physics == null)
			return;
		let c = Scene.GetLocalTransform(Entity).Position;
		let zones = scope List<EntityHandle>();
		physics.OverlapSphere(.(c.X, 0.0f, c.Z), Span, zones, (uint32)1 << (int)ZoneGroup);
		if (zones.IsEmpty)
			return;
		mFound = true;
		for (int i = 0; (i < zones.Count) && (i < cDots); i++)
		{
			mZones.Add(zones[i]);
			mWaiting.Add(-1);
			if (let dot = Hud.Find(Run, scope $"map-sub-{i}"))
				Hud.Snap(dot, "transform", At(Scene.GetWorldPosition(zones[i]), 12.0f, 12.0f, .. scope .()));
		}
	}

	/// The move that centres a marker of the given pixel size on a world position, from the map's
	/// corner (a CSS transform), into `outText`.
	private void At(Float3 world, float width, float height, String outText)
	{
		let c = Scene.GetLocalTransform(Entity).Position;
		let u = ((world.X - c.X) / Span + 0.5f) * MapSize;
		let v = ((world.Z - c.Z) / Span + 0.5f) * MapSize;
		outText.AppendF("translate({}px, {}px)", u - width * 0.5f, v - height * 0.5f);
	}
}

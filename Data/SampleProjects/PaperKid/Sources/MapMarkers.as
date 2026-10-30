// MapMarkers - on the block's top-down camera, which draws the Minimap texture the HUD shows. Places
// the HUD's markers over that image from world positions: a dot per subscriber (dimmed once it has
// its paper) and the bike, turned to its heading. The camera is orthographic and looks straight
// down, so world to map is a scale and an offset: map right is +X, map up is -Z.

// The HUD has this many subscriber dots (map-sub-0 ...).
const uint kDots = 8;

// A HUD element: the top screen's first, then any (a HUD just replaced is still in the tree while it
// leaves, with the same ids, and would be found first). Named for this script: the behaviours
// compile into one module, beside Level.as's hud().
Node@ markersHud(string id)
{
	ScreenStack@ stack = ScreenStack::Of(Gui.Root().Find("screens"));
	Screen@ top = stack !is null ? stack.Top : null;
	Node@ n = top !is null ? top.Find(id) : null;
	return n !is null ? n : Gui.Root().Find(id);
}

class MapMarkers
{
	Entity self;
	Scene@ scene;

	[null, "The bike"] Entity bike;
	[84.0, "World metres the map spans (the camera's orthoHeight)"] float span;
	[200.0, "The map view's size in pixels"] float mapSize;
	[2, "The delivery zones' collision group"] int zoneGroup;

	private array<Entity> m_zones;
	private array<int> m_waiting; // each dot's state shown: 1 waiting, 0 delivered, -1 not yet shown
	private bool m_found = false;

	void onUpdate(float dt)
	{
		// The zones are static triggers, there once physics has built them, so look once on the
		// first update rather than in onStart.
		if (!m_found)
		{
			findZones();
		}
		for (uint i = 0; i < m_zones.length(); i++)
		{
			Node@ dot = markersHud("map-sub-" + i);
			if (dot is null)
			{
				continue;
			}
			Entity marker = m_zones[i].FindChildByName("Marker");
			int waiting = marker.IsValid() && marker.IsActive() ? 1 : 0;
			if (waiting != m_waiting[i]) // the sheet's 0 until placed, then full or dimmed
			{
				m_waiting[i] = waiting;
				dot.Tween("opacity", waiting == 1 ? "1" : "0.3", 0.0f, "linear");
			}
		}
		if (!bike.IsValid())
		{
			return;
		}
		Node@ arrow = markersHud("map-bike");
		if (arrow is null)
		{
			return;
		}
		// The bike faces its local +Z; on the map that points (x, z) with z down the screen, and a
		// view turns clockwise from up. Set every frame (a tween of no length replaces the last).
		Float3 f = RotateVector(bike.GetLocalTransform().Rotation, Float3(0.0f, 0.0f, 1.0f));
		arrow.Tween("transform", at(bike.GetLocalTransform().Position, 10.0f, 16.0f) + " rotate(" + RadiansToDegrees(Atan2(f.X, -f.Z)) + "deg)",
			0.0f, "linear");
		arrow.Tween("opacity", "1", 0.0f, "linear");
	}

	private void findZones()
	{
		Float3 c = self.GetLocalTransform().Position;
		array<Entity> zones;
		scene.Physics.OverlapSphere(Float3(c.X, 0.0f, c.Z), span, zones, uint(1) << uint(zoneGroup));
		if (zones.length() == 0)
		{
			return;
		}
		m_found = true;
		for (uint i = 0; i < zones.length() && i < kDots; i++)
		{
			m_zones.insertLast(zones[i]);
			m_waiting.insertLast(-1);
			Node@ dot = markersHud("map-sub-" + i);
			if (dot !is null)
			{
				dot.Tween("transform", at(zones[i].GetWorldPosition(), 12.0f, 12.0f), 0.0f, "linear");
			}
		}
	}

	// The move that centres a marker of the given pixel size on a world position, from the map's
	// corner (a CSS transform).
	private string at(Float3 world, float width, float height)
	{
		Float3 c = self.GetLocalTransform().Position;
		float u = ((world.X - c.X) / span + 0.5f) * mapSize;
		float v = ((world.Z - c.Z) / span + 0.5f) * mapSize;
		return "translate(" + (u - width * 0.5f) + "px, " + (v - height * 0.5f) + "px)";
	}
}

// MapMarkers - on the block's top-down camera, which draws the Minimap texture the HUD shows. Places
// the HUD's markers over that image from world positions: a dot per subscriber (dimmed once it has
// its paper) and the bike, turned to its heading. The camera is orthographic and looks straight
// down, so world to map is a scale and an offset: map right is +X, map up is -Z.

// The HUD has this many subscriber dots (map-sub-0 ...).
const uint kDots = 8;

class MapMarkers
{
	Entity self;
	Scene@ scene;

	[null, "The bike"] Entity bike;
	[84.0, "World metres the map spans (the camera's orthoHeight)"] float span;
	[200.0, "The map view's size in pixels"] float mapSize;
	[2, "The delivery zones' collision group"] int zoneGroup;

	private array<Entity> m_zones;
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
			View dot = Ui.Find("map-sub-" + i);
			if (!dot.IsValid)
			{
				continue;
			}
			Entity marker = m_zones[i].FindChildByName("Marker");
			bool waiting = marker.IsValid() && marker.IsActive();
			dot.SetOpacity(waiting ? 1.0f : 0.3f);
		}
		if (!bike.IsValid())
		{
			return;
		}
		View arrow = Ui.Find("map-bike");
		if (!arrow.IsValid)
		{
			return;
		}
		place(arrow, bike.GetLocalTransform().Position, 10.0f, 16.0f);
		// The bike faces its local +Z; on the map that points (x, z) with z down the screen, and a
		// view turns clockwise from up.
		Float3 f = RotateVector(bike.GetLocalTransform().Rotation, Float3(0.0f, 0.0f, 1.0f));
		arrow.SetRotation(RadiansToDegrees(Atan2(f.X, -f.Z)));
		arrow.SetVisible(true);
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
			View dot = Ui.Find("map-sub-" + i);
			if (dot.IsValid)
			{
				place(dot, zones[i].GetWorldPosition(), 12.0f, 12.0f);
				dot.SetVisible(true);
			}
		}
	}

	// Centre a marker of the given pixel size on a world position.
	private void place(View marker, Float3 world, float width, float height)
	{
		Float3 c = self.GetLocalTransform().Position;
		float u = ((world.X - c.X) / span + 0.5f) * mapSize;
		float v = ((world.Z - c.Z) / span + 0.5f) * mapSize;
		marker.SetTranslation(u - width * 0.5f, v - height * 0.5f);
	}
}

// TrackMark - one stretch of the board's track in the snow (Prefabs/TrackMark, effects.py): it
// lies as it was dropped, fades over the end of its life and removes itself, so the track behind
// the rider stays a few seconds long.
class TrackMark
{
	Entity self;

	[6.0, "How long the mark lasts (s)"] float life;
	[2.0, "How long it takes to fade, at the end (s)"] float fade;

	private float m_age = 0.0f;
	private float m_alpha = -1.0f; // the decal's alpha as authored, read at the first update

	void onUpdate(float dt)
	{
		m_age += dt;
		Entity decal = self.GetFirstChild();
		if (decal.IsValid())
		{
			DecalComponent mark = DecalComponent(decal);
			Color c = mark.Color;
			if (m_alpha < 0.0f)
				m_alpha = c.A;
			float left = life - m_age;
			float k = (left < fade) ? ((left > 0.0f) ? left / fade : 0.0f) : 1.0f;
			mark.Color = Color(c.R, c.G, c.B, m_alpha * k);
		}
		if (m_age >= life)
			self.Destroy();
	}
}

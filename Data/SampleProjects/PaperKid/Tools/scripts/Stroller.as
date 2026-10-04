// Stroller - crosses the title backdrop along X, from `xFrom` to `xTo`, then after a pause comes
// round again from the start: a car on the road or a person on the pavement. It moves itself, not
// a navigation agent (the backdrop has no navmesh), and faces the way it goes.
//
// Its model is its first child. With a walk clip, the clip plays at the pace it moves (over the
// metres the clip covers at speed 1); a car has none.
class Stroller
{
	Entity self;
	Scene@ scene;

	[-30.0, "Where each crossing starts (m along X)"] float xFrom;
	[30.0, "Where each crossing ends (m along X)"] float xTo;
	[1.4, "Speed (m/s)"] float speed;
	[6.0, "Longest pause between crossings (s)"] float pause;
	["asset:AnimationClip", "The model's walk clip, if it walks"] Guid walkClip;
	[1.3, "Metres the walk clip covers at speed 1"] float walkMetres;

	private float m_x = 0.0f;
	private float m_wait = 0.0f;
	private Entity m_model;

	void onStart()
	{
		// Somewhere along the way already, so the backdrop is busy from the first frame.
		m_x = Random.Range(xFrom, xTo);
		float heading = (xTo > xFrom) ? 90.0f : -90.0f;
		self.SetLocalRotation(FromYawPitchRoll(DegreesToRadians(heading), 0.0f, 0.0f));
		place();
		m_model = self.GetFirstChild();
		if (m_model.IsValid() && !walkClip.IsNil)
		{
			scene.Animation.SetClip(m_model, walkClip);
			scene.Animation.Play(m_model);
			SkeletalAnimationComponent(m_model).Speed = speed / walkMetres;
		}
	}

	void onUpdate(float dt)
	{
		if (m_wait > 0.0f)
		{
			m_wait -= dt;
			if (m_wait <= 0.0f)
			{
				m_x = xFrom;
				place();
			}
			return;
		}
		float way = (xTo > xFrom) ? 1.0f : -1.0f;
		m_x += way * speed * dt;
		if ((m_x - xTo) * way >= 0.0f)
		{
			m_wait = Random.Range(0.5f, pause);
		}
		place();
	}

	private void place()
	{
		Float3 p = self.GetLocalTransform().Position;
		self.SetLocalPosition(Float3(m_x, p.Y, p.Z));
	}
}

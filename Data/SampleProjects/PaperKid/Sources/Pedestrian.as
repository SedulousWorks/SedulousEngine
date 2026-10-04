// Pedestrian - wanders the block on the navmesh: picks a spot around the ring road (on a verge or
// across it), walks there, picks another. The Level sets the walking speed ("PedestrianSpeed") and
// says where the ring road runs ("BlockRing"), which sets the band the walks stay in.
//
// The figure (Models/Town/PedestrianModel) turns toward where it walks, easing round rather than
// snapping, and its Walk clip (two 0.65 m steps a second) plays at the pace it walks.
class Pedestrian
{
	Entity self;
	Scene@ scene;

	[1.6, "Walking speed until the Level sets one (m/s)"] float speed;
	[18.0, "Nearest the middle a walk may lead (m)"] float inner;
	[31.0, "Farthest from the middle a walk may lead (m)"] float outer;
	["asset:AnimationClip", "The figure's walk clip"] Guid walkClip;
	[1.3, "Metres the walk clip covers at speed 1"] float walkMetres;

	private bool m_walking = false;
	private Entity m_figure;
	private float m_yaw = 0.0f; // radians; 0 faces +Z

	void onStart()
	{
		NavAgentComponent(self).MaxSpeed = speed;
		pickTarget();
		m_figure = self.FindChildByName("PedestrianModel");
		if (m_figure.IsValid() && !walkClip.IsNil)
		{
			scene.Animation.SetClip(m_figure, walkClip);
			scene.Animation.Play(m_figure);
		}
	}

	void onPedestrianSpeed(float s)
	{
		speed = s;
		NavAgentComponent(self).MaxSpeed = speed;
	}

	void onBlockRing(float ring)
	{
		inner = ring - 6.0f;
		outer = ring + 7.0f;
		pickTarget();
	}

	void onUpdate(float dt)
	{
		NavAgentComponent agent = NavAgentComponent(self);
		if (m_walking && agent.Finished)
		{
			pickTarget();
		}
		// Face the way the walk goes (turning the short way round, a few times a second), and
		// step at the pace of it; standing, the figure stands still.
		Float3 v = agent.DesiredVelocity;
		float pace = Sqrt(v.X * v.X + v.Z * v.Z);
		if (pace > 0.05f)
		{
			float turn = Atan2(v.X, v.Z) - m_yaw;
			while (turn > 3.14159f) { turn -= 6.28318f; }
			while (turn < -3.14159f) { turn += 6.28318f; }
			float ease = 8.0f * dt;
			m_yaw += turn * ((ease < 1.0f) ? ease : 1.0f);
			self.SetLocalRotation(FromYawPitchRoll(m_yaw, 0.0f, 0.0f));
		}
		if (m_figure.IsValid())
		{
			SkeletalAnimationComponent(m_figure).Speed = pace / walkMetres;
		}
	}

	// A point in the band around the ring road, on one of its four sides.
	private void pickTarget()
	{
		float along = Random.Range(-outer, outer);
		float across = Random.Range(inner, outer);
		if (Random.Bool())
		{
			across = -across;
		}
		float x = along;
		float z = across;
		if (Random.Bool())
		{
			x = across;
			z = along;
		}
		NavAgentComponent(self).Navigate(Float3(x, 0.0f, z));
		m_walking = true;
	}
}

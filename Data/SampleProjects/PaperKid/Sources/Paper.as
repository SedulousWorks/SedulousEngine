// Paper - a thrown newspaper. Entering any trigger, it tells that trigger's entity it arrived
// ("PaperArrived"); only a subscriber's delivery zone answers, so nothing here needs to know which
// triggers are porches. Its first hard landing kicks up a puff of dust. Gone a while after it is
// thrown, delivered or not.

Guid kFxPuff = Guid::FromString("8fdf193a-2ba9-c44d-ab1d-b75071f66278");

class Paper
{
	Entity self;
	Scene@ scene;

	[6.0, "Seconds before the paper is gone"] float lifetime;

	private float m_age = 0.0f;
	private bool m_landed = false;

	void onTriggerEnter(Entity other)
	{
		other.Send("PaperArrived");
	}

	void onContactBegin(Entity other, Float3 point, Float3 normal, float speed)
	{
		if (m_landed || speed < 2.0f)
		{
			return;
		}
		m_landed = true;
		scene.Prefabs.Spawn(kFxPuff, point);
	}

	void onUpdate(float dt)
	{
		m_age += dt;
		if (m_age >= lifetime)
		{
			self.Destroy();
		}
	}
}

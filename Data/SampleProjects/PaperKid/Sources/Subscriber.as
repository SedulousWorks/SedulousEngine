// Subscriber - a house that takes papers.
//
// A per-entity behavior on a subscriber's DELIVERY ZONE: a trigger body in the subscriber
// collision group. When a thrown paper enters it the delivery counts once, and the house's points
// go out twice: to the scene (the Level tallies the quota) and to the run (the Game keeps score).
class Subscriber
{
	Entity self;
	Scene@ scene;

	// Points this delivery is worth.
	int value = 10;

	private bool m_delivered = false;

	void onTriggerEnter(Entity other)
	{
		if (m_delivered || !self.IsValid())
		{
			return;
		}
		m_delivered = true;
		scene.Scripts.Emit("Delivered", value);
		Run.Emit("Delivered", value);
	}
}

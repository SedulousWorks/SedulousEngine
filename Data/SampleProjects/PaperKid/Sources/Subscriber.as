// Subscriber - a house that takes papers.
//
// A per-entity behavior on a subscriber's DELIVERY ZONE: a trigger body in the subscriber
// collision group. When a thrown paper enters it the delivery counts once, and the house's points
// go out once, as "Delivered" on the scene's event bus. In a game run the scene bus IS the run bus,
// so the Level (which tallies the quota) and the Game (which keeps score) both hear that one emit.
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
	}
}

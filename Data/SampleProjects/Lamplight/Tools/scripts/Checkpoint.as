// Checkpoint - a trigger volume the thief walks into: from then on a catch sends him back here
// (a Checkpoint event with where to stand, which Thief.as keeps). Once each.
class Checkpoint
{
	Entity self;
	Scene@ scene;

	[null, "The thief"] Entity thief;

	private bool m_reached = false;

	void onTriggerEnter(Entity other)
	{
		if (m_reached || !thief.IsValid() || !other.IsValid() || other != thief)
			return;
		m_reached = true;
		scene.Scripts.Emit("Checkpoint", self.GetWorldPosition());
	}
}

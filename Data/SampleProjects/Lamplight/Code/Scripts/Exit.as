// Exit - the way out of a level (a trigger volume): the thief walking in says so (Escaped); the
// level script (Level.as) ends the level if he carries the target, or tells him to find it.
class Exit : EntityBehavior
{
	Entity self;
	Scene@ scene;

	[null, "The thief"] Entity thief;

	void onTriggerEnter(Entity other)
	{
		if (!thief.IsValid() || !other.IsValid() || other != thief)
			return;
		scene.Behaviors.Emit("Escaped", self.GetWorldPosition());
	}
}

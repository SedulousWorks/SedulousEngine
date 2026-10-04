// Subscriber - a house that takes the paper. On the delivery zone in front of its porch (a static
// trigger), whose child "Marker" floats above to show the house wants one. The first paper to
// arrive ("PaperArrived", from Paper.as) is a delivery: "Delivered" goes out with the points, the
// marker goes, and the zone switches itself off: it takes no more papers, and an inactive entity
// has no trigger, so the bike's auto-aim (an overlap of the zone group) no longer finds it and
// stops drawing its arc and ring to a porch already served. A delivery sounds: the paper slapping
// the porch and a chime, sparkles off the porch, and a tap on the pad.
//
// In a run the scene bus IS the run bus: the Level (which tallies the quota) and the Game (which
// keeps score) both hear the one "Delivered".

Guid kLandSound = Guid::FromString("{{PaperLand}}");
Guid kDeliveredSound = Guid::FromString("{{Delivered}}");
Guid kFxSparkle = Guid::FromString("{{Prefab:FxSparkle}}");

class Subscriber
{
	Entity self;
	Scene@ scene;

	[100, "Points for this delivery"] int value;

	private bool m_delivered = false;

	void onPaperArrived()
	{
		if (m_delivered)
		{
			return;
		}
		m_delivered = true;
		Audio.PlayOneShot(kLandSound, AudioBus::Effects, 0.9f, Random.Range(0.95f, 1.05f));
		Audio.PlayOneShot(kDeliveredSound, AudioBus::Effects, 0.8f);
		Input.Rumble(0.1f, 0.45f, 0.1f); // a delivery's tap
		scene.Prefabs.Spawn(kFxSparkle, self.GetLocalTransform().Position + Float3(0.0f, 0.3f, 0.0f));
		scene.Scripts.Emit("Delivered", value);
		Entity marker = self.FindChildByName("Marker");
		if (marker.IsValid())
		{
			marker.SetActive(false);
		}
		self.SetActive(false);
	}
}

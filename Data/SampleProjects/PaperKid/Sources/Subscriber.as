// Subscriber - a house that takes the paper. On the delivery zone in front of its porch (a static
// trigger), whose child "Marker" floats above to show the house wants one. The first paper to
// arrive ("PaperArrived", from Paper.as) is a delivery: "Delivered" goes out with the points, the
// marker goes, and the zone switches itself off: it takes no more papers, and an inactive entity
// has no trigger, so the bike's auto-aim (an overlap of the zone group) no longer finds it and
// stops drawing its arc and ring to a porch already served. A delivery sounds: the paper slapping
// the porch and a chime, and sparkles off the porch.
//
// In a run the scene bus IS the run bus: the Level (which tallies the quota) and the Game (which
// keeps score) both hear the one "Delivered".

Guid kLandSound = Guid::FromString("a178cf74-4e03-9e41-8ba7-625dab7a98ec");
Guid kDeliveredSound = Guid::FromString("554f86eb-3e59-fe4b-adf7-670f7368d5e3");
Guid kFxSparkle = Guid::FromString("f9f2812e-7302-1e41-b95c-15d8e38e49a2");

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

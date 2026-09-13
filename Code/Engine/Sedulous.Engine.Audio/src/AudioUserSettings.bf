using System;
using System.Collections;
using Sedulous.Audio;
using Sedulous.Core.Serialization;

namespace Sedulous.Engine.Audio;

/// The USER's mixer state: what an options menu's sliders set.
///
/// Applied AFTER any project bus layout. The layout is the artistic baseline and this is
/// absolute, which is how an options menu is expected to behave. A host loads it at startup
/// and captures it at shutdown.
///
/// The volumes are LISTS rather than a fixed pair of arrays, which is where this diverges
/// from Raptor. Raptor hand writes a bus count and then a pair per bus, so a file written by
/// a build with more buses reads back into one with fewer. A list carries that same length
/// itself, and the generated body walks it, so the tolerance comes for free instead of from a
/// body that has to be kept in step with the bus enum. The cost is two small allocations for
/// a blob that is read once at startup.
[Serializable(1)]
class AudioUserSettings
{
	public List<float> Volumes = new .() ~ delete _;
	public List<bool> Muted = new .() ~ delete _;

	public this()
	{
		for (int bus < (int)AudioBus.Count)
		{
			Volumes.Add(1.0f);
			Muted.Add(false);
		}
	}

	/// Pushes this state onto the engine, over as many buses as BOTH sides have: a file from
	/// a build with more buses stops at this build's last one rather than running off the end.
	public void ApplyTo(AudioEngine engine)
	{
		let buses = Math.Min(Volumes.Count, (int)AudioBus.Count);
		for (int bus < buses)
		{
			engine.SetBusVolume((AudioBus)bus, Volumes[bus]);
			if (bus < Muted.Count)
				engine.SetBusMuted((AudioBus)bus, Muted[bus]);
		}
	}

	/// Reads the engine's current state back, which is what a shutdown saves.
	public void CaptureFrom(AudioEngine engine)
	{
		Volumes.Clear();
		Muted.Clear();

		for (int bus < (int)AudioBus.Count)
		{
			Volumes.Add(engine.BusVolume((AudioBus)bus));
			Muted.Add(engine.BusMuted((AudioBus)bus));
		}
	}
}

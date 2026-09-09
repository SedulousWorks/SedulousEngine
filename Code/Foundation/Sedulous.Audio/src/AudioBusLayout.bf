using System;
using System.Collections;

namespace Sedulous.Audio;

/// The whole layout: the fixed buses' tuning, and any named ones on top.
class AudioBusLayout
{
	public AudioBusSettings[AudioBus.Count] Buses = .(new .(), new .(), new .(), new .())
		~ { for (var settings in _) delete settings; };

	public List<AudioNamedBus> CustomBuses = new .() ~ DeleteContainerAndItems!(_);

	public AudioBusSettings this[AudioBus bus] => Buses[(int)bus];
}

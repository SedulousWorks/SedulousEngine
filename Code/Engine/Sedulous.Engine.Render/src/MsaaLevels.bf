using System;

namespace Sedulous.Engine.Render;

/// THE ordered scene pass multisampling levels, and the mapping between an index and a
/// sample count.
///
/// The single source of truth for both: add a level here, raise the device ceiling, and
/// every menu and every conversion picks it up, because nothing else writes the list down.
/// The device still clamps at runtime, so a level the hardware cannot do is simply not
/// offered rather than failing.
static class MsaaLevels
{
	public static readonly MsaaLevel[3] All = .(
		.(1, "Off"),
		.(2, "2x"),
		.(4, "4x"));

	public static uint32 Count => (uint32)All.Count;

	/// The highest level whose count does not exceed `samples`, so a stored four selects the
	/// four times level and a stored three selects two times rather than nothing.
	public static int32 IndexForSamples(uint32 samples)
	{
		int32 index = 0;
		for (uint32 i < Count)
		{
			if (samples >= All[i].Samples)
				index = (int32)i;
		}
		return index;
	}

	/// One sample, meaning off, for an index that is not a level.
	public static uint32 SamplesForIndex(int32 index) =>
		((index >= 0) && (index < (int32)Count)) ? All[index].Samples : 1;
}

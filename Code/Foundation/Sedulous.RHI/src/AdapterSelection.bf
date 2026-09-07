using System;
using System.Collections;

namespace Sedulous.RHI;

/// Ordering adapters so the best GPU comes first.
///
/// One place defines the order, so every backend agrees on what element zero means.
static class AdapterSelection
{
	/// Lower is more preferred.
	public static int PreferenceRank(AdapterType type)
	{
		switch (type)
		{
		case .DiscreteGpu: return 0;
		case .IntegratedGpu: return 1;
		case .Unknown: return 2;
		case .Cpu: return 3;
		}
	}

	/// Sorts in place, most preferred first.
	///
	/// STABLE, so adapters of equal type keep the driver's own order: that order carries
	/// the driver's own preference, and reordering within a type would discard it. An
	/// insertion sort because adapter counts are tiny.
	public static void SortByPreference(List<IAdapter> adapters)
	{
		let info = scope AdapterInfo();

		int RankOf(IAdapter adapter)
		{
			info.Name.Clear();
			adapter.GetInfo(info);
			return PreferenceRank(info.Type);
		}

		for (int i = 1; i < adapters.Count; i++)
		{
			let key = adapters[i];
			let keyRank = RankOf(key);
			int j = i;
			while ((j > 0) && (RankOf(adapters[j - 1]) > keyRank))
			{
				adapters[j] = adapters[j - 1];
				j--;
			}
			adapters[j] = key;
		}
	}
}

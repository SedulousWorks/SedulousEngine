using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.RHI;
using Sedulous.RHI.WebGPU;

namespace Sedulous.Engine.Player.Web;

/// Choosing which content pak this browser should be served.
///
/// A web dist built by this engine ships Content-bc.pak for desktop browsers and
/// Content-astc.pak for mobile ones, because the two families of compressed texture do not
/// overlap and shipping both to everyone doubles the download. The chosen one is fetched AS
/// Content.pak, so the project loader opens the name it always opens and knows nothing about
/// variants. An older or single pak bundle falls back to Content.pak outright.
static class ContentVariant
{
	private const String cBlockCompressed = "Content-bc.pak";
	private const String cAdaptiveScalable = "Content-astc.pak";
	private const String cSinglePak = "Content.pak";

	/// Probes the adapter, picks the family and mounts it as Content.pak.
	public static void SelectAndFetch()
	{
		// Already there means a build preloaded a single pak, and there is nothing to choose.
		if (FileExists(cSinglePak))
			return;

		var blockCompressed = false;
		var adaptiveScalable = false;
		Probe(ref blockCompressed, ref adaptiveScalable);

		// BC first: it is the desktop family, and a device reporting both is unusual enough
		// that the order only has to be decided, not agonised over.
		let variant = blockCompressed ? cBlockCompressed
			: (adaptiveScalable ? cAdaptiveScalable : null);

		GlobalLog(.Information, "Player: content variant probe, bc={} astc={} -> {}",
			blockCompressed, adaptiveScalable, (variant != null) ? variant : cSinglePak);

		if ((variant != null) && WebDist.FetchAs(variant, cSinglePak))
			return;

		// No variant on the server, or a device reporting neither family, which the spec says
		// cannot happen: serve the single pak rather than render nothing.
		WebDist.Fetch(cSinglePak);
	}

	/// A THROWAWAY backend, just to read the adapter's feature flags.
	///
	/// Torn down before the app boots and makes its own device. Two adapter requests per page
	/// is unremarkable, and the alternative is threading a probe result through a boot that
	/// has not started yet.
	private static void Probe(ref bool blockCompressed, ref bool adaptiveScalable)
	{
		if (!(WebGpuRhi.CreateBackend() case .Ok(let backend)))
			return;

		defer
		{
			backend.Destroy();
			delete backend;
		}

		let adapters = backend.EnumerateAdapters();
		if (adapters.IsEmpty)
			return;

		let info = scope AdapterInfo();
		adapters[0].GetInfo(info);
		blockCompressed = info.SupportedFeatures.TextureCompressionBC;
		adaptiveScalable = info.SupportedFeatures.TextureCompressionASTC;
	}
}

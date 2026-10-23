using System;
using Sedulous.Core.Serialization;
using Sedulous.Resource;

namespace Sedulous.VG.Resource;

/// Registration for the vector graphics resource types.
///
/// Which factories a host wants stays the application's business, as everywhere else.
[SerializableRegistry]
static class VGResources
{
	/// This library's resource module: its type registration and the factory descriptions
	/// the engine composition creates from, built on first use so no static
	/// initialisation order matters.
	public static ResourceModule Module => sModule ?? (sModule = new .("vg", () => RegisterAll(), new .(
		.ByDefault<VectorImage, VectorImageResource, VectorImageFactory>())));
	private static ResourceModule sModule ~ delete _;
}

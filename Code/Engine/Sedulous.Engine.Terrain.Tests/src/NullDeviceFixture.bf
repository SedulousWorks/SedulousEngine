using Sedulous.RHI;
using Sedulous.RHI.Null;

namespace Sedulous.Engine.Terrain.Tests;

/// A bare null device, which is all the cache tests need: they check what was created and
/// destroyed, not what any of it draws.
class NullDeviceFixture
{
	public IBackend Backend;
	public IDevice Device;

	public this()
	{
		Backend = NullRhi.CreateBackend();
		Device = Backend.EnumerateAdapters()[0].CreateDevice(.()).Value;
	}

	public ~this()
	{
		if (Device != null)
			Device.Destroy();
		if (Backend != null)
		{
			Backend.Destroy();
			delete Backend;
		}
	}
}

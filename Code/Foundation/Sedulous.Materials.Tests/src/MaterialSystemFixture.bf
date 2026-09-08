using System;
using Sedulous.Core;
using Sedulous.Materials;
using Sedulous.RHI;
using Sedulous.RHI.Null;

namespace Sedulous.Materials.Tests;

/// A null device with a material system brought up on it.
class MaterialSystemFixture
{
	public IBackend Backend ~ delete _;
	public IDevice Device;
	public MaterialSystem System = new .() ~ delete _;

	public this()
	{
		Backend = NullRhi.CreateBackend();
		Device = Backend.EnumerateAdapters()[0].CreateDevice(.()).Value;
		Test.Assert(System.Initialize(Device) case .Ok);
	}
}

using System;
using Sedulous.Content;

namespace Sedulous.Resource.Tests;

/// Resource composition: a module's factory descriptions, the services a gated factory asks
/// for by type, and the set that creates, owns and registers.
class ResourceCompositionTests
{
	class PlainProduct {}
	class GatedProduct {}

	/// The service a gated factory asks for: any type.
	class FakeDevice
	{
		public int32 Generation = 7;
	}

	class PlainFactory : IResourceFactory
	{
		public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<PlainProduct>();
		public Type CookedType => typeof(TestSource);
		public Object Create(ResourceManager manager, Instance instance) => null;
	}

	class GatedFactory : IResourceFactory
	{
		public FakeDevice Device;
		public this(FakeDevice device) { Device = device; }
		public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<GatedProduct>();
		public Type CookedType => typeof(GatedProduct);
		public Object Create(ResourceManager manager, Instance instance) => null;
	}

	static int sRegistered = 0;

	static ResourceModule sFakeModule = new .("fake", () => { sRegistered++; }, new .(
		.ByDefault<PlainProduct, TestSource, PlainFactory>(),
		.(typeof(GatedProduct), typeof(GatedProduct), typeof(FakeDevice), (services) =>
			{
				let device = services.Service(typeof(FakeDevice)) as FakeDevice;
				return (device != null) ? new GatedFactory(device) : null;
			}))) ~ delete _;

	[Test]
	public static void AModuleDescribesItsFactoriesProductCookedFormAndService()
	{
		Test.Assert(sFakeModule.Id == "fake");
		Test.Assert(sFakeModule.Factories.Length == 2);
		let plain = sFakeModule.Factories[0];
		let gated = sFakeModule.Factories[1];
		Test.Assert(plain.Product == typeof(PlainProduct));
		Test.Assert(plain.Cooked == typeof(TestSource));
		Test.Assert(plain.Service == null);
		Test.Assert(gated.Product == typeof(GatedProduct));
		Test.Assert(gated.Service == typeof(FakeDevice));
		// The descriptions agree with the factories they make.
		let none = scope NoResourceServices();
		let made = plain.Create(none);
		Test.Assert(made != null);
		defer delete (Object)made;
		Test.Assert(made.ProductTypeId == ResourceManager.ProductTypeIdOf(plain.Product));
		Test.Assert(made.CookedType == plain.Cooked);
		Test.Assert(gated.Create(none) == null, "no device, no factory");
		// Type registration goes through the module.
		let before = sRegistered;
		sFakeModule.RegisterTypes();
		Test.Assert(sRegistered == before + 1);
		let silent = scope ResourceModule("silent", null, null);
		silent.RegisterTypes(); // a module with no registrar is fine
		Test.Assert(silent.Factories.IsEmpty);
	}

	[Test]
	public static void TheSetCreatesWhatTheServicesAllowReportsTheRestFillsTheGapLaterAndNeverDuplicates()
	{
		ResourceModule[1] modules = .(sFakeModule);
		let set = scope ResourceFactorySet();

		// Headless: the gated factory is skipped and says which service it wanted.
		let none = scope NoResourceServices();
		set.Create(modules, none);
		Test.Assert(set.Count == 1);
		Test.Assert(set.Has(typeof(PlainProduct)));
		Test.Assert(!set.Has(typeof(GatedProduct)));
		Test.Assert(set.Skipped.Length == 1);
		Test.Assert(set.Skipped[0].Product == typeof(GatedProduct));
		Test.Assert(set.Skipped[0].Service == typeof(FakeDevice));

		// Still headless: nothing new, nothing duplicated, the skip still recorded once.
		set.Create(modules, none);
		Test.Assert(set.Count == 1);
		Test.Assert(set.Skipped.Length == 1);

		// The device arrives: the gap fills, the skip clears, the plain one is not made again.
		let device = scope FakeDevice();
		let services = scope ResourceServiceTable();
		services.Add(typeof(FakeDevice), device);
		set.Create(modules, services);
		Test.Assert(set.Count == 2);
		Test.Assert(set.Skipped.IsEmpty);
		int seen = 0;
		for (let factory in set.Factories)
		{
			seen++;
			if (let gated = factory as GatedFactory)
				Test.Assert(gated.Device == device);
		}
		Test.Assert(seen == 2);

		// A table answers only what it was given; a null instance is not offered.
		services.Add(typeof(String), null);
		Test.Assert(services.Service(typeof(String)) == null);
		Test.Assert(services.Service(typeof(FakeDevice)) == device);
	}

	[Test]
	public static void RegisterHandsEveryCreatedFactoryToAManager()
	{
		let manager = scope ResourceManager(null);
		ResourceModule[1] modules = .(sFakeModule);
		let set = scope ResourceFactorySet();
		let device = scope FakeDevice();
		let services = scope ResourceServiceTable();
		services.Add(typeof(FakeDevice), device);
		set.Create(modules, services);
		set.Register(manager);
		Test.Assert(manager.FactoryCount == 2);
		Test.Assert(manager.HasFactory(ResourceManager.ProductTypeIdOf<PlainProduct>()));
		Test.Assert(manager.HasFactory(ResourceManager.ProductTypeIdOf<GatedProduct>()));
	}
}

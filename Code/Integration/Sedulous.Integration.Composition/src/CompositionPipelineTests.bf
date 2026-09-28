using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Engine.DefaultApp;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Registration;
using Sedulous.Resource;

namespace Sedulous.Integration.Composition;

/// The engine's resource factories joined to the pipeline's builders: a cross collection
/// join, so it lives here rather than in an engine suite, which has no business linking the
/// pipeline.
class CompositionPipelineTests
{
	/// Every standard factory declares the cooked form it reads, a registered serializable
	/// that some builder produces: the runtime to asset link the scene format reference joins.
	[Test]
	public static void EveryStandardFactorysCookedFormIsRegisteredAndSomeBuilderProducesIt()
	{
		let resources = scope ResourceManager(null);
		let host = scope StubHost();
		let app = scope DefaultApplication();
		app.AttachResourceManager(resources, host);

		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(builders);
		Test.Assert(builders.Count == PipelineRegistration.cBuilderCount);

		int joined = 0;
		for (let factory in resources.Factories)
		{
			let cooked = factory.CookedType;
			Test.Assert(cooked != null, scope $"factory {factory.ProductTypeId} declares no cooked form");
			let name = cooked.GetFullName(.. scope .());
			// The cooked form is what the cook stamped and ReadObject reconstructs: registered.
			Test.Assert(GlobalSerializableRegistry.IsRegistered(TypeIdOf(name)), scope $"{name} is not registered");
			// And some builder produces exactly it: the link from the runtime type to the asset.
			bool produced = false;
			builders.ForEach(scope [&](builder) => { produced |= (builder.ProductType == cooked); });
			Test.Assert(produced, scope $"no builder produces {name}");
			joined++;
		}
		Test.Assert(joined == resources.FactoryCount);
		Test.Assert(joined >= 25);
	}
}

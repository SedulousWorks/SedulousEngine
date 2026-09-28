using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Engine.Composition;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Registration;
using Sedulous.Resource;

namespace Sedulous.Integration.Composition;

/// The engine's resource factories joined to the pipeline's builders: a cross collection
/// join, so it lives here rather than in an engine suite, which has no business linking the
/// pipeline.
class CompositionPipelineTests
{
	/// Every factory description the composition carries names a cooked form that is a
	/// registered serializable some builder produces: the runtime to asset link the scene
	/// format reference joins, read from the descriptions, so nothing is constructed.
	[Test]
	public static void EveryFactoryDescriptionsCookedFormIsRegisteredAndSomeBuilderProducesIt()
	{
		EngineComposition.RegisterResourceTypes();
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(builders);
		Test.Assert(builders.Count == PipelineRegistration.cBuilderCount);

		let descriptions = scope List<ResourceFactoryDesc*>();
		EngineComposition.FactoryDescriptions(descriptions);
		Test.Assert(descriptions.Count == 27);
		for (let desc in descriptions)
		{
			let cooked = desc.Cooked;
			let name = cooked.GetFullName(.. scope .());
			// The cooked form is what the cook stamped and ReadObject reconstructs: registered.
			Test.Assert(GlobalSerializableRegistry.IsRegistered(TypeIdOf(name)), scope $"{name} is not registered");
			// And some builder produces exactly it: the link from the runtime type to the asset.
			bool produced = false;
			builders.ForEach(scope [&](builder) => { produced |= (builder.ProductType == cooked); });
			Test.Assert(produced, scope $"no builder produces {name}");
		}
	}
}

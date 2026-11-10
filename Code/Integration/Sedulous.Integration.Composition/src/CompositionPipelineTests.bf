using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Engine.Composition;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Registration;
using Sedulous.Resource;
using Sedulous.VFS;

namespace Sedulous.Integration.Composition;

/// The engine's resource factories joined to the pipeline's builders: a cross collection
/// join, so it lives here rather than in an engine suite, which has no business linking the
/// pipeline.
class CompositionPipelineTests
{
	/// Every cooked form a factory description the composition carries names is a
	/// registered serializable some builder produces: the runtime to asset link the scene
	/// format reference joins, read from the descriptions. The exception is a factory that reads
	/// an AUTHORED record (a prefab document), which no cook builds: that one is constructed to
	/// ask it.
	[Test]
	public static void EveryFactoryDescriptionsCookedFormIsRegisteredAndSomeBuilderProducesIt()
	{
		EngineComposition.RegisterResourceTypes();
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(builders, FindDataRoot(.. scope .()));
		Test.Assert(builders.Count == PipelineRegistration.cBuilderCount);

		let descriptions = scope List<ResourceFactoryDesc*>();
		EngineComposition.FactoryDescriptions(descriptions);
		Test.Assert(descriptions.Count == 30); // with the scene's prefabs and the GUI's documents and sheets
		let none = scope NoResourceServices();
		int forms = 0;
		int authored = 0;
		for (let desc in descriptions)
		{
			// An authored record is read as it was written, so no builder makes it. The factories
			// needing a service (the device's, the shader system's) are not made here; they read
			// cooked forms.
			bool readsAuthored = false;
			if (desc.Service == null)
			{
				let made = desc.Create(none);
				Test.Assert(made != null);
				readsAuthored = made.ReadsAuthoredRecord;
				delete (Object)made;
			}
			if (readsAuthored)
				authored++;
			// Every cooked form a description names, not only the first (a texture's factory
			// reads a render texture's record too).
			desc.ForEachCooked(scope [&](cooked) =>
				{
					forms++;
					let name = cooked.GetFullName(.. scope .());
					// The cooked form is what the cook stamped and ReadObject reconstructs: registered.
					Test.Assert(GlobalSerializableRegistry.IsRegistered(TypeIdOf(name)), scope $"{name} is not registered");
					if (readsAuthored)
						return;
					// And some builder produces exactly it: the link from the runtime type to the asset.
					bool produced = false;
					builders.ForEach(scope [&](builder) => { produced |= (builder.ProductType == cooked); });
					Test.Assert(produced, scope $"no builder produces {name}");
				});
		}
		Test.Assert(forms == 31, scope $"{forms} cooked forms");
		Test.Assert(authored == 1, "the prefab factory alone reads an authored record");
	}
}

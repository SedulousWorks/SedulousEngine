using Sedulous.Engine.Domain;
using Sedulous.Scene;
using Sedulous.Sequence.Resource;

namespace Sedulous.Engine.Sequence;

/// The sequence domain: the scene's player of sequences, and the sequence resource.
static class SequenceDomain
{
	public static DomainModule Module => sModule ?? (sModule = new .("sequence", => AddSequenceSceneSystems,
		new .(SequenceResources.Module)));
	private static DomainModule sModule ~ delete _;

	/// The scene install: the player of sequences and the components that start plays from
	/// entities.
	public static void AddSequenceSceneSystems(Scene scene)
	{
		scene.AddSystem<SequenceSystem>();
		scene.AddSystem<SequenceComponentManager>();
	}
}

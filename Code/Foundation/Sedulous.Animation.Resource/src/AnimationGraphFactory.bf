using System;
using Sedulous.Animation;
using Sedulous.Content;
using Sedulous.Resource;

namespace Sedulous.Animation.Resource;

/// Builds a cooked graph, binding each node's clip through the manager.
///
/// SYNCHRONOUS ONLY: those binds are what record the graph to clip edges, and an edge is the
/// manager's to write on the thread that owns it. A clip binds asynchronously on its own.
class AnimationGraphFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<AnimationGraph>();

	public Object Create(ResourceManager manager, Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;

		let source = stored as AnimationGraphSource;
		if (source == null)
		{
			delete stored;
			return null;
		}
		defer delete source;

		let graph = new AnimationGraph();
		source.BuildInto(manager, graph);
		return graph;
	}
}

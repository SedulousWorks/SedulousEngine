using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Resource;

namespace Sedulous.Physics.Resource;

/// Builds a cooked collision shape into what a collider binds.
///
/// PURELY CPU: the blob is handed to the world as bytes and only restored when a body is
/// created from it, so nothing here touches the backend at all.
class CollisionShapeFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<CollisionShape>();

	public bool SupportsAsync => true;

	public Object Create(ResourceManager manager, Instance instance) => BuildFrom(instance);

	public Object DecodeStage(Instance instance) => BuildFrom(instance);

	public Object FinalizeStage(ResourceManager manager, Object decoded) => decoded;

	private Object BuildFrom(Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;

		let source = stored as CollisionShapeSource;
		if (source == null)
		{
			delete stored;
			return null;
		}
		defer delete source;

		let shape = new CollisionShape();
		shape.Convex = source.Convex;
		shape.Blob.AddRange(source.ShapeBlob);

		// The outline is stored flat and read back in threes; a trailing partial vertex is
		// dropped rather than read past.
		let vertexCount = source.Outline.Count / 3;
		for (int v = 0; v < vertexCount; v++)
			shape.Outline.Add(.(source.Outline[v * 3 + 0], source.Outline[v * 3 + 1],
				source.Outline[v * 3 + 2]));

		return shape;
	}
}

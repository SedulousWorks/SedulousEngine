using System;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Pipeline.Core;

namespace Sedulous.Physics.Pipeline;

/// The physics domain's New Asset creators: a physical material and a collision shape, each at
/// its defaults.
static class PhysicsCreators
{
	public static void Register(AssetCreatorRegistry registry)
	{
		registry.Register(new AssetCreator("Physical Material", "Physics", typeof(PhysicalMaterialAsset), new (context) =>
			AssetCreator.CreateWritten(context.Target, context.NameOr("PhysicalMaterial"), typeof(PhysicalMaterialAsset), scope PhysicalMaterialAsset())));
		registry.Register(new AssetCreator("Collision Shape", "Physics", typeof(CollisionShapeAsset), new (context) =>
			AssetCreator.CreateWritten(context.Target, context.NameOr("CollisionShape"), typeof(CollisionShapeAsset), scope CollisionShapeAsset())));
	}
}

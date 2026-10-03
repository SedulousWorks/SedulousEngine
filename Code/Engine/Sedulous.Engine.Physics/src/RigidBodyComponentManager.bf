using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Physics;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics;

/// The pool of physics bodies, and the static level geometry they make: the static, solid
/// bodies' collision shapes, which the navigation bake reads.
class RigidBodyComponentManager : ResourceBindingComponentManager<RigidBodyComponent>, IStaticGeometrySource
{
	public override IStaticGeometrySource AsStaticGeometrySource => this;

	/// Static, solid bodies only: a dynamic or kinematic body moves and a trigger lets things
	/// through, so neither is level geometry (a character is no rigid body at all). An inactive
	/// entity has no body, as at scene start. Needs no world: the bake runs in edit mode.
	public void CollectStaticGeometry(Scene scene, AABB bounds, float detail, List<Float3> outTriangles)
	{
		let heightBuffers = scope List<List<float>>();
		defer { ClearAndDeleteItems!(heightBuffers); }
		let bodies = scope List<BodyDesc>();
		defer { ClearAndDeleteItems!(bodies); }
		for (let entity in Owners)
		{
			let component = Get(entity);
			if ((component.Motion != .Static) || component.IsTrigger || !scene.IsEffectivelyActive(entity))
				continue;
			let desc = new BodyDesc();
			if (PhysicsBodies.Describe(scene, component, entity, desc, heightBuffers))
				bodies.Add(desc);
			else
				delete desc;
		}
		let failed = PhysicsWorld.AppendBodyTriangles(bodies, bounds, outTriangles);
		if (failed > 0)
			GlobalLog(.Warning, "Physics: {} static bodies have a shape that does not build; they are left out of the static geometry", failed);
	}
}

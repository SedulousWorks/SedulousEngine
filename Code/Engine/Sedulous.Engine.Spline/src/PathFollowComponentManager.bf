using System;
using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Engine.Spline;

/// Advances every follower, and only while the scene is simulating: edit mode never moves
/// them, which is what keeps an authored start offset where the designer put it.
class PathFollowComponentManager : SerializableComponentManager<PathFollowComponent>
{
	/// BORROWED: the scene owns this manager.
	private Scene mScene = null;

	public override bool IsSimulationOnly => true;

	public override void OnSceneCreate(Scene scene) => mScene = scene;

	public override void OnUpdate(ScenePhase phase, float deltaTime)
	{
		if ((phase != .Update) || (mScene == null) || (deltaTime <= 0.0f))
			return;

		let splines = mScene.GetSystem<SplineComponentManager>();
		if (splines == null)
			return;

		ForEach(scope (follow, owner) =>
			{
				if (!follow.Playing || follow.Spline.IsNil || !mScene.IsEffectivelyActive(owner))
					return;

				let splineEntity = mScene.FindEntity(follow.Spline.Id);
				let component = splines.Get(splineEntity);
				if (component == null)
					return;

				let curve = component.Curve;
				let length = curve.Length;
				if (length <= 0.0f)
					return;

				follow.Distance += follow.Speed * deltaTime;
				if (curve.Closed || follow.Loop)
				{
					follow.Distance -= Math.Floor(follow.Distance / length) * length;
				}
				else if (follow.Distance >= length)
				{
					follow.Distance = length;
					follow.Playing = false; // arrived
				}
				else if (follow.Distance < 0.0f)
				{
					follow.Distance = 0.0f;
					follow.Playing = false;
				}

				let t = curve.DistanceToT(follow.Distance);
				let splineWorld = mScene.GetWorldMatrix(splineEntity);
				let world = TransformPoint(curve.Evaluate(t), splineWorld);

				// ASSUMES an unparented follower, so local is world. A parented one would need
				// the world position mapped back into its parent's space first.
				var transform = mScene.GetLocalTransform(owner);
				transform.Position = world;

				if (follow.AlignToTangent)
				{
					let tangent = Normalized(TransformDirection(curve.Tangent(t), splineWorld));
					if (LengthSquared(tangent) > 0.5f)
					{
						// Yaw and pitch that turn -Z onto the tangent, leaving roll alone.
						let yaw = Math.Atan2(-tangent.X, -tangent.Z);
						let horizontal = Math.Sqrt(tangent.X * tangent.X + tangent.Z * tangent.Z);
						let pitch = Math.Atan2(tangent.Y, horizontal);
						transform.Rotation = Quaternion.FromAxisAngle(.(0, 1, 0), yaw)
							* Quaternion.FromAxisAngle(.(1, 0, 0), pitch);
					}
				}

				mScene.SetLocalTransform(owner, transform);
			});
	}
}

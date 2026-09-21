using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Heightfield;
using Sedulous.Physics;
using Sedulous.Physics.Resource;
using Sedulous.Resource;
using Sedulous.Profiler;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics;

/// The per scene physics runtime.
///
/// It owns the scene's world, builds the bodies, joints and characters when the scene starts,
/// steps on the FIXED clock, and hands the render frame interpolated poses.
///
/// SIMULATION ONLY: an editor's edit mode runs nothing.
class PhysicsSceneSystem : SceneSystem
{
	/// BORROWED: the scene outlives its systems.
	private Scene mScene = null;
	private PhysicsSceneSettings mSettings = new .() ~ delete _;
	private PhysicsWorld mWorld = null ~ delete _;
	private List<ContactEvent> mEvents = new .() ~ delete _;
	/// BORROWED from the subsystem, whose list has a stable address. Null means nothing is
	/// listening, which is what a bare harness with no subsystem gets.
	private List<IContactListener> mListeners = null;

	/// Sample buffers held alive across ONE body build, because the backend copies them when
	/// the body is created rather than when the shape is described.
	private List<List<float>> mHeightBuffers = new .() ~ DeleteContainerAndItems!(_);

	public override bool IsSimulationOnly => true;

	public override void OnSceneCreate(Scene scene)
	{
		mScene = scene;
	}

	public override Type SettingsType => typeof(PhysicsSceneSettings);
	public override void* SettingsInstance => Internal.UnsafeCastToPtr(mSettings);
	public override StringView SettingsId => "physics";

	public override void SerializeSettings(ISerializer ar)
	{
		mSettings.Serialize(ar);
	}

	public PhysicsSceneSettings Settings => mSettings;
	public PhysicsWorld World => mWorld;
	public Scene OwningScene => mScene;
	public Span<ContactEvent> Events => .(mEvents.Ptr, mEvents.Count);

	/// The subsystem points this at its own list, whose address is stable.
	public void SetContactListeners(List<IContactListener> listeners)
	{
		mListeners = listeners;
	}

	/// Launches a body, QUEUEING the impulse when the body does not exist yet.
	///
	/// Spawning a thing and throwing it in the same frame is the case: the world exists but
	/// this body is not assembled until the next step, and applying the impulse straight to a
	/// missing body would drop it silently and leave the thing to fall. The queue is flushed
	/// once, where the body is created.
	///
	/// It lives here rather than on a script facade, because it is the world that makes it
	/// possible and a facade would only forward.
	// ---- scene queries --------------------------------------------------------------------
	//
	// They live where the world does, and they are the script surface for asking the scene
	// about space: what is at a point, what a ray meets, how heavy the world is. Every one
	// answers something explicit rather than mutating state to read back.

	public void SetGravity(Float3 gravity)
	{
		if (mWorld != null)
			mWorld.SetGravity(gravity);
	}

	public Float3 Gravity => (mWorld != null) ? mWorld.Gravity : .(0, 0, 0);

	public int BodyCount => (mWorld != null) ? mWorld.BodyCount : 0;

	/// A ray against this scene's world, answering the CLOSEST hit. Direction must be unit
	/// length: Distance scales by its magnitude otherwise.
	public PhysicsHit RayCast(Float3 from, Float3 direction, float maxDistance,
		uint32 groupMask = 0xFFFFFFFF)
	{
		var result = PhysicsHit();
		if (mWorld == null)
			return result;
		if (mWorld.RayCast(from, direction, maxDistance, let hit, groupMask))
			FillHit(ref result, hit, maxDistance);
		return result;
	}

	/// A swept SPHERE from `from` along `direction`, answering the closest hit. Like RayCast
	/// with a volume: the ray that slips through a gap a fat projectile cannot.
	public PhysicsHit SphereCast(Float3 from, Float3 direction, float maxDistance, float radius,
		uint32 groupMask = 0xFFFFFFFF)
	{
		var result = PhysicsHit();
		if (mWorld == null)
			return result;
		var shape = QueryShape();
		shape.Kind = .Sphere;
		shape.Radius = radius;
		if (mWorld.ShapeCast(shape, from, .Identity, direction, maxDistance, let hit, groupMask))
			FillHit(ref result, hit, maxDistance);
		return result;
	}

	/// The body NEAREST `center` whose shape overlaps a sphere of `radius` there, or Hit false.
	///
	/// One handle rather than a list, because "act on the closest thing in range" is what a
	/// script asks far more often than "act on all of them", and the group mask does the
	/// category filtering. Nearest is by body ORIGIN, and Position is that origin; an overlap
	/// has no contact surface, so Normal is zero.
	public PhysicsHit NearestOverlap(Float3 center, float radius, uint32 groupMask = 0xFFFFFFFF)
	{
		var result = PhysicsHit();
		if (mWorld == null)
			return result;

		var shape = QueryShape();
		shape.Kind = .Sphere;
		shape.Radius = radius;
		let bodies = scope List<BodyId>();
		mWorld.ShapeOverlap(shape, center, .Identity, bodies, groupMask);

		var bestSq = float.MaxValue;
		for (let body in bodies)
		{
			mWorld.GetBodyTransform(body, let position, ?);
			let d = position - center;
			let dSq = Dot(d, d);
			if (dSq < bestSq)
			{
				bestSq = dSq;
				result.Hit = true;
				result.Entity = PhysicsEntityPacking.UnpackEntity(mWorld.UserData(body));
				result.Position = position;
			}
		}
		if (result.Hit)
			result.Distance = Sqrt(bestSq);
		return result;
	}

	/// Every entity whose body overlaps a sphere of `radius` at `center`, filtered to the
	/// group mask. Bodies carrying no live entity are left out rather than answered as Invalid.
	public void OverlapSphere(Float3 center, float radius, List<EntityHandle> outEntities,
		uint32 groupMask = 0xFFFFFFFF)
	{
		outEntities.Clear();
		if ((mWorld == null) || (mScene == null))
			return;

		var shape = QueryShape();
		shape.Kind = .Sphere;
		shape.Radius = radius;
		let bodies = scope List<BodyId>();
		mWorld.ShapeOverlap(shape, center, .Identity, bodies, groupMask);
		for (let body in bodies)
		{
			let entity = PhysicsEntityPacking.UnpackEntity(mWorld.UserData(body));
			if (mScene.IsValid(entity))
				outEntities.Add(entity);
		}
	}

	private static void FillHit(ref PhysicsHit result, RayHit hit, float maxDistance)
	{
		result.Hit = true;
		result.Entity = PhysicsEntityPacking.UnpackEntity(hit.UserData);
		result.Distance = hit.Fraction * maxDistance;
		result.Position = hit.Position;
		result.Normal = hit.Normal;
		result.Surface = (int32)hit.Surface;
	}

	public void ApplyImpulse(EntityHandle entity, Float3 impulse)
	{
		let bodies = (mScene != null) ? mScene.GetSystem<RigidBodyComponentManager>() : null;
		let component = (bodies != null) ? bodies.Get(entity) : null;
		if (component == null)
			return;

		if ((mWorld != null) && component.Body.IsValid)
		{
			mWorld.AddImpulse(component.Body, impulse);
			return;
		}

		component.PendingImpulse += impulse;
	}

	// ---- the play lifecycle ----

	public override void OnSceneStarted()
	{
		// The world matrices are current before this fires, so the bodies build from the
		// AUTHORED layout rather than from identity matrices no update has touched yet.
		let settings = scope PhysicsWorldSettings();
		settings.Gravity = mSettings.Gravity;

		let rows = Math.Min(mSettings.GroupCollides.Count, PhysicsWorldSettings.CollisionGroupCount);
		for (int i < rows)
			settings.GroupCollides[i] = mSettings.GroupCollides[i];

		mWorld = new PhysicsWorld(settings);

		BuildBodies();
		BuildJoints();
		BuildCharacters();
	}

	public override void OnSceneStopped()
	{
		if (mScene != null)
		{
			if (let bodies = mScene.GetSystem<RigidBodyComponentManager>())
			{
				bodies.ForEach(scope (component, entity) =>
					{
						component.Body = .();
						component.SimActive = false;
						// The queue belongs to the RUN: an impulse queued in the last frame
						// before a stop must not fire as an unexplained kick at the next play.
						component.PendingImpulse = .(0, 0, 0);
					});
			}

			if (let joints = mScene.GetSystem<JointComponentManager>())
			{
				joints.ForEach(scope (component, entity) =>
					{
						component.Joint = .();
						component.SimActive = false;
					});
			}

			if (let characters = mScene.GetSystem<CharacterComponentManager>())
			{
				characters.ForEach(scope (component, entity) =>
					{
						component.Character = .();
						component.SimActive = false;
					});
			}
		}

		mEvents.Clear();
		DeleteAndNullify!(mWorld);
	}

	// ---- the fixed step ----

	public override void OnFixedUpdate(float fixedDeltaTime)
	{
		if (mWorld == null)
			return;

		let bodies = mScene.GetSystem<RigidBodyComponentManager>();
		if (bodies == null)
			return;

		using (ProfileScope("Physics.Step"))
		{
			// The active edges settle BEFORE this step simulates, so a body that just went
			// away does not take one more step first.
			ReconcileActiveState();

			// A KINEMATIC body follows the scene, moved by velocity toward this step's target
			// rather than teleported, so what it pushes is pushed rather than penetrated.
			bodies.ForEach(scope (component, entity) =>
				{
					if (!component.Body.IsValid || (component.Motion != .Kinematic))
						return;

					if (Decompose(mScene.GetWorldMatrix(entity), let position,
						let rotation, ?))
						mWorld.MoveKinematic(component.Body, position, rotation, fixedDeltaTime);
				});

			// The motor fields are LIVE, so an inspector edit or a gameplay change applies on
			// the next step rather than at the next rebuild.
			if (let joints = mScene.GetSystem<JointComponentManager>())
			{
				joints.ForEach(scope (component, entity) =>
					{
						if (component.Joint.IsValid)
							mWorld.SetJointMotor(component.Joint, component.MotorEnabled,
								component.MotorTargetVelocity);
					});
			}

			mWorld.Step(fixedDeltaTime, (mSettings.CollisionSteps < 1) ? 1
				: mSettings.CollisionSteps);

			mEvents.Clear();
			mWorld.DrainContacts(mEvents);
			// PUSHED here, at the tick. The list clears every substep, so a frame with several
			// substeps would lose all but the last if a listener only read it once a frame.
			DispatchContacts();

			StepCharacters(fixedDeltaTime);

			// The dynamic poses into the double buffer, which is what the interpolation reads.
			bodies.ForEach(scope (component, entity) =>
				{
					if (!component.Body.IsValid || (component.Motion != .Dynamic))
						return;

					component.PrevPosition = component.CurrPosition;
					component.PrevRotation = component.CurrRotation;
					mWorld.GetBodyTransform(component.Body, out component.CurrPosition,
						out component.CurrRotation);
				});
		}
	}

	/// The standard recipe: grounded is a planar move plus a one shot jump, and airborne keeps
	/// the fall gravity has integrated while still steering horizontally.
	private void StepCharacters(float fixedDeltaTime)
	{
		let characters = mScene.GetSystem<CharacterComponentManager>();
		if (characters == null)
			return;

		let gravity = mWorld.Gravity;
		characters.ForEach(scope (component, entity) =>
			{
				if (!component.Character.IsValid)
					return;

				// A teleport snaps the character, drops its momentum and SKIPS this step's
				// integration so the snap is exact. The interpolation snaps with it, both ends
				// of the buffer being the destination, and the ground re-evaluates next step.
				if (component.TeleportPending)
				{
					mWorld.SetCharacterPosition(component.Character, component.TeleportTo);
					mWorld.SetCharacterVelocity(component.Character, .(0, 0, 0));
					component.MoveVelocity = .(0, 0, 0);
					component.JumpSpeed = 0.0f;
					component.PrevPosition = component.TeleportTo;
					component.CurrPosition = component.TeleportTo;
					component.Ground = .InAir;
					component.TeleportPending = false;
					return;
				}

				let current = mWorld.CharacterVelocity(component.Character);
				var velocity = Float3(component.MoveVelocity.X, 0.0f, component.MoveVelocity.Z);

				if (component.Ground == .OnGround)
				{
					if (component.JumpSpeed > 0.0f)
					{
						velocity.Y = component.JumpSpeed;
						component.JumpSpeed = 0.0f;
					}
				}
				else
				{
					velocity.Y = current.Y + gravity.Y * fixedDeltaTime;
				}

				// The push force is live as well.
				mWorld.SetCharacterStrength(component.Character, component.MaxStrength);
				mWorld.SetCharacterVelocity(component.Character, velocity);
				mWorld.UpdateCharacter(component.Character, fixedDeltaTime);

				component.Ground = mWorld.GetCharacterGround(component.Character);
				component.PrevPosition = component.CurrPosition;
				component.CurrPosition = mWorld.CharacterPosition(component.Character);
			});
	}

	/// The render frame's interpolation, driven by the subsystem with the scene's own alpha.
	///
	/// It writes WORLD poses converted back to local against the current parent, because the
	/// scene stores local transforms and physics works in world.
	public void ApplyInterpolation(float alpha)
	{
		if ((mWorld == null) || (mScene == null) || !mScene.SimulationEnabled)
			return;

		let bodies = mScene.GetSystem<RigidBodyComponentManager>();
		if (bodies == null)
			return;

		bodies.ForEach(scope (component, entity) =>
			{
				if (!component.Body.IsValid || (component.Motion != .Dynamic))
					return;

				let position = Lerp(component.PrevPosition, component.CurrPosition, alpha);
				let rotation = Slerp(component.PrevRotation, component.CurrRotation,
					alpha);
				WriteWorldPose(entity, position, rotation, true);
			});

		if (let characters = mScene.GetSystem<CharacterComponentManager>())
		{
			characters.ForEach(scope (component, entity) =>
				{
					if (!component.Character.IsValid)
						return;

					let position = Lerp(component.PrevPosition, component.CurrPosition, alpha);
					// The ROTATION stays the scene's: which way a character faces is gameplay.
					WriteWorldPose(entity, position, mScene.GetLocalTransform(entity).Rotation,
						false);
				});
		}
	}

	/// Writes a world pose back as a local one against the current parent. The SCALE is left
	/// as authored: physics never scales a body, so taking it from here would quietly reset it.
	private void WriteWorldPose(EntityHandle entity, Float3 position, Quaternion rotation,
		bool writeRotation)
	{
		var local = mScene.GetLocalTransform(entity);
		let parent = mScene.GetParent(entity);

		if (parent.IsAssigned)
		{
			let world = Transform(position, rotation, .(1, 1, 1)).ToMatrix();
			let parentInverse = Inverse(mScene.GetWorldMatrix(parent));
			if (Decompose(world * parentInverse, let localPosition,
				let localRotation, ?))
			{
				local.Position = localPosition;
				if (writeRotation)
					local.Rotation = localRotation;
			}
		}
		else
		{
			local.Position = position;
			if (writeRotation)
				local.Rotation = rotation;
		}

		mScene.SetLocalTransform(entity, local);
	}

	// ---- building ----

	private void BuildBodies()
	{
		let bodies = mScene.GetSystem<RigidBodyComponentManager>();
		if (bodies == null)
			return;

		bodies.ForEach(scope (component, entity) =>
			{
				// An effectively inactive entity enters the world with NO body: the reconcile
				// creates one on the activation edge, so a scene that starts with the entity
				// inactive never simulates it at all.
				if (!mScene.IsEffectivelyActive(entity))
				{
					component.SimActive = false;
					return;
				}

				component.SimActive = true;
				CreateBodyForEntity(component, entity);
			});
	}

	/// One entity's body, shared by the scene's start and the activation edge.
	///
	/// It reads the entity's CURRENT world transform, so a body rebuilt on reactivation starts
	/// where the entity is NOW and with no velocity.
	private void CreateBodyForEntity(RigidBodyComponent* component, EntityHandle entity)
	{
		if (!Decompose(mScene.GetWorldMatrix(entity), let position, let rotation,
			let scale))
			return;

		let desc = scope BodyDesc();
		desc.Motion = component.Motion;
		desc.Layer = component.Layer;
		desc.Friction = component.Friction;
		desc.Restitution = component.Restitution;
		desc.LinearDamping = component.LinearDamping;
		desc.AngularDamping = component.AngularDamping;
		desc.IsTrigger = component.IsTrigger;
		desc.ContinuousCollision = component.ContinuousCollision;
		desc.MassOverride = component.Mass;
		desc.Group = component.CollisionGroup;
		// The reverse map, so a contact can name the entity again.
		desc.UserData = PhysicsEntityPacking.PackEntity(entity);
		desc.Position = position;
		desc.Rotation = rotation;

		// The sample buffers live until the body is created, which is where the backend
		// copies them.
		ClearAndDeleteItems!(mHeightBuffers);

		var own = ShapeDesc();
		own.Kind = component.Shape;
		own.HalfExtents = component.HalfExtents;
		own.Radius = component.Radius;
		own.HalfHeight = component.HalfHeight;
		own.PlaneHalfExtent = component.PlaneHalfExtent;

		if (component.Shape == .Cooked)
		{
			let cooked = component.CollisionShape.Get;
			if (cooked == null)
			{
				GlobalLog(.Warning,
					"Physics: '{}' has a cooked shape but no collision shape resource, so the body was skipped",
					mScene.GetEntityName(entity));
				return;
			}
			own.Cooked = cooked.Blob;
			// Cooked geometry is authored at unit scale, so the entity's scale applies here.
			own.Scale = scale;
		}
		else if (component.Shape == .Heightfield)
		{
			if (!FillHeightfield(ref own, component.Heightfield))
			{
				GlobalLog(.Warning,
					"Physics: '{}' has a heightfield shape but no heightfield resource, so the body was skipped",
					mScene.GetEntityName(entity));
				return;
			}
		}

		// A shape that can only be static, the backend's MustBeStatic: a plane, a heightfield,
		// a cooked triangle mesh. Under a moving body the world makes it static rather than
		// tripping the backend's mass assert; named HERE, where the entity is known, so the
		// author can find the component.
		let staticOnly = (component.Shape == .Plane) || (component.Shape == .Heightfield)
			|| ((component.Shape == .Cooked) && (component.CollisionShape.Get != null)
				&& !component.CollisionShape.Get.Convex);
		if ((component.Motion != .Static) && staticOnly)
		{
			GlobalLog(.Error,
				"Physics: '{}': a {} body cannot use a {} shape, which is static only, having no mass and no mesh against mesh collision; simulated as static",
				mScene.GetEntityName(entity),
				(component.Motion == .Kinematic) ? "kinematic" : "dynamic",
				(component.Shape == .Plane) ? "plane"
					: (component.Shape == .Heightfield) ? "heightfield" : "triangle mesh");
			desc.Motion = .Static;
		}

		desc.Shapes.Add(own);
		AddDescendantColliders(desc, entity);

		// A referenced SURFACE wins over the inline fields.
		if (let material = component.Material.Get)
		{
			desc.Friction = material.Friction;
			desc.Restitution = material.Restitution;
			desc.Density = material.Density;
		}

		component.Body = mWorld.CreateBody(desc);
		component.PrevPosition = position;
		component.CurrPosition = position;
		component.PrevRotation = rotation;
		component.CurrRotation = rotation;

		if (!component.Body.IsValid)
		{
			GlobalLog(.Warning, "Physics: the body for '{}' could not be created",
				mScene.GetEntityName(entity));
			return;
		}

		// Flush an impulse queued BEFORE the body existed, which is what spawning a thing and
		// launching it in the same frame produces.
		if ((component.PendingImpulse.X != 0.0f) || (component.PendingImpulse.Y != 0.0f)
			|| (component.PendingImpulse.Z != 0.0f))
		{
			mWorld.AddImpulse(component.Body, component.PendingImpulse);
			component.PendingImpulse = .(0, 0, 0);
		}
	}

	/// The hierarchy's extra shapes fold into the body's compound at their offset relative to
	/// the body's entity, captured NOW.
	private void AddDescendantColliders(BodyDesc desc, EntityHandle entity)
	{
		let colliders = mScene.GetSystem<ColliderComponentManager>();
		if (colliders == null)
			return;

		let bodyInverse = Inverse(mScene.GetWorldMatrix(entity));
		colliders.ForEach(scope [&] (extra, child) =>
			{
				if (!IsDescendantOf(child, entity))
					return;

				if (!Decompose(mScene.GetWorldMatrix(child) * bodyInverse,
					let localPosition, let localRotation, let localScale))
					return;

				var shape = ShapeDesc();
				shape.Kind = extra.Shape;
				shape.HalfExtents = extra.HalfExtents;
				shape.Radius = extra.Radius;
				shape.HalfHeight = extra.HalfHeight;
				shape.PlaneHalfExtent = extra.PlaneHalfExtent;

				if (extra.Shape == .Cooked)
				{
					let cooked = extra.CollisionShape.Get;
					if (cooked == null)
						return;
					shape.Cooked = cooked.Blob;
					shape.Scale = localScale;
				}
				else if (extra.Shape == .Heightfield)
				{
					if (!FillHeightfield(ref shape, extra.Heightfield))
						return;
				}

				shape.LocalPosition = localPosition;
				shape.LocalRotation = localRotation;
				desc.Shapes.Add(shape);
			});
	}

	/// Converts a heightfield's stored samples into the world heights the backend wants, into
	/// a buffer that outlives the description.
	private bool FillHeightfield(ref ShapeDesc shape, Ref<Heightfield> reference)
	{
		let heightfield = reference.Get;
		if ((heightfield == null) || heightfield.IsEmpty)
			return false;

		let buffer = new List<float>();
		mHeightBuffers.Add(buffer);

		let samples = heightfield.Samples;
		buffer.Resize(samples.Length);
		for (int i < samples.Length)
			buffer[i] = heightfield.SampleToWorldY((float)samples[i]);

		shape.HeightSamples = .(buffer.Ptr, buffer.Count);
		shape.HeightSampleCount = (uint32)heightfield.Size;
		shape.HeightWorldSize = heightfield.WorldSize;
		return true;
	}

	private void BuildCharacters()
	{
		let characters = mScene.GetSystem<CharacterComponentManager>();
		if (characters == null)
			return;

		characters.ForEach(scope (component, entity) =>
			{
				if (!mScene.IsEffectivelyActive(entity))
				{
					// Built on the activation edge instead.
					component.SimActive = false;
					return;
				}

				component.SimActive = true;
				CreateCharacterForEntity(component, entity);
			});
	}

	/// A rebuilt character starts at the CURRENT pose with no momentum, which is the same
	/// toggle behaviour a body has.
	private void CreateCharacterForEntity(CharacterComponent* component, EntityHandle entity)
	{
		if (!Decompose(mScene.GetWorldMatrix(entity), let position, ?, ?))
			return;

		var desc = CharacterDesc();
		desc.CapsuleRadius = component.Radius;
		desc.CapsuleHalfHeight = component.HalfHeight;
		desc.MaxSlopeDegrees = component.MaxSlopeDegrees;
		desc.Mass = component.Mass;
		desc.MaxStrength = component.MaxStrength;
		desc.StepUp = component.StepUp;
		desc.StepDown = component.StepDown;
		desc.Position = position;
		desc.UserData = PhysicsEntityPacking.PackEntity(entity);

		component.Character = mWorld.CreateCharacter(desc);
		component.Ground = .InAir;
		component.PrevPosition = position;
		component.CurrPosition = position;
		component.MoveVelocity = .(0, 0, 0);
		component.JumpSpeed = 0.0f;
		component.TeleportPending = false;
	}

	/// AFTER the bodies: a joint references bodies that already exist.
	private void BuildJoints()
	{
		let joints = mScene.GetSystem<JointComponentManager>();
		if ((joints == null) || (mScene.GetSystem<RigidBodyComponentManager>() == null))
			return;

		joints.ForEach(scope (component, entity) =>
			{
				if (!mScene.IsEffectivelyActive(entity))
				{
					component.SimActive = false;
					return;
				}

				component.SimActive = true;
				CreateJointForEntity(component, entity, true);
			});
	}

	/// One entity's joint.
	///
	/// `logFailures` is on for the scene's start only. The reconcile retries SILENTLY, because
	/// a missing endpoint there usually means the target is inactive right now, which is a
	/// state rather than a mistake.
	private void CreateJointForEntity(JointComponent* component, EntityHandle entity,
		bool logFailures)
	{
		let bodies = mScene.GetSystem<RigidBodyComponentManager>();
		if (bodies == null)
			return;

		let own = bodies.Get(entity);
		if (own == null)
		{
			if (logFailures)
				GlobalLog(.Warning, "Physics: '{}' has a joint but no rigid body on its entity",
					mScene.GetEntityName(entity));
			return;
		}

		// The body is pending, so the reconcile will retry.
		if (!own.Body.IsValid)
			return;

		// An invalid target is an attachment to the WORLD.
		var target = BodyId();

		if (!component.TargetEntity.IsNil)
		{
			let named = mScene.FindEntity(component.TargetEntity.Id);
			let targetBody = named.IsAssigned ? bodies.Get(named) : null;
			if (targetBody == null)
			{
				if (logFailures)
					GlobalLog(.Warning,
						"Physics: '{}' names a joint target with no rigid body, so the joint was skipped",
						mScene.GetEntityName(entity));
				return;
			}

			// Inactive right now, so it is rebuilt when the target returns.
			if (!targetBody.Body.IsValid)
				return;

			target = targetBody.Body;
		}
		else
		{
			// The nearest ANCESTOR with a body, or the world.
			var parent = mScene.GetParent(entity);
			while (parent.IsAssigned)
			{
				let parentBody = bodies.Get(parent);
				if ((parentBody != null) && parentBody.Body.IsValid)
				{
					target = parentBody.Body;
					break;
				}
				parent = mScene.GetParent(parent);
			}
		}

		let world = mScene.GetWorldMatrix(entity);

		var desc = JointDesc();
		desc.Kind = component.Kind;
		desc.BodyA = own.Body;
		desc.BodyB = target;
		desc.Anchor = TransformPoint(component.LocalAnchor, world);
		desc.Axis = Decompose(world, ?, let rotation, ?)
			? RotateVector(rotation, component.LocalAxis) : component.LocalAxis;
		desc.LimitMin = component.LimitMin;
		desc.LimitMax = component.LimitMax;
		desc.MinDistance = component.MinDistance;
		desc.MaxDistance = component.MaxDistance;
		desc.MotorEnabled = component.MotorEnabled;
		desc.MotorTargetVelocity = component.MotorTargetVelocity;
		desc.MotorLimit = component.MotorLimit;

		component.Joint = mWorld.CreateJoint(desc);
		if (!component.Joint.IsValid && logFailures)
			GlobalLog(.Warning, "Physics: the joint on '{}' could not be created",
				mScene.GetEntityName(entity));
	}

	/// Whether an explicitly named target is ready.
	///
	/// The EFFECTIVE ACTIVE term matters because joints reconcile BEFORE bodies: on the tick a
	/// target deactivates, its body is still alive during the joint pass, so gating on the
	/// body alone would keep the joint one tick past the body it references. Activation is the
	/// mirror image: the rebuilt body appears a pass later, so the joint returns on the tick
	/// after, through the silent retry.
	private bool JointTargetReady(JointComponent* component)
	{
		if (component.TargetEntity.IsNil)
			return true;

		let target = mScene.FindEntity(component.TargetEntity.Id);
		if (!target.IsAssigned || !mScene.IsEffectivelyActive(target))
			return false;

		let bodies = mScene.GetSystem<RigidBodyComponentManager>();
		let body = (bodies != null) ? bodies.Get(target) : null;
		return (body != null) && body.Body.IsValid;
	}

	/// Reconciles the world against the effective active EDGES, one latch per component.
	///
	/// Latching per component makes this order independent and self healing: it does not
	/// matter which pass runs first or whether a component arrived before the scene loaded.
	///
	/// Deactivation DESTROYS the body, character or joint rather than skipping its sync: the
	/// backend steps everything in its world, so a skipped sync would leave the thing
	/// simulating invisibly. Activation rebuilds from the current pose with no momentum.
	private void ReconcileActiveState()
	{
		// JOINTS FIRST, which is the reverse of the start's build order: a joint whose
		// referenced body dies THIS reconcile must go while both bodies are still alive, so
		// the surviving side gets its wake.
		if (let joints = mScene.GetSystem<JointComponentManager>())
		{
			// A joint reconciles on the full comparison rather than on its own entity's edge
			// alone: an ACTIVE entity's joint must also drop when its explicit target
			// deactivates, because that body is gone, and return when the target does.
			joints.ForEach(scope (component, entity) =>
				{
					let effective = mScene.IsEffectivelyActive(entity);
					component.SimActive = effective;

					let want = effective && JointTargetReady(component);
					let have = component.Joint.IsValid;
					if (want == have)
						return;

					if (!want)
					{
						mWorld.DestroyJoint(component.Joint);
						component.Joint = .();
					}
					else
					{
						CreateJointForEntity(component, entity, false);
					}
				});
		}

		if (let bodies = mScene.GetSystem<RigidBodyComponentManager>())
		{
			bodies.ForEach(scope (component, entity) =>
				{
					let effective = mScene.IsEffectivelyActive(entity);
					if (effective == component.SimActive)
					{
						// A queued impulse lives only until the assembly right after it was
						// queued. If the body is STILL not valid here, the build failed or the
						// entity is inactive, so the queue drops: a script calling this every
						// frame would otherwise accumulate an unbounded launch that fires
						// whenever the body finally appears.
						if (!component.Body.IsValid)
							component.PendingImpulse = .(0, 0, 0);
						return;
					}

					component.SimActive = effective;

					if (!effective)
					{
						if (component.Body.IsValid)
						{
							mWorld.DestroyBody(component.Body);
							component.Body = .();
						}
						// An impulse queued while active dies with the body, so coming back
						// does not launch a sum accumulated across the dark window.
						component.PendingImpulse = .(0, 0, 0);
					}
					else if (!component.Body.IsValid)
					{
						CreateBodyForEntity(component, entity);
					}
				});
		}

		if (let characters = mScene.GetSystem<CharacterComponentManager>())
		{
			characters.ForEach(scope (component, entity) =>
				{
					let effective = mScene.IsEffectivelyActive(entity);
					if (effective == component.SimActive)
						return;

					component.SimActive = effective;

					if (!effective)
					{
						if (component.Character.IsValid)
						{
							mWorld.DestroyCharacter(component.Character);
							component.Character = .();
						}
					}
					else if (!component.Character.IsValid)
					{
						CreateCharacterForEntity(component, entity);
					}
				});
		}
	}

	/// Resolves each drained contact's packed word back to a live entity and pushes the result
	/// to every listener.
	///
	/// A side that does not resolve, because its body was destroyed or its slot went stale,
	/// arrives unassigned; a contact with NEITHER side live is dropped, having nothing to say.
	private void DispatchContacts()
	{
		if ((mListeners == null) || mListeners.IsEmpty || (mScene == null))
			return;

		for (let event in mEvents)
		{
			let a = PhysicsEntityPacking.UnpackEntity(event.UserA);
			let b = PhysicsEntityPacking.UnpackEntity(event.UserB);

			var contact = EntityContact();
			contact.Kind = event.Kind;
			contact.Scene = mScene;
			contact.A = mScene.IsValid(a) ? a : EntityHandle();
			contact.B = mScene.IsValid(b) ? b : EntityHandle();

			if (!contact.A.IsAssigned && !contact.B.IsAssigned)
				continue;

			contact.Point = event.Point;
			contact.Normal = event.Normal;
			contact.Speed = event.Speed;

			for (let listener in mListeners)
			{
				if (listener != null)
					listener.OnContact(contact);
			}
		}
	}

	private bool IsDescendantOf(EntityHandle child, EntityHandle ancestor)
	{
		var current = child;
		while (current.IsAssigned)
		{
			if (current == ancestor)
				return true;
			current = mScene.GetParent(current);
		}
		return false;
	}
}

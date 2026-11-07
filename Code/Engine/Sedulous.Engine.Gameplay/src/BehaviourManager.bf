using System;
using System.Collections;
using System.Diagnostics;
using System.Reflection;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using internal Sedulous.Engine.Gameplay;

namespace Sedulous.Engine.Gameplay;

/// The `T` behaviours of one scene: one manager per behaviour class, a scene system like any
/// component manager, so a behaviour is one more component to the scene, its loader, prefabs
/// and the tools.
///
/// It OWNS its instances, kept as a sparse set as ComponentManager keeps its values: a dense
/// list in pool order, the owner per slot, and an entity index for O(1) lookup, with removal
/// swapping the last into the hole. An instance goes (OnDisable and OnDestroy first, as they
/// are owed, then deleted) when it is removed, when its entity is destroyed and when the
/// manager is (the scene torn down, or the manager removed).
///
/// While the scene's BehaviourSystem runs a pass over it, the pool keeps that shape (a removal
/// still swaps at once, so the pool and the index are always whole), but the pass walks the
/// instances it held when it began, and what is removed is deleted only as the pass ends: an
/// instance a callback removes, its own included, stays alive until no callback can be running
/// on it.
///
/// The identity on disk and the tick lists it joins are the class's own, read at compile time.
class BehaviourManager<T> : BehaviourManagerBase where T : Behaviour, new, delete
{
	private const uint32 cInvalid = 0xFFFFFFFF;

	/// OWNED instances, in pool order, no holes.
	private List<T> mDense = new .() ~ delete _;
	/// The owning entity per dense slot.
	private List<EntityHandle> mOwners = new .() ~ delete _;
	/// Entity index to dense index.
	private Dictionary<uint32, uint32> mSparse = new .() ~ delete _;

	private String mTypeId = new .() ~ delete _;
	private uint32 mDataVersion = 1;
	/// The oldest stored version a legacy reader accepts; nought is the current one alone.
	private uint32 mMinReadDataVersion = 0;

	/// Whether `T` overrides each tick, baked in at compile time.
	private bool mTicksUpdate = false;
	private bool mTicksFixedUpdate = false;
	private bool mTicksLateUpdate = false;

	/// The instances the open pass visits, as they were when it began. BORROWED from the
	/// pool, or, once removed, from mRetired.
	private List<T> mPass = new .() ~ delete _;
	/// OWNED: what was removed during the open pass, released and detached, deleted as it
	/// closes.
	private List<T> mRetired = new .() ~ delete _;
	private bool mInPass = false;

	public this()
	{
		EmitIdentity(typeof(T));
		EmitTickLists(typeof(T));
	}

	/// Deletes what is still held, OnDisable and OnDestroy first as they are owed. The scene
	/// deletes its systems newest first while it is still whole, so they still have its scene
	/// and the systems older than this one.
	public ~this()
	{
		while (!mDense.IsEmpty)
		{
			let instance = mDense.PopBack();
			mSparse.Remove(mOwners.PopBack().Index);
			instance.Release();
			instance.Detach();
			delete instance;
		}
		mPass.Clear();
		for (let instance in mRetired)
			delete instance;
	}

	/// Bakes the class's [Behaviour] in at compile time, as SerializableComponentManager bakes
	/// a component's [SerializableComponent]: no attribute is constructed per manager, and a
	/// class missing its attribute fails when its manager is built rather than when a record
	/// fails to route. Appended rather than interpolated: comptime cannot evaluate an
	/// interpolated string.
	[Comptime]
	private static void EmitIdentity(Type type)
	{
		String code = scope .();
		if (type.GetCustomAttribute<BehaviourAttribute>() case .Ok(let attribute))
		{
			code.Append("mTypeId.Set(\"");
			code.Append(attribute.TypeId);
			code.Append("\");\n");
			code.Append("mDataVersion = ");
			attribute.DataVersion.ToString(code);
			code.Append(";\n");
			code.Append("mMinReadDataVersion = ");
			attribute.MinReadDataVersion.ToString(code);
			code.Append(";");
			Compiler.MixinRoot(code);
			return;
		}

		// Emitted rather than asserted: the unspecialized generic is comptimed too, carries no
		// attribute and is never constructed. A concrete manager of a class without one fatals
		// the moment it is built.
		code.Append("Runtime.FatalError(\"");
		type.GetFullName(code);
		code.Append(" is stored by a BehaviourManager but carries no [Behaviour] attribute\");");
		Compiler.MixinRoot(code);
	}

	/// Finds, at compile time, which ticks `T` overrides, so a class joins only the tick lists
	/// it has work in: a class without an OnUpdate costs the frame nothing. Found from the
	/// methods themselves rather than by reflection at run time, which would need every
	/// behaviour's methods reflected into the binary.
	///
	/// The unspecialized generic has no methods to look at, and bakes in nothing.
	[Comptime]
	private static void EmitTickLists(Type type)
	{
		String code = scope .();
		if (Overrides(type, "OnUpdate"))
			code.Append("mTicksUpdate = true;\n");
		if (Overrides(type, "OnFixedUpdate"))
			code.Append("mTicksFixedUpdate = true;\n");
		if (Overrides(type, "OnLateUpdate"))
			code.Append("mTicksLateUpdate = true;\n");
		if (!code.IsEmpty)
			Compiler.MixinRoot(code);
	}

	/// Whether `type`, or a class between it and Behaviour, declares the tick `name` (one
	/// float). The walk runs from `type` down through its bases, so Behaviour's own empty
	/// virtual is the one declaration that does not count.
	[Comptime]
	private static bool Overrides(Type type, StringView name)
	{
		let instance = type as TypeInstance;
		if (instance == null)
			return false;
		for (let method in instance.GetMethods(.Instance | .Public | .NonPublic))
		{
			if ((method.Name != name) || (method.ParamCount != 1) || (method.GetParamType(0) != typeof(float)))
				continue;
			if (method.DeclaringType != typeof(Behaviour))
				return true;
		}
		return false;
	}

	/// A new `T` on `entity`, one per entity. Nothing runs on it until the scene simulates.
	public T Add(EntityHandle entity)
	{
		Debug.Assert(!HasComponent(entity), "one behaviour of a type per entity");

		let instance = new T();
		instance.Attach(Scene, entity);
		let slot = mDense.Count;
		mDense.Add(instance);
		mOwners.Add(entity);
		mSparse[entity.Index] = (uint32)slot;
		return instance;
	}

	/// `entity`'s `T`, or null when it has none or the handle is stale. BORROWED.
	public T Get(EntityHandle entity)
	{
		let index = DenseIndex(entity);
		return (index != cInvalid) ? mDense[(int)index] : null;
	}

	public override bool HasComponent(EntityHandle entity) => DenseIndex(entity) != cInvalid;

	public override bool AddDefaultComponent(EntityHandle entity)
	{
		if (HasComponent(entity))
			return false;
		Add(entity);
		return true;
	}

	/// Removes and deletes `entity`'s `T`, OnDisable and OnDestroy first as they are owed. It
	/// leaves the pool before they run, so what they do to the pool (removing another) does
	/// not move it under the removal. During a pass the delete waits for the pass to end.
	public override void RemoveComponent(EntityHandle entity)
	{
		let index = DenseIndex(entity);
		if (index == cInvalid)
			return;

		let slot = (int)index;
		let instance = mDense[slot];
		let last = mDense.Count - 1;
		if (slot != last)
		{
			mDense[slot] = mDense[last];
			mOwners[slot] = mOwners[last];
			mSparse[mOwners[slot].Index] = (uint32)slot;
		}
		mDense.PopBack();
		mOwners.PopBack();
		mSparse.Remove(entity.Index);

		Retire(instance);
	}

	/// The instance itself: an object's fields sit at offsets from its own address, which is
	/// what reflection (FieldInfo.GetValueReference) and the inspector read a class through.
	public override void* GetComponentAddress(EntityHandle entity)
	{
		let instance = Get(entity);
		return (instance != null) ? Internal.UnsafeCastToPtr(instance) : null;
	}

	public override uint32 ComponentCount => (uint32)mDense.Count;
	public uint32 Count => (uint32)mDense.Count;
	public override Type ComponentType => typeof(T);

	/// The instances in pool order, and their owners parallel to them.
	public Span<T> Instances => mDense;
	public override Span<EntityHandle> OwnerHandles => mOwners;

	// ---- serialization ----

	public override bool IsSerializable => true;
	public override StringView SerializationTypeId => mTypeId;

	public override void WriteComponent(ISerializer ar, EntityHandle entity)
	{
		let instance = Get(entity);
		if (instance == null)
			return;

		BeginVersionedPayload(ar, TypeIdOf(mTypeId), mDataVersion);
		instance.Serialize(ar);
		EndVersionedPayload(ar);
	}

	/// Reads `entity`'s `T` into a FRESH instance: one already there (a restore into the same
	/// scene, a prefab override applied, a duplicate record) is replaced, and deleted
	/// (OnDestroy first when it had started) once the read is done, so no runtime state
	/// outlives the read. A refused payload is not read, and leaves the fresh instance at its
	/// defaults.
	public override void ReadComponent(ISerializer ar, EntityHandle entity)
	{
		T instance;
		T replaced = null;
		let index = DenseIndex(entity);
		if (index == cInvalid)
		{
			instance = Add(entity);
		}
		else
		{
			// The fresh one takes the slot (and so the pool order) of the one it replaces.
			replaced = mDense[(int)index];
			instance = new T();
			instance.Attach(Scene, entity);
			mDense[(int)index] = instance;
		}

		BeginVersionedPayload(ar, TypeIdOf(mTypeId), mDataVersion, mMinReadDataVersion);
		if (ar.IsPayloadOk)
			instance.Serialize(ar);
		EndVersionedPayload(ar);

		// Last, so whatever its OnDestroy does to the pool happens after the read.
		if (replaced != null)
			Retire(replaced);
	}

	/// Ends an instance already out of the pool: its closing edges (Release), then detached,
	/// so a pass still holding it finds it inactive with nothing owed, then deleted, at once
	/// or, during a pass, as the pass ends.
	private void Retire(T instance)
	{
		instance.Release();
		instance.Detach();
		if (mInPass)
			mRetired.Add(instance);
		else
			delete instance;
	}

	// ---- the system's pass ----

	protected internal override bool TicksUpdate => mTicksUpdate;
	protected internal override bool TicksFixedUpdate => mTicksFixedUpdate;
	protected internal override bool TicksLateUpdate => mTicksLateUpdate;

	protected internal override void BeginPass()
	{
		Debug.Assert(!mInPass, "passes do not nest");
		mPass.Clear();
		mPass.AddRange(mDense);
		mInPass = true;
	}

	protected internal override void EndPass()
	{
		mInPass = false;
		mPass.Clear();
		for (let instance in mRetired)
			delete instance;
		mRetired.Clear();
	}

	protected internal override void DeliverEdges()
	{
		for (let instance in mPass)
			instance.SettleEnabled();
	}

	// The ticks call `T`'s own override, reached past its protection: the manager is the one
	// caller the lifecycle has.

	protected internal override void RunUpdate(float deltaTime)
	{
		for (let instance in mPass)
		{
			if (instance.Ticks)
				instance.[Friend]OnUpdate(deltaTime);
		}
	}

	protected internal override void RunFixedUpdate(float fixedDeltaTime)
	{
		for (let instance in mPass)
		{
			if (instance.Ticks)
				instance.[Friend]OnFixedUpdate(fixedDeltaTime);
		}
	}

	protected internal override void RunLateUpdate(float deltaTime)
	{
		for (let instance in mPass)
		{
			if (instance.Ticks)
				instance.[Friend]OnLateUpdate(deltaTime);
		}
	}

	/// The dense index of a live, generation matching instance, or cInvalid.
	private uint32 DenseIndex(EntityHandle entity)
	{
		if (!mSparse.TryGetValue(entity.Index, let dense))
			return cInvalid;
		// The owner carries the whole handle, so a stale one fails the generation check.
		return (mOwners[(int)dense] == entity) ? dense : cInvalid;
	}
}

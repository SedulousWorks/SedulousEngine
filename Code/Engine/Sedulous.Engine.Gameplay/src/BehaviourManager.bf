using System;
using System.Collections;
using System.Diagnostics;
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
/// swapping the last into the hole. An instance goes (OnDestroy first, when it had started,
/// then deleted) when it is removed, when its entity is destroyed and when the manager is
/// (the scene torn down, or the manager removed).
///
/// The identity on disk is the class's own [Behaviour], read at compile time.
class BehaviourManager<T> : ComponentManagerBase where T : Behaviour, new, delete
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

	public this()
	{
		EmitIdentity(typeof(T));
	}

	/// Deletes what is still held, OnDestroy first for the started. The scene deletes its
	/// systems newest first while it is still whole, so OnDestroy still has its scene and
	/// the systems older than this one.
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

	/// Removes and deletes `entity`'s `T`, OnDestroy first when it had started. It leaves the
	/// pool before OnDestroy runs, so what OnDestroy does to the pool (removing another) does
	/// not move it under the removal.
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

		instance.Release();
		delete instance;
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
		{
			replaced.Release();
			delete replaced;
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

using System;
using System.Collections;
using System.Diagnostics;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Physics;
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
/// The identity on disk, the tick lists it joins and the fields it replicates are the class's
/// own, read at compile time.
class BehaviourManager<T> : BehaviourManagerBase, IReplicatedStateSource where T : Behaviour, new, delete
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
	/// And which contact callbacks it overrides.
	private ContactCallbacks mContacts = .None;

	/// The instances the open pass visits, as they were when it began. BORROWED from the
	/// pool, or, once removed, from mRetired.
	private List<T> mPass = new .() ~ delete _;
	/// OWNED: what was removed during the open pass, released and detached, deleted as it
	/// closes.
	private List<T> mRetired = new .() ~ delete _;
	private bool mInPass = false;
	/// The holds open (Hold), each deferring deletes as a pass does.
	private int32 mHolds = 0;

	public this()
	{
		EmitIdentity(typeof(T));
		EmitTickLists(typeof(T));
	}

	/// Deletes what is still held, OnDisable and OnDestroy first as they are owed. The scene
	/// deletes its systems in the order they were added, while the rest of it is whole, so
	/// they still have its scene and the systems added after this one.
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

	/// Finds, at compile time, which ticks and contact callbacks `T` overrides, so a class
	/// joins only the lists it has work in: a class without an OnUpdate costs the frame
	/// nothing, and one without a contact callback costs a contact nothing. Found from the
	/// methods themselves rather than by reflection at run time, which would need every
	/// behaviour's methods reflected into the binary.
	///
	/// The unspecialized generic has no methods to look at, and bakes in nothing.
	[Comptime]
	private static void EmitTickLists(Type type)
	{
		String code = scope .();
		if (Overrides(type, "OnUpdate", 1, typeof(float)))
			code.Append("mTicksUpdate = true;\n");
		if (Overrides(type, "OnFixedUpdate", 1, typeof(float)))
			code.Append("mTicksFixedUpdate = true;\n");
		if (Overrides(type, "OnLateUpdate", 1, typeof(float)))
			code.Append("mTicksLateUpdate = true;\n");
		if (Overrides(type, "OnContactBegin", 4, typeof(EntityHandle)))
			code.Append("mContacts |= .ContactBegin;\n");
		if (Overrides(type, "OnContactEnd", 4, typeof(EntityHandle)))
			code.Append("mContacts |= .ContactEnd;\n");
		if (Overrides(type, "OnTriggerEnter", 1, typeof(EntityHandle)))
			code.Append("mContacts |= .TriggerEnter;\n");
		if (Overrides(type, "OnTriggerExit", 1, typeof(EntityHandle)))
			code.Append("mContacts |= .TriggerExit;\n");
		if (!code.IsEmpty)
			Compiler.MixinRoot(code);
	}

	/// Whether `type`, or a class between it and Behaviour, declares the callback `name`
	/// (`paramCount` parameters, the first a `firstParam`). The walk runs from `type` down
	/// through its bases, so Behaviour's own empty virtual is the one declaration that does
	/// not count.
	[Comptime]
	private static bool Overrides(Type type, StringView name, int paramCount, Type firstParam)
	{
		let instance = type as TypeInstance;
		if (instance == null)
			return false;
		for (let method in instance.GetMethods(.Instance | .Public | .NonPublic))
		{
			if ((method.Name != name) || (method.ParamCount != paramCount) || (method.GetParamType(0) != firstParam))
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
		instance.Attach(Scene, entity, this);
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
			instance.Attach(Scene, entity, this);
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
	/// or, during a pass or a hold, as the last of them ends.
	private void Retire(T instance)
	{
		instance.Release();
		instance.Detach();
		if (mInPass || (mHolds > 0))
			mRetired.Add(instance);
		else
			delete instance;
	}

	private void DeleteRetired()
	{
		for (let instance in mRetired)
			delete instance;
		mRetired.Clear();
	}

	// ---- the system's pass ----

	protected internal override bool TicksUpdate => mTicksUpdate;
	protected internal override bool TicksFixedUpdate => mTicksFixedUpdate;
	protected internal override bool TicksLateUpdate => mTicksLateUpdate;
	protected internal override ContactCallbacks Contacts => mContacts;

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
		if (mHolds == 0)
			DeleteRetired();
	}

	protected internal override void Hold()
	{
		mHolds++;
	}

	protected internal override void Unhold()
	{
		if ((--mHolds == 0) && !mInPass)
			DeleteRetired();
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

	protected internal override void DeliverContact(EntityHandle self, EntityHandle other, ContactKind kind,
		Float3 point, Float3 normal, float speed)
	{
		ContactCallbacks callback = .None;
		switch (kind)
		{
		case .Begin: callback = .ContactBegin;
		case .End: callback = .ContactEnd;
		case .TriggerEnter: callback = .TriggerEnter;
		case .TriggerExit: callback = .TriggerExit;
		}
		if (!mContacts.HasFlag(callback))
			return;

		// The live instance, not the pass's: one removed since the contact is gone, and one
		// added since has not started.
		let instance = Get(self);
		if ((instance == null) || !instance.Ticks)
			return;
		switch (kind)
		{
		case .Begin: instance.[Friend]OnContactBegin(other, point, normal, speed);
		case .End: instance.[Friend]OnContactEnd(other, point, normal, speed);
		case .TriggerEnter: instance.[Friend]OnTriggerEnter(other);
		case .TriggerExit: instance.[Friend]OnTriggerExit(other);
		}
	}

	// ---- replication ----

	/// Its class's [Replicated] fields travel with a networked entity, in the bytes
	/// BehaviourReplication describes. Every manager is a source, one whose class marks no
	/// field writing nothing, so a peer never reads its records as reflected fields.
	public override IReplicatedStateSource AsReplicatedStateSource => this;

	/// `entity`'s replicated fields, live; false when it has no `T` or its class marks none.
	public bool WriteReplicatedState(EntityHandle entity, List<uint8> outState)
	{
		outState.Clear();
		let instance = Get(entity);
		if (instance == null)
			return false;
		let stream = scope MemoryStream();
		let writer = scope BinaryWriter(stream);
		uint32 count = 0;
		writer.Write(count); // patched below
		EmitWriteReplicated(typeof(T));
		if (count == 0)
			return false;
		let bytes = stream.Bytes;
		*(uint32*)bytes.Ptr = count;
		outState.AddRange(bytes);
		return writer.IsOk;
	}

	/// Writes a peer's values into `entity`'s `T`, straight into its fields: nothing is called,
	/// as a script's replicated property is set without a callback, so a behaviour that reacts
	/// to a change compares with what it last saw. An entry whose name or kind matches no
	/// replicated field of `T` is passed over; one cut short stops the read, and what came
	/// before it stays applied.
	public void ReadReplicatedState(EntityHandle entity, Span<uint8> state)
	{
		let instance = Get(entity);
		if (instance == null)
			return;
		let stream = scope MemoryStream();
		stream.Write(state);
		stream.Seek(0, .Begin);
		let reader = scope BinaryReader(stream);
		uint32 count = 0;
		if (!reader.Read(out count))
			return;
		let text = scope String();
		for (uint32 i < count)
		{
			uint64 hash = 0;
			uint8 kind = 0;
			reader.Read(out hash);
			reader.Read(out kind);
			var value = ReplicatedValue();
			if (!BehaviourReplication.ReadValue(reader, (ReplicatedKind)kind, ref value, text))
				return; // cut short: nothing half read is applied
			EmitReadReplicated(typeof(T));
		}
	}

	/// One write per [Replicated] field of `type`, in declaration order, base first, its name's
	/// hash baked in. [BehaviourAttribute] has already refused a field of a kind the wire does
	/// not carry; one here is passed over all the same, so this emits only what compiles.
	/// Private fields are reached past their protection: replication is the manager's to do.
	[Comptime]
	private static void EmitWriteReplicated(Type type)
	{
		if (!(type is TypeInstance))
			return;
		let fields = scope List<FieldInfo>();
		BehaviourReplication.ReplicatedFields(type, fields);
		let code = scope String();
		for (let field in fields)
		{
			if (!field.IsInstanceField || (BehaviourReplication.KindOf(field.FieldType) == .None))
				continue;
			code.Append("BehaviourReplication.Write(writer, ");
			BehaviourReplication.FieldHash(field.Name).ToString(code);
			code.Append("UL, instance.[Friend]");
			code.Append(field.Name);
			code.Append(");\ncount++;\n");
		}
		if (!code.IsEmpty)
			Compiler.MixinRoot(code);
	}

	/// The match per [Replicated] field of `type`: the entry's hash and kind against the
	/// field's, the value into the field when both agree. A String field takes the text into
	/// its own String (a null one is left alone: the instance owns what it holds).
	[Comptime]
	private static void EmitReadReplicated(Type type)
	{
		if (!(type is TypeInstance))
			return;
		let fields = scope List<FieldInfo>();
		BehaviourReplication.ReplicatedFields(type, fields);
		let code = scope String();
		for (let field in fields)
		{
			let kind = BehaviourReplication.KindOf(field.FieldType);
			if (!field.IsInstanceField || (kind == .None))
				continue;
			code.Append("if ((hash == ");
			BehaviourReplication.FieldHash(field.Name).ToString(code);
			// By number: the emitted line needs no enum name looked up at compile time.
			code.Append("UL) && (value.Kind == (ReplicatedKind)");
			((int)kind).ToString(code);
			code.Append("))\n{\n");
			let target = scope String();
			target.Append("instance.[Friend]");
			target.Append(field.Name);
			switch (kind)
			{
			case .Bool: code.Append(target); code.Append(" = value.BoolValue;\n");
			case .Int: code.Append(target); code.Append(" = value.IntValue;\n");
			case .Float: code.Append(target); code.Append(" = value.FloatValue;\n");
			case .Float3: code.Append(target); code.Append(" = value.VectorValue;\n");
			case .Color: code.Append(target); code.Append(" = value.ColorValue;\n");
			case .String:
				code.Append("if (");
				code.Append(target);
				code.Append(" != null)\n");
				code.Append(target);
				code.Append(".Set(text);\n");
			default:
			}
			code.Append("continue;\n}\n");
		}
		if (!code.IsEmpty)
			Compiler.MixinRoot(code);
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

using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;

namespace Sedulous.Resource.Tests;

/// What a component stores, and what of it reaches the file.
class RefTests
{
	/// ONLY the identity is serialized. The binding and the direct override are runtime
	/// state, so a component read from a file arrives unbound and is bound afterwards.
	[Test]
	public static void OnlyTheIdentityCrossesTheWire()
	{
		let id = Guid.Create();
		let stream = scope MemoryStream();

		{
			let component = scope TestComponent();
			component.SortOrder = 3;
			component.Mesh.SetId(id);

			let writer = scope BinarySerializer(stream, .Write);
			Serialize(writer, (ISerializable)component);
			Test.Assert(writer.IsOk);
		}

		// int32 plus a raw guid, and nothing else: the reference costs exactly what a bare
		// identity field would.
		Test.Assert(stream.Size() == 4 + 16, scope $"wrote {stream.Size()} bytes");

		Test.Assert(stream.Seek(0, .Begin) == 0);
		let loaded = scope TestComponent();
		{
			let reader = scope BinarySerializer(stream, .Read);
			Serialize(reader, (ISerializable)loaded);
			Test.Assert(reader.IsOk);
		}

		Test.Assert(loaded.SortOrder == 3);
		Test.Assert(loaded.Mesh.Id == id);
		Test.Assert(!loaded.Mesh.IsBound, "it arrives unbound");
		Test.Assert(loaded.Mesh.Get == null);
	}

	/// An object made in code has no identity, is never serialized, and wins over the
	/// binding for as long as it is set.
	[Test]
	public static void ADirectOverrideWinsAndIsNotSerialized()
	{
		let fixture = scope ResourceFixture("scratch_ref_direct");
		let factory = scope TestProductFactory();
		fixture.Manager.AddFactory(factory);

		let id = fixture.Author("mesh", 2, 2);

		// The creator owns it, which is the contract: a struct field cannot release it.
		let procedural = scope TestProduct();
		procedural.Area = 999;

		var reference = Ref<TestProduct>(id);
		reference.Bind(fixture.Manager);
		Test.Assert(reference.Get.Area == 4, "the bound resource");

		reference.SetDirect(procedural);
		Test.Assert(reference.Get.Area == 999, "the override wins");

		// And it does not reach the file: only the identity does.
		let stream = scope MemoryStream();
		{
			let writer = scope BinarySerializer(stream, .Write);
			reference.Serialize(writer);
		}
		Test.Assert(stream.Size() == 16, "a guid, and nothing of the override");
	}

	/// Replaying over a LIVE component, which is what a paste or an undo does. A changed
	/// identity must drop the stale binding, and a NIL identity must actually unbind, or
	/// the previous resource carries on being shown by something told to stop.
	[Test]
	public static void ReadingADifferentIdentityDropsTheStaleBinding()
	{
		let fixture = scope ResourceFixture("scratch_ref_replay");
		let factory = scope TestProductFactory();
		fixture.Manager.AddFactory(factory);

		let first = fixture.Author("a", 2, 2);
		let second = fixture.Author("b", 3, 3);

		var live = Ref<TestProduct>(first);
		live.Bind(fixture.Manager);
		Test.Assert(live.Get.Area == 4);
		Test.Assert(live.IsBound);

		// A blob naming a DIFFERENT resource replays over it.
		let stream = scope MemoryStream();
		{
			var incoming = Ref<TestProduct>(second);
			let writer = scope BinarySerializer(stream, .Write);
			incoming.Serialize(writer);
		}
		Test.Assert(stream.Seek(0, .Begin) == 0);
		{
			let reader = scope BinarySerializer(stream, .Read);
			live.Serialize(reader);
		}

		Test.Assert(live.Id == second);
		Test.Assert(!live.IsBound, "the stale binding went");
		Test.Assert(live.Get == null, "and it does not still show the old resource");

		live.Bind(fixture.Manager);
		Test.Assert(live.Get.Area == 9, "rebinding reaches the new one");
	}

	/// The case worth calling out specifically: reading a nil identity has to unbind, not
	/// leave the old resource in place.
	[Test]
	public static void ReadingANilIdentityUnbinds()
	{
		let fixture = scope ResourceFixture("scratch_ref_nil");
		let factory = scope TestProductFactory();
		fixture.Manager.AddFactory(factory);

		var live = Ref<TestProduct>(fixture.Author("a", 2, 2));
		live.Bind(fixture.Manager);
		Test.Assert(live.Get != null);

		let stream = scope MemoryStream();
		{
			var cleared = Ref<TestProduct>(Guid.Empty);
			let writer = scope BinarySerializer(stream, .Write);
			cleared.Serialize(writer);
		}
		Test.Assert(stream.Seek(0, .Begin) == 0);
		{
			let reader = scope BinarySerializer(stream, .Read);
			live.Serialize(reader);
		}

		Test.Assert(live.Id == Guid.Empty);
		Test.Assert(live.Get == null, "cleared, not still rendering the previous resource");
	}

	/// Rebind drops the override as well as the binding, which is what an editor picker
	/// assigning a different asset needs.
	[Test]
	public static void RebindDropsTheOverride()
	{
		let fixture = scope ResourceFixture("scratch_ref_rebind");
		let factory = scope TestProductFactory();
		fixture.Manager.AddFactory(factory);

		let procedural = scope TestProduct();
		procedural.Area = 999;

		var reference = Ref<TestProduct>(fixture.Author("a", 2, 2));
		reference.SetDirect(procedural);
		Test.Assert(reference.Get.Area == 999);

		reference.Rebind(fixture.Manager);
		Test.Assert(reference.Get.Area == 4, "the override went and the identity resolved");
	}

	/// A reference that names nothing is inert rather than dangerous.
	[Test]
	public static void AnUnsetReferenceIsHarmless()
	{
		Ref<TestProduct> reference = default;
		Test.Assert(reference.Id == Guid.Empty);
		Test.Assert(!reference.HasValue);
		Test.Assert(reference.Get == null);
		Test.Assert(!reference.IsBound);
		Test.Assert(reference.State == .Unloaded);

		// Binding with no manager, or no identity, does nothing.
		reference.Bind(null);
		Test.Assert(!reference.IsBound);
	}

	/// A Ref<T> is reference shaped: through its run time reflection, knowing only its type and
	/// address, a tool reads the identity, and a write either drops the stale binding (no
	/// manager) or rebinds it to the new identity.
	[Test]
	public static void AReferenceIsReadAndWrittenByIdentityWithoutNamingItsType()
	{
		let fixture = scope ResourceFixture("scratch_ref_shape");
		let factory = scope TestProductFactory();
		fixture.Manager.AddFactory(factory);
		let first = fixture.Author("a", 2, 2);
		let second = fixture.Author("b", 3, 3);

		var reference = Ref<TestProduct>(first);
		reference.Bind(fixture.Manager);
		Test.Assert(reference.Get.Area == 4);
		let type = typeof(Ref<TestProduct>);
		Test.Assert(ReferenceShape.Is(type));
		Test.Assert(!ReferenceShape.Is(typeof(Guid)));
		Test.Assert(!ReferenceShape.Is(typeof(TestComponent)));
		Test.Assert(ReferenceShape.Id(type, &reference) case .Ok(first));

		// With a manager: the identity lands and the binding follows it.
		Test.Assert(ReferenceShape.Assign(type, &reference, second, fixture.Manager) case .Ok);
		Test.Assert(reference.Id == second);
		Test.Assert(reference.IsBound);
		Test.Assert(reference.Get.Area == 9, "bound to the new resource");

		// With none: the identity lands and the stale binding and any override go.
		let procedural = scope TestProduct();
		reference.SetDirect(procedural);
		Test.Assert(ReferenceShape.Assign(type, &reference, first, null) case .Ok);
		Test.Assert(reference.Id == first);
		Test.Assert(!reference.IsBound);
		Test.Assert(reference.Get == null, "the override went with the binding");

		// Reached as a component field is: the field's type and its address inside the owner.
		let component = scope TestComponent();
		component.Mesh.SetId(second);
		let field = typeof(TestComponent).GetField("Mesh").Value;
		let address = (uint8*)Internal.UnsafeCastToPtr(component) + field.MemberOffset;
		Test.Assert(ReferenceShape.Is(field.FieldType));
		Test.Assert(ReferenceShape.Id(field.FieldType, address) case .Ok(second));
	}

	/// A reference as a LIST element: walked through IReflectedList and read through
	/// ReferenceShape, the element type and address standing in for a field's.
	[Test]
	public static void AReferenceInAListIsReadByIdentity()
	{
		let first = Guid.Create();
		let second = Guid.Create();
		let materials = scope List<Ref<TestProduct>>();
		materials.Add(Ref<TestProduct>(first));
		materials.Add(Ref<TestProduct>(Guid()));
		materials.Add(Ref<TestProduct>(second));

		let list = (Object)materials as IReflectedList;
		Test.Assert(list != null);
		Test.Assert(ReferenceShape.Is(list.ElementType));
		Test.Assert(ReferenceShape.Id(list.ElementType, list.ElementAddress(0)) case .Ok(first));
		Test.Assert(ReferenceShape.Id(list.ElementType, list.ElementAddress(1)) case .Ok(Guid()), "an unset element reads nil");
		Test.Assert(ReferenceShape.Id(list.ElementType, list.ElementAddress(2)) case .Ok(second));
		Test.Assert(ReferenceShape.Assign(list.ElementType, list.ElementAddress(1), first, null) case .Ok);
		Test.Assert(materials[1].Id == first, "written in place");
	}
}

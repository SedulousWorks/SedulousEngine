using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Core.Tests;

/// SchemaRecorder: what a Serialize body writes, recorded in order with kinds, defaults,
/// nesting, text, guids, blobs and the versioned payload's chain: the wire format taken from
/// the writer.
class SchemaRecorderTests
{
	enum Motion : uint8
	{
		case Static = 0;
		case Kinematic = 1;
		case Dynamic = 2;
	}

	struct Inner : ISerializable
	{
		public int32 Depth = 3;
		public bool Lit = false;

		public this() {}

		public void Serialize(ISerializer ar) mut
		{
			ar.BeginObject();
			SerializeValue(ar, "depth", ref Depth);
			SerializeValue(ar, "lit", ref Lit);
			ar.EndObject();
		}
	}

	class Probe
	{
		public Motion Motion = .Dynamic;
		public float Speed = 1.5f;
		public bool On = true;
		public int64 Big = -7;
		public uint16 Small = 65535;
		public String Name = new .("lamp") ~ delete _;
		public Guid Id = Guid.Parse("855ffed4-4da7-4fa0-9756-a95c6c842890").Value;
		public Inner Inner = .();
		public List<float> Weights = new .() { 0.25f, 0.75f } ~ delete _;
		public List<Inner> Items = new .() { .(), .() } ~ delete _;
		public uint8[5] Bytes = .();

		/// The body writes an enum as a raw byte, the way real components do.
		public void Serialize(ISerializer ar)
		{
			var motion = (uint8)Motion;
			SerializeValue(ar, "motion", ref motion);
			Motion = (Motion)motion;
			SerializeValue(ar, "speed", ref Speed);
			SerializeValue(ar, "on", ref On);
			SerializeValue(ar, "big", ref Big);
			SerializeValue(ar, "small", ref Small);
			ar.Key("name");
			ar.Text(Name);
			SerializeValue(ar, "id", ref Id);
			ar.Key("inner");
			Inner.Serialize(ar);
			ar.Key("weights");
			SerializeList(ar, Weights);
			ar.Key("items");
			uint32 count = (uint32)Items.Count;
			ar.BeginArray(ref count);
			for (int i < Items.Count)
				Items[i].Serialize(ar);
			ar.EndArray();
			ar.Key("bytes");
			ar.Blob(&Bytes, Bytes.Count);
		}
	}

	[Test]
	public static void ABodysKeysKindsDefaultsAndNestingAreRecordedInWriteOrder()
	{
		let ar = scope SchemaRecorder();
		Test.Assert(ar.Mode == .Write);
		let probe = scope Probe();
		probe.Serialize(ar);
		Test.Assert(ar.IsOk);
		let root = ar.Root;
		Test.Assert(root.Kind == .Object);
		Test.Assert(root.Children.Count == 11);

		// Order is the writer's order, and the enum is what the writer wrote: a byte with value 2.
		Test.Assert(root.At(0).Key == "motion");
		Test.Assert(root.At(0).Kind == .Scalar);
		Test.Assert(root.At(0).Scalar == .UInt8);
		Test.Assert(root.At(0).Value == "2");
		Test.Assert(root.At(1).Key == "speed");
		Test.Assert(root.At(1).Scalar == .Float32);
		Test.Assert(root.At(1).Value == "1.5");
		Test.Assert(root.Find("on").Scalar == .Bool);
		Test.Assert(root.Find("on").Value == "true");
		Test.Assert(root.Find("big").Scalar == .Int64);
		Test.Assert(root.Find("big").Value == "-7");
		Test.Assert(root.Find("small").Scalar == .UInt16);
		Test.Assert(root.Find("small").Value == "65535");
		// Text and guid are first class.
		Test.Assert(root.Find("name").Kind == .Text);
		Test.Assert(root.Find("name").Value == "lamp");
		Test.Assert(root.Find("id").Kind == .Guid);
		Test.Assert(root.Find("id").Value == "855ffed4-4da7-4fa0-9756-a95c6c842890");
		// A nested object carries its own fields.
		let inner = root.Find("inner");
		Test.Assert((inner != null) && (inner.Kind == .Object) && (inner.Children.Count == 2));
		Test.Assert((inner.At(0).Key == "depth") && (inner.At(0).Value == "3"));
		Test.Assert((inner.At(1).Key == "lit") && (inner.At(1).Value == "false"));
		// An array records its count and every element written, unkeyed.
		let weights = root.Find("weights");
		Test.Assert((weights != null) && (weights.Kind == .Array) && (weights.Count == 2));
		Test.Assert(weights.Children.Count == 2);
		Test.Assert(weights.At(0).Key.IsEmpty);
		Test.Assert(weights.At(0).Scalar == .Float32);
		Test.Assert(weights.At(1).Value == "0.75");
		let items = root.Find("items");
		Test.Assert((items != null) && (items.Count == 2) && (items.Children.Count == 2));
		Test.Assert(items.At(1).Kind == .Object);
		Test.Assert(items.At(1).Find("depth").Value == "3");
		// A blob records its size only.
		Test.Assert(root.Find("bytes").Kind == .Blob);
		Test.Assert(root.Find("bytes").BlobSize == 5);
		Test.Assert(root.Find("nobody") == null);
		Test.Assert(root.At(11) == null);
		// Nothing was versioned.
		Test.Assert(ar.VersionChain.IsEmpty);
	}

	[Test]
	public static void AVersionedPayloadsChainIsRecordedAsPushedAndTheFieldsFollowTheDataVersionsArray()
	{
		let ar = scope SchemaRecorder();
		BeginVersionedPayload(ar, 0xABCDUL, 4);
		var depth = (int32)9;
		SerializeValue(ar, "depth", ref depth);
		EndVersionedPayload(ar);
		Test.Assert(ar.IsOk);

		// The chain: the concrete type's id and its data version.
		Test.Assert(ar.VersionChain.Length == 1);
		Test.Assert(ar.VersionChain[0].TypeId == 0xABCDUL);
		Test.Assert(ar.VersionChain[0].Version == 4);
		// And the recording shows what the wire carries first: the dataVersions array of type
		// and version pairs, written flat per entry, then the body's fields.
		let root = ar.Root;
		Test.Assert(root.Children.Count == 2);
		Test.Assert(root.At(0).Key == "dataVersions");
		Test.Assert(root.At(0).Kind == .Array);
		Test.Assert(root.At(0).Count == 1);
		Test.Assert(root.At(0).Children.Count == 2);
		Test.Assert(root.At(0).At(0).Key == "type");
		Test.Assert(root.At(0).At(0).Scalar == .UInt64);
		Test.Assert(root.At(0).At(0).Value == scope $"{0xABCDUL}");
		Test.Assert(root.At(0).At(1).Key == "version");
		Test.Assert((root.At(1).Key == "depth") && (root.At(1).Value == "9"));

		// A second, inner versioned payload does not replace the outermost chain.
		let nested = scope SchemaRecorder();
		SerializedDataVersion[2] outer = .(.(111, 3), .(222, 5));
		nested.PushVersionScope(outer);
		SerializedDataVersion[1] innerChain = .(.(333, 1));
		nested.PushVersionScope(innerChain);
		nested.PopVersionScope();
		nested.PopVersionScope();
		Test.Assert(nested.VersionChain.Length == 2);
		Test.Assert(nested.VersionChain[1].TypeId == 222);
	}

	[Test]
	public static void ScalarTextSpellsEveryKindTheWayADefaultReads()
	{
		var t = true;
		var i8v = (int8)-3;
		var u8v = (uint8)200;
		var i16v = (int16)-300;
		var u16v = (uint16)60000;
		var i32v = (int32)-70000;
		var u32v = (uint32)4000000000;
		var i64v = (int64)-5000000000;
		var u64v = (uint64)18000000000000000000;
		var f32v = 0.5f;
		var f64v = -2.25;
		Test.Assert(SchemaRecorder.ScalarText(&t, .Bool, .. scope .()) == "true");
		Test.Assert(SchemaRecorder.ScalarText(&i8v, .Int8, .. scope .()) == "-3");
		Test.Assert(SchemaRecorder.ScalarText(&u8v, .UInt8, .. scope .()) == "200");
		Test.Assert(SchemaRecorder.ScalarText(&i16v, .Int16, .. scope .()) == "-300");
		Test.Assert(SchemaRecorder.ScalarText(&u16v, .UInt16, .. scope .()) == "60000");
		Test.Assert(SchemaRecorder.ScalarText(&i32v, .Int32, .. scope .()) == "-70000");
		Test.Assert(SchemaRecorder.ScalarText(&u32v, .UInt32, .. scope .()) == "4000000000");
		Test.Assert(SchemaRecorder.ScalarText(&i64v, .Int64, .. scope .()) == "-5000000000");
		Test.Assert(SchemaRecorder.ScalarText(&u64v, .UInt64, .. scope .()) == "18000000000000000000");
		Test.Assert(SchemaRecorder.ScalarText(&f32v, .Float32, .. scope .()) == "0.5");
		Test.Assert(SchemaRecorder.ScalarText(&f64v, .Float64, .. scope .()) == "-2.25");
		// A float that has no short decimal still reads as the float it is, not its double widening.
		var tenth = 0.1f;
		Test.Assert(SchemaRecorder.ScalarText(&tenth, .Float32, .. scope .()) == "0.1");
	}
}

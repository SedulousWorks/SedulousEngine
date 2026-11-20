using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Script.Resource;
using Sedulous.VFS;

namespace Sedulous.Script.Resource.Tests;

/// The cooked record round trips with every property kind, the product is built from it,
/// and the type registers under the name an instance stores.
static class ScriptClassResourceTests
{
	private static ScriptPropertyDesc Property(StringView name, ScriptPropertyType type, ScriptPropertyValue value, StringView assetType = "")
	{
		let p = new ScriptPropertyDesc();
		p.Name.Set(name);
		p.Hash = ScriptPropertyNames.HashOf(name);
		p.Type = type;
		p.AssetType.Set(assetType);
		p.Default = value;
		return p;
	}

	private static ScriptClassSource Authored()
	{
		let source = new ScriptClassSource();
		source.Language.Set("angelscript");
		source.ClassName.Set("Mover");
		source.SourceName.Set("Mover.as");
		source.Source.Set("class Mover { float speed = 2; void onUpdate(float dt) {} }");
		source.Properties.Add(Property("speed", .Float, .Float(2)));
		source.Properties.Add(Property("lives", .Int, .Int(3)));
		source.Properties.Add(Property("armed", .Bool, .Bool(true)));
		source.Properties.Add(Property("label", .String, .Str(new String("hello"))));
		source.Properties.Add(Property("tint", .Color, .Colour(.(1, 0, 0, 1))));
		source.Properties.Add(Property("offset", .Vec3, .Vec3(.(1, 2, 3))));
		source.Properties.Add(Property("target", .Entity, .Entity(Guid.Create())));
		source.Properties.Add(Property("clip", .Asset, .Asset(Guid.Create()), "AudioClip"));
		source.Handlers.Add(new String("onStart"));
		source.Handlers.Add(new String("onUpdate"));
		source.UsesCoroutines = true;
		source.Kind = .Entity;
		return source;
	}

	[Test]
	public static void TheRecordRoundTripsEveryKind()
	{
		let authored = Authored();
		defer delete authored;

		let buffer = scope MemoryStream();
		{
			let writer = scope BinarySerializer(buffer, .Write);
			((ISerializable)authored).Serialize(writer);
			Test.Assert(writer.IsOk);
		}
		buffer.Seek(0, .Begin);
		let read = scope ScriptClassSource();
		{
			let reader = scope BinarySerializer(buffer, .Read);
			((ISerializable)read).Serialize(reader);
			Test.Assert(reader.IsOk);
		}

		Test.Assert(read.Language == "angelscript");
		Test.Assert(read.ClassName == "Mover");
		Test.Assert(read.SourceName == "Mover.as");
		Test.Assert(read.Source == authored.Source);
		Test.Assert(read.Properties.Count == 8);
		for (int i = 0; i < 8; i++)
		{
			let a = authored.Properties[i];
			let b = read.Properties[i];
			Test.Assert(b.Name == a.Name);
			Test.Assert(b.Hash == a.Hash, "the hash is rebuilt from the name on read");
			Test.Assert(b.Type == a.Type);
			Test.Assert(b.AssetType == a.AssetType);
			Test.Assert(b.Default.Equals(a.Default), a.Name);
		}
		Test.Assert(read.Properties[3].Default.Text == "hello");
		Test.Assert((read.Handlers.Count == 2) && (read.Handlers[1] == "onUpdate"));
		Test.Assert(read.UsesCoroutines);
		Test.Assert(read.Kind == .Entity);
	}

	[Test]
	public static void TheProductIsBuiltFromTheRecord()
	{
		let source = Authored();
		defer delete source;
		let product = scope ScriptClass();
		product.From(source);

		Test.Assert(product.ClassName == "Mover");
		Test.Assert(!product.IsModule);
		Test.Assert(product.HasHandler("onUpdate") && !product.HasHandler("onDestroy"));
		Test.Assert(product.FindProperty("speed").Default.Number == 2);
		Test.Assert(product.FindProperty(ScriptPropertyNames.HashOf("clip")).AssetType == "AudioClip");
		Test.Assert(product.FindProperty("nope") == null);
		Test.Assert(product.FindProperty("label").Default.Text == "hello");
		Test.Assert(product.FindProperty("label").Default.Text !== source.Properties[3].Default.Text, "the product owns its copy");
		Test.Assert(product.ProfileName == "Script Mover");
		Test.Assert(product.Kind == .Entity);

		source.ClassName.Clear();
		product.From(source);
		Test.Assert(product.IsModule && (product.ProfileName == "Script (module)"));
	}

	[Test]
	public static void PropertyTypesParse()
	{
		let assetType = scope String();
		Test.Assert(ScriptPropertyNames.Parse("float", let f, assetType) && (f == .Float));
		Test.Assert(ScriptPropertyNames.Parse("entity", let e, assetType) && (e == .Entity));
		Test.Assert(ScriptPropertyNames.Parse("asset:AudioClip", let a, assetType) && (a == .Asset) && (assetType == "AudioClip"));
		Test.Assert(!ScriptPropertyNames.Parse("asset:", let none, assetType));
		Test.Assert(!ScriptPropertyNames.Parse("double", let d, assetType) && (d == .None));
		// The table reads both ways: every spelling parses back to its kind.
		for (let entry in ScriptPropertyNames.TypeNames)
		{
			Test.Assert(ScriptPropertyNames.TypeName(entry.Kind) == entry.Name);
			let text = (entry.Kind == .Asset) ? scope:: $"{ScriptPropertyNames.cAssetTypePrefix}Texture" : entry.Name;
			Test.Assert(ScriptPropertyNames.Parse(text, let kind, assetType) && (kind == entry.Kind));
		}
		Test.Assert(ScriptPropertyNames.TypeName(.None).IsEmpty);
		Test.Assert(ScriptPropertyNames.HashOf("speed") == ScriptPropertyNames.HashOf("speed"));
		Test.Assert(ScriptPropertyNames.HashOf("speed") != ScriptPropertyNames.HashOf("Speed"));
	}

	/// A record cooked before each property carried its replicated flag (no data version), before
	/// it carried its included files (version 1), before it named its assembly (version 2), or
	/// before it recorded its behavior kind (version 3), is in another layout. Read as this one it misread its counts (it could hold the editor for
	/// minutes opening a scene); the data version refuses it, and the script recooks.
	[Test]
	public static void ARecordCookedBeforeTheReplicatedFlagTheIncludesTheAssemblyOrTheKindIsRefused()
	{
		Test.Assert(ScriptClassSource.DataVersion == 4);

		let old = scope UnversionedScriptRecord();
		old.Language.Set("angelscript");
		old.ClassName.Set("Mover");
		old.Properties.Add(Property("speed", .Float, .Float(2)));
		AssertRefused(old);

		for (uint32 stale = 1; stale < ScriptClassSource.DataVersion; stale++)
		{
			let versioned = scope StaleScriptRecord(stale);
			versioned.Language.Set("angelscript");
			versioned.ClassName.Set("Mover");
			versioned.Properties.Add(Property("speed", .Float, .Float(2)));
			AssertRefused(versioned);
		}
	}

	private static void AssertRefused(ISerializable stale)
	{
		let buffer = scope MemoryStream();
		{
			let writer = scope BinarySerializer(buffer, .Write);
			stale.Serialize(writer);
			Test.Assert(writer.IsOk);
		}
		buffer.Seek(0, .Begin);

		let read = scope ScriptClassSource();
		let reader = scope BinarySerializer(buffer, .Read);
		((ISerializable)read).Serialize(reader);
		Test.Assert(!reader.IsOk, "the stale record was refused");
		Test.Assert(read.Language.IsEmpty && read.Properties.IsEmpty, "and left unread");
	}

	/// A class built into its project's assembly names the assembly in its cooked record; the
	/// factory binds the assembly's product beside the class, its image and symbols whole, and the
	/// class keeps its source. The assembly's class descriptions read back with its record, for
	/// the cook of each class's asset.
	[Test]
	public static void AClassBuiltIntoAProjectAssemblyBindsTheAssembly()
	{
		let root = "scratch_scriptres_assembly";
		RemoveDirectoryRecursive(root);
		CreateDirectory(root);
		defer { RemoveDirectoryRecursive(root); }
		ScriptResources.RegisterAll(); // a read constructs its record by the stored type's name

		let mount = scope NativeFileSystem(root);
		SerializerFactory serializers = scope (stream, mode) => new BinarySerializerContext(stream, mode);
		let database = scope ContentDatabase(mount, serializers, "rasset");

		let assembly = scope ScriptAssemblySource();
		assembly.Language.Set("stand-in");
		assembly.Image.Add(0x4D);
		assembly.Image.Add(0x5A);
		assembly.Image.Add(0x90);
		assembly.Symbols.Add(0x42);
		let mover = new ScriptAssemblyClass();
		mover.ClassName.Set("Mover");
		mover.Handlers.Add(new String("onUpdate"));
		assembly.Classes.Add(mover);
		let assemblyInstance = database.RootGroup.CreateInstance("assembly", typeof(ScriptAssemblySource).GetFullName(.. scope .()));
		Test.Assert(assemblyInstance != null);
		Test.Assert(assemblyInstance.WriteObject(assembly) case .Ok);

		let cooked = scope ScriptClassSource();
		cooked.Language.Set("stand-in");
		cooked.ClassName.Set("Mover");
		cooked.SourceName.Set("Mover.si");
		cooked.Source.Set("class Mover");
		cooked.Assembly = assemblyInstance.Id;
		let classInstance = database.RootGroup.CreateInstance("mover", typeof(ScriptClassSource).GetFullName(.. scope .()));
		Test.Assert(classInstance != null);
		Test.Assert(classInstance.WriteObject(cooked) case .Ok);

		// The record reads back with its classes, for the cook of each class's asset.
		{
			let read = assemblyInstance.ReadObject();
			defer delete read;
			let readBack = read as ScriptAssemblySource;
			Test.Assert(readBack != null);
			Test.Assert(readBack.FindClass("Mover") != null);
			Test.Assert(readBack.FindClass("Mover").Handlers.Count == 1);
			Test.Assert(readBack.FindClass("Nobody") == null);
		}

		let manager = scope ResourceManager(database, null);
		let classes = scope ScriptClassFactory();
		let assemblies = scope ScriptAssemblyFactory();
		ScriptResources.AddFactories(manager, classes, assemblies);
		let product = manager.Bind<ScriptClass>(classInstance.Id).Get;
		Test.Assert(product != null, "bound");
		Test.Assert(product.AssemblyId == assemblyInstance.Id);
		Test.Assert(product.Source == "class Mover", "the class keeps its source");
		Test.Assert(product.Assembly != null, "the assembly bound beside it");
		Test.Assert(product.Assembly.Language == "stand-in");
		Test.Assert((product.Assembly.Image.Count == 3) && (product.Assembly.Image[0] == 0x4D) && (product.Assembly.Image[2] == 0x90));
		Test.Assert((product.Assembly.Symbols.Count == 1) && (product.Assembly.Symbols[0] == 0x42));
		Test.Assert(product.Assembly === manager.Bind<ScriptAssembly>(assemblyInstance.Id).Get, "the assembly's own product, shared");

		// A class that cooks alone binds none.
		let alone = scope ScriptClassSource();
		alone.Language.Set("stand-in");
		alone.ClassName.Set("Loner");
		let aloneInstance = database.RootGroup.CreateInstance("loner", typeof(ScriptClassSource).GetFullName(.. scope .()));
		Test.Assert(aloneInstance.WriteObject(alone) case .Ok);
		let loner = manager.Bind<ScriptClass>(aloneInstance.Id).Get;
		Test.Assert((loner != null) && (loner.AssemblyId == Guid.Empty) && (loner.Assembly == null));
	}

	[Test]
	public static void TheResourceTypeRegisters()
	{
		let registry = scope SerializableRegistry();
		ScriptResources.RegisterAll(registry);
		Test.Assert(registry.IsRegistered(ScriptClassSource.TypeId));
		Test.Assert(registry.IsRegistered(TypeIdOf("Sedulous.Script.Resource.ScriptClassSource")));
		let created = registry.Create(ScriptClassSource.TypeId);
		defer delete created;
		Test.Assert(created is ScriptClassSource);
	}
}

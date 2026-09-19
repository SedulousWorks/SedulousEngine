using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Script.Resource;

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
		Test.Assert(ScriptPropertyNames.HashOf("speed") == ScriptPropertyNames.HashOf("speed"));
		Test.Assert(ScriptPropertyNames.HashOf("speed") != ScriptPropertyNames.HashOf("Speed"));
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

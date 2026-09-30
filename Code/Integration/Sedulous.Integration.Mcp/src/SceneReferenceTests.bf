using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Editor.Mcp;
using Sedulous.Editor.Project;
using Sedulous.Engine.Composition;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Pipeline.Registration;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Script.Resource;
using static Sedulous.Integration.Mcp.McpCalls;

namespace Sedulous.Integration.Mcp;

/// The scene format reference: the generated schema's joins, the example's round trip
/// through the real reader, the determinism contract, and the live surface every host serves.
static class SceneReferenceTests
{
	/// The builders (cooked form to asset type); the factory descriptions come from the engine
	/// composition, so nothing else is composed here. OWNED by the caller.
	private static SceneReference Generate()
	{
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(builders);
		return SceneReference.Generate(builders);
	}

	private static JsonValue Field(JsonValue fields, StringView key) => Named(fields, "key", key);

	[Test]
	public static void ThePhysicsSettingsBlockListsItsFieldsInWireOrderAndTheLookupFoldsCase()
	{
		let reference = Generate();
		defer delete reference;
		let physics = SceneReference.FindEntry(reference.Schema, "physics");
		Test.Assert(physics != null);
		Test.Assert(physics.Get("system").AsString() == "physics");
		Test.Assert(physics.Get("dataVersions").Count >= 1);
		Test.Assert(physics.Get("dataVersions").At(0).Get("typeName").AsString() == "physics");
		let fields = physics.Get("fields");
		Test.Assert(fields.At(0).Get("key").AsString() == "gravity", "wire order, not declaration order alone");
		let groupNames = Field(fields, "groupNames");
		Test.Assert(groupNames != null);
		Test.Assert(groupNames.Get("kind").AsString() == "array");
		Test.Assert(groupNames.Get("count").AsNumber() == 0, "empty at default");
		Test.Assert(groupNames.Get("elementType").AsString() == "String");
		// Every key has a reflected field here, so nothing is unreflected; nested math values
		// (the gravity vector's x, y, z) have no reflected fields to miss either.
		Test.Assert(physics.Get("unreflected").Count == 0);
		// The lookup folds case and also answers to the settings type's name.
		Test.Assert(SceneReference.FindEntry(reference.Schema, "PHYSICS") != null);
		Test.Assert(SceneReference.FindEntry(reference.Schema, physics.Get("type").Get("name").AsString()) != null);
		Test.Assert(SceneReference.FindEntry(reference.Schema, "no-such-block") == null);
		// A key whose data does not live in a field of the component is listed: the spline's
		// points and closed flag are its curve's.
		let spline = SceneReference.FindEntry(reference.Schema, "spline");
		Test.Assert(HasString(spline.Get("unreflected"), "points"));
	}

	[Test]
	public static void EntityRefsAreRefEntityAndEveryResourceRefJoinsToItsAssetType()
	{
		let reference = Generate();
		defer delete reference;

		// mesh.mesh: Ref<StaticMesh>, the geometry module's description, StaticMeshSource, the
		// builder, its asset.
		let mesh = SceneReference.FindEntry(reference.Schema, "mesh");
		Test.Assert(mesh != null);
		let meshField = Field(mesh.Get("fields"), "mesh");
		Test.Assert(meshField.Get("kind").AsString() == "guid");
		Test.Assert(meshField.Get("ref").Get("resource").AsString() == "StaticMesh");
		Test.Assert(meshField.Get("ref").Get("asset").AsString() == "StaticMeshAsset");
		Test.Assert(!HasString(mesh.Get("unreflected"), "mesh"));

		// Entity references are ref: entity: a single one a guid field, a list of them an array
		// annotated through its element type (the animation mesh targets).
		bool sawEntityRef = false;
		bool sawEntityRefList = false;
		let components = reference.Schema.Get("components");
		for (int c < components.Count)
		{
			let fields = components.At(c).Get("fields");
			for (int i < fields.Count)
			{
				let field = fields.At(i);
				let reference2 = field.Get("ref");
				if ((reference2 != null) && (reference2.AsString() == "entity"))
				{
					let kind = field.Get("kind").AsString();
					Test.Assert((kind == "guid") || (kind == "array"));
					sawEntityRef |= kind == "guid";
					sawEntityRefList |= kind == "array";
				}
				// Every resource reference resolves: the composition describes a factory for each
				// runtime type a component references and a builder produces each cooked form, so
				// no host serves a resource name alone.
				if ((reference2 != null) && (reference2.Get("resource") != null))
					Test.Assert(reference2.Get("asset") != null, scope $"{field.Get("key").AsString()} names no asset");
			}
		}
		Test.Assert(sawEntityRef && sawEntityRefList);

		// Enum names ride along: the light's type field names its values; its range carries the
		// inspector's bounds; its colour is a math value, an object of r, g, b, a.
		let light = SceneReference.FindEntry(reference.Schema, "light");
		Test.Assert(Field(light.Get("fields"), "type").Get("enum").Count >= 2);
		Test.Assert(Field(light.Get("fields"), "range").Get("range").Get("max").AsNumber() == 500);
		Test.Assert(Field(light.Get("fields"), "intensity").Get("range").Get("step").AsNumber() == 0.1);
		Test.Assert(Field(light.Get("fields"), "color").Get("fields").Count == 4);
		Test.Assert(!HasString(light.Get("unreflected"), "r"));
	}

	[Test]
	public static void TheOverrideSectionsWorkedHashIsTheRealOneAndEveryKindNamesItsPayloadKey()
	{
		let reference = Generate();
		defer delete reference;
		let overrides = reference.Schema.Get("scriptOverrides");
		let example = overrides.Get("hash").Get("example");
		let name = example.Get("name").AsString();
		Test.Assert(!name.IsEmpty);
		Test.Assert(example.Get("nameHash").AsString() == ScriptPropertyNames.HashOf(name).ToString(.. scope .()));

		let kinds = overrides.Get("kinds");
		Test.Assert(kinds.Count == ScriptPropertyNames.TypeNames.Count);
		StringView PayloadKey(StringView kindName)
		{
			let kind = Named(kinds, "name", kindName);
			return (kind != null) ? kind.Get("payload").At(0).Get("key").AsString() : "";
		}
		Test.Assert(PayloadKey("float") == "number");
		Test.Assert(PayloadKey("bool") == "boolean");
		Test.Assert(PayloadKey("string") == "text");
		Test.Assert(PayloadKey("vec3") == "vector");
		Test.Assert(PayloadKey("entity") == "id");
		Test.Assert(PayloadKey("asset") == "id");
		// The record framing as the wire has it: the hash, then the value's tag inline, then the
		// payload key the tag selects.
		let record = overrides.Get("record");
		Test.Assert(record.Count == 2);
		Test.Assert((record.At(0).Get("key").AsString() == "nameHash") && (record.At(0).Get("kind").AsString() == "u64"));
		Test.Assert((record.At(1).Get("key").AsString() == "kind") && (record.At(1).Get("kind").AsString() == "u8"));
		// The example's behaviour carries one override per kind, hashed from "<kind>Value".
		Test.Assert(reference.ExampleXml.Contains(ScriptPropertyNames.HashOf("floatValue").ToString(.. scope .())));
	}

	[Test]
	public static void TheExampleLoadsThroughTheRealReaderAndSceneValidateFindsItValid()
	{
		let reference = Generate();
		defer delete reference;
		Test.Assert(!reference.ExampleXml.IsEmpty);

		// Through the real reader into the full composition, every record routed to a manager.
		let stream = scope MemoryStream();
		stream.Write(Span<uint8>((uint8*)reference.ExampleXml.Ptr, reference.ExampleXml.Length));
		stream.Seek(0, .Begin);
		let loaded = scope Scene("loaded");
		EngineSceneComposition.AddAllSceneManagers(loaded);
		let reader = scope SceneStreamReader();
		Test.Assert(reader.Open(stream) case .Ok(let ar));
		SceneSerializer.SerializeScene(ar, loaded, .Referenced, true, reader.Encoding);
		Test.Assert(ar.IsOk);
		Test.Assert(loaded.UnresolvedComponents.IsEmpty);
		// Root, Child, and one entity per serializable manager (the schema's components list).
		let components = reference.Schema.Get("components");
		Test.Assert(loaded.EntityCount == 2 + (uint32)components.Count);
		for (int i < components.Count)
			Test.Assert(components.At(i).Get("recorded") == null, "every manager took its default component");

		// Through the tool an agent loops on.
		let server = scope McpServer();
		let session = scope ProjectSession();
		SceneTools.Register(server, session);
		let report = CallOk(server, "scene_validate", With(Obj(), "xml", reference.ExampleXml));
		defer delete report;
		Test.Assert(report.Get("valid").AsBool());
		Test.Assert(report.Get("warnings").Count == 0, scope $"{report.Get("warnings").Count} warnings");
		Test.Assert(report.Get("entityCount").AsInt() == loaded.EntityCount);
	}

	[Test]
	public static void TwoGenerationsAreByteIdenticalAndTheFormatNamesTheStream()
	{
		let first = Generate();
		defer delete first;
		let second = Generate();
		defer delete second;
		Test.Assert(first.ExampleXml == second.ExampleXml);
		Test.Assert(first.SchemaJson == second.SchemaJson);
		Test.Assert(!first.SchemaJson.IsEmpty);
		// The format section names the stream as the writer lays it out.
		let format = first.Schema.Get("format");
		Test.Assert(format.Get("version").AsNumber() == 3);
		let sections = format.Get("sections");
		Test.Assert(sections.Count >= 6);
		Test.Assert(sections.At(0).Get("key").AsString() == "magic");
		Test.Assert(sections.At(1).Get("key").AsString() == "version");
		Test.Assert(sections.At(3).Get("key").AsString() == "entities");
		Test.Assert(sections.At(4).Get("key").AsString() == "components");
		Test.Assert(sections.At(5).Get("key").AsString() == "systemSettings");
	}

	[Test]
	public static void EngineToolsServesBothGeneratedResourcesAndComponentSchema()
	{
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(builders);
		let importers = scope ImporterRegistry();
		let logBuffer = scope EditorLogBuffer();
		let session = scope ProjectSession(); // the stdio host's shape: no project open
		let server = scope McpServer();
		let operations = scope InlineProjectOperations(session, builders, "", "");
		EngineTools.Register(server, session, builders, importers, scope AssetCreatorRegistry(), logBuffer, scope EngineToolPaths(), operations);

		let listed = Ask(server, "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"resources/list\"}");
		defer delete listed;
		let resources = listed.Get("result").Get("resources");
		Test.Assert(Named(resources, "uri", SceneReference.cExampleUri).Get("mimeType").AsString() == "application/xml");
		Test.Assert(Named(resources, "uri", SceneReference.cSchemaUri).Get("mimeType").AsString() == "application/json");

		// The served bytes are the generator's for this composition: deterministic, so a fresh
		// generation over the same registrations reproduces them.
		let expected = SceneReference.Generate(builders);
		defer delete expected;
		String Read(StringView uri, String outText)
		{
			let reply = Ask(server, scope $"{{\"jsonrpc\":\"2.0\",\"id\":7,\"method\":\"resources/read\",\"params\":{{\"uri\":\"{uri}\"}}}}");
			defer delete reply;
			outText.Set(reply.Get("result").Get("contents").At(0).Get("text").AsString());
			return outText;
		}
		Test.Assert(Read(SceneReference.cExampleUri, .. scope .()) == expected.ExampleXml);
		let served = Read(SceneReference.cSchemaUri, .. scope .());
		Test.Assert(served == expected.SchemaJson);
		// And that host resolves asset types like any other: the join reads the composition.
		let parsed = JsonValue.Parse(served);
		defer delete parsed;
		Test.Assert(Field(SceneReference.FindEntry(parsed, "mesh").Get("fields"), "mesh").Get("ref").Get("asset").AsString() == "StaticMeshAsset");

		// component_schema("light") is the light's entry; an unknown name errs and lists what
		// exists.
		let light = CallOk(server, "component_schema", With(Obj(), "type", "light"));
		defer delete light;
		Test.Assert(light.Get("wireName").AsString() == "light");
		Test.Assert(light.Get("type").Get("name").AsString() == "LightComponent");
		Test.Assert(light.Get("fields").Count > 0);
		let refused = CallErr(server, "component_schema", With(Obj(), "type", "no_such_component"), .. scope .());
		Test.Assert(refused.Contains("light"));
	}
}

using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Json;
using Sedulous.Scene.Resource;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Editor.Mcp;

/// The small helpers every editor tool shares: argument reads, the guid spelling, the
/// group walk, the two document type names, and the refusal an agent sees for a tool that
/// needs a project when none is open.
static class McpTools
{
	public const String cNoProject = "no project is open (call project_open first)";

	/// The content database type names of the two scene documents.
	public static readonly String cSceneDocument = typeof(SceneDocument).GetFullName(.. new String()) ~ delete _;
	public static readonly String cPrefabDocument = typeof(PrefabDocument).GetFullName(.. new String()) ~ delete _;

	/// A string argument, or empty when absent. The schema accepted the call already, so a
	/// missing optional field is simply not there.
	public static void ArgString(JsonValue arguments, StringView key, String outValue)
	{
		outValue.Clear();
		let value = arguments.Get(key);
		if ((value != null) && value.IsString)
			outValue.Set(value.AsString());
	}

	public static bool ArgBool(JsonValue arguments, StringView key, bool fallback = false)
	{
		let value = arguments.Get(key);
		return ((value != null) && value.IsBool) ? value.AsBool() : fallback;
	}

	public static double ArgNumber(JsonValue arguments, StringView key, double fallback = 0)
	{
		let value = arguments.Get(key);
		return ((value != null) && value.IsNumber) ? value.AsNumber() : fallback;
	}

	/// A Guid as its canonical 36 character string.
	public static JsonValue GuidToJson(Guid id) => JsonValue.MakeString(id.ToString(.. scope String()));

	/// Parses a guid argument, appending the refusal to outError when it is not one.
	public static bool ParseGuid(StringView text, String outError, out Guid id)
	{
		if (Guid.Parse(text) case .Ok(let parsed))
		{
			id = parsed;
			return true;
		}
		id = .Empty;
		outError.AppendF("invalid guid '{}'", text);
		return false;
	}

	/// {guid, name, type} for an instance.
	public static JsonValue InstanceToJson(Instance instance)
	{
		let entry = JsonValue.MakeObject();
		entry.Set("guid", GuidToJson(instance.Id));
		entry.Set("name", JsonValue.MakeString(instance.Name));
		entry.Set("type", JsonValue.MakeString(instance.TypeName));
		return entry;
	}

	/// Walks, creating as needed, a slash joined group path under `root` and returns the
	/// leaf; an empty path is the root itself.
	public static Group ResolveGroupPath(Group root, StringView path)
	{
		var group = root;
		for (let part in path.Split('/'))
		{
			if (!part.IsEmpty)
				group = group.CreateGroup(part);
		}
		return group;
	}

	/// The slash joined path of a group, empty at the root.
	public static void GroupPath(Group group, String outPath)
	{
		outPath.Clear();
		if ((group == null) || (group.Parent == null))
			return;
		GroupPath(group.Parent, outPath);
		if (!outPath.IsEmpty)
			outPath.Append('/');
		outPath.Append(group.Name);
	}

	/// Reads a whole stream as text. THE CALLER OWNS the stream still.
	public static bool ReadAllText(IStream stream, String outText)
	{
		outText.Clear();
		let size = (int)stream.Size();
		if (size <= 0)
			return true;
		let bytes = scope List<uint8>();
		bytes.Resize(size);
		if (stream.Read(bytes) != size)
			return false;
		outText.Append(StringView((char8*)bytes.Ptr, size));
		return true;
	}

	/// The instance's stored scene stream as text, false when it has none.
	public static bool ReadSceneStream(Instance instance, String outXml)
	{
		let stream = instance.ReadData(SceneStorage.cStreamName);
		if (stream == null)
			return false;
		defer delete stream;
		return ReadAllText(stream, outXml);
	}

	/// The read envelope as a pipeline Asset, or null: an interface reference reaches the
	/// class through the object it is.
	public static Asset AsAsset(ISerializable object)
	{
		if (object == null)
			return null;
		return Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as Asset;
	}

	public static bool IsSceneDocument(Instance instance) => instance.TypeName == cSceneDocument;
	public static bool IsPrefabDocument(Instance instance) => instance.TypeName == cPrefabDocument;
}

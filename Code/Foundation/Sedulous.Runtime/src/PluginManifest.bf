using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Xml.Serialization;

namespace Sedulous.Runtime;

/// The parts a package may have, named after the hosts that take them. A part's project is
/// `<Name>.<Kind>`, `<Name>` being the package's folder.
enum PluginPartKind : uint8
{
	/// The runtime half: every host.
	case Engine;
	/// Asset types, importers, builders, creators: the editor and the CLI tools.
	case Pipeline;
	/// Headless tooling (MCP tools, export hooks): the editor, Export and Mcp.
	case Tooling;
	/// Editor UI only.
	case Editor;

	public const int Count = 4;

	/// The kind a manifest names: exact and case sensitive, since the name is also the part's
	/// project suffix.
	public static Result<PluginPartKind> Parse(StringView name)
	{
		for (int i < Count)
		{
			let kind = (PluginPartKind)i;
			if (kind.ToString(.. scope .()) == name)
				return kind;
		}
		return .Err;
	}
}

/// A version as manifests write it: "major.minor" or "major.minor.patch", decimal.
struct PluginVersion
{
	public uint32 Major;
	public uint32 Minor;
	public uint32 Patch;

	public this(uint32 major, uint32 minor, uint32 patch = 0)
	{
		Major = major;
		Minor = minor;
		Patch = patch;
	}

	public static Result<PluginVersion> Parse(StringView text)
	{
		uint32[3] fields = .(0, 0, 0);
		int count = 0;
		int start = 0;
		for (int i = 0; i <= text.Length; i++)
		{
			if ((i < text.Length) && (text[i] != '.'))
			{
				if (!text[i].IsDigit)
					return .Err;
				continue;
			}
			if ((i == start) || (count == 3))
				return .Err; // an empty field, or a fourth one
			uint64 value = 0;
			for (let c in text.Substring(start, i - start).RawChars)
			{
				value = value * 10 + (uint64)(c - '0');
				if (value > 0xFFFFFFFF)
					return .Err;
			}
			fields[count++] = (uint32)value;
			start = i + 1;
		}
		if (count < 2)
			return .Err;
		return PluginVersion(fields[0], fields[1], fields[2]);
	}

	/// Whether `version` is `minimum` or later (a dependency's version against what a plugin
	/// asks).
	public static bool AtLeast(PluginVersion version, PluginVersion minimum)
	{
		if (version.Major != minimum.Major)
			return version.Major > minimum.Major;
		if (version.Minor != minimum.Minor)
			return version.Minor > minimum.Minor;
		return version.Patch >= minimum.Patch;
	}

	/// Whether an engine at `engine` satisfies a plugin written for `required`: the same major,
	/// and at least the required minor and patch. Before 1.0 a minor release may break plugins,
	/// so there the minor must match too.
	public static bool EngineSatisfies(PluginVersion engine, PluginVersion required)
	{
		if (engine.Major != required.Major)
			return false;
		if (engine.Major == 0)
			return (engine.Minor == required.Minor) && (engine.Patch >= required.Patch);
		if (engine.Minor != required.Minor)
			return engine.Minor > required.Minor;
		return engine.Patch >= required.Patch;
	}
}

/// Another plugin this one needs, at a minimum version.
[Serializable]
class PluginDependency
{
	public String Id = new .() ~ delete _;
	/// Its minimum version.
	public String Version = new .() ~ delete _;
}

[Serializable]
class PluginManifestPart
{
	/// A PluginPartKind's name.
	public String Kind = new .() ~ delete _;
}

/// A platform the plugin supports and the files it deploys there (relative to the package).
/// Android, iOS and console entries later add their non-Beef pieces as more fields here.
[Serializable]
class PluginPlatform
{
	/// The export platform's tag: "Linux64", "Win64", "Web".
	public String Platform = new .() ~ delete _;
	public List<String> Deploy = new .() ~ DeleteContainerAndItems!(_);
}

/// A plugin package's manifest, `<package>/Plugin.xml`: the one place its identity, parts,
/// dependencies and platforms are written. The plugin host reads it to decide what it enables,
/// and each part carries its package's manifest compiled in, so a player with no package files
/// on disk still checks versions, dependencies and slots.
///
/// FIELD ORDER IS THE WIRE: append, and bump the version when the shape has to change.
[Serializable(1)]
class PluginManifest
{
	public const String cFileName = "Plugin.xml";

	/// Stable and lower case (IsValidId): it keys the project's entry and its settings, and
	/// renaming it orphans every project's entry.
	public String Id = new .() ~ delete _;
	/// For display.
	public String Name = new .() ~ delete _;
	/// The plugin's own version.
	public String Version = new .() ~ delete _;
	/// The engine version it was written for (PluginVersion.EngineSatisfies).
	public String EngineVersion = new .() ~ delete _;
	public List<PluginDependency> DependsOn = new .() ~ DeleteContainerAndItems!(_);
	/// Named slots, at most one enabled provider each ("online.backend").
	public List<String> Provides = new .() ~ DeleteContainerAndItems!(_);
	public List<PluginManifestPart> Parts = new .() ~ DeleteContainerAndItems!(_);
	/// A platform not listed is unsupported.
	public List<PluginPlatform> Platforms = new .() ~ DeleteContainerAndItems!(_);

	/// A plugin id: lower case ASCII letters, digits and underscores, starting with a letter.
	public static bool IsValidId(StringView id)
	{
		if (id.IsEmpty || !((id[0] >= 'a') && (id[0] <= 'z')))
			return false;
		for (let c in id.RawChars)
		{
			if (!(((c >= 'a') && (c <= 'z')) || c.IsDigit || (c == '_')))
				return false;
		}
		return true;
	}

	public bool HasPart(PluginPartKind kind)
	{
		let name = kind.ToString(.. scope .());
		for (let part in Parts)
		{
			if (part.Kind == name)
				return true;
		}
		return false;
	}

	/// The platform's entry, or null when the plugin does not support it.
	public PluginPlatform FindPlatform(StringView platform)
	{
		for (let entry in Platforms)
		{
			if (entry.Platform == platform)
				return entry;
		}
		return null;
	}

	/// Checks what the reader cannot: the id's form, the versions, the part kinds, the
	/// dependencies, and that an engine at `engineVersion` satisfies the plugin. False with the
	/// reason appended to `outWhyNot`; a host refuses the plugin with that message and never
	/// faults on it.
	public bool Check(StringView engineVersion, String outWhyNot)
	{
		if (!IsValidId(Id))
		{
			outWhyNot.AppendF("plugin id '{}' is not lower case letters, digits and underscores starting with a letter", Id);
			return false;
		}
		if (PluginVersion.Parse(Version) case .Err)
		{
			outWhyNot.AppendF("plugin '{}': version '{}' is not major.minor[.patch]", Id, Version);
			return false;
		}
		PluginVersion required = default;
		if (PluginVersion.Parse(EngineVersion) case .Ok(let parsed))
			required = parsed;
		else
		{
			outWhyNot.AppendF("plugin '{}': engineVersion '{}' is not major.minor[.patch]", Id, EngineVersion);
			return false;
		}
		let engine = PluginVersion.Parse(engineVersion);
		if ((engine case .Err) || !PluginVersion.EngineSatisfies(engine.Value, required))
		{
			outWhyNot.AppendF("plugin '{}' needs engine {}; this engine is {}", Id, EngineVersion, engineVersion);
			return false;
		}
		for (int i < Parts.Count)
		{
			let kind = Parts[i].Kind;
			if (PluginPartKind.Parse(kind) case .Err)
			{
				outWhyNot.AppendF("plugin '{}': unknown part kind '{}' (Engine, Pipeline, Tooling or Editor)", Id, kind);
				return false;
			}
			for (int j < i)
			{
				if (Parts[j].Kind == kind)
				{
					outWhyNot.AppendF("plugin '{}': part '{}' is listed twice", Id, kind);
					return false;
				}
			}
		}
		for (let dependency in DependsOn)
		{
			if (!IsValidId(dependency.Id) || (dependency.Id == Id))
			{
				outWhyNot.AppendF("plugin '{}': dependency '{}' is not another plugin's id", Id, dependency.Id);
				return false;
			}
			if (PluginVersion.Parse(dependency.Version) case .Err)
			{
				outWhyNot.AppendF("plugin '{}': dependency '{}' version '{}' is not major.minor[.patch]", Id, dependency.Id, dependency.Version);
				return false;
			}
		}
		return true;
	}

	/// Reads a manifest from `stream` (the XML of a Plugin.xml).
	public static Result<void, ErrorCode> Read(IStream stream, PluginManifest outManifest)
	{
		// The factory and every context it makes are the caller's to free.
		let factory = XmlSerializerFactory();
		defer delete factory;
		let context = factory(stream, .Read);
		if (context == null)
			return .Err(.Internal);
		defer delete context;
		if (context.Serializer == null)
			return .Err(.Internal);
		((ISerializable)outManifest).Serialize(context.Serializer);
		return context.Serializer.Status;
	}

	/// Reads a manifest from its text (a part's compiled-in manifest).
	public static Result<void, ErrorCode> Read(StringView xml, PluginManifest outManifest)
	{
		let stream = scope MemoryStream();
		stream.Write(.((uint8*)xml.Ptr, xml.Length));
		stream.Seek(0, .Begin);
		return Read(stream, outManifest);
	}

	/// Reads `<packageDir>/Plugin.xml`. NotFound when the package has none.
	public static Result<void, ErrorCode> Load(StringView packageDir, PluginManifest outManifest)
	{
		let path = scope String();
		PathJoin(packageDir, cFileName, path);
		let text = scope String();
		if (System.IO.File.ReadAllText(path, text) case .Err)
			return .Err(.NotFound);
		return Read(text, outManifest);
	}

	/// Writes the manifest as XML, appended to `outXml` (the scaffold and the tests write
	/// manifests this way).
	public Result<void, ErrorCode> Write(String outXml)
	{
		let buffer = scope MemoryStream();
		let factory = XmlSerializerFactory();
		defer delete factory;
		let context = factory(buffer, .Write);
		if (context == null)
			return .Err(.Internal);
		defer delete context;
		if (context.Serializer == null)
			return .Err(.Internal);
		((ISerializable)this).Serialize(context.Serializer);
		if (context.Serializer.Status case .Err(let error))
			return .Err(error);
		context.Flush(buffer);
		outXml.Append(StringView((char8*)buffer.Bytes.Ptr, buffer.Bytes.Length));
		return .Ok;
	}
}

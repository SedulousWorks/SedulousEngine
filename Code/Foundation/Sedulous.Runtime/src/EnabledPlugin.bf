using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Xml.Serialization;

namespace Sedulous.Runtime;

/// Whether a plugin is enabled on a platform.
enum PluginEnablement : uint8
{
	case Enabled;
	/// The entry leaves the platform out, or names none and the manifest lacks it.
	case NotEnabled;
	/// The entry names the platform, and the manifest does not support it.
	case Unsupported;
}

/// A project's entry for one plugin it enables: which plugin, where a project-local package is,
/// the platforms it is enabled on, and its settings. The settings stay the XML they were read
/// from, in every host and whether or not the plugin is there to read them: the project is read
/// before any plugin loads, and an entry whose plugin is missing must be written back unchanged.
/// A plugin's part reads them into its own reflected type when it loads
/// (PluginContext.Settings<T>), and an editor writes the type back into the entry (WriteSettings).
class EnabledPlugin : ISerializable
{
	/// The plugin's manifest id.
	public String Id = new .() ~ delete _;
	/// A project-local package, relative to the project; empty for the engine's.
	public String Path = new .() ~ delete _;
	/// The platforms it is enabled on; empty is every one its manifest supports.
	public List<String> Platforms = new .() ~ DeleteContainerAndItems!(_);
	/// Its settings payload, as XML elements (empty: the type's defaults).
	public List<uint8> Settings = new .() ~ delete _;

	public void Serialize(ISerializer ar)
	{
		ar.BeginObject();
		ar.Key("id");
		Sedulous.Core.Serialization.Serialize(ar, Id);
		ar.Key("path");
		Sedulous.Core.Serialization.Serialize(ar, Path);
		ar.Key("platforms");
		Sedulous.Core.Serialization.SerializeList(ar, Platforms);
		// Carried verbatim: the XML's remaining elements, and through the binary serializer (a
		// copy) the same bytes inside a framed region.
		ar.Key("settings");
		ar.BeginObject();
		ar.BeginFramedRegion();
		ar.RawRemainder(Settings);
		ar.EndFramedRegion();
		ar.EndObject();
		ar.EndObject();
	}

	/// Whether the entry enables its plugin (`manifest`) on `platform`.
	public PluginEnablement EnablementOn(PluginManifest manifest, StringView platform)
	{
		let supported = manifest.FindPlatform(platform) != null;
		if (Platforms.IsEmpty)
			return supported ? .Enabled : .NotEnabled;
		for (let listed in Platforms)
		{
			if (listed == platform)
				return supported ? .Enabled : .Unsupported;
		}
		return .NotEnabled;
	}

	/// The platforms the entry names that its manifest does not support, appended, which the
	/// project reports.
	public void UnsupportedPlatforms(PluginManifest manifest, List<String> outPlatforms)
	{
		for (let listed in Platforms)
		{
			if (manifest.FindPlatform(listed) == null)
				outPlatforms.Add(new .(listed));
		}
	}

	/// Reads settings into `into`, a versioned payload of into's type. Empty settings leave its
	/// defaults; a payload that does not read (another type, a stale data version, bad XML) fails
	/// and leaves `into` as the reader left it.
	public static Result<void, ErrorCode> ReadSettings(Span<uint8> settings, ISerializable into)
	{
		if (settings.IsEmpty)
			return .Ok;
		let stream = scope MemoryStream();
		let open = "<root>";
		let close = "</root>";
		stream.Write(.((uint8*)open.Ptr, open.Length));
		stream.Write(settings);
		stream.Write(.((uint8*)close.Ptr, close.Length));
		stream.Seek(0, .Begin);
		let factory = XmlSerializerFactory();
		defer delete factory;
		let context = factory(stream, .Read);
		if ((context == null) || (context.Serializer == null))
		{
			delete context;
			return .Err(.InvalidArgument);
		}
		defer delete context;
		var target = into;
		target.Serialize(context.Serializer);
		return context.Serializer.Status;
	}

	/// Writes `from` into settings, replacing them: the elements of its payload, without the
	/// document's root.
	public static Result<void, ErrorCode> WriteSettings(ISerializable from, List<uint8> outSettings)
	{
		let buffer = scope MemoryStream();
		let factory = XmlSerializerFactory();
		defer delete factory;
		let context = factory(buffer, .Write);
		if ((context == null) || (context.Serializer == null))
		{
			delete context;
			return .Err(.Internal);
		}
		defer delete context;
		var source = from;
		source.Serialize(context.Serializer);
		if (context.Serializer.Status case .Err(let error))
			return .Err(error);
		context.Flush(buffer);
		var written = StringView((char8*)buffer.Bytes.Ptr, buffer.Bytes.Length);
		written.Trim();
		let open = "<root>";
		let close = "</root>";
		if (!written.StartsWith(open) || !written.EndsWith(close))
			return .Err(.Internal);
		var elements = StringView(written, open.Length, written.Length - open.Length - close.Length);
		elements.Trim();
		outSettings.Clear();
		outSettings.AddRange(Span<uint8>((uint8*)elements.Ptr, elements.Length));
		return .Ok;
	}
}

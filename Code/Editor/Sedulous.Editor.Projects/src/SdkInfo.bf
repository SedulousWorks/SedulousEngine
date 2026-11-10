using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using internal Sedulous.Editor.Project;

namespace Sedulous.Editor.Project;

/// How far along its release an SDK's version is, from its label.
enum SdkRelease
{
	/// "dev": a build between releases.
	Dev,
	/// Any other label ("beta"): a pre-release.
	PreRelease,
	/// No label: the release itself.
	Final
}

/// What an engine SDK says of itself: its version and the toolchain it was built with.
///
/// A packed SDK carries sdk.json at its root, written by the packer: version (the numbers alone,
/// what a project's stamp is compared with), label, display (the version with its label),
/// buildNumber, platform, beef (the toolchain pin) and created. A checkout has none; its version is
/// read from the engine's own version file, and it is a checkout: its sources change on every
/// pull, so nothing built over it is ever known to be current.
class SdkInfo
{
	/// The file a packed SDK carries at its root.
	public const String cInfoFile = "sdk.json";
	/// The engine's version file under a checkout's root.
	public const String cVersionFile = "Code/Engine/Sedulous.Engine.Project/src/EngineVersion.bf";
	/// The label of a build between releases.
	public const String cDevLabel = "dev";

	/// The SDK's root, absolute.
	public String Root = new .() ~ delete _;
	/// "major.minor.patch".
	public String Version = new .() ~ delete _;
	public String Label = new .() ~ delete _;
	/// Version with its label ("0.2.0-beta"), as a person reads it.
	public String Display = new .() ~ delete _;
	/// 0 for a local build.
	public uint32 BuildNumber;
	/// The platform its libraries are for (Linux64); a checkout's is this host's.
	public String Platform = new .() ~ delete _;
	/// The toolchain it was built and tested with; empty when it names none (a checkout).
	public String Beef = new .() ~ delete _;
	/// When it was packed, as the packer wrote it; empty for a checkout.
	public String Created = new .() ~ delete _;
	/// No sdk.json: a source checkout.
	public bool IsCheckout;

	public SdkRelease Release => Label.IsEmpty ? .Final : ((Label == cDevLabel) ? .Dev : .PreRelease);

	public void Clear()
	{
		Root.Clear();
		Version.Clear();
		Label.Clear();
		Display.Clear();
		BuildNumber = 0;
		Platform.Clear();
		Beef.Clear();
		Created.Clear();
		IsCheckout = false;
	}

	public void CopyFrom(SdkInfo other)
	{
		Root.Set(other.Root);
		Version.Set(other.Version);
		Label.Set(other.Label);
		Display.Set(other.Display);
		BuildNumber = other.BuildNumber;
		Platform.Set(other.Platform);
		Beef.Set(other.Beef);
		Created.Set(other.Created);
		IsCheckout = other.IsCheckout;
	}

	/// Whether `root` is an SDK without sdk.json: a checkout.
	public static bool IsCheckoutAt(StringView root)
	{
		return ProjectBuild.IsSdk(root) && !FileExists(PathJoin(root, cInfoFile, .. scope .()));
	}

	/// Reads the SDK at `root` into `outInfo`: its sdk.json, else (a checkout) the engine's version
	/// file. NotFound when `root` is no SDK (ProjectBuild.IsSdk), or a checkout without the version
	/// file; InvalidArgument when what it has does not give a version ("major.minor.patch").
	public static Result<void, ErrorCode> Read(StringView root, SdkInfo outInfo)
	{
		outInfo.Clear();
		let absolute = ProjectBuild.Absolute(root, .. scope .());
		if (!ProjectBuild.IsSdk(absolute))
			return .Err(.NotFound);
		let text = scope String();
		Result<void, ErrorCode> read;
		if (ReadText(PathJoin(absolute, cInfoFile, .. scope .()), text) case .Ok)
			read = ParseInfo(text, outInfo);
		else if (ReadText(PathJoin(absolute, cVersionFile, .. scope .()), text) case .Ok)
		{
			read = ParseVersionFile(text, outInfo);
			outInfo.IsCheckout = true;
			outInfo.Platform.Set(BuildLayout.HostPlatformName);
		}
		else
			read = .Err(.NotFound);
		if (read case .Err(let error))
		{
			outInfo.Clear();
			return .Err(error);
		}
		outInfo.Root.Set(absolute);
		return .Ok;
	}

	/// sdk.json's members into `outInfo` (its root left as it is). InvalidArgument when the text is
	/// not one JSON object, its version is missing or not "major.minor.patch", or its buildNumber
	/// is not a number. A display it lacks is the version with its label.
	public static Result<void, ErrorCode> ParseInfo(StringView json, SdkInfo outInfo)
	{
		bool numbersRead = true;
		let read = ReadJsonMembers(json, scope [&](key, value) =>
			{
				if (key == "version")
					outInfo.Version.Set(value);
				else if (key == "label")
					outInfo.Label.Set(value);
				else if (key == "display")
					outInfo.Display.Set(value);
				else if (key == "platform")
					outInfo.Platform.Set(value);
				else if (key == "beef")
					outInfo.Beef.Set(value);
				else if (key == "created")
					outInfo.Created.Set(value);
				else if (key == "buildNumber")
				{
					if (uint32.Parse(value) case .Ok(let number))
						outInfo.BuildNumber = number;
					else
						numbersRead = false;
				}
			});
		if (!read || !numbersRead || !ProjectRegistry.ParseEngineVersion(outInfo.Version, ?))
			return .Err(.InvalidArgument);
		if (outInfo.Display.IsEmpty)
			ComposeDisplay(outInfo);
		return .Ok;
	}

	/// The constants of the engine's version file (String, Label, Display and BuildNumber, each
	/// `public const <type> <Name> = <value>;`) into `outInfo`. InvalidArgument when its String is
	/// missing or not "major.minor.patch", or it has no Label.
	public static Result<void, ErrorCode> ParseVersionFile(StringView source, SdkInfo outInfo)
	{
		if (!QuotedConstant(source, "String", outInfo.Version) || !ProjectRegistry.ParseEngineVersion(outInfo.Version, ?)
			|| !QuotedConstant(source, "Label", outInfo.Label))
			return .Err(.InvalidArgument);
		if (!QuotedConstant(source, "Display", outInfo.Display) || outInfo.Display.IsEmpty)
			ComposeDisplay(outInfo);
		let number = scope String();
		if (Constant(source, "uint32", "BuildNumber", number) && (uint32.Parse(number) case .Ok(let parsed)))
			outInfo.BuildNumber = parsed;
		return .Ok;
	}

	/// Display as the engine composes it: the version, and "-<label>" when there is one.
	private static void ComposeDisplay(SdkInfo info)
	{
		info.Display.Set(info.Version);
		if (!info.Label.IsEmpty)
			info.Display.AppendF("-{}", info.Label);
	}

	/// The value of a String constant `name` in `source`, without its quotes.
	private static bool QuotedConstant(StringView source, StringView name, String outValue)
	{
		let value = scope String();
		if (!Constant(source, "String", name, value) || (value.Length < 2) || !value.StartsWith('"') || !value.EndsWith('"'))
			return false;
		outValue.Set(value.Substring(1, value.Length - 2));
		return true;
	}

	/// The text between `public const <type> <name> =` and the `;` after it in `source`, trimmed.
	private static bool Constant(StringView source, StringView type, StringView name, String outValue)
	{
		outValue.Clear();
		let declaration = scope $"public const {type} {name} =";
		let at = source.IndexOf(declaration);
		if (at < 0)
			return false;
		let start = at + declaration.Length;
		let end = source.IndexOf(';', start);
		if (end < 0)
			return false;
		var value = source.Substring(start, end - start);
		value.Trim();
		outValue.Set(value);
		return true;
	}

	/// Calls `onMember` with each member of the JSON object `text` whose value is a string, a
	/// number, true, false or null, with that value as text (a string unescaped, the rest as
	/// written); a member holding an object or an array is passed by. False when `text` is not one
	/// object.
	public static bool ReadJsonMembers(StringView text, delegate void(StringView key, StringView value) onMember)
	{
		int i = 0;
		SkipSpace(text, ref i);
		if ((i >= text.Length) || (text[i] != '{'))
			return false;
		i++;
		SkipSpace(text, ref i);
		if ((i < text.Length) && (text[i] == '}'))
		{
			i++;
			SkipSpace(text, ref i);
			return i == text.Length;
		}
		let key = scope String();
		let value = scope String();
		while (true)
		{
			SkipSpace(text, ref i);
			if (!ReadJsonString(text, ref i, key))
				return false;
			SkipSpace(text, ref i);
			if ((i >= text.Length) || (text[i] != ':'))
				return false;
			i++;
			SkipSpace(text, ref i);
			if (i >= text.Length)
				return false;
			let c = text[i];
			if (c == '"')
			{
				if (!ReadJsonString(text, ref i, value))
					return false;
				onMember(key, value);
			}
			else if ((c == '{') || (c == '['))
			{
				if (!SkipJsonNested(text, ref i))
					return false;
			}
			else
			{
				let start = i;
				while ((i < text.Length) && (text[i] != ',') && (text[i] != '}') && !text[i].IsWhiteSpace)
					i++;
				if (i == start)
					return false;
				onMember(key, text.Substring(start, i - start));
			}
			SkipSpace(text, ref i);
			if (i >= text.Length)
				return false;
			if (text[i] == ',')
			{
				i++;
				continue;
			}
			if (text[i] != '}')
				return false;
			i++;
			break;
		}
		SkipSpace(text, ref i);
		return i == text.Length;
	}

	private static void SkipSpace(StringView text, ref int i)
	{
		while ((i < text.Length) && text[i].IsWhiteSpace)
			i++;
	}

	/// The JSON string at `i` (its opening quote) unescaped into `outValue`, `i` moved past its
	/// closing quote.
	private static bool ReadJsonString(StringView text, ref int i, String outValue)
	{
		outValue.Clear();
		if ((i >= text.Length) || (text[i] != '"'))
			return false;
		i++;
		while (i < text.Length)
		{
			let c = text[i++];
			if (c == '"')
				return true;
			if (c != '\\')
			{
				outValue.Append(c);
				continue;
			}
			if (i >= text.Length)
				return false;
			let escaped = text[i++];
			switch (escaped)
			{
			case '"', '\\', '/': outValue.Append(escaped);
			case 'b': outValue.Append('\b');
			case 'f': outValue.Append('\f');
			case 'n': outValue.Append('\n');
			case 'r': outValue.Append('\r');
			case 't': outValue.Append('\t');
			case 'u':
				if (i + 4 > text.Length)
					return false;
				switch (uint32.Parse(text.Substring(i, 4), .HexNumber))
				{
				case .Ok(let code): outValue.Append((char32)code);
				case .Err: return false;
				}
				i += 4;
			default:
				return false;
			}
		}
		return false;
	}

	/// Moves `i` past the object or array that starts there, strings in it read as strings.
	private static bool SkipJsonNested(StringView text, ref int i)
	{
		int depth = 0;
		let scratch = scope String();
		while (i < text.Length)
		{
			let c = text[i];
			if (c == '"')
			{
				if (!ReadJsonString(text, ref i, scratch))
					return false;
				continue;
			}
			i++;
			if ((c == '{') || (c == '['))
				depth++;
			else if ((c == '}') || (c == ']'))
			{
				depth--;
				if (depth == 0)
					return true;
			}
		}
		return false;
	}

	private static Result<void> ReadText(StringView path, String outText)
	{
		let bytes = scope List<uint8>();
		if (ReadFile(path, bytes) case .Err)
			return .Err;
		outText.Set(StringView((char8*)bytes.Ptr, bytes.Count));
		return .Ok;
	}
}

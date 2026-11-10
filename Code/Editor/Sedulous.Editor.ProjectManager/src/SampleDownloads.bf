using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Http;

namespace Sedulous.Editor.App;

/// One sample game a release offers.
class SampleInfo
{
	/// Its folder in the repository ("SkyHopper"), and the one made for it.
	public String Folder = new .() ~ delete _;
	/// Its project's name ("Sky Hopper").
	public String Name = new .() ~ delete _;
	/// One line on what it is.
	public String Description = new .() ~ delete _;
	/// Its zip in the release ("sample-SkyHopper.zip").
	public String Archive = new .() ~ delete _;
	/// Its picture in the release.
	public String Picture = new .() ~ delete _;
	/// The zip's digest, 64 lowercase hex digits.
	public String Sha256 = new .() ~ delete _;
	/// The zip's bytes.
	public uint64 Size = 0;
	/// What it extracts to.
	public uint64 UnpackedSize = 0;

	public void CopyFrom(SampleInfo other)
	{
		Folder.Set(other.Folder);
		Name.Set(other.Name);
		Description.Set(other.Description);
		Archive.Set(other.Archive);
		Picture.Set(other.Picture);
		Sha256.Set(other.Sha256);
		Size = other.Size;
		UnpackedSize = other.UnpackedSize;
	}
}

/// A release's samples.json: the sample games the project manager's Samples tab offers, as
/// pack-samples.py writes them.
class SampleCatalog
{
	public String Version = new .() ~ delete _;
	public List<SampleInfo> Samples = new .() ~ DeleteContainerAndItems!(_);

	/// Reads `json` into `outCatalog`, replacing what it held. False with `outError`, said for a
	/// person, when it is not a catalog: a sample missing its folder, archive or digest, or a folder
	/// or archive that is not a plain name, refuses the whole of it.
	public static bool Parse(StringView json, SampleCatalog outCatalog, String outError)
	{
		outCatalog.Version.Clear();
		ClearAndDeleteItems!(outCatalog.Samples);
		let parsed = scope JsonParseResult();
		JsonParser.Parse(json, parsed);
		let samples = parsed.Ok ? parsed.Value.Get("samples") : null;
		if (!parsed.Value.IsObject || (samples == null) || !samples.IsArray)
		{
			outError.Set("the samples list could not be read");
			return false;
		}
		let version = parsed.Value.Get("version");
		if (version != null)
			outCatalog.Version.Set(version.AsString());
		for (int i < samples.Count)
		{
			let item = samples.At(i);
			let info = new SampleInfo();
			outCatalog.Samples.Add(info);
			Text(item, "folder", info.Folder);
			Text(item, "name", info.Name);
			Text(item, "description", info.Description);
			Text(item, "archive", info.Archive);
			Text(item, "picture", info.Picture);
			Text(item, "sha256", info.Sha256);
			info.Size = (uint64)Math.Max((int64)0, Number(item, "size"));
			info.UnpackedSize = (uint64)Math.Max((int64)0, Number(item, "unpackedSize"));
			if (info.Name.IsEmpty)
				info.Name.Set(info.Folder);
			if (!PlainName(info.Folder) || !PlainName(info.Archive) || (info.Sha256.Length != 64)
				|| (!info.Picture.IsEmpty && !PlainName(info.Picture)))
			{
				outError.Set("the samples list names a sample this manager cannot fetch");
				outCatalog.Version.Clear();
				ClearAndDeleteItems!(outCatalog.Samples);
				return false;
			}
		}
		return true;
	}

	private static void Text(JsonValue item, StringView key, String outText)
	{
		let value = (item != null) ? item.Get(key) : null;
		if (value != null)
			outText.Set(value.AsString());
	}

	private static int64 Number(JsonValue item, StringView key)
	{
		let value = (item != null) ? item.Get(key) : null;
		return (value != null) ? value.AsInt() : 0;
	}

	/// A file or folder name alone: nothing that walks out of where it is put.
	public static bool PlainName(StringView name)
	{
		if (name.IsEmpty || (name == ".") || (name == ".."))
			return false;
		for (int i < name.Length)
		{
			if ((name[i] == '/') || (name[i] == '\\') || (name[i] == ':'))
				return false;
		}
		return true;
	}
}

/// A folder of release files served for --release-files <folder> (a copy Code/Tools/pack-samples.py
/// made, to try the Samples tab before a release has them): the file a GET names, by a plain name
/// in the folder alone, or a 404.
static class ReleaseFolder
{
	/// The response to `request`, which the caller owns.
	public static HttpResponse Serve(StringView folder, HttpRequest request)
	{
		let response = new HttpResponse();
		StringView name = request.Target;
		if (name.StartsWith("/"))
			name = StringView(name, 1);
		bool plain = !name.IsEmpty && (name != ".") && (name != "..") && (request.Method == "GET");
		for (int i < name.Length)
		{
			let c = name[i];
			plain = plain && (c != '/') && (c != '\\') && (c != ':') && (c != '?');
		}
		if (!plain || (ReadFile(PathJoin(folder, name, .. scope .()), response.Body) case .Err))
		{
			response.Body.Clear();
			response.Status = 404;
		}
		return response;
	}
}

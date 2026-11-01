using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Http;
using Sedulous.Http.Client;
using Sedulous.Zip;

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

/// A release's samples.json (Raptor's project-manager spec, P5): the sample games the project
/// manager's Samples tab offers, as Raptor's pack-samples.py writes them.
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
				outError.Set("the samples list names a sample this editor cannot fetch");
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
	private static bool PlainName(StringView name)
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

/// One sample's download into `target` (made if need be; a new or empty folder, as New Project's
/// check requires): streamed to `<target's parent>/.<folder>.download`, hashing it as it arrives,
/// checked against the catalog's SHA-256, extracted, the zip deleted. Cancelled or failed, it keeps
/// nothing it wrote. Everything happens inside the HTTP client's Pump, on the caller's thread; its
/// callbacks hold it, so it must outlive its request (deleting it cancels one still running).
class SampleDownload
{
	public enum DownloadState : uint8
	{
		Downloading,
		/// The project is in Target.
		Done,
		/// Error says why; nothing it wrote is left.
		Failed,
		/// Nothing it wrote is left.
		Cancelled,
	}

	/// BORROWED: the caller's, outliving the download.
	private IHttpClient mClient;
	private SampleInfo mSample = new .() ~ delete _;
	private String mUrl = new .() ~ delete _;
	private String mTarget = new .() ~ delete _;
	private String mPartial = new .() ~ delete _;
	private String mError = new .() ~ delete _;
	private FileStream mFile ~ delete _;
	private Sha256 mHash = new .() ~ delete _;
	private uint64 mRequest = 0;
	private uint64 mReceived = 0;
	private uint64 mTotal = 0;
	private DownloadState mState = .Downloading;
	private bool mTargetExisted = false;

	public this(IHttpClient client, SampleInfo sample, StringView url, StringView target)
	{
		mClient = client;
		mSample.CopyFrom(sample);
		mUrl.Set(url);
		mTarget.Set(target);
		mTargetExisted = DirectoryExists(mTarget);
		PathJoin(PathParent(mTarget, .. scope .()), scope $".{mSample.Folder}.download", mPartial);
		mTotal = mSample.Size;
	}

	public ~this()
	{
		if (mState == .Downloading)
			Cancel();
	}

	public DownloadState State => mState;
	public SampleInfo Sample => mSample;
	public StringView Target => mTarget;
	public StringView Error => mError;
	/// Bytes so far, and of how many (the catalog's size, or the response's length).
	public uint64 Received => mReceived;
	public uint64 Total => mTotal;

	/// How far along it is, 0 to 1.
	public float Progress => (mTotal == 0) ? 0.0f : Math.Min(1.0f, (float)((double)mReceived / (double)mTotal));

	/// Sends the request; what it hears comes inside the client's Pump.
	public void Start()
	{
		let parent = PathParent(mPartial, .. scope .());
		if (!CreateDirectory(parent))
		{
			Fail(scope $"{parent} could not be made");
			return;
		}
		let request = HttpClientRequest.Get(mUrl);
		request.TimeoutSeconds = 600.0f;
		request.MaxResponseBytes = (int)(Math.Max(mSample.Size, (uint64)1) * 2 + 1024 * 1024); // its size, with room
		request.OnHead = new (status, headers, length) => OnHead(status, length);
		request.OnBody = new (piece) => OnBody(piece);
		mRequest = mClient.Send(request, new (response) => OnDone(response));
	}

	/// Stops it and deletes what it wrote; the folder it would have filled is left as it was.
	public void Cancel()
	{
		if (mState != .Downloading)
			return;
		mClient.Cancel(mRequest);
		Discard();
		mState = .Cancelled;
	}

	private void OnHead(int32 status, int64 length)
	{
		if (mState != .Downloading)
			return;
		if (status != 200)
		{
			mClient.Cancel(mRequest);
			if (status == 404)
				Fail("the release does not have this sample");
			else
				Fail(scope $"the download was refused ({status})");
			return;
		}
		if (length > 0)
			mTotal = (uint64)length;
		mFile = new FileStream(mPartial, .Write);
		if (!mFile.IsValid)
		{
			mClient.Cancel(mRequest);
			Fail(scope $"{mPartial} could not be written");
		}
	}

	private void OnBody(Span<uint8> piece)
	{
		if ((mState != .Downloading) || (mFile == null))
			return;
		if (mFile.Write(piece) != piece.Length)
		{
			mClient.Cancel(mRequest);
			Fail("the download could not be written (is the disk full?)");
			return;
		}
		mHash.Update(piece);
		mReceived += (uint64)piece.Length;
	}

	private void OnDone(HttpClientResponse response)
	{
		if (mState != .Downloading)
			return;
		if (!response.Ok)
		{
			Fail(scope $"the download failed: {response.Error}");
			return;
		}
		DeleteAndNullify!(mFile); // closed, before it is read back
		if (mHash.Finish().ToHex(.. scope .()) != mSample.Sha256)
		{
			Fail("the download does not match its checksum: try again");
			return;
		}
		let error = scope String();
		bool unpacked = false;
		{
			let archive = scope FileStream(mPartial, .Read);
			let zip = scope ZipArchive();
			unpacked = archive.IsValid && zip.Open(archive, error) && zip.ExtractAll(mTarget, error);
		}
		if (!unpacked)
		{
			ClearTarget(); // a part of a project is no project
			Fail(scope $"the sample could not be unpacked: {error}");
			return;
		}
		DeleteFile(mPartial);
		mState = .Done;
	}

	private void Fail(StringView why)
	{
		Discard();
		mError.Set(why);
		mState = .Failed;
	}

	private void Discard()
	{
		DeleteAndNullify!(mFile);
		DeleteFile(mPartial);
	}

	/// Takes back what extracting wrote: a folder it made goes; one that was there (empty, as the
	/// check requires) is emptied and kept.
	private void ClearTarget()
	{
		if (!mTargetExisted)
		{
			RemoveDirectoryRecursive(mTarget);
			return;
		}
		let paths = scope List<String>();
		defer { ClearAndDeleteItems!(paths); }
		ListDirectory(mTarget, scope [&](name, isDirectory) => { paths.Add(PathJoin(mTarget, name, .. new .())); });
		for (let path in paths)
		{
			if (DirectoryExists(path))
				RemoveDirectoryRecursive(path);
			else
				DeleteFile(path);
		}
	}
}

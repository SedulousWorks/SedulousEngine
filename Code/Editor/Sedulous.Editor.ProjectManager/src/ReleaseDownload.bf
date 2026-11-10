using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Http.Client;
using Sedulous.Zip;

namespace Sedulous.Editor.ProjectManager;

/// One file of a release downloaded into `target`: streamed to `<target's parent>/.<target's
/// name>.download`, hashing it as it arrives, and checked against the SHA-256 the release's index
/// gives. Then, extracting (a sample, an SDK, a toolchain), the zip unpacks into `target` (made if
/// need be; a new or empty folder) and goes; else the file takes `target`'s name. Cancelled or
/// failed, it keeps nothing it wrote. Everything happens inside the HTTP client's Pump, on the
/// caller's thread; its callbacks hold it, so it must outlive its request (deleting it cancels one
/// still running).
class ReleaseDownload
{
	public enum DownloadState : uint8
	{
		Downloading,
		/// What it fetched is at Target.
		Done,
		/// Error says why; nothing it wrote is left.
		Failed,
		/// Nothing it wrote is left.
		Cancelled,
	}

	/// BORROWED: the caller's, outliving the download.
	private IHttpClient mClient;
	private String mUrl = new .() ~ delete _;
	private String mSha256 = new .() ~ delete _;
	private uint64 mSize = 0;
	private bool mExtract = true;
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

	/// `sha256` is the file's digest as 64 lowercase hex digits; `size` its bytes as the index
	/// gives them (0: unknown, the response's length then counts).
	public this(IHttpClient client, StringView url, StringView sha256, uint64 size, StringView target, bool extract = true)
	{
		mClient = client;
		mUrl.Set(url);
		mSha256.Set(sha256);
		mSize = size;
		mExtract = extract;
		mTarget.Set(target);
		mTargetExisted = extract ? DirectoryExists(mTarget) : FileExists(mTarget);
		let name = PathFilename(mTarget, .. scope .());
		PathJoin(PathParent(mTarget, .. scope .()), scope $".{name}.download", mPartial);
		mTotal = mSize;
	}

	public ~this()
	{
		if (mState == .Downloading)
			Cancel();
	}

	public DownloadState State => mState;
	public StringView Url => mUrl;
	public StringView Target => mTarget;
	public StringView Error => mError;
	/// Bytes so far, and of how many (the index's size, or the response's length).
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
		request.MaxResponseBytes = (int)(Math.Max(mSize, (uint64)1) * 2 + 1024 * 1024); // its size, with room
		request.OnHead = new (status, headers, length) => OnHead(status, length);
		request.OnBody = new (piece) => OnBody(piece);
		mRequest = mClient.Send(request, new (response) => OnDone(response));
	}

	/// Stops it and deletes what it wrote; the target is left as it was.
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
				Fail("the release does not have this file");
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
		if (mHash.Finish().ToHex(.. scope .()) != mSha256)
		{
			Fail("the download does not match its checksum: try again");
			return;
		}
		if (!mExtract)
		{
			if (mTargetExisted)
				DeleteFile(mTarget);
			if (!MoveFile(mPartial, mTarget))
			{
				Fail(scope $"{mTarget} could not be written");
				return;
			}
			mState = .Done;
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
			ClearTarget(); // a part of what it held is nothing usable
			Fail(scope $"it could not be unpacked: {error}");
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
	/// caller's check requires) is emptied and kept.
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

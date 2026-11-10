using System;
using Sedulous.Core.Logging;
using Sedulous.Net.Tls;
using Sedulous.Net.Tls.MbedTLS;
using Sedulous.Http;
using Sedulous.Http.Client;
using Sedulous.Engine.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.ProjectManager;

/// How a release is reached: an HTTP client over Mbed TLS with the system's roots, made on first
/// use, and where a release's files are read from. That is GitHub's release of the version, or
/// what --release-files names: a base URL, or a folder (one Code/Tools/pack-samples.py wrote)
/// served on loopback, started on first use. Deleting it cancels the client's requests, so what
/// made requests through it goes first.
class ReleaseAccess
{
	private String mReleaseFiles = new .() ~ delete _;
	private ITlsBackend mTls = null;
	private IHttpClient mClient = null;
	private HttpServer mServer = null;

	/// `releaseFiles` is --release-files' value; empty: the releases themselves.
	public this(StringView releaseFiles = default)
	{
		mReleaseFiles.Set(releaseFiles);
	}

	public ~this()
	{
		Close();
	}

	/// --release-files was given: the files come from there.
	public bool Overridden => !mReleaseFiles.IsEmpty;

	/// The client, made on first use. Borrowed.
	public IHttpClient Client()
	{
		if (mClient == null)
		{
			mTls = new MbedTlsBackend();
			mClient = HttpClients.Create(mTls);
		}
		return mClient;
	}

	/// Where `file` of this version's release is read from: what --release-files names, else the
	/// release's own download URL. A folder that cannot be served falls back to the release.
	public void FileUrl(StringView file, String outUrl)
	{
		if (!Overridden)
		{
			EngineVersion.ReleaseDownloadUrl(file, outUrl);
			return;
		}
		StringView from = mReleaseFiles;
		if (from.StartsWith("http://") || from.StartsWith("https://"))
		{
			while (from.EndsWith('/'))
				from = StringView(from, 0, from.Length - 1);
			outUrl.AppendF("{}/{}", from, file);
			return;
		}
		if (mServer == null)
		{
			let server = new HttpServer();
			let folder = new String(from);
			server.SetHandler(new [=folder] (request) => ReleaseFolder.Serve(folder, request) ~ delete folder);
			if (!server.Start(.()))
			{
				delete server;
				GlobalLog(.Error, "Projects: --release-files: the folder {} could not be served", from);
				EngineVersion.ReleaseDownloadUrl(file, outUrl);
				return;
			}
			mServer = server;
			GlobalLog(.Information, "Projects: --release-files: serving {} on 127.0.0.1:{}", from, server.BoundPort);
		}
		outUrl.AppendF("http://127.0.0.1:{}/{}", mServer.BoundPort, file);
	}

	/// Once a frame: the loopback server answers, before the client asks again.
	public void Pump()
	{
		if (mServer != null)
			mServer.Pump();
	}

	/// The client (its requests cancelled), the server, then the TLS backend the client used.
	public void Close()
	{
		DeleteAndNullify!(mClient);
		DeleteAndNullify!(mServer);
		DeleteAndNullify!(mTls);
	}
}

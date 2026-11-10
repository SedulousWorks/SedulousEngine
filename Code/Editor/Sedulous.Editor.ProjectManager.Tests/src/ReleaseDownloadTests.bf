using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Http.Client;
using Sedulous.Editor.ProjectManager;

namespace Sedulous.Editor.ProjectManager.Tests;

/// A release file kept as a file rather than extracted (an index, a picture): it takes its
/// target's name once its digest checks, replacing what was there; a wrong digest leaves what was
/// there and nothing beside it. The extracting kind is SampleDownloadsTests'.
class ReleaseDownloadTests
{
	private static void Run(ReleaseDownload download, NativeHttpClient client, LoopbackFiles server)
	{
		for (int i < 10000)
		{
			if (download.State != .Downloading)
				break;
			server.Pump();
			client.Pump();
			if (download.State == .Downloading)
				Thread.Sleep(1);
		}
	}

	private static void Text(StringView path, String outText)
	{
		let bytes = scope List<uint8>();
		Test.Assert(ReadFile(path, bytes) case .Ok, scope String(path));
		outText.Append(StringView((char8*)bytes.Ptr, bytes.Count));
	}

	[Test]
	public static void AFileKeptAsAFileTakesItsTargetsNameOnceItsDigestChecks()
	{
		let root = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_release_download", .. scope .());
		RemoveDirectoryRecursive(root);
		Test.Assert(CreateDirectory(root));
		defer RemoveDirectoryRecursive(root);
		let target = PathJoin(root, "sdk-linux64.json", .. scope .());
		let partial = PathJoin(root, ".sdk-linux64.json.download", .. scope .());
		let before = "{\"version\": \"0.1.0\"}";
		Test.Assert(WriteFile(target, .((uint8*)before.Ptr, before.Length)) case .Ok);
		let body = "{\"version\": \"0.2.0\"}";
		let bytes = Span<uint8>((uint8*)body.Ptr, body.Length);
		let digest = Sha256.Of(bytes).ToHex(.. scope .());
		let client = scope NativeHttpClient(null);
		let server = scope LoopbackFiles();
		server.Serve("/sdk-linux64.json", body);
		let url = server.Url("/sdk-linux64.json", .. scope .());

		// A wrong digest: what was there stays, and nothing is beside it.
		{
			let download = scope ReleaseDownload(client, url, "0000000000000000000000000000000000000000000000000000000000000000",
				(uint64)body.Length, target, false);
			download.Start();
			Run(download, client, server);
			Test.Assert(download.State == .Failed);
			Test.Assert(download.Error.Contains("checksum", true), scope String(download.Error));
			Test.Assert(Text(target, .. scope .()) == before);
			Test.Assert(!FileExists(partial));
		}

		let fetched = scope ReleaseDownload(client, url, digest, (uint64)body.Length, target, false);
		fetched.Start();
		Run(fetched, client, server);
		Test.Assert(fetched.State == .Done, scope String(fetched.Error));
		Test.Assert(fetched.Received == (uint64)body.Length);
		Test.Assert(Text(target, .. scope .()) == body, "replaced by what was fetched");
		Test.Assert(!FileExists(partial));
		Test.Assert(!DirectoryExists(target), "a file, not unpacked");
	}
}

using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.Http;
using Sedulous.Http.Client;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The Samples tab's catalog (a release's samples.json) and one sample's download against a
/// loopback server: streamed to a file, checked against its SHA-256, extracted and the zip deleted;
/// a wrong digest, a missing sample and a cancel each leave nothing behind.
class SampleDownloadsTests
{
	private class Fixture
	{
		public String Root = new .() ~ delete _;
		public List<uint8> Zip = new .() ~ delete _;
		public SampleInfo Sample = new .() ~ delete _;
		public NativeHttpClient Client = new .(null) ~ delete _;

		public this()
		{
			PathJoin(GetCurrentDirectory(.. scope .()), "scratch_sample_downloads", Root);
			RemoveDirectoryRecursive(Root);
			Test.Assert(CreateDirectory(Root));
			let zipPath = PathJoin(FindDataRoot(.. scope .()), "Tests/Zip/project.zip", .. scope .());
			Test.Assert(ReadFile(zipPath, Zip) case .Ok, zipPath);
			Sample.Folder.Set("Game");
			Sample.Name.Set("Game");
			Sample.Archive.Set("sample-Game.zip");
			Sample.Size = (uint64)Zip.Count;
			Sha256.Of(Zip).ToHex(Sample.Sha256);
		}

		public ~this()
		{
			RemoveDirectoryRecursive(Root);
		}

		/// Runs `download` to its end, the server and the client pumped together.
		public void Run(SampleDownload download, LoopbackFiles server)
		{
			for (int i < 10000)
			{
				if (download.State != .Downloading)
					break;
				server.Pump();
				Client.Pump();
				if (download.State == .Downloading)
					Thread.Sleep(1);
			}
		}

		public bool LeftNothing(StringView target) =>
			!DirectoryExists(target) && !FileExists(PathJoin(Root, ".Game.download", .. scope .()));
	}

	[Test]
	public static void AReleasesListOfSamplesAndWhatRefusesIt()
	{
		let catalog = scope SampleCatalog();
		let error = scope String();
		Test.Assert(SampleCatalog.Parse("""
			{"version": "0.1.0", "samples": [{"folder": "Snowline", "name": "Snowline", "description": "A time trial.",
			 "archive": "sample-Snowline.zip", "size": 1234, "unpackedSize": 5678,
			 "sha256": "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0", "picture": "sample-Snowline.png"}]}
			""", catalog, error), error);
		Test.Assert(catalog.Version == "0.1.0");
		Test.Assert(catalog.Samples.Count == 1);
		Test.Assert(catalog.Samples[0].Name == "Snowline");
		Test.Assert(catalog.Samples[0].Size == 1234);
		Test.Assert(catalog.Samples[0].UnpackedSize == 5678);

		Test.Assert(!SampleCatalog.Parse("not json", catalog, error));
		Test.Assert(catalog.Samples.IsEmpty);
		// A folder or an archive that walks out of where it goes refuses the whole list.
		Test.Assert(!SampleCatalog.Parse("""
			{"samples": [{"folder": "../x", "archive": "a.zip", "sha256": "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0"}]}
			""", catalog, error));
		Test.Assert(!SampleCatalog.Parse("{\"samples\": [{\"folder\": \"x\", \"archive\": \"a.zip\", \"sha256\": \"short\"}]}", catalog, error));
	}

	[Test]
	public static void StreamedCheckedAndUnpackedIntoItsFolderTheZipGoneAfter()
	{
		let f = scope Fixture();
		let server = scope LoopbackFiles();
		server.Serve("/sample-Game.zip", f.Zip);
		let target = PathJoin(f.Root, "Game", .. scope .());
		let download = scope SampleDownload(f.Client, f.Sample, server.Url("/sample-Game.zip", .. scope .()), target);
		download.Start();
		f.Run(download, server);
		Test.Assert(download.State == .Done, scope String(download.Error));
		Test.Assert(download.Received == (uint64)f.Zip.Count);
		Test.Assert(Math.Abs(download.Progress - 1.0f) < 1e-5f);
		Test.Assert(FileExists(PathJoin(target, "Game/Project.xml", .. scope .()))); // the fixture's own top folder
		Test.Assert(!FileExists(PathJoin(f.Root, ".Game.download", .. scope .())));
	}

	[Test]
	public static void AWrongDigestAMissingSampleAndACancelLeaveNothingBehind()
	{
		let f = scope Fixture();
		let target = PathJoin(f.Root, "Game", .. scope .());
		{
			let server = scope LoopbackFiles();
			server.Serve("/x.zip", f.Zip);
			let wrong = scope SampleInfo();
			wrong.CopyFrom(f.Sample);
			wrong.Sha256.Set("0000000000000000000000000000000000000000000000000000000000000000");
			let download = scope SampleDownload(f.Client, wrong, server.Url("/x.zip", .. scope .()), target);
			download.Start();
			f.Run(download, server);
			Test.Assert(download.State == .Failed);
			Test.Assert(download.Error.Contains("checksum", true), scope String(download.Error));
			Test.Assert(f.LeftNothing(target));
		}
		{
			let server = scope LoopbackFiles(); // serves nothing: a 404
			let download = scope SampleDownload(f.Client, f.Sample, server.Url("/x.zip", .. scope .()), target);
			download.Start();
			f.Run(download, server);
			Test.Assert(download.State == .Failed);
			Test.Assert(download.Error.Contains("does not have", true), scope String(download.Error));
			Test.Assert(f.LeftNothing(target));
		}
		{
			let server = scope LoopbackFiles();
			server.Serve("/x.zip", f.Zip);
			let download = scope SampleDownload(f.Client, f.Sample, server.Url("/x.zip", .. scope .()), target);
			download.Start();
			download.Cancel();
			Test.Assert(download.State == .Cancelled);
			for (int i < 50) // nothing more arrives for it
			{
				server.Pump();
				f.Client.Pump();
				Thread.Sleep(1);
			}
			Test.Assert(download.State == .Cancelled);
			Test.Assert(f.LeftNothing(target));
		}
	}

	/// What a release folder answers `method` `target` with: its status, and its body as text.
	private static int32 Get(StringView folder, StringView target, String outBody, StringView method = "GET")
	{
		let request = scope HttpRequest();
		request.Method.Set(method);
		request.Target.Set(target);
		let response = ReleaseFolder.Serve(folder, request);
		defer delete response;
		outBody.Append(response.BodyText);
		return response.Status;
	}

	[Test]
	public static void AReleaseFolderServesItsFilesByPlainNameAndNothingOutsideIt()
	{
		let folder = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_release_folder", .. scope .());
		RemoveDirectoryRecursive(folder);
		Test.Assert(CreateDirectory(PathJoin(folder, "inner", .. scope .())));
		let text = "{\"samples\": []}";
		Test.Assert(WriteFile(PathJoin(folder, "samples.json", .. scope .()), .((uint8*)text.Ptr, text.Length)) case .Ok);
		let body = scope String();
		Test.Assert(Get(folder, "/samples.json", body) == 200);
		Test.Assert(body == text);
		Test.Assert(Get(folder, "/missing.zip", body..Clear()) == 404);
		Test.Assert(Get(folder, "/../secret", body..Clear()) == 404);
		Test.Assert(Get(folder, "/inner/x", body..Clear()) == 404);
		Test.Assert(Get(folder, "/", body..Clear()) == 404);
		Test.Assert(Get(folder, "/samples.json", body..Clear(), "POST") == 404);
		RemoveDirectoryRecursive(folder);
	}
}

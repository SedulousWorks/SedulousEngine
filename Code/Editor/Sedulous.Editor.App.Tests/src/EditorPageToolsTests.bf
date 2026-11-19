using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

// A test asset given a source path, as a scan or a write gives one.
using internal Sedulous.Content;

namespace Sedulous.Editor.App.Tests;

/// The page tools over a real EditorContext with a test page factory: the list, opening by
/// guid (and focusing an already open page), the in place reload through the page's own hook,
/// the unsaved changes refusals of reload and close and the arguments that override them, and
/// the identity every tool returns.
class EditorPageToolsTests
{
	class PagedAsset
	{
	}

	class TestPage : EditorPage
	{
		private String mTitle = new .() ~ delete _;

		public this(StringView title)
		{
			mTitle.Set(title);
		}

		public override StringView Title => mTitle;

		public override Result<void, ErrorCode> Save()
		{
			ClearDirty();
			return .Ok;
		}

		public int Reloads = 0;
		public override void OnAssetExternallyModified() { Reloads++; }
		/// Discard reads the file again for a change made outside the history.
		public bool Readable = true;
		public override bool ReloadFromSource() => Readable;
	}

	class TestPageFactory : IEditorPageFactory
	{
		public int Created = 0;

		public Type PrimaryType => typeof(PagedAsset);

		public EditorPage CreatePage(EditorContext context, Instance instance)
		{
			Created++;
			return new TestPage(instance.Name);
		}
	}

	/// A tools/call's answer: the payload when it succeeded, OWNED, or the error text.
	class Answer
	{
		public bool Ok;
		public JsonValue Payload ~ delete _;
		public String Error = new .() ~ delete _;
	}

	private static Answer Call(McpServer server, StringView tool, StringView argumentsJson)
	{
		let line = scope String();
		line.AppendF("{{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{{\"name\":\"{}\",\"arguments\":{}}}}}", tool, argumentsJson);
		let reply = scope String();
		Test.Assert(server.HandleLine(line, reply) == .Answered);
		let response = JsonValue.Parse(reply);
		defer delete response;
		let result = response.Get("result");
		let answer = new Answer();
		answer.Ok = !result.Get("isError").AsBool();
		let text = result.Get("content").At(0).Get("text").AsString();
		if (answer.Ok)
			answer.Payload = JsonValue.Parse(text);
		else
			answer.Error.Set(text);
		return answer;
	}

	private static void GuidArgument(Guid id, StringView extra, String outText)
	{
		outText.AppendF("{{\"guid\":\"{}\"{}}}", id, extra);
	}

	[Test]
	public static void ListOpenFocusAndTheDirtyRefusalsOfReloadAndClose()
	{
		RemoveDirectoryRecursive("mcp_page_tools_project");
		defer RemoveDirectoryRecursive("mcp_page_tools_project");
		Test.Assert(EditorProject.Create("mcp_page_tools_project", "Pages") case .Ok);
		let project = EditorProject.Open("mcp_page_tools_project");
		Test.Assert(project != null);
		defer delete project;
		let pagedType = typeof(PagedAsset).GetFullName(.. scope .());
		let one = project.SourceDb.RootGroup.CreateInstance("One", pagedType);
		let two = project.SourceDb.RootGroup.CreateInstance("Two", pagedType);

		let context = scope EditorContext();
		let factory = new TestPageFactory();
		context.Pages.Register(factory);

		// The seams a test supplies: the context's own open and close (no panels here).
		int closes = 0;
		let seams = new PageToolSeams();
		seams.Context = context;
		seams.OpenPage = new [&](id) =>
			{
				let instance = project.SourceDb.GetInstance(id);
				return (instance != null) ? context.OpenPage(instance) : null;
			};
		seams.ClosePage = new [&](page) =>
			{
				closes++;
				context.ClosePage(page);
			};
		let server = scope McpServer();
		EditorPageTools.Register(server, seams);
		Test.Assert(server.ToolCount == EditorPageTools.cPageToolCount);

		// Nothing open yet.
		{
			let listed = Call(server, "page_list", "{}");
			defer delete listed;
			Test.Assert(listed.Ok);
			Test.Assert(listed.Payload.Get("pages").Count == 0);
		}

		// Open by guid: created once, active, clean; opening again focuses instead of recreating.
		let oneGuid = GuidArgument(one.Id, "", .. scope .());
		let twoGuid = GuidArgument(two.Id, "", .. scope .());
		{
			let opened = Call(server, "page_open", oneGuid);
			defer delete opened;
			Test.Assert(opened.Ok, opened.Error);
			Test.Assert(opened.Payload.Get("title").AsString() == "One");
			Test.Assert(opened.Payload.Get("active").AsBool());
			Test.Assert(!opened.Payload.Get("dirty").AsBool());
			Test.Assert(factory.Created == 1);
		}
		delete Call(server, "page_open", twoGuid);
		Test.Assert(context.ActivePage.InstanceId == two.Id);
		EditorPage revealed = null;
		context.OnRevealPage = new [&](shown) => { revealed = shown; };
		{
			let again = Call(server, "page_open", oneGuid);
			defer delete again;
			Test.Assert(again.Ok);
			Test.Assert(factory.Created == 2); // focused, not recreated
			Test.Assert(context.ActivePage.InstanceId == one.Id);
			Test.Assert(revealed === context.ActivePage); // and its tab raised: a background tab stays hidden otherwise
		}
		{
			let listed = Call(server, "page_list", "{}");
			defer delete listed;
			Test.Assert(listed.Ok);
			Test.Assert(listed.Payload.Get("pages").Count == 2);
		}

		// Unknown guids and a malformed one are refusals, not pages.
		{
			let unknown = Call(server, "page_open", "{\"guid\":\"00000000-0000-0000-0000-000000000000\"}");
			defer delete unknown;
			Test.Assert(!unknown.Ok);
			Test.Assert(unknown.Error.StartsWith("no asset with guid"), unknown.Error);
			let malformed = Call(server, "page_open", "{\"guid\":\"nope\"}");
			defer delete malformed;
			Test.Assert(!malformed.Ok);
			Test.Assert(malformed.Error.StartsWith("invalid guid"), malformed.Error);
		}

		// A clean page reloads in place: the same page object, refreshed through its hook, never
		// closed or recreated.
		let pageOne = (TestPage)context.ActivePage;
		{
			let reload = Call(server, "page_reload", oneGuid);
			defer delete reload;
			Test.Assert(reload.Ok, reload.Error);
			Test.Assert(pageOne.Reloads == 1);
			Test.Assert(closes == 0);
			Test.Assert(factory.Created == 2);
			Test.Assert(context.ActivePage == pageOne);
		}
		// A dirty page refuses reload and close; force discards THEN refreshes, discard drops.
		pageOne.MarkDirty();
		{
			let reload = Call(server, "page_reload", oneGuid);
			defer delete reload;
			Test.Assert(!reload.Ok);
			Test.Assert(reload.Error.StartsWith("page 'One' has unsaved changes"), reload.Error);
			Test.Assert(pageOne.Reloads == 1);
		}
		{
			let reload = Call(server, "page_reload", GuidArgument(one.Id, ",\"force\":true", .. scope .()));
			defer delete reload;
			Test.Assert(reload.Ok, reload.Error);
			Test.Assert(pageOne.Reloads == 2);
			Test.Assert(!pageOne.IsDirty);
			Test.Assert(closes == 0);
			Test.Assert(factory.Created == 2);
			Test.Assert(!reload.Payload.Get("dirty").AsBool());
			Test.Assert(reload.Payload.Get("active").AsBool());
			Test.Assert(context.OpenPages.Count == 2);
		}
		// A file that does not read cannot be gone back to: the changes stay, and the call says so.
		pageOne.Readable = false;
		pageOne.MarkDirty();
		{
			let reload = Call(server, "page_reload", GuidArgument(one.Id, ",\"force\":true", .. scope .()));
			defer delete reload;
			Test.Assert(!reload.Ok);
			Test.Assert(reload.Error.Contains("could not be discarded"), reload.Error);
			Test.Assert(pageOne.IsDirty);
			Test.Assert(pageOne.Reloads == 2);
		}
		pageOne.Readable = true;

		pageOne.MarkDirty();
		{
			let close = Call(server, "page_close", oneGuid);
			defer delete close;
			Test.Assert(!close.Ok);
			Test.Assert(close.Error.StartsWith("page 'One' has unsaved changes"), close.Error);
		}
		{
			let close = Call(server, "page_close", GuidArgument(one.Id, ",\"discard\":true", .. scope .()));
			defer delete close;
			Test.Assert(close.Ok, close.Error);
			Test.Assert(close.Payload.Get("closed").AsBool());
			Test.Assert(closes == 1);
			Test.Assert(context.OpenPages.Count == 1);
		}
		// Reloading a page that is not open is a refusal that points at the tools to use.
		{
			let reload = Call(server, "page_reload", oneGuid);
			defer delete reload;
			Test.Assert(!reload.Ok);
			Test.Assert(reload.Error.StartsWith("no open page for guid"), reload.Error);
		}
	}

	/// code_open hands a code asset, a Code/ file or the Code folder to the code opener at the
	/// line asked, and refuses what is not the project's code.
	[Test]
	public static void CodeOpenHandsCodeToTheOpenerAndRefusesWhatIsNotTheProjectsCode()
	{
		RemoveDirectoryRecursive("mcp_code_open_project");
		defer RemoveDirectoryRecursive("mcp_code_open_project");
		Test.Assert(EditorProject.Create("mcp_code_open_project", "Code") case .Ok);
		let project = EditorProject.Open("mcp_code_open_project");
		Test.Assert(project != null);
		defer delete project;
		let pagedType = typeof(PagedAsset).GetFullName(.. scope .());
		let script = project.SourceDb.RootGroup.CreateInstance("Player", pagedType);
		let level = project.SourceDb.RootGroup.CreateInstance("Level", pagedType);
		Test.Assert((script != null) && (level != null));
		script.SetSourceName("Code/Scripts/Player.as");
		level.SetSourceName("Levels/Level.scene");
		let file = project.SourceFile("Code/Scripts/Player.as", .. scope .());
		CreateDirectory(PathParent(file, .. scope .()));
		let text = "void Main() {}";
		Test.Assert(WriteFile(file, .((uint8*)text.Ptr, text.Length)) case .Ok);
		// A file beside the Code folder, which a path up from it would reach.
		let escape = project.SourceFile("Code/../escape.as", .. scope .());
		Test.Assert(WriteFile(escape, .((uint8*)text.Ptr, text.Length)) case .Ok);
		Test.Assert(FileExists(escape));

		let openedFiles = scope List<String>();
		defer { ClearAndDeleteItems(openedFiles); }
		let openedAt = scope List<(uint32 Line, uint32 Column)>();
		let context = scope EditorContext();
		let seams = new PageToolSeams();
		seams.Context = context;
		seams.OpenCode = new [&] (path, line, column) =>
			{
				openedFiles.Add(new String(path));
				openedAt.Add((line, column));
				return true;
			};
		let server = scope McpServer();
		EditorPageTools.Register(server, seams);

		// With no project in the editor, nothing opens.
		{
			let answer = Call(server, "code_open", "{}");
			defer delete answer;
			Test.Assert(!answer.Ok);
		}
		context.SetProject(project);
		defer context.SetProject(null); // before the project goes

		// A code asset at a line and column: the opener gets its file on disk.
		{
			let answer = Call(server, "code_open", scope String()..AppendF("{{\"guid\":\"{}\",\"line\":12,\"column\":3}}", script.Id));
			defer delete answer;
			Test.Assert(answer.Ok, answer.Error);
			Test.Assert(answer.Payload.Get("file").AsString() == "Code/Scripts/Player.as");
			Test.Assert(openedFiles.Count == 1);
			Test.Assert(openedFiles[0] == file);
			Test.Assert((openedAt[0].Line == 12) && (openedAt[0].Column == 3));
		}
		// The same file by its path, at the start.
		{
			let answer = Call(server, "code_open", "{\"path\":\"Code/Scripts/Player.as\"}");
			defer delete answer;
			Test.Assert(answer.Ok, answer.Error);
			Test.Assert((openedFiles.Count == 2) && (openedFiles[1] == file) && (openedAt[1].Line == 0));
		}
		// Neither: the Code folder, as an empty file.
		{
			let answer = Call(server, "code_open", "{}");
			defer delete answer;
			Test.Assert(answer.Ok, answer.Error);
			Test.Assert(answer.Payload.Get("file").AsString() == "Code");
			Test.Assert((openedFiles.Count == 3) && openedFiles[2].IsEmpty);
		}

		// Refused, nothing opened: an asset that is not code, a path out of the Code folder or
		// up from it, a file not there, an unknown guid, both at once, a negative line.
		let refused = scope List<String>();
		defer { ClearAndDeleteItems(refused); }
		refused.Add(new String()..AppendF("{{\"guid\":\"{}\"}}", level.Id));
		refused.Add(new String("{\"path\":\"Levels/Level.scene\"}"));
		refused.Add(new String("{\"path\":\"Code/../escape.as\"}"));
		refused.Add(new String("{\"path\":\"Code/Missing.as\"}"));
		refused.Add(new String("{\"guid\":\"00000000-0000-0000-0000-00000000c0de\"}"));
		refused.Add(new String()..AppendF("{{\"guid\":\"{}\",\"path\":\"Code/Scripts/Player.as\"}}", script.Id));
		refused.Add(new String("{\"path\":\"Code/Scripts/Player.as\",\"line\":-1}"));
		for (let arguments in refused)
		{
			let answer = Call(server, "code_open", arguments);
			defer delete answer;
			Test.Assert(!answer.Ok, arguments);
		}
		Test.Assert(openedFiles.Count == 3);
	}
}

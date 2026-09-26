using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The page tools over a real EditorContext with a test page factory: the list, opening by
/// guid (and focusing an already open page), the unsaved changes refusals of reload and close
/// and the arguments that override them, and the identity every tool returns.
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
		{
			let again = Call(server, "page_open", oneGuid);
			defer delete again;
			Test.Assert(again.Ok);
			Test.Assert(factory.Created == 2); // focused, not recreated
			Test.Assert(context.ActivePage.InstanceId == one.Id);
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

		// A dirty page refuses reload and close; force and discard override, and reload reopens.
		context.ActivePage.MarkDirty();
		{
			let reload = Call(server, "page_reload", oneGuid);
			defer delete reload;
			Test.Assert(!reload.Ok);
			Test.Assert(reload.Error.StartsWith("page 'One' has unsaved changes"), reload.Error);
			Test.Assert(closes == 0);
		}
		{
			let reload = Call(server, "page_reload", GuidArgument(one.Id, ",\"force\":true", .. scope .()));
			defer delete reload;
			Test.Assert(reload.Ok, reload.Error);
			Test.Assert(closes == 1);
			Test.Assert(factory.Created == 3); // closed and reopened
			Test.Assert(!reload.Payload.Get("dirty").AsBool());
			Test.Assert(reload.Payload.Get("active").AsBool());
			Test.Assert(context.OpenPages.Count == 2);
		}

		context.ActivePage.MarkDirty();
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
			Test.Assert(closes == 2);
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
}

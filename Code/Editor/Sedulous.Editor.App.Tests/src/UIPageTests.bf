using System;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// UIEditorPage: a page's content is a GUI node the shell docks, the same node each time it is
/// asked; its frame hooks do nothing unless the page has work of its own.
class UIPageTests
{
	private class NotePage : UIEditorPage
	{
		private Panel mContent = new .() ~ _.ReleaseRef();

		public override StringView Title => "Notes";
		public override Result<void, ErrorCode> Save() => .Ok;
		public override Node Content => mContent;
	}

	[Test]
	public static void ItsContentIsAGuiNodeTheSameEachTimeTheDockAsks()
	{
		let page = scope NotePage();
		let first = page.Content;
		Test.Assert(first != null);
		Test.Assert(page.Content === first);
		page.OnClose(); // nothing of its own to release
	}
}

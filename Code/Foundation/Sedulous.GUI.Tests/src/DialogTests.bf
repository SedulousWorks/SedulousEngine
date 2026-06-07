namespace Sedulous.GUI.Tests;

using System;

class DialogTests
{
	[Test]
	public static void Dialog_HasStyleId()
	{
		let dlg = scope Dialog("Test");
		Test.Assert(dlg.StyleId != null);
		Test.Assert(StringView(dlg.StyleId) == "dialog");
	}

	[Test]
	public static void Dialog_TitleProperty()
	{
		let dlg = scope Dialog("Hello");
		Test.Assert(dlg.Title != null);
		Test.Assert(StringView(dlg.Title) == "Hello");
	}

	[Test]
	public static void Dialog_DefaultResult()
	{
		let dlg = scope Dialog("Test");
		Test.Assert(dlg.Result == .None);
	}

	[Test]
	public static void Alert_Factory()
	{
		let dlg = Dialog.Alert("Title", "Message");
		defer delete dlg;
		Test.Assert(dlg.Title != null);
		Test.Assert(StringView(dlg.Title) == "Title");
	}

	[Test]
	public static void Confirm_Factory()
	{
		let dlg = Dialog.Confirm("Confirm", "Are you sure?");
		defer delete dlg;
		Test.Assert(dlg.Title != null);
		Test.Assert(StringView(dlg.Title) == "Confirm");
	}

	[Test]
	public static void Close_FiresOnClosed()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let dlg = new Dialog("Test");
		dlg.AddButton("OK", .OK);

		bool closed = false;
		DialogResult closedResult = .None;
		dlg.OnClosed.Add(new [&closed, &closedResult] (d, r) =>
		{
			closed = true;
			closedResult = r;
		});

		dlg.Show(ctx, false); // ownsView=false so we control deletion

		Test.Assert(root.PopupLayer.PopupCount == 1);

		dlg.Close(.OK);
		ctx.MutationQueue.Drain();

		Test.Assert(closed);
		Test.Assert(closedResult == .OK);
		Test.Assert(root.PopupLayer.PopupCount == 0);

		delete dlg;
	}

	[Test]
	public static void Show_CreatesModalPopup()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let dlg = new Dialog("Modal Test");
		dlg.Show(ctx, false);

		Test.Assert(root.PopupLayer.PopupCount == 1);
		Test.Assert(root.PopupLayer.HasModalPopup);

		dlg.Close(.Cancel);
		ctx.MutationQueue.Drain();

		Test.Assert(root.PopupLayer.PopupCount == 0);
		Test.Assert(!root.PopupLayer.HasModalPopup);

		delete dlg;
	}
}

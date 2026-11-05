using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Runtime;

namespace Sedulous.Editor.App;

// Add Native Code's dialog: a small window over its markup (Data/Editor/AddNativeCode.xml) that
// asks which parts of the game's plugin package to scaffold, a check box per part kind. A part the
// package already has shows checked and cannot be unchecked; Engine starts checked for a package
// not made yet. Add is enabled while a part the package lacks is checked, and the line under the
// boxes says what it makes. It makes nothing itself: Add hands the parts to make to the request.
// Escape or Cancel closes.

/// What Add Native Code's dialog asks about. Its delegate is owned.
class NativeCodeRequest
{
	/// The package's path in the project ("Plugins/MyGame").
	public String Path = new .() ~ delete _;
	/// The parts the package has (none: not made yet).
	public List<PluginPartKind> Existing = new .() ~ delete _;
	/// Gets the parts to make, in load order, after the dialog has closed.
	public delegate void(Span<PluginPartKind> parts) Accepted ~ delete _;
}

class NativeCodeDialog
{
	/// Its markup, under the data root.
	public const String cMarkupPath = "Editor/AddNativeCode.xml";
	public const float cWidth = 560.0f;
	public const float cHeight = 260.0f;

	/// A reference of ours: its buttons close it from inside their own click, which may let the
	/// tree's reference go.
	private Sedulous.GUI.Window mWindow ~ _?.ReleaseRef();
	// The body's: the window holds them. One per kind, in the kinds' order.
	private Sedulous.GUI.CheckBox[PluginPartKind.Count] mBoxes;
	private Sedulous.GUI.Label mWhat;
	private Sedulous.GUI.Button mAdd;
	private NativeCodeRequest mRequest ~ delete _;

	private this()
	{
	}

	/// Open as it goes, it closes.
	public ~this()
	{
		if ((mWindow != null) && mWindow.IsOpen)
			mWindow.Close();
	}

	/// The check box of `kind`'s id in the markup: native-code-<kind, lower case>.
	public static void BoxId(PluginPartKind kind, String outId)
	{
		outId.Set("native-code-");
		let start = outId.Length;
		kind.ToString(outId);
		for (int i = start; i < outId.Length; i++)
			outId[i] = outId[i].ToLower;
	}

	/// Opens it over `root` with `body` (the markup's) for `request`. Its Accepted is told the parts
	/// after it closes; it must not delete this, whose window's button is still on the stack. The
	/// caller's; deleted while open, it closes. Null when `body` lacks its parts. TAKES OWNERSHIP of
	/// a reference to `body` and of `request`, opened or not.
	public static NativeCodeDialog Open(SceneRoot root, Node body, NativeCodeRequest request)
	{
		if (body == null)
		{
			delete request;
			return null;
		}
		defer body.ReleaseRef(); // the window holds its own
		let what = body.FindElement("native-code-what") as Sedulous.GUI.Label;
		let add = body.FindElement("native-code-add") as Sedulous.GUI.Button;
		let cancel = body.FindElement("native-code-cancel") as Sedulous.GUI.Button;
		Sedulous.GUI.CheckBox[PluginPartKind.Count] boxes = default;
		bool complete = (what != null) && (add != null);
		for (int i < PluginPartKind.Count)
		{
			boxes[i] = body.FindElement(BoxId((PluginPartKind)i, .. scope .())) as Sedulous.GUI.CheckBox;
			complete &= boxes[i] != null;
		}
		if (!complete)
		{
			delete request;
			return null;
		}

		let dialog = new NativeCodeDialog();
		dialog.mBoxes = boxes;
		dialog.mWhat = what;
		dialog.mAdd = add;
		dialog.mRequest = request;

		let window = new Sedulous.GUI.Window();
		dialog.mWindow = window;
		window.Title = request.Existing.IsEmpty ? "Add Native Code" : "Add Native Code Parts";
		window.AddClass("add-native-code-window");
		window.Size = .(cWidth, cHeight);
		window.Content.AddChild(body);
		for (int i < PluginPartKind.Count)
		{
			let kind = (PluginPartKind)i;
			let there = request.Existing.Contains(kind);
			boxes[i].Checked = there || (request.Existing.IsEmpty && (kind == .Engine));
			boxes[i].Enabled = !there;
			boxes[i].SetOnToggled(new [=dialog] (on) => { dialog.Check(); });
		}
		add.SetOnClick(new [=dialog] () => { dialog.Commit(); });
		if (cancel != null)
			cancel.SetOnClick(new [=window] () => { window.Close(); });
		dialog.Check();
		window.OpenModal(root);
		return dialog;
	}

	/// Its window. Ours: a caller that keeps it takes a reference.
	public Sedulous.GUI.Window Window => mWindow;
	public bool IsOpen => mWindow.IsOpen;

	/// The parts checked that the package lacks, in load order, appended.
	public void Chosen(List<PluginPartKind> outParts)
	{
		for (int i < PluginPartKind.Count)
		{
			let kind = (PluginPartKind)i;
			if (mBoxes[i].Checked && !mRequest.Existing.Contains(kind))
				outParts.Add(kind);
		}
	}

	/// Add waits while no part the package lacks is checked; the line under the boxes says what
	/// it makes.
	private void Check()
	{
		let parts = Chosen(.. scope .());
		mAdd.Enabled = !parts.IsEmpty;
		if (parts.IsEmpty)
		{
			mWhat.Text = "Check a part the package does not have yet.";
			return;
		}
		let names = scope String();
		for (let kind in parts)
		{
			if (!names.IsEmpty)
				names.Append(", ");
			kind.ToString(names);
		}
		let plural = (parts.Count == 1) ? "" : "s";
		if (mRequest.Existing.IsEmpty)
			mWhat.Text = scope $"Makes {mRequest.Path} with its {names} part{plural}, and enables it.";
		else
			mWhat.Text = scope $"Adds the {names} part{plural} to {mRequest.Path}.";
	}

	/// Add: nothing while no part is chosen; else it closes, then the request is told the parts.
	private void Commit()
	{
		let parts = Chosen(.. scope .());
		if (parts.IsEmpty)
			return;
		let accepted = mRequest.Accepted;
		mRequest.Accepted = null;
		defer delete accepted;
		mWindow.Close();
		if (accepted != null)
			accepted((Span<PluginPartKind>)parts);
	}
}

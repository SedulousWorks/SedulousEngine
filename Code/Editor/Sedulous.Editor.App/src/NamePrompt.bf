using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.Editor.App;

// The name prompt: a small window over its markup (Data/Editor/NamePrompt.xml) that asks for one
// name, for whatever is about to be made where the user already is (a new group in the Assets
// panel or the group picker, a new asset in the Assets panel). It makes nothing itself: its request
// says how a name is refused and what accepting makes, and gets the accepted name. The name is
// checked as it is typed; while it is refused the accept button does nothing and the line under the
// field says why, and otherwise that line says what will be made. Enter accepts; Escape or Cancel
// closes.

/// What a name prompt asks for. Its delegates are owned.
class NameRequest
{
	/// The window's title ("New Group in Models").
	public String Title = new .() ~ delete _;
	/// The name it starts with, selected so typing replaces it.
	public String Suggested = new .() ~ delete _;
	/// The accept button's text ("Create"); empty: the markup's.
	public String Accept = new .() ~ delete _;
	/// Why `name` is refused, appended to `outWhy` (nothing: accepted); null accepts any.
	public delegate void(StringView name, String outWhy) Refusal ~ delete _;
	/// What accepting `name` makes, appended to `outText` ("Makes the group Props in Models."); null
	/// says nothing.
	public delegate void(StringView name, String outText) Describe ~ delete _;
	/// Gets the accepted name, after the prompt has closed.
	public delegate void(StringView name) Accepted ~ delete _;
}

class NamePrompt
{
	/// Its markup, under the data root.
	public const String cMarkupPath = "Editor/NamePrompt.xml";
	public const float cWidth = 400.0f;
	public const float cHeight = 160.0f;

	/// A reference of ours: its buttons close it from inside their own click, which may let the
	/// tree's reference go.
	private Sedulous.GUI.Window mWindow ~ _?.ReleaseRef();
	// The body's: the window holds them.
	private TextField mName;
	private Sedulous.GUI.Label mWhy;
	private Sedulous.GUI.Button mAccept;
	private NameRequest mRequest ~ delete _;

	private this()
	{
	}

	/// Open as it goes, it closes.
	public ~this()
	{
		if ((mWindow != null) && mWindow.IsOpen)
			mWindow.Close();
	}

	/// Opens it over `root` with `body` (the markup's) for `request`. Its Accepted is told the name
	/// after it closes; it must not delete this, whose window's button is still on the stack. The
	/// caller's; deleted while open, it closes. Null when `body` lacks its parts. TAKES OWNERSHIP of
	/// a reference to `body` and of `request`, opened or not.
	public static NamePrompt Open(SceneRoot root, Node body, NameRequest request)
	{
		if (body == null)
		{
			delete request;
			return null;
		}
		defer body.ReleaseRef(); // the window holds its own
		let name = body.FindElement("name-prompt-name") as TextField;
		let why = body.FindElement("name-prompt-why") as Sedulous.GUI.Label;
		let accept = body.FindElement("name-prompt-accept") as Sedulous.GUI.Button;
		let cancel = body.FindElement("name-prompt-cancel") as Sedulous.GUI.Button;
		if ((name == null) || (why == null) || (accept == null))
		{
			delete request;
			return null;
		}

		let prompt = new NamePrompt();
		prompt.mName = name;
		prompt.mWhy = why;
		prompt.mAccept = accept;
		prompt.mRequest = request;

		let window = new Sedulous.GUI.Window();
		prompt.mWindow = window;
		window.Title = request.Title;
		window.AddClass("name-prompt-window");
		window.Size = .(cWidth, cHeight);
		window.Content.AddChild(body);
		if (!request.Accept.IsEmpty)
			accept.Text = request.Accept;
		name.SetOnTextChanging(new [=prompt] (text) => { prompt.Check(); });
		name.SetOnSubmit(new [=prompt] (text) => { prompt.Commit(); });
		accept.SetOnClick(new [=prompt] () => { prompt.Commit(); });
		if (cancel != null)
			cancel.SetOnClick(new [=window] () => { window.Close(); });
		name.Text = request.Suggested;
		prompt.Check();
		window.OpenModal(root);
		name.FocusElement();
		name.SelectAll();
		return prompt;
	}

	/// Its window. Ours: a caller that keeps it takes a reference.
	public Sedulous.GUI.Window Window => mWindow;
	public bool IsOpen => mWindow.IsOpen;

	/// Why `name` is refused, appended (nothing: accepted).
	private void Refused(StringView name, String outWhy)
	{
		if (mRequest.Refusal != null)
			mRequest.Refusal(name, outWhy);
	}

	/// The accept button waits while the name is refused, the line under the name saying why (red),
	/// else what it makes.
	private void Check()
	{
		let refused = Refused(mName.Text, .. scope .());
		mAccept.Enabled = refused.IsEmpty;
		if (refused.IsEmpty)
		{
			mWhy.RemoveClass("refused");
			let makes = scope String();
			if (mRequest.Describe != null)
				mRequest.Describe(mName.Text, makes);
			mWhy.Text = makes;
		}
		else
		{
			mWhy.AddClass("refused");
			mWhy.Text = refused;
		}
	}

	/// Accept (or Enter in the name): a refused name waits, the line saying why; else it closes, then
	/// the request is told the name.
	private void Commit()
	{
		let chosen = scope String(mName.Text);
		if (!Refused(chosen, .. scope .()).IsEmpty)
			return; // it waits; the line says why
		let accepted = mRequest.Accepted;
		mRequest.Accepted = null;
		defer delete accepted;
		mWindow.Close();
		if (accepted != null)
			accepted(chosen);
	}
}

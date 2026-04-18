namespace UISandbox;

using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Demo page: EditText, PasswordBox, filters, read-only, multiline.
class TextEditingPage : DemoPage
{
	public this(DemoContext demo) : base(demo)
	{
		AddSection("EditText");
		{
			let edit = new EditText();
			edit.SetPlaceholder("Type here...");
			mLayout.AddView(edit, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 28 });
		}

		AddSection("PasswordBox");
		{
			let pw = new PasswordBox();
			pw.SetPlaceholder("Password...");
			mLayout.AddView(pw, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 28 });
		}

		AddSection("Filtered Input");
		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 6;
			mLayout.AddView(row, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 28 });

			let digits = new EditText();
			digits.SetPlaceholder("Digits only");
			digits.Filter = InputFilter.Digits();
			row.AddView(digits, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = Sedulous.UI.LayoutParams.MatchParent, Weight = 1 });

			let maxLen = new EditText();
			maxLen.SetPlaceholder("Max 8 chars");
			maxLen.MaxLength = 8;
			row.AddView(maxLen, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = Sedulous.UI.LayoutParams.MatchParent, Weight = 1 });
		}

		AddSection("Read-only");
		{
			let ro = new EditText();
			ro.SetText("Read-only text (try to edit)");
			ro.IsReadOnly = true;
			mLayout.AddView(ro, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 28 });
		}

		AddSection("Multiline");
		{
			let multi = new EditText();
			multi.Multiline = true;
			multi.SetPlaceholder("Multi-line text...");
			mLayout.AddView(multi, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 120 });
		}
	}
}

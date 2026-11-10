// The Code page's sample: a counter for a page, as a game's own code would write it.
// It is only shown here, never compiled.
using System;
using Sedulous.GUI;

class Counter
{
	private int mClicks = 0;

	/// The label says how many times the button was pressed.
	private void Show(Label label)
	{
		let unit = (mClicks == 1) ? "time" : "times";
		label.Text = scope $"Pressed {mClicks} {unit}";
	}

	/// Counts the button's clicks into the label beside it.
	public void Attach(Node root)
	{
		let label = root.FindElement("counter-label") as Label;
		if (let button = root.FindElement("counter-button"))
		{
			button.On("click", new (e) =>
				{
					mClicks++;
					Show(label);
					button.Animate("opacity", "0.6", 0.1f, "ease-out").ReleaseRef();
					return true;
				});
		}
	}

	public void Reset(Label label)
	{
		mClicks = 0;
		Show(label);
	}
}

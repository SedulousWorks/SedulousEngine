using Sedulous.Runtime.Client;
using Sedulous.Runtime;
namespace GUISandbox;

class GUISandboxApp: Application
{
	protected override void OnInitialize(Context context)
	{
	}

	protected override void OnInput(FrameContext frame)
	{
	}

	protected override bool OnRenderFrame(RenderContext render)
	{
		return false;// switch to true when we start rendering here
	}

	protected override void OnShutdown()
	{
		// clean up here
	}
}
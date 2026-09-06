using SDL2;
using System;
namespace VulkanTriangle;

extension VulkanTriangle
{
	typealias RenderCallbackDelegate = delegate void();

	const uint WIDTH = 800;
	const uint HEIGHT = 600;

	private SDL.Window* window;
	private void* NativeWindow;
	private void* Display; // X11

	private void InitWindow()
	{
		const bool visible = true;
		String title = scope String("Hello");


		if (SDL.Init(.Everything) < 0)
		{
			String errorMessage = scope String();
			errorMessage.AppendF("SDL initialization failed: {0}", SDL.GetError());
			Runtime.FatalError(errorMessage);
		}

		SDL.WindowFlags flags = (visible ? .Shown : .Hidden) /*| SDL.WindowFlags.Resizable*/ | SDL.WindowFlags.Vulkan;

		window = SDL.CreateWindow(title, .Undefined, .Undefined, (int32)WIDTH, (int32)HEIGHT, flags);
		SDL.GL_SetAttribute(SDL.SDL_GLAttr.GL_CONTEXT_PROFILE_MASK, 1);
		if (window == null)
		{
			Runtime.FatalError("Failed to create SDL window.");
		}

		SDL.SDL_SysWMinfo info = .();
		SDL.GetVersion(out info.version);
		SDL.GetWindowWMInfo(window, ref info);
		SDL.SDL_SYSWM_TYPE subsystem = info.subsystem;
		switch (subsystem) {
#if BF_PLATFORM_WINDOWS
		case SDL.SDL_SYSWM_TYPE.SDL_SYSWM_WINDOWS:
			NativeWindow = (void*)(int)info.info.win.window;
			break;
#endif

		case SDL.SDL_SYSWM_TYPE.SDL_SYSWM_X11:
			NativeWindow = info.info.x11.window;
			Display = info.info.x11.display;
			break;

		case SDL.SDL_SYSWM_TYPE.SDL_SYSWM_UNKNOWN:
			fallthrough;
		default:
			Runtime.FatalError("Subsystem not currently supported.");
		}
	}

	private void DestroyWindow()
	{
		if (window != null)
		{
			SDL.DestroyWindow(window);
			window = null;
		}
		//////////////////////////////////////////////////////////////

		SDL.Quit();
	}


	private void MainLoop(RenderCallbackDelegate renderCallback)
	{
		bool running = true;

		SDL.Event ev = .();

		SDL.PumpEvents();
		while (running)
		{
			while (SDL.PollEvent(out ev) != 0)
			{
				this.OnEvent(ev);

				if (ev.type == .Quit)
				{
					running = false;
				}
			}

			renderCallback();
		}
	}

	private void OnEvent(SDL.Event ev)
	{
		if (ev.type == SDL.EventType.WindowEvent)
		{
			var windowEvent = ev.window;
			if (windowEvent.windowEvent != .SizeChanged)
			{
				switch (windowEvent.windowEvent) {
				case .FocusGained:
					OnFocusGained();
					break;

				case .Focus_lost:
					OnFocusLost();
					break;

				case .Close:
					OnClosing();
					break;

				default:
					break;
				}
			} else
			{
				int32 width = 0;
				int32 height = 0;
				SDL.GetWindowSize(window, out width, out height);

				OnSizeChanged((uint32)width, (uint32)height);
			}
		}
	}

	private static void OnFocusGained() { }
	private static void OnFocusLost() { }
	private static void OnClosing() { }
	private static void OnSizeChanged(uint32 width, uint32 height)
	{
	}
}

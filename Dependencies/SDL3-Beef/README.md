# SDL3 Beef Bindings

This project provides **Beef** bindings for **SDL3**, offering a low-level interface to the SDL (Simple DirectMedia Layer) library. These bindings cover almost all of SDL3, excluding standalone OpenGL, Metal, and Vulkan APIs.

## Features
- Complete binding to **SDL3** (except standalone OpenGL, Metal, and Vulkan APIs)
- Direct mapping of SDL3 functions, structures, and enumerations
- Supports **windowing, input handling, audio, events, surfaces, and more**
- Designed for **performance and ease of use** in Beef

## Getting Started

### Prerequisites
- **Beef** compiler and IDE
- **SDL3 library** (Only required on non-Windows systems. Windows users can use the provided SDL binaries.)

### Installation
1. Clone this repository:
   ```sh
   git clone https://github.com/jayrulez/SDL3-Beef.git
   ```
2. (For Windows) The required SDL binaries are included, so no additional installation is needed.
3. (For non-Windows users) Ensure SDL3 is installed and available on your system.
4. Add the bindings to your Beef project.

### Usage
Add SDLNative as a dependency to your Beef project:
```beef
using SDL3;
```
Example: Creating a window
```beef
using System.Diagnostics;
using SDL3;

class Program
{
	public static void Main()
	{
		if (!SDL_Init(.SDL_INIT_VIDEO))
		{
			Debug.WriteLine("SDL_Init failed: {0}", SDL_GetError());
			return;
		}
		defer SDL_Quit();

		let window = SDL_CreateWindow("SDL3 Beef", 1280, 720, .SDL_WINDOW_RESIZABLE);
		if (window == null)
		{
			Debug.WriteLine("SDL_CreateWindow failed: {0}", SDL_GetError());
			return;
		}
		defer SDL_DestroyWindow(window);

		while (true)
		{
			SDL_Event ev = .();
			while (SDL_PollEvent(&ev))
			{
				if (ev.type == (.)SDL_EventType.SDL_EVENT_QUIT)
					return;
			}
			SDL_Delay(16);
		}
	}
}
```

## Missing Features
- OpenGL, Metal, and Vulkan standalone APIs are **not** currently included in this binding.
- Future enhancements may add support if needed.

## Contributing
- If you find issues or want to contribute, feel free to open a pull request or submit an issue.

## License
This project is released under the **MIT License**.

---

**Credits:** Huge thanks to the SDL3 developers and the Beef community!


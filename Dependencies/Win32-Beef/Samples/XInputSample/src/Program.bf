using Win32.Foundation;
using Win32.UI.Input.XboxController;
using Win32.Graphics.Gdi;
using Win32.UI.WindowsAndMessaging;
using Win32.System.Com;
using Win32.System.LibraryLoader;
using System;
using Win32;
using Win32.System.Threading;
namespace XInputSample;

struct CONTROLLER_STATE
{
	public XINPUT_STATE State;
	public bool Connected;
}

class Program
{
	const uint32 MAX_CONTROLLERS = 4; // XInput handles up to 4 controllers
	const float INPUT_DEADZONE   = (0.24f * float(0x7FFF)); // Default to 24% of the +/- 32767 range.   This is a reasonable default value but can be altered if needed.

	static CONTROLLER_STATE[MAX_CONTROLLERS] g_Controllers;
	static String[4] g_szMessage = .(new .(), new .(), new .(), new .()) ~
		{
			for (var item in _)
			{
				delete item;
			}
		};
	static HWND    g_hWnd;
	static bool    g_bDeadZoneOn = true;

	/*
	public uint32 cbSize;
	public WNDCLASS_STYLES style;
	public WNDPROC lpfnWndProc;
	public int32 cbClsExtra;
	public int32 cbWndExtra;
	public HINSTANCE hInstance;
	public HICON hIcon;
	public HCURSOR hCursor;
	public HBRUSH hbrBackground;
	public PSTR lpszMenuName;
	public PSTR lpszClassName;
	public HICON hIconSm;
	*/

	static void Main()
	{
		// Initialize COM
		//HRESULT hr = CoInitializeEx(null, .COINIT_MULTITHREADED);
		//if (FAILED(hr))
		//	return;
		//defer CoUninitialize();

		// Register the window class
		//HBRUSH hBrush = CreateSolidBrush( 0xFF0000 );
		WNDCLASSEXW wc = .();
		wc.cbSize = sizeof(WNDCLASSEXW);
		wc.style = .CS_HREDRAW | .CS_VREDRAW;
		wc.lpfnWndProc = => MsgProc;
		wc.hInstance = GetModuleHandle(null);
		wc.hIcon = LoadIconW(0, IDI_APPLICATION);
		wc.hCursor = LoadCursorW(0, IDC_ARROW);
		wc.lpszClassName = scope String("MyWindowClass").ToScopedNativeWChar!();
		wc.hIconSm = LoadIconW(0, IDI_APPLICATION);

		if (RegisterClassExW(&wc) == 0)
		{
			MessageBoxA(0, (uint8*)"RegisterClassEx failed", (uint8*)"Fatal Error", .MB_OK);
			return;
		}

		// Clean up
		defer UnregisterClass((.)scope String("XInputSample").CStr(), 0);

		// Create the application's window

		RECT initialRect = .(0, 0, 1024, 768);
		AdjustWindowRectEx(&initialRect, .WS_OVERLAPPEDWINDOW, FALSE, .WS_EX_OVERLAPPEDWINDOW);
		int64 initialWidth = initialRect.right - initialRect.left;
		int64 initialHeight = initialRect.bottom - initialRect.top;

		g_hWnd = CreateWindowExW(.WS_EX_OVERLAPPEDWINDOW,
			wc.lpszClassName,
			scope String("XInput Sample").ToScopedNativeWChar!(),
			.WS_OVERLAPPEDWINDOW | .WS_VISIBLE,
			CW_USEDEFAULT, CW_USEDEFAULT,
			(int32)initialWidth,
			(int32)initialHeight,
			0, 0, GetModuleHandle(null), null);

		// Init state
		//ZeroMemory( g_Controllers, sizeof( CONTROLLER_STATE ) * MAX_CONTROLLERS );
		g_Controllers = .();

		// Enter the message loop
		bool bGotMsg;
		MSG msg;
		msg.message = WM_NULL;

		while (WM_QUIT != msg.message)
		{
			// Use PeekMessage() so we can use idle time to render the scene and call pEngine->DoWork()
			bGotMsg = (PeekMessage(&msg, 0, 0U, 0U, .PM_REMOVE) != 0);

			if (bGotMsg)
			{
				// Translate and dispatch the message
				TranslateMessage(&msg);
				DispatchMessage(&msg);
			}
			else
			{
				UpdateControllerState();
				RenderFrame();
			}
		}
	}

	static HRESULT UpdateControllerState()
	{
		uint32 dwResult;
		for (uint32 i = 0; i < MAX_CONTROLLERS; i++)
		{
			// Simply get the state of the controller from XInput.
			dwResult = XInputGetState(i, &g_Controllers[i].State);

			if (dwResult == (.)WIN32_ERROR.ERROR_SUCCESS)
				g_Controllers[i].Connected = true;
			else
				g_Controllers[i].Connected = false;
		}

		return S_OK;
	}

	static void RenderFrame()
	{
		bool bRepaint = false;

		String[4] sz = .(scope .(), scope .(), scope .(), scope .());
		for (uint32 i = 0; i < MAX_CONTROLLERS; i++)
		{
			if (g_Controllers[i].Connected)
			{
				XINPUT_GAMEPAD_BUTTON_FLAGS wButtons = g_Controllers[i].State.Gamepad.wButtons;

				if (g_bDeadZoneOn)
				{
					// Zero value if thumbsticks are within the dead zone
					if ((g_Controllers[i].State.Gamepad.sThumbLX < INPUT_DEADZONE &&
						g_Controllers[i].State.Gamepad.sThumbLX > -INPUT_DEADZONE) &&
						(g_Controllers[i].State.Gamepad.sThumbLY < INPUT_DEADZONE &&
						g_Controllers[i].State.Gamepad.sThumbLY > -INPUT_DEADZONE))
					{
						g_Controllers[i].State.Gamepad.sThumbLX = 0;
						g_Controllers[i].State.Gamepad.sThumbLY = 0;
					}

					if ((g_Controllers[i].State.Gamepad.sThumbRX < INPUT_DEADZONE &&
						g_Controllers[i].State.Gamepad.sThumbRX > -INPUT_DEADZONE) &&
						(g_Controllers[i].State.Gamepad.sThumbRY < INPUT_DEADZONE &&
						g_Controllers[i].State.Gamepad.sThumbRY > -INPUT_DEADZONE))
					{
						g_Controllers[i].State.Gamepad.sThumbRX = 0;
						g_Controllers[i].State.Gamepad.sThumbRY = 0;
					}
				}

				sz[i].AppendF("""
Controller {}: Connected
Buttons: {}{}{}{}{}{}{}{}{}{}{}{}{}{}
Left Trigger: {}
Right Trigger: {}
Left Thumbstick: {}/{}
Right Thumbstick: {}/{}
""",
					i,
					(wButtons & .XINPUT_GAMEPAD_DPAD_UP != 0) ? "DPAD_UP " : "",
					(wButtons & .XINPUT_GAMEPAD_DPAD_DOWN  != 0) ? "DPAD_DOWN " : "",
					(wButtons & .XINPUT_GAMEPAD_DPAD_LEFT  != 0) ? "DPAD_LEFT " : "",
					(wButtons & .XINPUT_GAMEPAD_DPAD_RIGHT  != 0) ? "DPAD_RIGHT " : "",
					(wButtons & .XINPUT_GAMEPAD_START  != 0) ? "START " : "",
					(wButtons & .XINPUT_GAMEPAD_BACK  != 0) ? "BACK " : "",
					(wButtons & .XINPUT_GAMEPAD_LEFT_THUMB  != 0) ? "LEFT_THUMB " : "",
					(wButtons & .XINPUT_GAMEPAD_RIGHT_THUMB  != 0) ? "RIGHT_THUMB " : "",
					(wButtons & .XINPUT_GAMEPAD_LEFT_SHOULDER  != 0) ? "LEFT_SHOULDER " : "",
					(wButtons & .XINPUT_GAMEPAD_RIGHT_SHOULDER  != 0) ? "RIGHT_SHOULDER " : "",
					(wButtons & .XINPUT_GAMEPAD_A  != 0) ? "A " : "",
					(wButtons & .XINPUT_GAMEPAD_B  != 0) ? "B " : "",
					(wButtons & .XINPUT_GAMEPAD_X  != 0) ? "X " : "",
					(wButtons & .XINPUT_GAMEPAD_Y  != 0) ? "Y " : "",
					g_Controllers[i].State.Gamepad.bLeftTrigger,
					g_Controllers[i].State.Gamepad.bRightTrigger,
					g_Controllers[i].State.Gamepad.sThumbLX,
					g_Controllers[i].State.Gamepad.sThumbLY,
					g_Controllers[i].State.Gamepad.sThumbRX,
					g_Controllers[i].State.Gamepad.sThumbRY);
			}
			else
			{
				sz[i].AppendF("Controller {}: Not connected", i);
			}

			if (String.Compare(sz[i], g_szMessage[i], true) != 0)
			{
				g_szMessage[i].Set(sz[i]);
				bRepaint = true;
			}
		}

		if (bRepaint)
		{
			// Repaint the window if needed
			InvalidateRect(g_hWnd, null, TRUE);
			UpdateWindow(g_hWnd);
		}

		// This sample doesn't use Direct3D.  Instead, it just yields CPU time to other 
		// apps but this is not typically done when rendering
		Sleep(10);
	}



	static LRESULT MsgProc(HWND hwnd, uint32 msg, WPARAM wParam, LPARAM lParam)
	{
		switch (msg)
		{
		case WM_ACTIVATEAPP:
			{
//#if (_WIN32_WINNT >= 0x0602 /*_WIN32_WINNT_WIN8*/) && (_WIN32_WINNT < 0x0A00 /*_WIN32_WINNT_WIN10*/)

				//
				// XInputEnable is implemented by XInput 1.3 and 1.4, but not 9.1.0
				//

				if (wParam == TRUE)
				{
					// App is now active, so re-enable XInput
					XInputEnable(TRUE);
				}
				else
				{
					// App is now inactive, so disable XInput to prevent
					// user input from effecting application and to 
					// disable rumble.
					XInputEnable(FALSE);
				}

//#endif
				break;
			}

		case WM_KEYDOWN:
			{
				if (wParam == (.)'D') g_bDeadZoneOn = !g_bDeadZoneOn;
				break;
			}

		case WM_PAINT:
			{
				// Paint some simple explanation text
				PAINTSTRUCT ps;
				HDC hDC = BeginPaint(hwnd, &ps);
				SetBkColor(hDC, 0xFF0000);
				SetTextColor(hDC, 0xFFFFFF);
				RECT rect;
				GetClientRect(hwnd, &rect);

				rect.top = 20;
				rect.left = 20;
				DrawText(hDC, (.)"This sample displays the state of all 4 XInput controllers\nPress 'D' to toggle dead zone clamping.".CStr(), -1, &rect, 0);

				for (uint32 i = 0; i < MAX_CONTROLLERS; i++)
				{
					rect.top = (.)(i * 120 + 70);
					rect.left = 20;
					DrawText(hDC, (.)g_szMessage[i].CStr(), -1, &rect, 0);
				}

				EndPaint(hwnd, &ps);
				return 0;
			}

		case WM_DESTROY:
			{
				PostQuitMessage(0);
				break;
			}
		}

		return DefWindowProc(hwnd, msg, wParam, lParam);
	}
}
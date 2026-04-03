using Win32.Foundation;
using Win32.Security;
using System;

namespace Win32.System.Console;

#region Constants
public static
{
	public const uint32 CONSOLE_TEXTMODE_BUFFER = 1;
	public const uint32 ATTACH_PARENT_PROCESS = 4294967295;
	public const uint32 CTRL_C_EVENT = 0;
	public const uint32 CTRL_BREAK_EVENT = 1;
	public const uint32 CTRL_CLOSE_EVENT = 2;
	public const uint32 CTRL_LOGOFF_EVENT = 5;
	public const uint32 CTRL_SHUTDOWN_EVENT = 6;
	public const uint32 PSEUDOCONSOLE_INHERIT_CURSOR = 1;
	public const uint32 CONSOLE_NO_SELECTION = 0;
	public const uint32 CONSOLE_SELECTION_IN_PROGRESS = 1;
	public const uint32 CONSOLE_SELECTION_NOT_EMPTY = 2;
	public const uint32 CONSOLE_MOUSE_SELECTION = 4;
	public const uint32 CONSOLE_MOUSE_DOWN = 8;
	public const uint32 HISTORY_NO_DUP_FLAG = 1;
	public const uint32 CONSOLE_FULLSCREEN = 1;
	public const uint32 CONSOLE_FULLSCREEN_HARDWARE = 2;
	public const uint32 CONSOLE_FULLSCREEN_MODE = 1;
	public const uint32 CONSOLE_WINDOWED_MODE = 2;
	public const uint32 RIGHT_ALT_PRESSED = 1;
	public const uint32 LEFT_ALT_PRESSED = 2;
	public const uint32 RIGHT_CTRL_PRESSED = 4;
	public const uint32 LEFT_CTRL_PRESSED = 8;
	public const uint32 SHIFT_PRESSED = 16;
	public const uint32 NUMLOCK_ON = 32;
	public const uint32 SCROLLLOCK_ON = 64;
	public const uint32 CAPSLOCK_ON = 128;
	public const uint32 ENHANCED_KEY = 256;
	public const uint32 NLS_DBCSCHAR = 65536;
	public const uint32 NLS_ALPHANUMERIC = 0;
	public const uint32 NLS_KATAKANA = 131072;
	public const uint32 NLS_HIRAGANA = 262144;
	public const uint32 NLS_ROMAN = 4194304;
	public const uint32 NLS_IME_CONVERSION = 8388608;
	public const uint32 ALTNUMPAD_BIT = 67108864;
	public const uint32 NLS_IME_DISABLE = 536870912;
	public const uint32 FROM_LEFT_1ST_BUTTON_PRESSED = 1;
	public const uint32 RIGHTMOST_BUTTON_PRESSED = 2;
	public const uint32 FROM_LEFT_2ND_BUTTON_PRESSED = 4;
	public const uint32 FROM_LEFT_3RD_BUTTON_PRESSED = 8;
	public const uint32 FROM_LEFT_4TH_BUTTON_PRESSED = 16;
	public const uint32 MOUSE_MOVED = 1;
	public const uint32 DOUBLE_CLICK = 2;
	public const uint32 MOUSE_WHEELED = 4;
	public const uint32 MOUSE_HWHEELED = 8;
	public const uint32 KEY_EVENT = 1;
	public const uint32 MOUSE_EVENT = 2;
	public const uint32 WINDOW_BUFFER_SIZE_EVENT = 4;
	public const uint32 MENU_EVENT = 8;
	public const uint32 FOCUS_EVENT = 16;
}
#endregion

#region TypeDefs
typealias HPCON = int;

#endregion


#region Enums

[AllowDuplicates]
public enum CONSOLE_MODE : uint32
{
	ENABLE_PROCESSED_INPUT = 1,
	ENABLE_LINE_INPUT = 2,
	ENABLE_ECHO_INPUT = 4,
	ENABLE_WINDOW_INPUT = 8,
	ENABLE_MOUSE_INPUT = 16,
	ENABLE_INSERT_MODE = 32,
	ENABLE_QUICK_EDIT_MODE = 64,
	ENABLE_EXTENDED_FLAGS = 128,
	ENABLE_AUTO_POSITION = 256,
	ENABLE_VIRTUAL_TERMINAL_INPUT = 512,
	ENABLE_PROCESSED_OUTPUT = 1,
	ENABLE_WRAP_AT_EOL_OUTPUT = 2,
	ENABLE_VIRTUAL_TERMINAL_PROCESSING = 4,
	DISABLE_NEWLINE_AUTO_RETURN = 8,
	ENABLE_LVB_GRID_WORLDWIDE = 16,
}


[AllowDuplicates]
public enum STD_HANDLE : uint32
{
	STD_INPUT_HANDLE = 4294967286,
	STD_OUTPUT_HANDLE = 4294967285,
	STD_ERROR_HANDLE = 4294967284,
}


[AllowDuplicates]
public enum CONSOLE_CHARACTER_ATTRIBUTES : uint16
{
	FOREGROUND_BLUE = 1,
	FOREGROUND_GREEN = 2,
	FOREGROUND_RED = 4,
	FOREGROUND_INTENSITY = 8,
	BACKGROUND_BLUE = 16,
	BACKGROUND_GREEN = 32,
	BACKGROUND_RED = 64,
	BACKGROUND_INTENSITY = 128,
	COMMON_LVB_LEADING_BYTE = 256,
	COMMON_LVB_TRAILING_BYTE = 512,
	COMMON_LVB_GRID_HORIZONTAL = 1024,
	COMMON_LVB_GRID_LVERTICAL = 2048,
	COMMON_LVB_GRID_RVERTICAL = 4096,
	COMMON_LVB_REVERSE_VIDEO = 16384,
	COMMON_LVB_UNDERSCORE = 32768,
	COMMON_LVB_SBCSDBCS = 768,
}

#endregion

#region Function Pointers
public function BOOL PHANDLER_ROUTINE(uint32 CtrlType);

#endregion

#region Structs
[CRepr]
public struct COORD
{
	public int16 X;
	public int16 Y;
}

[CRepr]
public struct SMALL_RECT
{
	public int16 Left;
	public int16 Top;
	public int16 Right;
	public int16 Bottom;
}

[CRepr]
public struct KEY_EVENT_RECORD
{
	[CRepr, Union]
	public struct _uChar_e__Union
	{
		public char16 UnicodeChar;
		public CHAR AsciiChar;
	}
	public BOOL bKeyDown;
	public uint16 wRepeatCount;
	public uint16 wVirtualKeyCode;
	public uint16 wVirtualScanCode;
	public _uChar_e__Union uChar;
	public uint32 dwControlKeyState;
}

[CRepr]
public struct MOUSE_EVENT_RECORD
{
	public COORD dwMousePosition;
	public uint32 dwButtonState;
	public uint32 dwControlKeyState;
	public uint32 dwEventFlags;
}

[CRepr]
public struct WINDOW_BUFFER_SIZE_RECORD
{
	public COORD dwSize;
}

[CRepr]
public struct MENU_EVENT_RECORD
{
	public uint32 dwCommandId;
}

[CRepr]
public struct FOCUS_EVENT_RECORD
{
	public BOOL bSetFocus;
}

[CRepr]
public struct INPUT_RECORD
{
	[CRepr, Union]
	public struct _Event_e__Union
	{
		public KEY_EVENT_RECORD KeyEvent;
		public MOUSE_EVENT_RECORD MouseEvent;
		public WINDOW_BUFFER_SIZE_RECORD WindowBufferSizeEvent;
		public MENU_EVENT_RECORD MenuEvent;
		public FOCUS_EVENT_RECORD FocusEvent;
	}
	public uint16 EventType;
	public _Event_e__Union Event;
}

[CRepr]
public struct CHAR_INFO
{
	[CRepr, Union]
	public struct _Char_e__Union
	{
		public char16 UnicodeChar;
		public CHAR AsciiChar;
	}
	public _Char_e__Union Char;
	public uint16 Attributes;
}

[CRepr]
public struct CONSOLE_FONT_INFO
{
	public uint32 nFont;
	public COORD dwFontSize;
}

[CRepr]
public struct CONSOLE_READCONSOLE_CONTROL
{
	public uint32 nLength;
	public uint32 nInitialChars;
	public uint32 dwCtrlWakeupMask;
	public uint32 dwControlKeyState;
}

[CRepr]
public struct CONSOLE_CURSOR_INFO
{
	public uint32 dwSize;
	public BOOL bVisible;
}

[CRepr]
public struct CONSOLE_SCREEN_BUFFER_INFO
{
	public COORD dwSize;
	public COORD dwCursorPosition;
	public CONSOLE_CHARACTER_ATTRIBUTES wAttributes;
	public SMALL_RECT srWindow;
	public COORD dwMaximumWindowSize;
}

[CRepr]
public struct CONSOLE_SCREEN_BUFFER_INFOEX
{
	public uint32 cbSize;
	public COORD dwSize;
	public COORD dwCursorPosition;
	public CONSOLE_CHARACTER_ATTRIBUTES wAttributes;
	public SMALL_RECT srWindow;
	public COORD dwMaximumWindowSize;
	public uint16 wPopupAttributes;
	public BOOL bFullscreenSupported;
	public COLORREF[16] ColorTable;
}

[CRepr]
public struct CONSOLE_FONT_INFOEX
{
	public uint32 cbSize;
	public uint32 nFont;
	public COORD dwFontSize;
	public uint32 FontFamily;
	public uint32 FontWeight;
	public char16[32] FaceName;
}

[CRepr]
public struct CONSOLE_SELECTION_INFO
{
	public uint32 dwFlags;
	public COORD dwSelectionAnchor;
	public SMALL_RECT srSelection;
}

[CRepr]
public struct CONSOLE_HISTORY_INFO
{
	public uint32 cbSize;
	public uint32 HistoryBufferSize;
	public uint32 NumberOfHistoryBuffers;
	public uint32 dwFlags;
}

#endregion

#region Functions
public static
{
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AllocConsole();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FreeConsole();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AttachConsole(uint32 dwProcessId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetConsoleCP();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetConsoleOutputCP();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetConsoleMode(HANDLE hConsoleHandle, CONSOLE_MODE* lpMode);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetConsoleMode(HANDLE hConsoleHandle, CONSOLE_MODE dwMode);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNumberOfConsoleInputEvents(HANDLE hConsoleInput, uint32* lpNumberOfEvents);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReadConsoleInputA(HANDLE hConsoleInput, INPUT_RECORD* lpBuffer, uint32 nLength, uint32* lpNumberOfEventsRead);
	public static BOOL ReadConsoleInput(HANDLE hConsoleInput, INPUT_RECORD* lpBuffer, uint32 nLength, uint32* lpNumberOfEventsRead) => ReadConsoleInputA(hConsoleInput, lpBuffer, nLength, lpNumberOfEventsRead);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReadConsoleInputW(HANDLE hConsoleInput, INPUT_RECORD* lpBuffer, uint32 nLength, uint32* lpNumberOfEventsRead);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PeekConsoleInputA(HANDLE hConsoleInput, INPUT_RECORD* lpBuffer, uint32 nLength, uint32* lpNumberOfEventsRead);
	public static BOOL PeekConsoleInput(HANDLE hConsoleInput, INPUT_RECORD* lpBuffer, uint32 nLength, uint32* lpNumberOfEventsRead) => PeekConsoleInputA(hConsoleInput, lpBuffer, nLength, lpNumberOfEventsRead);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PeekConsoleInputW(HANDLE hConsoleInput, INPUT_RECORD* lpBuffer, uint32 nLength, uint32* lpNumberOfEventsRead);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReadConsoleA(HANDLE hConsoleInput, void* lpBuffer, uint32 nNumberOfCharsToRead, uint32* lpNumberOfCharsRead, CONSOLE_READCONSOLE_CONTROL* pInputControl);
	public static BOOL ReadConsole(HANDLE hConsoleInput, void* lpBuffer, uint32 nNumberOfCharsToRead, uint32* lpNumberOfCharsRead, CONSOLE_READCONSOLE_CONTROL* pInputControl) => ReadConsoleA(hConsoleInput, lpBuffer, nNumberOfCharsToRead, lpNumberOfCharsRead, pInputControl);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReadConsoleW(HANDLE hConsoleInput, void* lpBuffer, uint32 nNumberOfCharsToRead, uint32* lpNumberOfCharsRead, CONSOLE_READCONSOLE_CONTROL* pInputControl);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WriteConsoleA(HANDLE hConsoleOutput, void* lpBuffer, uint32 nNumberOfCharsToWrite, uint32* lpNumberOfCharsWritten, void* lpReserved);
	public static BOOL WriteConsole(HANDLE hConsoleOutput, void* lpBuffer, uint32 nNumberOfCharsToWrite, uint32* lpNumberOfCharsWritten, void* lpReserved) => WriteConsoleA(hConsoleOutput, lpBuffer, nNumberOfCharsToWrite, lpNumberOfCharsWritten, lpReserved);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WriteConsoleW(HANDLE hConsoleOutput, void* lpBuffer, uint32 nNumberOfCharsToWrite, uint32* lpNumberOfCharsWritten, void* lpReserved);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetConsoleCtrlHandler(PHANDLER_ROUTINE HandlerRoutine, BOOL Add);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreatePseudoConsole(COORD size, HANDLE hInput, HANDLE hOutput, uint32 dwFlags, HPCON* phPC);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ResizePseudoConsole(HPCON hPC, COORD size);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ClosePseudoConsole(HPCON hPC);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FillConsoleOutputCharacterA(HANDLE hConsoleOutput, CHAR cCharacter, uint32 nLength, COORD dwWriteCoord, uint32* lpNumberOfCharsWritten);
	public static BOOL FillConsoleOutputCharacter(HANDLE hConsoleOutput, CHAR cCharacter, uint32 nLength, COORD dwWriteCoord, uint32* lpNumberOfCharsWritten) => FillConsoleOutputCharacterA(hConsoleOutput, cCharacter, nLength, dwWriteCoord, lpNumberOfCharsWritten);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FillConsoleOutputCharacterW(HANDLE hConsoleOutput, char16 cCharacter, uint32 nLength, COORD dwWriteCoord, uint32* lpNumberOfCharsWritten);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FillConsoleOutputAttribute(HANDLE hConsoleOutput, uint16 wAttribute, uint32 nLength, COORD dwWriteCoord, uint32* lpNumberOfAttrsWritten);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GenerateConsoleCtrlEvent(uint32 dwCtrlEvent, uint32 dwProcessGroupId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateConsoleScreenBuffer(uint32 dwDesiredAccess, uint32 dwShareMode, SECURITY_ATTRIBUTES* lpSecurityAttributes, uint32 dwFlags, void* lpScreenBufferData);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetConsoleActiveScreenBuffer(HANDLE hConsoleOutput);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FlushConsoleInputBuffer(HANDLE hConsoleInput);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetConsoleCP(uint32 wCodePageID);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetConsoleOutputCP(uint32 wCodePageID);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetConsoleCursorInfo(HANDLE hConsoleOutput, CONSOLE_CURSOR_INFO* lpConsoleCursorInfo);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetConsoleCursorInfo(HANDLE hConsoleOutput, CONSOLE_CURSOR_INFO* lpConsoleCursorInfo);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetConsoleScreenBufferInfo(HANDLE hConsoleOutput, CONSOLE_SCREEN_BUFFER_INFO* lpConsoleScreenBufferInfo);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetConsoleScreenBufferInfoEx(HANDLE hConsoleOutput, CONSOLE_SCREEN_BUFFER_INFOEX* lpConsoleScreenBufferInfoEx);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetConsoleScreenBufferInfoEx(HANDLE hConsoleOutput, CONSOLE_SCREEN_BUFFER_INFOEX* lpConsoleScreenBufferInfoEx);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetConsoleScreenBufferSize(HANDLE hConsoleOutput, COORD dwSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetConsoleCursorPosition(HANDLE hConsoleOutput, COORD dwCursorPosition);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern COORD GetLargestConsoleWindowSize(HANDLE hConsoleOutput);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetConsoleTextAttribute(HANDLE hConsoleOutput, CONSOLE_CHARACTER_ATTRIBUTES wAttributes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetConsoleWindowInfo(HANDLE hConsoleOutput, BOOL bAbsolute, SMALL_RECT* lpConsoleWindow);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WriteConsoleOutputCharacterA(HANDLE hConsoleOutput, uint8* lpCharacter, uint32 nLength, COORD dwWriteCoord, uint32* lpNumberOfCharsWritten);
	public static BOOL WriteConsoleOutputCharacter(HANDLE hConsoleOutput, uint8* lpCharacter, uint32 nLength, COORD dwWriteCoord, uint32* lpNumberOfCharsWritten) => WriteConsoleOutputCharacterA(hConsoleOutput, lpCharacter, nLength, dwWriteCoord, lpNumberOfCharsWritten);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WriteConsoleOutputCharacterW(HANDLE hConsoleOutput, char16* lpCharacter, uint32 nLength, COORD dwWriteCoord, uint32* lpNumberOfCharsWritten);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WriteConsoleOutputAttribute(HANDLE hConsoleOutput, uint16* lpAttribute, uint32 nLength, COORD dwWriteCoord, uint32* lpNumberOfAttrsWritten);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReadConsoleOutputCharacterA(HANDLE hConsoleOutput, uint8* lpCharacter, uint32 nLength, COORD dwReadCoord, uint32* lpNumberOfCharsRead);
	public static BOOL ReadConsoleOutputCharacter(HANDLE hConsoleOutput, uint8* lpCharacter, uint32 nLength, COORD dwReadCoord, uint32* lpNumberOfCharsRead) => ReadConsoleOutputCharacterA(hConsoleOutput, lpCharacter, nLength, dwReadCoord, lpNumberOfCharsRead);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReadConsoleOutputCharacterW(HANDLE hConsoleOutput, char16* lpCharacter, uint32 nLength, COORD dwReadCoord, uint32* lpNumberOfCharsRead);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReadConsoleOutputAttribute(HANDLE hConsoleOutput, uint16* lpAttribute, uint32 nLength, COORD dwReadCoord, uint32* lpNumberOfAttrsRead);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WriteConsoleInputA(HANDLE hConsoleInput, INPUT_RECORD* lpBuffer, uint32 nLength, uint32* lpNumberOfEventsWritten);
	public static BOOL WriteConsoleInput(HANDLE hConsoleInput, INPUT_RECORD* lpBuffer, uint32 nLength, uint32* lpNumberOfEventsWritten) => WriteConsoleInputA(hConsoleInput, lpBuffer, nLength, lpNumberOfEventsWritten);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WriteConsoleInputW(HANDLE hConsoleInput, INPUT_RECORD* lpBuffer, uint32 nLength, uint32* lpNumberOfEventsWritten);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ScrollConsoleScreenBufferA(HANDLE hConsoleOutput, SMALL_RECT* lpScrollRectangle, SMALL_RECT* lpClipRectangle, COORD dwDestinationOrigin, CHAR_INFO* lpFill);
	public static BOOL ScrollConsoleScreenBuffer(HANDLE hConsoleOutput, SMALL_RECT* lpScrollRectangle, SMALL_RECT* lpClipRectangle, COORD dwDestinationOrigin, CHAR_INFO* lpFill) => ScrollConsoleScreenBufferA(hConsoleOutput, lpScrollRectangle, lpClipRectangle, dwDestinationOrigin, lpFill);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ScrollConsoleScreenBufferW(HANDLE hConsoleOutput, SMALL_RECT* lpScrollRectangle, SMALL_RECT* lpClipRectangle, COORD dwDestinationOrigin, CHAR_INFO* lpFill);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WriteConsoleOutputA(HANDLE hConsoleOutput, CHAR_INFO* lpBuffer, COORD dwBufferSize, COORD dwBufferCoord, SMALL_RECT* lpWriteRegion);
	public static BOOL WriteConsoleOutput(HANDLE hConsoleOutput, CHAR_INFO* lpBuffer, COORD dwBufferSize, COORD dwBufferCoord, SMALL_RECT* lpWriteRegion) => WriteConsoleOutputA(hConsoleOutput, lpBuffer, dwBufferSize, dwBufferCoord, lpWriteRegion);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WriteConsoleOutputW(HANDLE hConsoleOutput, CHAR_INFO* lpBuffer, COORD dwBufferSize, COORD dwBufferCoord, SMALL_RECT* lpWriteRegion);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReadConsoleOutputA(HANDLE hConsoleOutput, CHAR_INFO* lpBuffer, COORD dwBufferSize, COORD dwBufferCoord, SMALL_RECT* lpReadRegion);
	public static BOOL ReadConsoleOutput(HANDLE hConsoleOutput, CHAR_INFO* lpBuffer, COORD dwBufferSize, COORD dwBufferCoord, SMALL_RECT* lpReadRegion) => ReadConsoleOutputA(hConsoleOutput, lpBuffer, dwBufferSize, dwBufferCoord, lpReadRegion);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReadConsoleOutputW(HANDLE hConsoleOutput, CHAR_INFO* lpBuffer, COORD dwBufferSize, COORD dwBufferCoord, SMALL_RECT* lpReadRegion);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetConsoleTitleA(uint8* lpConsoleTitle, uint32 nSize);
	public static uint32 GetConsoleTitle(uint8* lpConsoleTitle, uint32 nSize) => GetConsoleTitleA(lpConsoleTitle, nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetConsoleTitleW(char16* lpConsoleTitle, uint32 nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetConsoleOriginalTitleA(uint8* lpConsoleTitle, uint32 nSize);
	public static uint32 GetConsoleOriginalTitle(uint8* lpConsoleTitle, uint32 nSize) => GetConsoleOriginalTitleA(lpConsoleTitle, nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetConsoleOriginalTitleW(char16* lpConsoleTitle, uint32 nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetConsoleTitleA(PSTR lpConsoleTitle);
	public static BOOL SetConsoleTitle(PSTR lpConsoleTitle) => SetConsoleTitleA(lpConsoleTitle);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetConsoleTitleW(PWSTR lpConsoleTitle);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNumberOfConsoleMouseButtons(uint32* lpNumberOfMouseButtons);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern COORD GetConsoleFontSize(HANDLE hConsoleOutput, uint32 nFont);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCurrentConsoleFont(HANDLE hConsoleOutput, BOOL bMaximumWindow, CONSOLE_FONT_INFO* lpConsoleCurrentFont);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCurrentConsoleFontEx(HANDLE hConsoleOutput, BOOL bMaximumWindow, CONSOLE_FONT_INFOEX* lpConsoleCurrentFontEx);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetCurrentConsoleFontEx(HANDLE hConsoleOutput, BOOL bMaximumWindow, CONSOLE_FONT_INFOEX* lpConsoleCurrentFontEx);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetConsoleSelectionInfo(CONSOLE_SELECTION_INFO* lpConsoleSelectionInfo);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetConsoleHistoryInfo(CONSOLE_HISTORY_INFO* lpConsoleHistoryInfo);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetConsoleHistoryInfo(CONSOLE_HISTORY_INFO* lpConsoleHistoryInfo);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetConsoleDisplayMode(uint32* lpModeFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetConsoleDisplayMode(HANDLE hConsoleOutput, uint32 dwFlags, COORD* lpNewScreenBufferDimensions);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HWND GetConsoleWindow();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddConsoleAliasA(PSTR Source, PSTR Target, PSTR ExeName);
	public static BOOL AddConsoleAlias(PSTR Source, PSTR Target, PSTR ExeName) => AddConsoleAliasA(Source, Target, ExeName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AddConsoleAliasW(PWSTR Source, PWSTR Target, PWSTR ExeName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetConsoleAliasA(PSTR Source, uint8* TargetBuffer, uint32 TargetBufferLength, PSTR ExeName);
	public static uint32 GetConsoleAlias(PSTR Source, uint8* TargetBuffer, uint32 TargetBufferLength, PSTR ExeName) => GetConsoleAliasA(Source, TargetBuffer, TargetBufferLength, ExeName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetConsoleAliasW(PWSTR Source, char16* TargetBuffer, uint32 TargetBufferLength, PWSTR ExeName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetConsoleAliasesLengthA(PSTR ExeName);
	public static uint32 GetConsoleAliasesLength(PSTR ExeName) => GetConsoleAliasesLengthA(ExeName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetConsoleAliasesLengthW(PWSTR ExeName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetConsoleAliasExesLengthA();
	public static uint32 GetConsoleAliasExesLength() => GetConsoleAliasExesLengthA();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetConsoleAliasExesLengthW();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetConsoleAliasesA(uint8* AliasBuffer, uint32 AliasBufferLength, PSTR ExeName);
	public static uint32 GetConsoleAliases(uint8* AliasBuffer, uint32 AliasBufferLength, PSTR ExeName) => GetConsoleAliasesA(AliasBuffer, AliasBufferLength, ExeName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetConsoleAliasesW(char16* AliasBuffer, uint32 AliasBufferLength, PWSTR ExeName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetConsoleAliasExesA(uint8* ExeNameBuffer, uint32 ExeNameBufferLength);
	public static uint32 GetConsoleAliasExes(uint8* ExeNameBuffer, uint32 ExeNameBufferLength) => GetConsoleAliasExesA(ExeNameBuffer, ExeNameBufferLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetConsoleAliasExesW(char16* ExeNameBuffer, uint32 ExeNameBufferLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ExpungeConsoleCommandHistoryA(PSTR ExeName);
	public static void ExpungeConsoleCommandHistory(PSTR ExeName) => ExpungeConsoleCommandHistoryA(ExeName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ExpungeConsoleCommandHistoryW(PWSTR ExeName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetConsoleNumberOfCommandsA(uint32 Number, PSTR ExeName);
	public static BOOL SetConsoleNumberOfCommands(uint32 Number, PSTR ExeName) => SetConsoleNumberOfCommandsA(Number, ExeName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetConsoleNumberOfCommandsW(uint32 Number, PWSTR ExeName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetConsoleCommandHistoryLengthA(PSTR ExeName);
	public static uint32 GetConsoleCommandHistoryLength(PSTR ExeName) => GetConsoleCommandHistoryLengthA(ExeName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetConsoleCommandHistoryLengthW(PWSTR ExeName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetConsoleCommandHistoryA(PSTR Commands, uint32 CommandBufferLength, PSTR ExeName);
	public static uint32 GetConsoleCommandHistory(PSTR Commands, uint32 CommandBufferLength, PSTR ExeName) => GetConsoleCommandHistoryA(Commands, CommandBufferLength, ExeName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetConsoleCommandHistoryW(PWSTR Commands, uint32 CommandBufferLength, PWSTR ExeName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetConsoleProcessList(uint32* lpdwProcessList, uint32 dwProcessCount);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE GetStdHandle(STD_HANDLE nStdHandle);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetStdHandle(STD_HANDLE nStdHandle, HANDLE hHandle);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetStdHandleEx(STD_HANDLE nStdHandle, HANDLE hHandle, HANDLE* phPrevValue);

}
#endregion

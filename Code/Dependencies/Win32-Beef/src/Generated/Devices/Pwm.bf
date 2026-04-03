using Win32.Foundation;
using System;

namespace Win32.Devices.Pwm;

#region Constants
public static
{
	public const Guid GUID_DEVINTERFACE_PWM_CONTROLLER = .(0x60824b4c, 0xeed1, 0x4c9c, 0xb4, 0x9c, 0x1b, 0x96, 0x14, 0x61, 0xa8, 0x19);
	public const String GUID_DEVINTERFACE_PWM_CONTROLLER_WSZ = "{60824B4C-EED1-4C9C-B49C-1B961461A819}";
	public const uint32 IOCTL_PWM_CONTROLLER_GET_INFO = 262144;
	public const uint32 IOCTL_PWM_CONTROLLER_GET_ACTUAL_PERIOD = 262148;
	public const uint32 IOCTL_PWM_CONTROLLER_SET_DESIRED_PERIOD = 294920;
	public const uint32 IOCTL_PWM_PIN_GET_ACTIVE_DUTY_CYCLE_PERCENTAGE = 262544;
	public const uint32 IOCTL_PWM_PIN_SET_ACTIVE_DUTY_CYCLE_PERCENTAGE = 295316;
	public const uint32 IOCTL_PWM_PIN_GET_POLARITY = 262552;
	public const uint32 IOCTL_PWM_PIN_SET_POLARITY = 295324;
	public const uint32 IOCTL_PWM_PIN_START = 295331;
	public const uint32 IOCTL_PWM_PIN_STOP = 295335;
	public const uint32 IOCTL_PWM_PIN_IS_STARTED = 262568;
	public const int32 PWM_IOCTL_ID_CONTROLLER_GET_INFO = 0;
	public const int32 PWM_IOCTL_ID_CONTROLLER_GET_ACTUAL_PERIOD = 1;
	public const int32 PWM_IOCTL_ID_CONTROLLER_SET_DESIRED_PERIOD = 2;
	public const int32 PWM_IOCTL_ID_PIN_GET_ACTIVE_DUTY_CYCLE_PERCENTAGE = 100;
	public const int32 PWM_IOCTL_ID_PIN_SET_ACTIVE_DUTY_CYCLE_PERCENTAGE = 101;
	public const int32 PWM_IOCTL_ID_PIN_GET_POLARITY = 102;
	public const int32 PWM_IOCTL_ID_PIN_SET_POLARITY = 103;
	public const int32 PWM_IOCTL_ID_PIN_START = 104;
	public const int32 PWM_IOCTL_ID_PIN_STOP = 105;
	public const int32 PWM_IOCTL_ID_PIN_IS_STARTED = 106;
}
#endregion

#region Enums

[AllowDuplicates]
public enum PWM_POLARITY : int32
{
	PWM_ACTIVE_HIGH = 0,
	PWM_ACTIVE_LOW = 1,
}

#endregion


#region Structs
[CRepr]
public struct PWM_CONTROLLER_INFO
{
	public uint Size;
	public uint32 PinCount;
	public uint64 MinimumPeriod;
	public uint64 MaximumPeriod;
}

[CRepr]
public struct PWM_CONTROLLER_GET_ACTUAL_PERIOD_OUTPUT
{
	public uint64 ActualPeriod;
}

[CRepr]
public struct PWM_CONTROLLER_SET_DESIRED_PERIOD_INPUT
{
	public uint64 DesiredPeriod;
}

[CRepr]
public struct PWM_CONTROLLER_SET_DESIRED_PERIOD_OUTPUT
{
	public uint64 ActualPeriod;
}

[CRepr]
public struct PWM_PIN_GET_ACTIVE_DUTY_CYCLE_PERCENTAGE_OUTPUT
{
	public uint64 Percentage;
}

[CRepr]
public struct PWM_PIN_SET_ACTIVE_DUTY_CYCLE_PERCENTAGE_INPUT
{
	public uint64 Percentage;
}

[CRepr]
public struct PWM_PIN_GET_POLARITY_OUTPUT
{
	public PWM_POLARITY Polarity;
}

[CRepr]
public struct PWM_PIN_SET_POLARITY_INPUT
{
	public PWM_POLARITY Polarity;
}

[CRepr]
public struct PWM_PIN_IS_STARTED_OUTPUT
{
	public BOOLEAN IsStarted;
}

#endregion

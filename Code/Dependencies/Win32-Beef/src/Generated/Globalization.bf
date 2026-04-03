using Win32.Foundation;
using Win32.Graphics.Gdi;
using Win32.System.Com;
using System;

namespace Win32.Globalization;

#region Constants
public static
{
	public const uint32 ALL_SERVICE_TYPES = 0;
	public const uint32 HIGHLEVEL_SERVICE_TYPES = 1;
	public const uint32 LOWLEVEL_SERVICE_TYPES = 2;
	public const uint32 ALL_SERVICES = 0;
	public const uint32 ONLINE_SERVICES = 1;
	public const uint32 OFFLINE_SERVICES = 2;
	public const uint32 MAX_LEADBYTES = 12;
	public const uint32 MAX_DEFAULTCHAR = 2;
	public const uint32 HIGH_SURROGATE_START = 55296;
	public const uint32 HIGH_SURROGATE_END = 56319;
	public const uint32 LOW_SURROGATE_START = 56320;
	public const uint32 LOW_SURROGATE_END = 57343;
	public const uint32 WC_COMPOSITECHECK = 512;
	public const uint32 WC_DISCARDNS = 16;
	public const uint32 WC_SEPCHARS = 32;
	public const uint32 WC_DEFAULTCHAR = 64;
	public const uint32 WC_ERR_INVALID_CHARS = 128;
	public const uint32 WC_NO_BEST_FIT_CHARS = 1024;
	public const uint32 CT_CTYPE1 = 1;
	public const uint32 CT_CTYPE2 = 2;
	public const uint32 CT_CTYPE3 = 4;
	public const uint32 C1_UPPER = 1;
	public const uint32 C1_LOWER = 2;
	public const uint32 C1_DIGIT = 4;
	public const uint32 C1_SPACE = 8;
	public const uint32 C1_PUNCT = 16;
	public const uint32 C1_CNTRL = 32;
	public const uint32 C1_BLANK = 64;
	public const uint32 C1_XDIGIT = 128;
	public const uint32 C1_ALPHA = 256;
	public const uint32 C1_DEFINED = 512;
	public const uint32 C2_LEFTTORIGHT = 1;
	public const uint32 C2_RIGHTTOLEFT = 2;
	public const uint32 C2_EUROPENUMBER = 3;
	public const uint32 C2_EUROPESEPARATOR = 4;
	public const uint32 C2_EUROPETERMINATOR = 5;
	public const uint32 C2_ARABICNUMBER = 6;
	public const uint32 C2_COMMONSEPARATOR = 7;
	public const uint32 C2_BLOCKSEPARATOR = 8;
	public const uint32 C2_SEGMENTSEPARATOR = 9;
	public const uint32 C2_WHITESPACE = 10;
	public const uint32 C2_OTHERNEUTRAL = 11;
	public const uint32 C2_NOTAPPLICABLE = 0;
	public const uint32 C3_NONSPACING = 1;
	public const uint32 C3_DIACRITIC = 2;
	public const uint32 C3_VOWELMARK = 4;
	public const uint32 C3_SYMBOL = 8;
	public const uint32 C3_KATAKANA = 16;
	public const uint32 C3_HIRAGANA = 32;
	public const uint32 C3_HALFWIDTH = 64;
	public const uint32 C3_FULLWIDTH = 128;
	public const uint32 C3_IDEOGRAPH = 256;
	public const uint32 C3_KASHIDA = 512;
	public const uint32 C3_LEXICAL = 1024;
	public const uint32 C3_HIGHSURROGATE = 2048;
	public const uint32 C3_LOWSURROGATE = 4096;
	public const uint32 C3_ALPHA = 32768;
	public const uint32 C3_NOTAPPLICABLE = 0;
	public const uint32 LCMAP_LOWERCASE = 256;
	public const uint32 LCMAP_UPPERCASE = 512;
	public const uint32 LCMAP_TITLECASE = 768;
	public const uint32 LCMAP_SORTKEY = 1024;
	public const uint32 LCMAP_BYTEREV = 2048;
	public const uint32 LCMAP_HIRAGANA = 1048576;
	public const uint32 LCMAP_KATAKANA = 2097152;
	public const uint32 LCMAP_HALFWIDTH = 4194304;
	public const uint32 LCMAP_FULLWIDTH = 8388608;
	public const uint32 LCMAP_LINGUISTIC_CASING = 16777216;
	public const uint32 LCMAP_SIMPLIFIED_CHINESE = 33554432;
	public const uint32 LCMAP_TRADITIONAL_CHINESE = 67108864;
	public const uint32 LCMAP_SORTHANDLE = 536870912;
	public const uint32 LCMAP_HASH = 262144;
	public const uint32 FIND_STARTSWITH = 1048576;
	public const uint32 FIND_ENDSWITH = 2097152;
	public const uint32 FIND_FROMSTART = 4194304;
	public const uint32 FIND_FROMEND = 8388608;
	public const uint32 LCID_ALTERNATE_SORTS = 4;
	public const uint32 LOCALE_ALL = 0;
	public const uint32 LOCALE_WINDOWS = 1;
	public const uint32 LOCALE_SUPPLEMENTAL = 2;
	public const uint32 LOCALE_ALTERNATE_SORTS = 4;
	public const uint32 LOCALE_REPLACEMENT = 8;
	public const uint32 LOCALE_NEUTRALDATA = 16;
	public const uint32 LOCALE_SPECIFICDATA = 32;
	public const uint32 CSTR_LESS_THAN = 1;
	public const uint32 CSTR_EQUAL = 2;
	public const uint32 CSTR_GREATER_THAN = 3;
	public const uint32 CP_ACP = 0;
	public const uint32 CP_OEMCP = 1;
	public const uint32 CP_MACCP = 2;
	public const uint32 CP_THREAD_ACP = 3;
	public const uint32 CP_SYMBOL = 42;
	public const uint32 CP_UTF7 = 65000;
	public const uint32 CP_UTF8 = 65001;
	public const uint32 CTRY_DEFAULT = 0;
	public const uint32 CTRY_ALBANIA = 355;
	public const uint32 CTRY_ALGERIA = 213;
	public const uint32 CTRY_ARGENTINA = 54;
	public const uint32 CTRY_ARMENIA = 374;
	public const uint32 CTRY_AUSTRALIA = 61;
	public const uint32 CTRY_AUSTRIA = 43;
	public const uint32 CTRY_AZERBAIJAN = 994;
	public const uint32 CTRY_BAHRAIN = 973;
	public const uint32 CTRY_BELARUS = 375;
	public const uint32 CTRY_BELGIUM = 32;
	public const uint32 CTRY_BELIZE = 501;
	public const uint32 CTRY_BOLIVIA = 591;
	public const uint32 CTRY_BRAZIL = 55;
	public const uint32 CTRY_BRUNEI_DARUSSALAM = 673;
	public const uint32 CTRY_BULGARIA = 359;
	public const uint32 CTRY_CANADA = 2;
	public const uint32 CTRY_CARIBBEAN = 1;
	public const uint32 CTRY_CHILE = 56;
	public const uint32 CTRY_COLOMBIA = 57;
	public const uint32 CTRY_COSTA_RICA = 506;
	public const uint32 CTRY_CROATIA = 385;
	public const uint32 CTRY_CZECH = 420;
	public const uint32 CTRY_DENMARK = 45;
	public const uint32 CTRY_DOMINICAN_REPUBLIC = 1;
	public const uint32 CTRY_ECUADOR = 593;
	public const uint32 CTRY_EGYPT = 20;
	public const uint32 CTRY_EL_SALVADOR = 503;
	public const uint32 CTRY_ESTONIA = 372;
	public const uint32 CTRY_FAEROE_ISLANDS = 298;
	public const uint32 CTRY_FINLAND = 358;
	public const uint32 CTRY_FRANCE = 33;
	public const uint32 CTRY_GEORGIA = 995;
	public const uint32 CTRY_GERMANY = 49;
	public const uint32 CTRY_GREECE = 30;
	public const uint32 CTRY_GUATEMALA = 502;
	public const uint32 CTRY_HONDURAS = 504;
	public const uint32 CTRY_HONG_KONG = 852;
	public const uint32 CTRY_HUNGARY = 36;
	public const uint32 CTRY_ICELAND = 354;
	public const uint32 CTRY_INDIA = 91;
	public const uint32 CTRY_INDONESIA = 62;
	public const uint32 CTRY_IRAN = 981;
	public const uint32 CTRY_IRAQ = 964;
	public const uint32 CTRY_IRELAND = 353;
	public const uint32 CTRY_ISRAEL = 972;
	public const uint32 CTRY_ITALY = 39;
	public const uint32 CTRY_JAMAICA = 1;
	public const uint32 CTRY_JAPAN = 81;
	public const uint32 CTRY_JORDAN = 962;
	public const uint32 CTRY_KAZAKSTAN = 7;
	public const uint32 CTRY_KENYA = 254;
	public const uint32 CTRY_KUWAIT = 965;
	public const uint32 CTRY_KYRGYZSTAN = 996;
	public const uint32 CTRY_LATVIA = 371;
	public const uint32 CTRY_LEBANON = 961;
	public const uint32 CTRY_LIBYA = 218;
	public const uint32 CTRY_LIECHTENSTEIN = 41;
	public const uint32 CTRY_LITHUANIA = 370;
	public const uint32 CTRY_LUXEMBOURG = 352;
	public const uint32 CTRY_MACAU = 853;
	public const uint32 CTRY_MACEDONIA = 389;
	public const uint32 CTRY_MALAYSIA = 60;
	public const uint32 CTRY_MALDIVES = 960;
	public const uint32 CTRY_MEXICO = 52;
	public const uint32 CTRY_MONACO = 33;
	public const uint32 CTRY_MONGOLIA = 976;
	public const uint32 CTRY_MOROCCO = 212;
	public const uint32 CTRY_NETHERLANDS = 31;
	public const uint32 CTRY_NEW_ZEALAND = 64;
	public const uint32 CTRY_NICARAGUA = 505;
	public const uint32 CTRY_NORWAY = 47;
	public const uint32 CTRY_OMAN = 968;
	public const uint32 CTRY_PAKISTAN = 92;
	public const uint32 CTRY_PANAMA = 507;
	public const uint32 CTRY_PARAGUAY = 595;
	public const uint32 CTRY_PERU = 51;
	public const uint32 CTRY_PHILIPPINES = 63;
	public const uint32 CTRY_POLAND = 48;
	public const uint32 CTRY_PORTUGAL = 351;
	public const uint32 CTRY_PRCHINA = 86;
	public const uint32 CTRY_PUERTO_RICO = 1;
	public const uint32 CTRY_QATAR = 974;
	public const uint32 CTRY_ROMANIA = 40;
	public const uint32 CTRY_RUSSIA = 7;
	public const uint32 CTRY_SAUDI_ARABIA = 966;
	public const uint32 CTRY_SERBIA = 381;
	public const uint32 CTRY_SINGAPORE = 65;
	public const uint32 CTRY_SLOVAK = 421;
	public const uint32 CTRY_SLOVENIA = 386;
	public const uint32 CTRY_SOUTH_AFRICA = 27;
	public const uint32 CTRY_SOUTH_KOREA = 82;
	public const uint32 CTRY_SPAIN = 34;
	public const uint32 CTRY_SWEDEN = 46;
	public const uint32 CTRY_SWITZERLAND = 41;
	public const uint32 CTRY_SYRIA = 963;
	public const uint32 CTRY_TAIWAN = 886;
	public const uint32 CTRY_TATARSTAN = 7;
	public const uint32 CTRY_THAILAND = 66;
	public const uint32 CTRY_TRINIDAD_Y_TOBAGO = 1;
	public const uint32 CTRY_TUNISIA = 216;
	public const uint32 CTRY_TURKEY = 90;
	public const uint32 CTRY_UAE = 971;
	public const uint32 CTRY_UKRAINE = 380;
	public const uint32 CTRY_UNITED_KINGDOM = 44;
	public const uint32 CTRY_UNITED_STATES = 1;
	public const uint32 CTRY_URUGUAY = 598;
	public const uint32 CTRY_UZBEKISTAN = 7;
	public const uint32 CTRY_VENEZUELA = 58;
	public const uint32 CTRY_VIET_NAM = 84;
	public const uint32 CTRY_YEMEN = 967;
	public const uint32 CTRY_ZIMBABWE = 263;
	public const uint32 LOCALE_NOUSEROVERRIDE = 2147483648;
	public const uint32 LOCALE_USE_CP_ACP = 1073741824;
	public const uint32 LOCALE_RETURN_NUMBER = 536870912;
	public const uint32 LOCALE_RETURN_GENITIVE_NAMES = 268435456;
	public const uint32 LOCALE_ALLOW_NEUTRAL_NAMES = 134217728;
	public const uint32 LOCALE_SLOCALIZEDDISPLAYNAME = 2;
	public const uint32 LOCALE_SENGLISHDISPLAYNAME = 114;
	public const uint32 LOCALE_SNATIVEDISPLAYNAME = 115;
	public const uint32 LOCALE_SLOCALIZEDLANGUAGENAME = 111;
	public const uint32 LOCALE_SENGLISHLANGUAGENAME = 4097;
	public const uint32 LOCALE_SNATIVELANGUAGENAME = 4;
	public const uint32 LOCALE_SLOCALIZEDCOUNTRYNAME = 6;
	public const uint32 LOCALE_SENGLISHCOUNTRYNAME = 4098;
	public const uint32 LOCALE_SNATIVECOUNTRYNAME = 8;
	public const uint32 LOCALE_IDIALINGCODE = 5;
	public const uint32 LOCALE_SLIST = 12;
	public const uint32 LOCALE_IMEASURE = 13;
	public const uint32 LOCALE_SDECIMAL = 14;
	public const uint32 LOCALE_STHOUSAND = 15;
	public const uint32 LOCALE_SGROUPING = 16;
	public const uint32 LOCALE_IDIGITS = 17;
	public const uint32 LOCALE_ILZERO = 18;
	public const uint32 LOCALE_INEGNUMBER = 4112;
	public const uint32 LOCALE_SNATIVEDIGITS = 19;
	public const uint32 LOCALE_SCURRENCY = 20;
	public const uint32 LOCALE_SINTLSYMBOL = 21;
	public const uint32 LOCALE_SMONDECIMALSEP = 22;
	public const uint32 LOCALE_SMONTHOUSANDSEP = 23;
	public const uint32 LOCALE_SMONGROUPING = 24;
	public const uint32 LOCALE_ICURRDIGITS = 25;
	public const uint32 LOCALE_ICURRENCY = 27;
	public const uint32 LOCALE_INEGCURR = 28;
	public const uint32 LOCALE_SSHORTDATE = 31;
	public const uint32 LOCALE_SLONGDATE = 32;
	public const uint32 LOCALE_STIMEFORMAT = 4099;
	public const uint32 LOCALE_SAM = 40;
	public const uint32 LOCALE_SPM = 41;
	public const uint32 LOCALE_ICALENDARTYPE = 4105;
	public const uint32 LOCALE_IOPTIONALCALENDAR = 4107;
	public const uint32 LOCALE_IFIRSTDAYOFWEEK = 4108;
	public const uint32 LOCALE_IFIRSTWEEKOFYEAR = 4109;
	public const uint32 LOCALE_SDAYNAME1 = 42;
	public const uint32 LOCALE_SDAYNAME2 = 43;
	public const uint32 LOCALE_SDAYNAME3 = 44;
	public const uint32 LOCALE_SDAYNAME4 = 45;
	public const uint32 LOCALE_SDAYNAME5 = 46;
	public const uint32 LOCALE_SDAYNAME6 = 47;
	public const uint32 LOCALE_SDAYNAME7 = 48;
	public const uint32 LOCALE_SABBREVDAYNAME1 = 49;
	public const uint32 LOCALE_SABBREVDAYNAME2 = 50;
	public const uint32 LOCALE_SABBREVDAYNAME3 = 51;
	public const uint32 LOCALE_SABBREVDAYNAME4 = 52;
	public const uint32 LOCALE_SABBREVDAYNAME5 = 53;
	public const uint32 LOCALE_SABBREVDAYNAME6 = 54;
	public const uint32 LOCALE_SABBREVDAYNAME7 = 55;
	public const uint32 LOCALE_SMONTHNAME1 = 56;
	public const uint32 LOCALE_SMONTHNAME2 = 57;
	public const uint32 LOCALE_SMONTHNAME3 = 58;
	public const uint32 LOCALE_SMONTHNAME4 = 59;
	public const uint32 LOCALE_SMONTHNAME5 = 60;
	public const uint32 LOCALE_SMONTHNAME6 = 61;
	public const uint32 LOCALE_SMONTHNAME7 = 62;
	public const uint32 LOCALE_SMONTHNAME8 = 63;
	public const uint32 LOCALE_SMONTHNAME9 = 64;
	public const uint32 LOCALE_SMONTHNAME10 = 65;
	public const uint32 LOCALE_SMONTHNAME11 = 66;
	public const uint32 LOCALE_SMONTHNAME12 = 67;
	public const uint32 LOCALE_SMONTHNAME13 = 4110;
	public const uint32 LOCALE_SABBREVMONTHNAME1 = 68;
	public const uint32 LOCALE_SABBREVMONTHNAME2 = 69;
	public const uint32 LOCALE_SABBREVMONTHNAME3 = 70;
	public const uint32 LOCALE_SABBREVMONTHNAME4 = 71;
	public const uint32 LOCALE_SABBREVMONTHNAME5 = 72;
	public const uint32 LOCALE_SABBREVMONTHNAME6 = 73;
	public const uint32 LOCALE_SABBREVMONTHNAME7 = 74;
	public const uint32 LOCALE_SABBREVMONTHNAME8 = 75;
	public const uint32 LOCALE_SABBREVMONTHNAME9 = 76;
	public const uint32 LOCALE_SABBREVMONTHNAME10 = 77;
	public const uint32 LOCALE_SABBREVMONTHNAME11 = 78;
	public const uint32 LOCALE_SABBREVMONTHNAME12 = 79;
	public const uint32 LOCALE_SABBREVMONTHNAME13 = 4111;
	public const uint32 LOCALE_SPOSITIVESIGN = 80;
	public const uint32 LOCALE_SNEGATIVESIGN = 81;
	public const uint32 LOCALE_IPOSSIGNPOSN = 82;
	public const uint32 LOCALE_INEGSIGNPOSN = 83;
	public const uint32 LOCALE_IPOSSYMPRECEDES = 84;
	public const uint32 LOCALE_IPOSSEPBYSPACE = 85;
	public const uint32 LOCALE_INEGSYMPRECEDES = 86;
	public const uint32 LOCALE_INEGSEPBYSPACE = 87;
	public const uint32 LOCALE_FONTSIGNATURE = 88;
	public const uint32 LOCALE_SISO639LANGNAME = 89;
	public const uint32 LOCALE_SISO3166CTRYNAME = 90;
	public const uint32 LOCALE_IPAPERSIZE = 4106;
	public const uint32 LOCALE_SENGCURRNAME = 4103;
	public const uint32 LOCALE_SNATIVECURRNAME = 4104;
	public const uint32 LOCALE_SYEARMONTH = 4102;
	public const uint32 LOCALE_SSORTNAME = 4115;
	public const uint32 LOCALE_IDIGITSUBSTITUTION = 4116;
	public const uint32 LOCALE_SNAME = 92;
	public const uint32 LOCALE_SDURATION = 93;
	public const uint32 LOCALE_SSHORTESTDAYNAME1 = 96;
	public const uint32 LOCALE_SSHORTESTDAYNAME2 = 97;
	public const uint32 LOCALE_SSHORTESTDAYNAME3 = 98;
	public const uint32 LOCALE_SSHORTESTDAYNAME4 = 99;
	public const uint32 LOCALE_SSHORTESTDAYNAME5 = 100;
	public const uint32 LOCALE_SSHORTESTDAYNAME6 = 101;
	public const uint32 LOCALE_SSHORTESTDAYNAME7 = 102;
	public const uint32 LOCALE_SISO639LANGNAME2 = 103;
	public const uint32 LOCALE_SISO3166CTRYNAME2 = 104;
	public const uint32 LOCALE_SNAN = 105;
	public const uint32 LOCALE_SPOSINFINITY = 106;
	public const uint32 LOCALE_SNEGINFINITY = 107;
	public const uint32 LOCALE_SSCRIPTS = 108;
	public const uint32 LOCALE_SPARENT = 109;
	public const uint32 LOCALE_SCONSOLEFALLBACKNAME = 110;
	public const uint32 LOCALE_IREADINGLAYOUT = 112;
	public const uint32 LOCALE_INEUTRAL = 113;
	public const uint32 LOCALE_INEGATIVEPERCENT = 116;
	public const uint32 LOCALE_IPOSITIVEPERCENT = 117;
	public const uint32 LOCALE_SPERCENT = 118;
	public const uint32 LOCALE_SPERMILLE = 119;
	public const uint32 LOCALE_SMONTHDAY = 120;
	public const uint32 LOCALE_SSHORTTIME = 121;
	public const uint32 LOCALE_SOPENTYPELANGUAGETAG = 122;
	public const uint32 LOCALE_SSORTLOCALE = 123;
	public const uint32 LOCALE_SRELATIVELONGDATE = 124;
	public const uint32 LOCALE_ICONSTRUCTEDLOCALE = 125;
	public const uint32 LOCALE_SSHORTESTAM = 126;
	public const uint32 LOCALE_SSHORTESTPM = 127;
	public const uint32 LOCALE_IUSEUTF8LEGACYACP = 1638;
	public const uint32 LOCALE_IUSEUTF8LEGACYOEMCP = 2457;
	public const uint32 LOCALE_IDEFAULTCODEPAGE = 11;
	public const uint32 LOCALE_IDEFAULTANSICODEPAGE = 4100;
	public const uint32 LOCALE_IDEFAULTMACCODEPAGE = 4113;
	public const uint32 LOCALE_IDEFAULTEBCDICCODEPAGE = 4114;
	public const uint32 LOCALE_ILANGUAGE = 1;
	public const uint32 LOCALE_SABBREVLANGNAME = 3;
	public const uint32 LOCALE_SABBREVCTRYNAME = 7;
	public const uint32 LOCALE_IGEOID = 91;
	public const uint32 LOCALE_IDEFAULTLANGUAGE = 9;
	public const uint32 LOCALE_IDEFAULTCOUNTRY = 10;
	public const uint32 LOCALE_IINTLCURRDIGITS = 26;
	public const uint32 LOCALE_SDATE = 29;
	public const uint32 LOCALE_STIME = 30;
	public const uint32 LOCALE_IDATE = 33;
	public const uint32 LOCALE_ILDATE = 34;
	public const uint32 LOCALE_ITIME = 35;
	public const uint32 LOCALE_ITIMEMARKPOSN = 4101;
	public const uint32 LOCALE_ICENTURY = 36;
	public const uint32 LOCALE_ITLZERO = 37;
	public const uint32 LOCALE_IDAYLZERO = 38;
	public const uint32 LOCALE_IMONLZERO = 39;
	public const uint32 LOCALE_SKEYBOARDSTOINSTALL = 94;
	public const uint32 LOCALE_SLANGUAGE = 2;
	public const uint32 LOCALE_SLANGDISPLAYNAME = 111;
	public const uint32 LOCALE_SENGLANGUAGE = 4097;
	public const uint32 LOCALE_SNATIVELANGNAME = 4;
	public const uint32 LOCALE_SCOUNTRY = 6;
	public const uint32 LOCALE_SENGCOUNTRY = 4098;
	public const uint32 LOCALE_SNATIVECTRYNAME = 8;
	public const uint32 LOCALE_ICOUNTRY = 5;
	public const uint32 LOCALE_S1159 = 40;
	public const uint32 LOCALE_S2359 = 41;
	public const uint32 CAL_NOUSEROVERRIDE = 2147483648;
	public const uint32 CAL_USE_CP_ACP = 1073741824;
	public const uint32 CAL_RETURN_NUMBER = 536870912;
	public const uint32 CAL_RETURN_GENITIVE_NAMES = 268435456;
	public const uint32 CAL_ICALINTVALUE = 1;
	public const uint32 CAL_SCALNAME = 2;
	public const uint32 CAL_IYEAROFFSETRANGE = 3;
	public const uint32 CAL_SERASTRING = 4;
	public const uint32 CAL_SSHORTDATE = 5;
	public const uint32 CAL_SLONGDATE = 6;
	public const uint32 CAL_SDAYNAME1 = 7;
	public const uint32 CAL_SDAYNAME2 = 8;
	public const uint32 CAL_SDAYNAME3 = 9;
	public const uint32 CAL_SDAYNAME4 = 10;
	public const uint32 CAL_SDAYNAME5 = 11;
	public const uint32 CAL_SDAYNAME6 = 12;
	public const uint32 CAL_SDAYNAME7 = 13;
	public const uint32 CAL_SABBREVDAYNAME1 = 14;
	public const uint32 CAL_SABBREVDAYNAME2 = 15;
	public const uint32 CAL_SABBREVDAYNAME3 = 16;
	public const uint32 CAL_SABBREVDAYNAME4 = 17;
	public const uint32 CAL_SABBREVDAYNAME5 = 18;
	public const uint32 CAL_SABBREVDAYNAME6 = 19;
	public const uint32 CAL_SABBREVDAYNAME7 = 20;
	public const uint32 CAL_SMONTHNAME1 = 21;
	public const uint32 CAL_SMONTHNAME2 = 22;
	public const uint32 CAL_SMONTHNAME3 = 23;
	public const uint32 CAL_SMONTHNAME4 = 24;
	public const uint32 CAL_SMONTHNAME5 = 25;
	public const uint32 CAL_SMONTHNAME6 = 26;
	public const uint32 CAL_SMONTHNAME7 = 27;
	public const uint32 CAL_SMONTHNAME8 = 28;
	public const uint32 CAL_SMONTHNAME9 = 29;
	public const uint32 CAL_SMONTHNAME10 = 30;
	public const uint32 CAL_SMONTHNAME11 = 31;
	public const uint32 CAL_SMONTHNAME12 = 32;
	public const uint32 CAL_SMONTHNAME13 = 33;
	public const uint32 CAL_SABBREVMONTHNAME1 = 34;
	public const uint32 CAL_SABBREVMONTHNAME2 = 35;
	public const uint32 CAL_SABBREVMONTHNAME3 = 36;
	public const uint32 CAL_SABBREVMONTHNAME4 = 37;
	public const uint32 CAL_SABBREVMONTHNAME5 = 38;
	public const uint32 CAL_SABBREVMONTHNAME6 = 39;
	public const uint32 CAL_SABBREVMONTHNAME7 = 40;
	public const uint32 CAL_SABBREVMONTHNAME8 = 41;
	public const uint32 CAL_SABBREVMONTHNAME9 = 42;
	public const uint32 CAL_SABBREVMONTHNAME10 = 43;
	public const uint32 CAL_SABBREVMONTHNAME11 = 44;
	public const uint32 CAL_SABBREVMONTHNAME12 = 45;
	public const uint32 CAL_SABBREVMONTHNAME13 = 46;
	public const uint32 CAL_SYEARMONTH = 47;
	public const uint32 CAL_ITWODIGITYEARMAX = 48;
	public const uint32 CAL_SSHORTESTDAYNAME1 = 49;
	public const uint32 CAL_SSHORTESTDAYNAME2 = 50;
	public const uint32 CAL_SSHORTESTDAYNAME3 = 51;
	public const uint32 CAL_SSHORTESTDAYNAME4 = 52;
	public const uint32 CAL_SSHORTESTDAYNAME5 = 53;
	public const uint32 CAL_SSHORTESTDAYNAME6 = 54;
	public const uint32 CAL_SSHORTESTDAYNAME7 = 55;
	public const uint32 CAL_SMONTHDAY = 56;
	public const uint32 CAL_SABBREVERASTRING = 57;
	public const uint32 CAL_SRELATIVELONGDATE = 58;
	public const uint32 CAL_SENGLISHERANAME = 59;
	public const uint32 CAL_SENGLISHABBREVERANAME = 60;
	public const uint32 CAL_SJAPANESEERAFIRSTYEAR = 61;
	public const uint32 ENUM_ALL_CALENDARS = 4294967295;
	public const uint32 CAL_GREGORIAN = 1;
	public const uint32 CAL_GREGORIAN_US = 2;
	public const uint32 CAL_JAPAN = 3;
	public const uint32 CAL_TAIWAN = 4;
	public const uint32 CAL_KOREA = 5;
	public const uint32 CAL_HIJRI = 6;
	public const uint32 CAL_THAI = 7;
	public const uint32 CAL_HEBREW = 8;
	public const uint32 CAL_GREGORIAN_ME_FRENCH = 9;
	public const uint32 CAL_GREGORIAN_ARABIC = 10;
	public const uint32 CAL_GREGORIAN_XLIT_ENGLISH = 11;
	public const uint32 CAL_GREGORIAN_XLIT_FRENCH = 12;
	public const uint32 CAL_PERSIAN = 22;
	public const uint32 CAL_UMALQURA = 23;
	public const uint32 LGRPID_WESTERN_EUROPE = 1;
	public const uint32 LGRPID_CENTRAL_EUROPE = 2;
	public const uint32 LGRPID_BALTIC = 3;
	public const uint32 LGRPID_GREEK = 4;
	public const uint32 LGRPID_CYRILLIC = 5;
	public const uint32 LGRPID_TURKIC = 6;
	public const uint32 LGRPID_TURKISH = 6;
	public const uint32 LGRPID_JAPANESE = 7;
	public const uint32 LGRPID_KOREAN = 8;
	public const uint32 LGRPID_TRADITIONAL_CHINESE = 9;
	public const uint32 LGRPID_SIMPLIFIED_CHINESE = 10;
	public const uint32 LGRPID_THAI = 11;
	public const uint32 LGRPID_HEBREW = 12;
	public const uint32 LGRPID_ARABIC = 13;
	public const uint32 LGRPID_VIETNAMESE = 14;
	public const uint32 LGRPID_INDIC = 15;
	public const uint32 LGRPID_GEORGIAN = 16;
	public const uint32 LGRPID_ARMENIAN = 17;
	public const uint32 MUI_LANGUAGE_ID = 4;
	public const uint32 MUI_LANGUAGE_NAME = 8;
	public const uint32 MUI_MERGE_SYSTEM_FALLBACK = 16;
	public const uint32 MUI_MERGE_USER_FALLBACK = 32;
	public const uint32 MUI_THREAD_LANGUAGES = 64;
	public const uint32 MUI_CONSOLE_FILTER = 256;
	public const uint32 MUI_COMPLEX_SCRIPT_FILTER = 512;
	public const uint32 MUI_RESET_FILTERS = 1;
	public const uint32 MUI_USER_PREFERRED_UI_LANGUAGES = 16;
	public const uint32 MUI_USE_INSTALLED_LANGUAGES = 32;
	public const uint32 MUI_USE_SEARCH_ALL_LANGUAGES = 64;
	public const uint32 MUI_LANG_NEUTRAL_PE_FILE = 256;
	public const uint32 MUI_NON_LANG_NEUTRAL_FILE = 512;
	public const uint32 MUI_MACHINE_LANGUAGE_SETTINGS = 1024;
	public const uint32 MUI_FILETYPE_NOT_LANGUAGE_NEUTRAL = 1;
	public const uint32 MUI_FILETYPE_LANGUAGE_NEUTRAL_MAIN = 2;
	public const uint32 MUI_FILETYPE_LANGUAGE_NEUTRAL_MUI = 4;
	public const uint32 MUI_QUERY_TYPE = 1;
	public const uint32 MUI_QUERY_CHECKSUM = 2;
	public const uint32 MUI_QUERY_LANGUAGE_NAME = 4;
	public const uint32 MUI_QUERY_RESOURCE_TYPES = 8;
	public const uint32 MUI_FILEINFO_VERSION = 1;
	public const uint32 MUI_FULL_LANGUAGE = 1;
	public const uint32 MUI_PARTIAL_LANGUAGE = 2;
	public const uint32 MUI_LIP_LANGUAGE = 4;
	public const uint32 MUI_LANGUAGE_INSTALLED = 32;
	public const uint32 MUI_LANGUAGE_LICENSED = 64;
	public const int32 GEOID_NOT_AVAILABLE = -1;
	public const uint32 SORTING_PARADIGM_NLS = 0;
	public const uint32 SORTING_PARADIGM_ICU = 16777216;
	public const uint32 IDN_ALLOW_UNASSIGNED = 1;
	public const uint32 IDN_USE_STD3_ASCII_RULES = 2;
	public const uint32 IDN_EMAIL_ADDRESS = 4;
	public const uint32 IDN_RAW_PUNYCODE = 8;
	public const uint32 VS_ALLOW_LATIN = 1;
	public const uint32 GSS_ALLOW_INHERITED_COMMON = 1;
	public const uint32 MUI_FORMAT_REG_COMPAT = 1;
	public const uint32 MUI_FORMAT_INF_COMPAT = 2;
	public const uint32 MUI_VERIFY_FILE_EXISTS = 4;
	public const uint32 MUI_SKIP_STRING_CACHE = 8;
	public const uint32 MUI_IMMUTABLE_LOOKUP = 16;
	public const String LOCALE_NAME_INVARIANT = "";
	public const String LOCALE_NAME_SYSTEM_DEFAULT = "!x-sys-default-locale";
	public const uint32 MIN_SPELLING_NTDDI = 100794368;
	public const uint32 SCRIPT_UNDEFINED = 0;
	public const HRESULT USP_E_SCRIPT_NOT_IN_FONT = -2147220992;
	public const uint32 SGCM_RTL = 1;
	public const uint32 SSA_PASSWORD = 1;
	public const uint32 SSA_TAB = 2;
	public const uint32 SSA_CLIP = 4;
	public const uint32 SSA_FIT = 8;
	public const uint32 SSA_DZWG = 16;
	public const uint32 SSA_FALLBACK = 32;
	public const uint32 SSA_BREAK = 64;
	public const uint32 SSA_GLYPHS = 128;
	public const uint32 SSA_RTL = 256;
	public const uint32 SSA_GCP = 512;
	public const uint32 SSA_HOTKEY = 1024;
	public const uint32 SSA_METAFILE = 2048;
	public const uint32 SSA_LINK = 4096;
	public const uint32 SSA_HIDEHOTKEY = 8192;
	public const uint32 SSA_HOTKEYONLY = 9216;
	public const uint32 SSA_FULLMEASURE = 67108864;
	public const uint32 SSA_LPKANSIFALLBACK = 134217728;
	public const uint32 SSA_PIDX = 268435456;
	public const uint32 SSA_LAYOUTRTL = 536870912;
	public const uint32 SSA_DONTGLYPH = 1073741824;
	public const uint32 SSA_NOKASHIDA = 2147483648;
	public const uint32 SCRIPT_DIGITSUBSTITUTE_CONTEXT = 0;
	public const uint32 SCRIPT_DIGITSUBSTITUTE_NONE = 1;
	public const uint32 SCRIPT_DIGITSUBSTITUTE_NATIONAL = 2;
	public const uint32 SCRIPT_DIGITSUBSTITUTE_TRADITIONAL = 3;
	public const uint32 UNISCRIBE_OPENTYPE = 256;
	public const uint32 SCRIPT_TAG_UNKNOWN = 0;
	public const uint32 MUI_LANGUAGE_EXACT = 16;
	public const uint32 NLS_CP_CPINFO = 268435456;
	public const uint32 NLS_CP_MBTOWC = 1073741824;
	public const uint32 NLS_CP_WCTOMB = 2147483648;
	public const uint32 U_DISABLE_RENAMING = 1;
	public const uint32 U_SHOW_CPLUSPLUS_API = 0;
	public const uint32 U_DEFAULT_SHOW_DRAFT = 0;
	public const uint32 U_HIDE_DRAFT_API = 1;
	public const uint32 U_HIDE_DEPRECATED_API = 1;
	public const uint32 U_HIDE_OBSOLETE_API = 1;
	public const uint32 U_HIDE_INTERNAL_API = 1;
	public const uint32 U_NO_DEFAULT_INCLUDE_UTF_HEADERS = 1;
	public const uint32 U_DEBUG = 1;
	public const uint32 UCLN_NO_AUTO_CLEANUP = 1;
	public const uint32 U_OVERRIDE_CXX_ALLOCATION = 1;
	public const uint32 U_ENABLE_TRACING = 0;
	public const uint32 UCONFIG_ENABLE_PLUGINS = 0;
	public const uint32 U_ENABLE_DYLOAD = 1;
	public const uint32 U_CHECK_DYLOAD = 1;
	public const uint32 U_HAVE_LIB_SUFFIX = 1;
	public const String U_LIB_SUFFIX_C_NAME_STRING = "";
	public const uint32 UCONFIG_ONLY_COLLATION = 0;
	public const uint32 UCONFIG_NO_BREAK_ITERATION = 1;
	public const uint32 UCONFIG_NO_IDNA = 1;
	public const uint32 UCONFIG_NO_FORMATTING = 1;
	public const uint32 UCONFIG_NO_TRANSLITERATION = 1;
	public const uint32 UCONFIG_NO_REGULAR_EXPRESSIONS = 1;
	public const uint32 UCONFIG_NO_FILE_IO = 0;
	public const uint32 UCONFIG_NO_CONVERSION = 0;
	public const uint32 UCONFIG_NO_LEGACY_CONVERSION = 1;
	public const uint32 UCONFIG_ONLY_HTML_CONVERSION = 0;
	public const uint32 UCONFIG_NO_NORMALIZATION = 0;
	public const uint32 UCONFIG_NO_COLLATION = 1;
	public const uint32 UCONFIG_NO_SERVICE = 0;
	public const uint32 UCONFIG_HAVE_PARSEALLINPUT = 1;
	public const uint32 UCONFIG_NO_FILTERED_BREAK_ITERATION = 0;
	public const uint32 U_PF_UNKNOWN = 0;
	public const uint32 U_PF_WINDOWS = 1000;
	public const uint32 U_PF_MINGW = 1800;
	public const uint32 U_PF_CYGWIN = 1900;
	public const uint32 U_PF_HPUX = 2100;
	public const uint32 U_PF_SOLARIS = 2600;
	public const uint32 U_PF_BSD = 3000;
	public const uint32 U_PF_AIX = 3100;
	public const uint32 U_PF_IRIX = 3200;
	public const uint32 U_PF_DARWIN = 3500;
	public const uint32 U_PF_IPHONE = 3550;
	public const uint32 U_PF_QNX = 3700;
	public const uint32 U_PF_LINUX = 4000;
	public const uint32 U_PF_BROWSER_NATIVE_CLIENT = 4020;
	public const uint32 U_PF_ANDROID = 4050;
	public const uint32 U_PF_FUCHSIA = 4100;
	public const uint32 U_PF_EMSCRIPTEN = 5010;
	public const uint32 U_PF_OS390 = 9000;
	public const uint32 U_PF_OS400 = 9400;
	public const uint32 U_PLATFORM = 1800;
	public const uint32 U_PLATFORM_USES_ONLY_WIN32_API = 1;
	public const uint32 U_PLATFORM_HAS_WIN32_API = 1;
	public const uint32 U_PLATFORM_IMPLEMENTS_POSIX = 0;
	public const uint32 U_PLATFORM_IS_LINUX_BASED = 1;
	public const uint32 U_PLATFORM_IS_DARWIN_BASED = 1;
	public const uint32 U_HAVE_STDINT_H = 1;
	public const uint32 U_HAVE_INTTYPES_H = 1;
	public const uint32 U_GCC_MAJOR_MINOR = 0;
	public const uint32 U_IS_BIG_ENDIAN = 0;
	public const uint32 U_HAVE_PLACEMENT_NEW = 0;
	public const uint32 U_HAVE_DEBUG_LOCATION_NEW = 1;
	public const uint32 U_CPLUSPLUS_VERSION = 0;
	public const uint32 U_ASCII_FAMILY = 0;
	public const uint32 U_EBCDIC_FAMILY = 1;
	public const uint32 U_CHARSET_FAMILY = 1;
	public const uint32 U_CHARSET_IS_UTF8 = 1;
	public const uint32 U_HAVE_WCHAR_H = 0;
	public const uint32 U_SIZEOF_WCHAR_T = 1;
	public const uint32 U_HAVE_WCSCPY = 0;
	public const uint32 U_HAVE_CHAR16_T = 1;
	public const uint32 U_DEFINE_FALSE_AND_TRUE = 1;
	public const uint32 U_SIZEOF_UCHAR = 2;
	public const uint32 U_CHAR16_IS_TYPEDEF = 1;
	public const int32 U_SENTINEL = -1;
	public const String U8_LEAD3_T1_BITS = " 000000000000\u{0010}00";
	public const String U8_LEAD4_T1_BITS = "\u{0000}\u{0000}\u{0000}\u{0000}\u{0000}\u{0000}\u{0000}\u{0000}\u{001e}\u{000f}\u{000f}\u{000f}\u{0000}\u{0000}\u{0000}\u{0000}";
	public const uint32 U8_MAX_LENGTH = 4;
	public const uint32 U16_MAX_LENGTH = 2;
	public const uint32 U_HIDE_OBSOLETE_UTF_OLD_H = 0;
	public const uint32 UTF_SIZE = 16;
	public const uint32 UTF8_ERROR_VALUE_1 = 21;
	public const uint32 UTF8_ERROR_VALUE_2 = 159;
	public const uint32 UTF_ERROR_VALUE = 65535;
	public const uint32 UTF8_MAX_CHAR_LENGTH = 4;
	public const uint32 UTF16_MAX_CHAR_LENGTH = 2;
	public const uint32 UTF32_MAX_CHAR_LENGTH = 1;
	public const uint32 UTF_MAX_CHAR_LENGTH = 2;
	public const uint32 U_COPYRIGHT_STRING_LENGTH = 128;
	public const uint32 U_MAX_VERSION_LENGTH = 4;
	public const uint32 U_MAX_VERSION_STRING_LENGTH = 20;
	public const uint32 U_MILLIS_PER_SECOND = 1000;
	public const uint32 U_MILLIS_PER_MINUTE = 60000;
	public const uint32 U_MILLIS_PER_HOUR = 3600000;
	public const uint32 U_MILLIS_PER_DAY = 86400000;
	public const uint32 U_COMBINED_IMPLEMENTATION = 1;
	public const uint32 U_SHAPE_LENGTH_GROW_SHRINK = 0;
	public const uint32 U_SHAPE_LAMALEF_RESIZE = 0;
	public const uint32 U_SHAPE_LENGTH_FIXED_SPACES_NEAR = 1;
	public const uint32 U_SHAPE_LAMALEF_NEAR = 1;
	public const uint32 U_SHAPE_LENGTH_FIXED_SPACES_AT_END = 2;
	public const uint32 U_SHAPE_LAMALEF_END = 2;
	public const uint32 U_SHAPE_LENGTH_FIXED_SPACES_AT_BEGINNING = 3;
	public const uint32 U_SHAPE_LAMALEF_BEGIN = 3;
	public const uint32 U_SHAPE_LAMALEF_AUTO = 65536;
	public const uint32 U_SHAPE_LENGTH_MASK = 65539;
	public const uint32 U_SHAPE_LAMALEF_MASK = 65539;
	public const uint32 U_SHAPE_TEXT_DIRECTION_LOGICAL = 0;
	public const uint32 U_SHAPE_TEXT_DIRECTION_VISUAL_RTL = 0;
	public const uint32 U_SHAPE_TEXT_DIRECTION_VISUAL_LTR = 4;
	public const uint32 U_SHAPE_TEXT_DIRECTION_MASK = 4;
	public const uint32 U_SHAPE_LETTERS_NOOP = 0;
	public const uint32 U_SHAPE_LETTERS_SHAPE = 8;
	public const uint32 U_SHAPE_LETTERS_UNSHAPE = 16;
	public const uint32 U_SHAPE_LETTERS_SHAPE_TASHKEEL_ISOLATED = 24;
	public const uint32 U_SHAPE_LETTERS_MASK = 24;
	public const uint32 U_SHAPE_DIGITS_NOOP = 0;
	public const uint32 U_SHAPE_DIGITS_EN2AN = 32;
	public const uint32 U_SHAPE_DIGITS_AN2EN = 64;
	public const uint32 U_SHAPE_DIGITS_ALEN2AN_INIT_LR = 96;
	public const uint32 U_SHAPE_DIGITS_ALEN2AN_INIT_AL = 128;
	public const uint32 U_SHAPE_DIGITS_RESERVED = 160;
	public const uint32 U_SHAPE_DIGITS_MASK = 224;
	public const uint32 U_SHAPE_DIGIT_TYPE_AN = 0;
	public const uint32 U_SHAPE_DIGIT_TYPE_AN_EXTENDED = 256;
	public const uint32 U_SHAPE_DIGIT_TYPE_RESERVED = 512;
	public const uint32 U_SHAPE_DIGIT_TYPE_MASK = 768;
	public const uint32 U_SHAPE_AGGREGATE_TASHKEEL = 16384;
	public const uint32 U_SHAPE_AGGREGATE_TASHKEEL_NOOP = 0;
	public const uint32 U_SHAPE_AGGREGATE_TASHKEEL_MASK = 16384;
	public const uint32 U_SHAPE_PRESERVE_PRESENTATION = 32768;
	public const uint32 U_SHAPE_PRESERVE_PRESENTATION_NOOP = 0;
	public const uint32 U_SHAPE_PRESERVE_PRESENTATION_MASK = 32768;
	public const uint32 U_SHAPE_SEEN_TWOCELL_NEAR = 2097152;
	public const uint32 U_SHAPE_SEEN_MASK = 7340032;
	public const uint32 U_SHAPE_YEHHAMZA_TWOCELL_NEAR = 16777216;
	public const uint32 U_SHAPE_YEHHAMZA_MASK = 58720256;
	public const uint32 U_SHAPE_TASHKEEL_BEGIN = 262144;
	public const uint32 U_SHAPE_TASHKEEL_END = 393216;
	public const uint32 U_SHAPE_TASHKEEL_RESIZE = 524288;
	public const uint32 U_SHAPE_TASHKEEL_REPLACE_BY_TATWEEL = 786432;
	public const uint32 U_SHAPE_TASHKEEL_MASK = 917504;
	public const uint32 U_SHAPE_SPACES_RELATIVE_TO_TEXT_BEGIN_END = 67108864;
	public const uint32 U_SHAPE_SPACES_RELATIVE_TO_TEXT_MASK = 67108864;
	public const uint32 U_SHAPE_TAIL_NEW_UNICODE = 134217728;
	public const uint32 U_SHAPE_TAIL_TYPE_MASK = 134217728;
	public const String ULOC_CHINESE = "zh";
	public const String ULOC_ENGLISH = "en";
	public const String ULOC_FRENCH = "fr";
	public const String ULOC_GERMAN = "de";
	public const String ULOC_ITALIAN = "it";
	public const String ULOC_JAPANESE = "ja";
	public const String ULOC_KOREAN = "ko";
	public const String ULOC_SIMPLIFIED_CHINESE = "zh_CN";
	public const String ULOC_TRADITIONAL_CHINESE = "zh_TW";
	public const String ULOC_CANADA = "en_CA";
	public const String ULOC_CANADA_FRENCH = "fr_CA";
	public const String ULOC_CHINA = "zh_CN";
	public const String ULOC_PRC = "zh_CN";
	public const String ULOC_FRANCE = "fr_FR";
	public const String ULOC_GERMANY = "de_DE";
	public const String ULOC_ITALY = "it_IT";
	public const String ULOC_JAPAN = "ja_JP";
	public const String ULOC_KOREA = "ko_KR";
	public const String ULOC_TAIWAN = "zh_TW";
	public const String ULOC_UK = "en_GB";
	public const String ULOC_US = "en_US";
	public const uint32 ULOC_LANG_CAPACITY = 12;
	public const uint32 ULOC_COUNTRY_CAPACITY = 4;
	public const uint32 ULOC_FULLNAME_CAPACITY = 157;
	public const uint32 ULOC_SCRIPT_CAPACITY = 6;
	public const uint32 ULOC_KEYWORDS_CAPACITY = 96;
	public const uint32 ULOC_KEYWORD_AND_VALUES_CAPACITY = 100;
	public const uint32 ULOC_KEYWORD_SEPARATOR_UNICODE = 64;
	public const uint32 ULOC_KEYWORD_ASSIGN_UNICODE = 61;
	public const uint32 ULOC_KEYWORD_ITEM_SEPARATOR_UNICODE = 59;
	public const String UCNV_SUB_STOP_ON_ILLEGAL = "i";
	public const String UCNV_SKIP_STOP_ON_ILLEGAL = "i";
	public const String UCNV_ESCAPE_JAVA = "J";
	public const String UCNV_ESCAPE_C = "C";
	public const String UCNV_ESCAPE_XML_DEC = "D";
	public const String UCNV_ESCAPE_XML_HEX = "X";
	public const String UCNV_ESCAPE_UNICODE = "U";
	public const String UCNV_ESCAPE_CSS2 = "S";
	public const uint32 UCNV_MAX_CONVERTER_NAME_LENGTH = 60;
	public const uint32 UCNV_SI = 15;
	public const uint32 UCNV_SO = 14;
	public const String UCNV_OPTION_SEP_STRING = ",";
	public const String UCNV_VALUE_SEP_STRING = "=";
	public const String UCNV_LOCALE_OPTION_STRING = ",locale=";
	public const String UCNV_VERSION_OPTION_STRING = ",version=";
	public const String UCNV_SWAP_LFNL_OPTION_STRING = ",swaplfnl";
	public const uint32 U_FOLD_CASE_DEFAULT = 0;
	public const uint32 U_FOLD_CASE_EXCLUDE_SPECIAL_I = 1;
	public const uint32 U_TITLECASE_WHOLE_STRING = 32;
	public const uint32 U_TITLECASE_SENTENCES = 64;
	public const uint32 U_TITLECASE_NO_LOWERCASE = 256;
	public const uint32 U_TITLECASE_NO_BREAK_ADJUSTMENT = 512;
	public const uint32 U_TITLECASE_ADJUST_TO_CASED = 1024;
	public const uint32 U_EDITS_NO_RESET = 8192;
	public const uint32 U_OMIT_UNCHANGED_TEXT = 16384;
	public const uint32 U_COMPARE_CODE_POINT_ORDER = 32768;
	public const uint32 U_COMPARE_IGNORE_CASE = 65536;
	public const uint32 UNORM_INPUT_IS_FCD = 131072;
	public const uint32 UCHAR_MIN_VALUE = 0;
	public const uint32 UCHAR_MAX_VALUE = 1114111;
	public const uint32 UBIDI_DEFAULT_LTR = 254;
	public const uint32 UBIDI_DEFAULT_RTL = 255;
	public const uint32 UBIDI_MAX_EXPLICIT_LEVEL = 125;
	public const uint32 UBIDI_LEVEL_OVERRIDE = 128;
	public const int32 UBIDI_MAP_NOWHERE = -1;
	public const uint32 UBIDI_KEEP_BASE_COMBINING = 1;
	public const uint32 UBIDI_DO_MIRRORING = 2;
	public const uint32 UBIDI_INSERT_LRM_FOR_NUMERIC = 4;
	public const uint32 UBIDI_REMOVE_BIDI_CONTROLS = 8;
	public const uint32 UBIDI_OUTPUT_REVERSE = 16;
	public const uint32 USPREP_DEFAULT = 0;
	public const uint32 USPREP_ALLOW_UNASSIGNED = 1;
	public const String U_ICU_VERSION_BUNDLE = "icuver";
	public const String U_ICU_DATA_KEY = "DataVersion";
	public const String UCAL_UNKNOWN_ZONE_ID = "Etc/Unknown";
	public const String UDAT_YEAR = "y";
	public const String UDAT_QUARTER = "QQQQ";
	public const String UDAT_ABBR_QUARTER = "QQQ";
	public const String UDAT_YEAR_QUARTER = "yQQQQ";
	public const String UDAT_YEAR_ABBR_QUARTER = "yQQQ";
	public const String UDAT_MONTH = "MMMM";
	public const String UDAT_ABBR_MONTH = "MMM";
	public const String UDAT_NUM_MONTH = "M";
	public const String UDAT_YEAR_MONTH = "yMMMM";
	public const String UDAT_YEAR_ABBR_MONTH = "yMMM";
	public const String UDAT_YEAR_NUM_MONTH = "yM";
	public const String UDAT_DAY = "d";
	public const String UDAT_YEAR_MONTH_DAY = "yMMMMd";
	public const String UDAT_YEAR_ABBR_MONTH_DAY = "yMMMd";
	public const String UDAT_YEAR_NUM_MONTH_DAY = "yMd";
	public const String UDAT_WEEKDAY = "EEEE";
	public const String UDAT_ABBR_WEEKDAY = "E";
	public const String UDAT_YEAR_MONTH_WEEKDAY_DAY = "yMMMMEEEEd";
	public const String UDAT_YEAR_ABBR_MONTH_WEEKDAY_DAY = "yMMMEd";
	public const String UDAT_YEAR_NUM_MONTH_WEEKDAY_DAY = "yMEd";
	public const String UDAT_MONTH_DAY = "MMMMd";
	public const String UDAT_ABBR_MONTH_DAY = "MMMd";
	public const String UDAT_NUM_MONTH_DAY = "Md";
	public const String UDAT_MONTH_WEEKDAY_DAY = "MMMMEEEEd";
	public const String UDAT_ABBR_MONTH_WEEKDAY_DAY = "MMMEd";
	public const String UDAT_NUM_MONTH_WEEKDAY_DAY = "MEd";
	public const String UDAT_HOUR = "j";
	public const String UDAT_HOUR24 = "H";
	public const String UDAT_MINUTE = "m";
	public const String UDAT_HOUR_MINUTE = "jm";
	public const String UDAT_HOUR24_MINUTE = "Hm";
	public const String UDAT_SECOND = "s";
	public const String UDAT_HOUR_MINUTE_SECOND = "jms";
	public const String UDAT_HOUR24_MINUTE_SECOND = "Hms";
	public const String UDAT_MINUTE_SECOND = "ms";
	public const String UDAT_LOCATION_TZ = "VVVV";
	public const String UDAT_GENERIC_TZ = "vvvv";
	public const String UDAT_ABBR_GENERIC_TZ = "v";
	public const String UDAT_SPECIFIC_TZ = "zzzz";
	public const String UDAT_ABBR_SPECIFIC_TZ = "z";
	public const String UDAT_ABBR_UTC_TZ = "ZZZZ";
	public const int32 USEARCH_DONE = -1;
	public const uint32 U_HAVE_STD_STRING = 0;
	public const uint32 UCONFIG_FORMAT_FASTPATHS_49 = 1;
	public const uint32 U_PLATFORM_HAS_WINUWP_API = 0;
	public const uint32 U_IOSTREAM_SOURCE = 199711;
	public const uint32 U_HAVE_RVALUE_REFERENCES = 1;
	public const uint32 U_USING_ICU_NAMESPACE = 1;
	public const String U_ICUDATA_TYPE_LETTER = "e";
	public const String U_UNICODE_VERSION = "8.0";
	public const uint32 CANITER_SKIP_ZEROES = 1;
	public const uint32 NUMSYS_NAME_CAPACITY = 8;
	public const uint32 U_HAVE_RBNF = 0;
	public const uint32 MAX_MIMECP_NAME = 64;
	public const uint32 MAX_MIMECSET_NAME = 50;
	public const uint32 MAX_MIMEFACE_NAME = 32;
	public const uint32 MAX_RFC1766_NAME = 6;
	public const uint32 MAX_LOCALE_NAME = 32;
	public const uint32 MAX_SCRIPT_NAME = 48;
	public const int32 CPIOD_PEEK = 1073741824;
	public const int32 CPIOD_FORCE_PROMPT = -2147483648;
	public const int32 UITER_UNKNOWN_INDEX = -2;
	public const int32 UCPTRIE_FAST_SHIFT = 6;
	public const int32 UCPTRIE_FAST_DATA_BLOCK_LENGTH = 64;
	public const int32 UCPTRIE_FAST_DATA_MASK = 63;
	public const int32 UCPTRIE_SMALL_MAX = 4095;
	public const int32 UCPTRIE_ERROR_VALUE_NEG_DATA_OFFSET = 1;
	public const int32 UCPTRIE_HIGH_VALUE_NEG_DATA_OFFSET = 2;
	public const int32 UTEXT_PROVIDER_LENGTH_IS_EXPENSIVE = 1;
	public const int32 UTEXT_PROVIDER_STABLE_CHUNKS = 2;
	public const int32 UTEXT_PROVIDER_WRITABLE = 3;
	public const int32 UTEXT_PROVIDER_HAS_META_DATA = 4;
	public const int32 UTEXT_PROVIDER_OWNS_TEXT = 5;
	public const int32 UTEXT_MAGIC = 878368812;
	public const int32 USET_IGNORE_SPACE = 1;
	public const int32 USET_CASE_INSENSITIVE = 2;
	public const int32 USET_ADD_CASE_MAPPINGS = 4;
	public const int32 USET_SERIALIZED_STATIC_ARRAY_CAPACITY = 8;
	public const int32 U_PARSE_CONTEXT_LEN = 16;
	public const int32 UIDNA_DEFAULT = 0;
	public const int32 UIDNA_USE_STD3_RULES = 2;
	public const int32 UIDNA_CHECK_BIDI = 4;
	public const int32 UIDNA_CHECK_CONTEXTJ = 8;
	public const int32 UIDNA_NONTRANSITIONAL_TO_ASCII = 16;
	public const int32 UIDNA_NONTRANSITIONAL_TO_UNICODE = 32;
	public const int32 UIDNA_CHECK_CONTEXTO = 64;
	public const int32 UIDNA_ERROR_EMPTY_LABEL = 1;
	public const int32 UIDNA_ERROR_LABEL_TOO_LONG = 2;
	public const int32 UIDNA_ERROR_DOMAIN_NAME_TOO_LONG = 4;
	public const int32 UIDNA_ERROR_LEADING_HYPHEN = 8;
	public const int32 UIDNA_ERROR_TRAILING_HYPHEN = 16;
	public const int32 UIDNA_ERROR_HYPHEN_3_4 = 32;
	public const int32 UIDNA_ERROR_LEADING_COMBINING_MARK = 64;
	public const int32 UIDNA_ERROR_DISALLOWED = 128;
	public const int32 UIDNA_ERROR_PUNYCODE = 256;
	public const int32 UIDNA_ERROR_LABEL_HAS_DOT = 512;
	public const int32 UIDNA_ERROR_INVALID_ACE_LABEL = 1024;
	public const int32 UIDNA_ERROR_BIDI = 2048;
	public const int32 UIDNA_ERROR_CONTEXTJ = 4096;
	public const int32 UIDNA_ERROR_CONTEXTO_PUNCTUATION = 8192;
	public const int32 UIDNA_ERROR_CONTEXTO_DIGITS = 16384;
	public const Guid ELS_GUID_LANGUAGE_DETECTION = .(0xcf7e00b1, 0x909b, 0x4d95, 0xa8, 0xf4, 0x61, 0x1f, 0x7c, 0x37, 0x77, 0x02);
	public const Guid ELS_GUID_SCRIPT_DETECTION = .(0x2d64b439, 0x6caf, 0x4f6b, 0xb6, 0x88, 0xe5, 0xd0, 0xf4, 0xfa, 0xa7, 0xd7);
	public const Guid ELS_GUID_TRANSLITERATION_HANT_TO_HANS = .(0xa3a8333b, 0xf4fc, 0x42f6, 0xa0, 0xc4, 0x04, 0x62, 0xfe, 0x73, 0x17, 0xcb);
	public const Guid ELS_GUID_TRANSLITERATION_HANS_TO_HANT = .(0x3caccdc8, 0x5590, 0x42dc, 0x9a, 0x7b, 0xb5, 0xa6, 0xb5, 0xb3, 0xb6, 0x3b);
	public const Guid ELS_GUID_TRANSLITERATION_MALAYALAM_TO_LATIN = .(0xd8b983b1, 0xf8bf, 0x4a2b, 0xbc, 0xd5, 0x5b, 0x5e, 0xa2, 0x06, 0x13, 0xe1);
	public const Guid ELS_GUID_TRANSLITERATION_DEVANAGARI_TO_LATIN = .(0xc4a4dcfe, 0x2661, 0x4d02, 0x98, 0x35, 0xf4, 0x81, 0x87, 0x10, 0x98, 0x03);
	public const Guid ELS_GUID_TRANSLITERATION_CYRILLIC_TO_LATIN = .(0x3dd12a98, 0x5afd, 0x4903, 0xa1, 0x3f, 0xe1, 0x7e, 0x6c, 0x0b, 0xfe, 0x01);
	public const Guid ELS_GUID_TRANSLITERATION_BENGALI_TO_LATIN = .(0xf4dfd825, 0x91a4, 0x489f, 0x85, 0x5e, 0x9a, 0xd9, 0xbe, 0xe5, 0x57, 0x27);
	public const Guid ELS_GUID_TRANSLITERATION_HANGUL_DECOMPOSITION = .(0x4ba2a721, 0xe43d, 0x41b7, 0xb3, 0x30, 0x53, 0x6a, 0xe1, 0xe4, 0x88, 0x63);
	public const int32 UMSGPAT_ARG_NAME_NOT_NUMBER = -1;
	public const int32 UMSGPAT_ARG_NAME_NOT_VALID = -2;
}
#endregion

#region TypeDefs
typealias HIMC = int;

typealias HIMCC = int;

typealias HSAVEDUILANGUAGES = int;

#endregion


#region Enums

[AllowDuplicates]
public enum FOLD_STRING_MAP_FLAGS : uint32
{
	MAP_COMPOSITE = 64,
	MAP_EXPAND_LIGATURES = 8192,
	MAP_FOLDCZONE = 16,
	MAP_FOLDDIGITS = 128,
	MAP_PRECOMPOSED = 32,
}


[AllowDuplicates]
public enum ENUM_DATE_FORMATS_FLAGS : uint32
{
	DATE_SHORTDATE = 1,
	DATE_LONGDATE = 2,
	DATE_YEARMONTH = 8,
	DATE_MONTHDAY = 128,
	DATE_AUTOLAYOUT = 64,
	DATE_LTRREADING = 16,
	DATE_RTLREADING = 32,
	DATE_USE_ALT_CALENDAR = 4,
}


[AllowDuplicates]
public enum TRANSLATE_CHARSET_INFO_FLAGS : uint32
{
	TCI_SRCCHARSET = 1,
	TCI_SRCCODEPAGE = 2,
	TCI_SRCFONTSIG = 3,
	TCI_SRCLOCALE = 4096,
}


[AllowDuplicates]
public enum TIME_FORMAT_FLAGS : uint32
{
	TIME_NOMINUTESORSECONDS = 1,
	TIME_NOSECONDS = 2,
	TIME_NOTIMEMARKER = 4,
	TIME_FORCE24HOURFORMAT = 8,
}


[AllowDuplicates]
public enum ENUM_SYSTEM_LANGUAGE_GROUPS_FLAGS : uint32
{
	LGRPID_INSTALLED = 1,
	LGRPID_SUPPORTED = 2,
}


[AllowDuplicates]
public enum MULTI_BYTE_TO_WIDE_CHAR_FLAGS : uint32
{
	MB_COMPOSITE = 2,
	MB_ERR_INVALID_CHARS = 8,
	MB_PRECOMPOSED = 1,
	MB_USEGLYPHCHARS = 4,
}


[AllowDuplicates]
public enum COMPARE_STRING_FLAGS : uint32
{
	LINGUISTIC_IGNORECASE = 16,
	LINGUISTIC_IGNOREDIACRITIC = 32,
	NORM_IGNORECASE = 1,
	NORM_IGNOREKANATYPE = 65536,
	NORM_IGNORENONSPACE = 2,
	NORM_IGNORESYMBOLS = 4,
	NORM_IGNOREWIDTH = 131072,
	NORM_LINGUISTIC_CASING = 134217728,
	SORT_DIGITSASNUMBERS = 8,
	SORT_STRINGSORT = 4096,
}


[AllowDuplicates]
public enum IS_VALID_LOCALE_FLAGS : uint32
{
	LCID_INSTALLED = 1,
	LCID_SUPPORTED = 2,
}


[AllowDuplicates]
public enum ENUM_SYSTEM_CODE_PAGES_FLAGS : uint32
{
	CP_INSTALLED = 1,
	CP_SUPPORTED = 2,
}


[AllowDuplicates]
public enum SCRIPT_IS_COMPLEX_FLAGS : uint32
{
	SIC_ASCIIDIGIT = 2,
	SIC_COMPLEX = 1,
	SIC_NEUTRAL = 4,
}


[AllowDuplicates]
public enum IS_TEXT_UNICODE_RESULT : uint32
{
	IS_TEXT_UNICODE_ASCII16 = 1,
	IS_TEXT_UNICODE_REVERSE_ASCII16 = 16,
	IS_TEXT_UNICODE_STATISTICS = 2,
	IS_TEXT_UNICODE_REVERSE_STATISTICS = 32,
	IS_TEXT_UNICODE_CONTROLS = 4,
	IS_TEXT_UNICODE_REVERSE_CONTROLS = 64,
	IS_TEXT_UNICODE_SIGNATURE = 8,
	IS_TEXT_UNICODE_REVERSE_SIGNATURE = 128,
	IS_TEXT_UNICODE_ILLEGAL_CHARS = 256,
	IS_TEXT_UNICODE_ODD_LENGTH = 512,
	IS_TEXT_UNICODE_NULL_BYTES = 4096,
	IS_TEXT_UNICODE_UNICODE_MASK = 15,
	IS_TEXT_UNICODE_REVERSE_MASK = 240,
	IS_TEXT_UNICODE_NOT_UNICODE_MASK = 3840,
	IS_TEXT_UNICODE_NOT_ASCII_MASK = 61440,
}


[AllowDuplicates]
public enum SYSNLS_FUNCTION : int32
{
	COMPARE_STRING = 1,
}


[AllowDuplicates]
public enum SYSGEOTYPE : int32
{
	GEO_NATION = 1,
	GEO_LATITUDE = 2,
	GEO_LONGITUDE = 3,
	GEO_ISO2 = 4,
	GEO_ISO3 = 5,
	GEO_RFC1766 = 6,
	GEO_LCID = 7,
	GEO_FRIENDLYNAME = 8,
	GEO_OFFICIALNAME = 9,
	GEO_TIMEZONES = 10,
	GEO_OFFICIALLANGUAGES = 11,
	GEO_ISO_UN_NUMBER = 12,
	GEO_PARENT = 13,
	GEO_DIALINGCODE = 14,
	GEO_CURRENCYCODE = 15,
	GEO_CURRENCYSYMBOL = 16,
	GEO_NAME = 17,
	GEO_ID = 18,
}


[AllowDuplicates]
public enum SYSGEOCLASS : int32
{
	GEOCLASS_NATION = 16,
	GEOCLASS_REGION = 14,
	GEOCLASS_ALL = 0,
}


[AllowDuplicates]
public enum NORM_FORM : int32
{
	NormalizationOther = 0,
	NormalizationC = 1,
	NormalizationD = 2,
	NormalizationKC = 5,
	NormalizationKD = 6,
}


[AllowDuplicates]
public enum WORDLIST_TYPE : int32
{
	WORDLIST_TYPE_IGNORE = 0,
	WORDLIST_TYPE_ADD = 1,
	WORDLIST_TYPE_EXCLUDE = 2,
	WORDLIST_TYPE_AUTOCORRECT = 3,
}


[AllowDuplicates]
public enum CORRECTIVE_ACTION : int32
{
	CORRECTIVE_ACTION_NONE = 0,
	CORRECTIVE_ACTION_GET_SUGGESTIONS = 1,
	CORRECTIVE_ACTION_REPLACE = 2,
	CORRECTIVE_ACTION_DELETE = 3,
}


[AllowDuplicates]
public enum SCRIPT_JUSTIFY : int32
{
	SCRIPT_JUSTIFY_NONE = 0,
	SCRIPT_JUSTIFY_ARABIC_BLANK = 1,
	SCRIPT_JUSTIFY_CHARACTER = 2,
	SCRIPT_JUSTIFY_RESERVED1 = 3,
	SCRIPT_JUSTIFY_BLANK = 4,
	SCRIPT_JUSTIFY_RESERVED2 = 5,
	SCRIPT_JUSTIFY_RESERVED3 = 6,
	SCRIPT_JUSTIFY_ARABIC_NORMAL = 7,
	SCRIPT_JUSTIFY_ARABIC_KASHIDA = 8,
	SCRIPT_JUSTIFY_ARABIC_ALEF = 9,
	SCRIPT_JUSTIFY_ARABIC_HA = 10,
	SCRIPT_JUSTIFY_ARABIC_RA = 11,
	SCRIPT_JUSTIFY_ARABIC_BA = 12,
	SCRIPT_JUSTIFY_ARABIC_BARA = 13,
	SCRIPT_JUSTIFY_ARABIC_SEEN = 14,
	SCRIPT_JUSTIFY_ARABIC_SEEN_M = 15,
}


[AllowDuplicates]
public enum UErrorCode : int32
{
	U_USING_FALLBACK_WARNING = -128,
	U_ERROR_WARNING_START = -128,
	U_USING_DEFAULT_WARNING = -127,
	U_SAFECLONE_ALLOCATED_WARNING = -126,
	U_STATE_OLD_WARNING = -125,
	U_STRING_NOT_TERMINATED_WARNING = -124,
	U_SORT_KEY_TOO_SHORT_WARNING = -123,
	U_AMBIGUOUS_ALIAS_WARNING = -122,
	U_DIFFERENT_UCA_VERSION = -121,
	U_PLUGIN_CHANGED_LEVEL_WARNING = -120,
	U_ZERO_ERROR = 0,
	U_ILLEGAL_ARGUMENT_ERROR = 1,
	U_MISSING_RESOURCE_ERROR = 2,
	U_INVALID_FORMAT_ERROR = 3,
	U_FILE_ACCESS_ERROR = 4,
	U_INTERNAL_PROGRAM_ERROR = 5,
	U_MESSAGE_PARSE_ERROR = 6,
	U_MEMORY_ALLOCATION_ERROR = 7,
	U_INDEX_OUTOFBOUNDS_ERROR = 8,
	U_PARSE_ERROR = 9,
	U_INVALID_CHAR_FOUND = 10,
	U_TRUNCATED_CHAR_FOUND = 11,
	U_ILLEGAL_CHAR_FOUND = 12,
	U_INVALID_TABLE_FORMAT = 13,
	U_INVALID_TABLE_FILE = 14,
	U_BUFFER_OVERFLOW_ERROR = 15,
	U_UNSUPPORTED_ERROR = 16,
	U_RESOURCE_TYPE_MISMATCH = 17,
	U_ILLEGAL_ESCAPE_SEQUENCE = 18,
	U_UNSUPPORTED_ESCAPE_SEQUENCE = 19,
	U_NO_SPACE_AVAILABLE = 20,
	U_CE_NOT_FOUND_ERROR = 21,
	U_PRIMARY_TOO_LONG_ERROR = 22,
	U_STATE_TOO_OLD_ERROR = 23,
	U_TOO_MANY_ALIASES_ERROR = 24,
	U_ENUM_OUT_OF_SYNC_ERROR = 25,
	U_INVARIANT_CONVERSION_ERROR = 26,
	U_INVALID_STATE_ERROR = 27,
	U_COLLATOR_VERSION_MISMATCH = 28,
	U_USELESS_COLLATOR_ERROR = 29,
	U_NO_WRITE_PERMISSION = 30,
	U_BAD_VARIABLE_DEFINITION = 65536,
	U_PARSE_ERROR_START = 65536,
	U_MALFORMED_RULE = 65537,
	U_MALFORMED_SET = 65538,
	U_MALFORMED_SYMBOL_REFERENCE = 65539,
	U_MALFORMED_UNICODE_ESCAPE = 65540,
	U_MALFORMED_VARIABLE_DEFINITION = 65541,
	U_MALFORMED_VARIABLE_REFERENCE = 65542,
	U_MISMATCHED_SEGMENT_DELIMITERS = 65543,
	U_MISPLACED_ANCHOR_START = 65544,
	U_MISPLACED_CURSOR_OFFSET = 65545,
	U_MISPLACED_QUANTIFIER = 65546,
	U_MISSING_OPERATOR = 65547,
	U_MISSING_SEGMENT_CLOSE = 65548,
	U_MULTIPLE_ANTE_CONTEXTS = 65549,
	U_MULTIPLE_CURSORS = 65550,
	U_MULTIPLE_POST_CONTEXTS = 65551,
	U_TRAILING_BACKSLASH = 65552,
	U_UNDEFINED_SEGMENT_REFERENCE = 65553,
	U_UNDEFINED_VARIABLE = 65554,
	U_UNQUOTED_SPECIAL = 65555,
	U_UNTERMINATED_QUOTE = 65556,
	U_RULE_MASK_ERROR = 65557,
	U_MISPLACED_COMPOUND_FILTER = 65558,
	U_MULTIPLE_COMPOUND_FILTERS = 65559,
	U_INVALID_RBT_SYNTAX = 65560,
	U_INVALID_PROPERTY_PATTERN = 65561,
	U_MALFORMED_PRAGMA = 65562,
	U_UNCLOSED_SEGMENT = 65563,
	U_ILLEGAL_CHAR_IN_SEGMENT = 65564,
	U_VARIABLE_RANGE_EXHAUSTED = 65565,
	U_VARIABLE_RANGE_OVERLAP = 65566,
	U_ILLEGAL_CHARACTER = 65567,
	U_INTERNAL_TRANSLITERATOR_ERROR = 65568,
	U_INVALID_ID = 65569,
	U_INVALID_FUNCTION = 65570,
	U_UNEXPECTED_TOKEN = 65792,
	U_FMT_PARSE_ERROR_START = 65792,
	U_MULTIPLE_DECIMAL_SEPARATORS = 65793,
	U_MULTIPLE_DECIMAL_SEPERATORS = 65793,
	U_MULTIPLE_EXPONENTIAL_SYMBOLS = 65794,
	U_MALFORMED_EXPONENTIAL_PATTERN = 65795,
	U_MULTIPLE_PERCENT_SYMBOLS = 65796,
	U_MULTIPLE_PERMILL_SYMBOLS = 65797,
	U_MULTIPLE_PAD_SPECIFIERS = 65798,
	U_PATTERN_SYNTAX_ERROR = 65799,
	U_ILLEGAL_PAD_POSITION = 65800,
	U_UNMATCHED_BRACES = 65801,
	U_UNSUPPORTED_PROPERTY = 65802,
	U_UNSUPPORTED_ATTRIBUTE = 65803,
	U_ARGUMENT_TYPE_MISMATCH = 65804,
	U_DUPLICATE_KEYWORD = 65805,
	U_UNDEFINED_KEYWORD = 65806,
	U_DEFAULT_KEYWORD_MISSING = 65807,
	U_DECIMAL_NUMBER_SYNTAX_ERROR = 65808,
	U_FORMAT_INEXACT_ERROR = 65809,
	U_NUMBER_ARG_OUTOFBOUNDS_ERROR = 65810,
	U_NUMBER_SKELETON_SYNTAX_ERROR = 65811,
	U_BRK_INTERNAL_ERROR = 66048,
	U_BRK_ERROR_START = 66048,
	U_BRK_HEX_DIGITS_EXPECTED = 66049,
	U_BRK_SEMICOLON_EXPECTED = 66050,
	U_BRK_RULE_SYNTAX = 66051,
	U_BRK_UNCLOSED_SET = 66052,
	U_BRK_ASSIGN_ERROR = 66053,
	U_BRK_VARIABLE_REDFINITION = 66054,
	U_BRK_MISMATCHED_PAREN = 66055,
	U_BRK_NEW_LINE_IN_QUOTED_STRING = 66056,
	U_BRK_UNDEFINED_VARIABLE = 66057,
	U_BRK_INIT_ERROR = 66058,
	U_BRK_RULE_EMPTY_SET = 66059,
	U_BRK_UNRECOGNIZED_OPTION = 66060,
	U_BRK_MALFORMED_RULE_TAG = 66061,
	U_REGEX_INTERNAL_ERROR = 66304,
	U_REGEX_ERROR_START = 66304,
	U_REGEX_RULE_SYNTAX = 66305,
	U_REGEX_INVALID_STATE = 66306,
	U_REGEX_BAD_ESCAPE_SEQUENCE = 66307,
	U_REGEX_PROPERTY_SYNTAX = 66308,
	U_REGEX_UNIMPLEMENTED = 66309,
	U_REGEX_MISMATCHED_PAREN = 66310,
	U_REGEX_NUMBER_TOO_BIG = 66311,
	U_REGEX_BAD_INTERVAL = 66312,
	U_REGEX_MAX_LT_MIN = 66313,
	U_REGEX_INVALID_BACK_REF = 66314,
	U_REGEX_INVALID_FLAG = 66315,
	U_REGEX_LOOK_BEHIND_LIMIT = 66316,
	U_REGEX_SET_CONTAINS_STRING = 66317,
	U_REGEX_MISSING_CLOSE_BRACKET = 66319,
	U_REGEX_INVALID_RANGE = 66320,
	U_REGEX_STACK_OVERFLOW = 66321,
	U_REGEX_TIME_OUT = 66322,
	U_REGEX_STOPPED_BY_CALLER = 66323,
	U_REGEX_PATTERN_TOO_BIG = 66324,
	U_REGEX_INVALID_CAPTURE_GROUP_NAME = 66325,
	U_IDNA_PROHIBITED_ERROR = 66560,
	U_IDNA_ERROR_START = 66560,
	U_IDNA_UNASSIGNED_ERROR = 66561,
	U_IDNA_CHECK_BIDI_ERROR = 66562,
	U_IDNA_STD3_ASCII_RULES_ERROR = 66563,
	U_IDNA_ACE_PREFIX_ERROR = 66564,
	U_IDNA_VERIFICATION_ERROR = 66565,
	U_IDNA_LABEL_TOO_LONG_ERROR = 66566,
	U_IDNA_ZERO_LENGTH_LABEL_ERROR = 66567,
	U_IDNA_DOMAIN_NAME_TOO_LONG_ERROR = 66568,
	U_STRINGPREP_PROHIBITED_ERROR = 66560,
	U_STRINGPREP_UNASSIGNED_ERROR = 66561,
	U_STRINGPREP_CHECK_BIDI_ERROR = 66562,
	U_PLUGIN_ERROR_START = 66816,
	U_PLUGIN_TOO_HIGH = 66816,
	U_PLUGIN_DIDNT_SET_LEVEL = 66817,
}


[AllowDuplicates]
public enum UTraceLevel : int32
{
	UTRACE_OFF = -1,
	UTRACE_ERROR = 0,
	UTRACE_WARNING = 3,
	UTRACE_OPEN_CLOSE = 5,
	UTRACE_INFO = 7,
	UTRACE_VERBOSE = 9,
}


[AllowDuplicates]
public enum UTraceFunctionNumber : int32
{
	UTRACE_FUNCTION_START = 0,
	UTRACE_U_INIT = 0,
	UTRACE_U_CLEANUP = 1,
	UTRACE_CONVERSION_START = 4096,
	UTRACE_UCNV_OPEN = 4096,
	UTRACE_UCNV_OPEN_PACKAGE = 4097,
	UTRACE_UCNV_OPEN_ALGORITHMIC = 4098,
	UTRACE_UCNV_CLONE = 4099,
	UTRACE_UCNV_CLOSE = 4100,
	UTRACE_UCNV_FLUSH_CACHE = 4101,
	UTRACE_UCNV_LOAD = 4102,
	UTRACE_UCNV_UNLOAD = 4103,
	UTRACE_COLLATION_START = 8192,
	UTRACE_UCOL_OPEN = 8192,
	UTRACE_UCOL_CLOSE = 8193,
	UTRACE_UCOL_STRCOLL = 8194,
	UTRACE_UCOL_GET_SORTKEY = 8195,
	UTRACE_UCOL_GETLOCALE = 8196,
	UTRACE_UCOL_NEXTSORTKEYPART = 8197,
	UTRACE_UCOL_STRCOLLITER = 8198,
	UTRACE_UCOL_OPEN_FROM_SHORT_STRING = 8199,
	UTRACE_UCOL_STRCOLLUTF8 = 8200,
	UTRACE_UDATA_START = 12288,
	UTRACE_UDATA_RESOURCE = 12288,
	UTRACE_UDATA_BUNDLE = 12289,
	UTRACE_UDATA_DATA_FILE = 12290,
	UTRACE_UDATA_RES_FILE = 12291,
}


[AllowDuplicates]
public enum UStringTrieResult : int32
{
	USTRINGTRIE_NO_MATCH = 0,
	USTRINGTRIE_NO_VALUE = 1,
	USTRINGTRIE_FINAL_VALUE = 2,
	USTRINGTRIE_INTERMEDIATE_VALUE = 3,
}


[AllowDuplicates]
public enum UScriptCode : int32
{
	USCRIPT_INVALID_CODE = -1,
	USCRIPT_COMMON = 0,
	USCRIPT_INHERITED = 1,
	USCRIPT_ARABIC = 2,
	USCRIPT_ARMENIAN = 3,
	USCRIPT_BENGALI = 4,
	USCRIPT_BOPOMOFO = 5,
	USCRIPT_CHEROKEE = 6,
	USCRIPT_COPTIC = 7,
	USCRIPT_CYRILLIC = 8,
	USCRIPT_DESERET = 9,
	USCRIPT_DEVANAGARI = 10,
	USCRIPT_ETHIOPIC = 11,
	USCRIPT_GEORGIAN = 12,
	USCRIPT_GOTHIC = 13,
	USCRIPT_GREEK = 14,
	USCRIPT_GUJARATI = 15,
	USCRIPT_GURMUKHI = 16,
	USCRIPT_HAN = 17,
	USCRIPT_HANGUL = 18,
	USCRIPT_HEBREW = 19,
	USCRIPT_HIRAGANA = 20,
	USCRIPT_KANNADA = 21,
	USCRIPT_KATAKANA = 22,
	USCRIPT_KHMER = 23,
	USCRIPT_LAO = 24,
	USCRIPT_LATIN = 25,
	USCRIPT_MALAYALAM = 26,
	USCRIPT_MONGOLIAN = 27,
	USCRIPT_MYANMAR = 28,
	USCRIPT_OGHAM = 29,
	USCRIPT_OLD_ITALIC = 30,
	USCRIPT_ORIYA = 31,
	USCRIPT_RUNIC = 32,
	USCRIPT_SINHALA = 33,
	USCRIPT_SYRIAC = 34,
	USCRIPT_TAMIL = 35,
	USCRIPT_TELUGU = 36,
	USCRIPT_THAANA = 37,
	USCRIPT_THAI = 38,
	USCRIPT_TIBETAN = 39,
	USCRIPT_CANADIAN_ABORIGINAL = 40,
	USCRIPT_UCAS = 40,
	USCRIPT_YI = 41,
	USCRIPT_TAGALOG = 42,
	USCRIPT_HANUNOO = 43,
	USCRIPT_BUHID = 44,
	USCRIPT_TAGBANWA = 45,
	USCRIPT_BRAILLE = 46,
	USCRIPT_CYPRIOT = 47,
	USCRIPT_LIMBU = 48,
	USCRIPT_LINEAR_B = 49,
	USCRIPT_OSMANYA = 50,
	USCRIPT_SHAVIAN = 51,
	USCRIPT_TAI_LE = 52,
	USCRIPT_UGARITIC = 53,
	USCRIPT_KATAKANA_OR_HIRAGANA = 54,
	USCRIPT_BUGINESE = 55,
	USCRIPT_GLAGOLITIC = 56,
	USCRIPT_KHAROSHTHI = 57,
	USCRIPT_SYLOTI_NAGRI = 58,
	USCRIPT_NEW_TAI_LUE = 59,
	USCRIPT_TIFINAGH = 60,
	USCRIPT_OLD_PERSIAN = 61,
	USCRIPT_BALINESE = 62,
	USCRIPT_BATAK = 63,
	USCRIPT_BLISSYMBOLS = 64,
	USCRIPT_BRAHMI = 65,
	USCRIPT_CHAM = 66,
	USCRIPT_CIRTH = 67,
	USCRIPT_OLD_CHURCH_SLAVONIC_CYRILLIC = 68,
	USCRIPT_DEMOTIC_EGYPTIAN = 69,
	USCRIPT_HIERATIC_EGYPTIAN = 70,
	USCRIPT_EGYPTIAN_HIEROGLYPHS = 71,
	USCRIPT_KHUTSURI = 72,
	USCRIPT_SIMPLIFIED_HAN = 73,
	USCRIPT_TRADITIONAL_HAN = 74,
	USCRIPT_PAHAWH_HMONG = 75,
	USCRIPT_OLD_HUNGARIAN = 76,
	USCRIPT_HARAPPAN_INDUS = 77,
	USCRIPT_JAVANESE = 78,
	USCRIPT_KAYAH_LI = 79,
	USCRIPT_LATIN_FRAKTUR = 80,
	USCRIPT_LATIN_GAELIC = 81,
	USCRIPT_LEPCHA = 82,
	USCRIPT_LINEAR_A = 83,
	USCRIPT_MANDAIC = 84,
	USCRIPT_MANDAEAN = 84,
	USCRIPT_MAYAN_HIEROGLYPHS = 85,
	USCRIPT_MEROITIC_HIEROGLYPHS = 86,
	USCRIPT_MEROITIC = 86,
	USCRIPT_NKO = 87,
	USCRIPT_ORKHON = 88,
	USCRIPT_OLD_PERMIC = 89,
	USCRIPT_PHAGS_PA = 90,
	USCRIPT_PHOENICIAN = 91,
	USCRIPT_MIAO = 92,
	USCRIPT_PHONETIC_POLLARD = 92,
	USCRIPT_RONGORONGO = 93,
	USCRIPT_SARATI = 94,
	USCRIPT_ESTRANGELO_SYRIAC = 95,
	USCRIPT_WESTERN_SYRIAC = 96,
	USCRIPT_EASTERN_SYRIAC = 97,
	USCRIPT_TENGWAR = 98,
	USCRIPT_VAI = 99,
	USCRIPT_VISIBLE_SPEECH = 100,
	USCRIPT_CUNEIFORM = 101,
	USCRIPT_UNWRITTEN_LANGUAGES = 102,
	USCRIPT_UNKNOWN = 103,
	USCRIPT_CARIAN = 104,
	USCRIPT_JAPANESE = 105,
	USCRIPT_LANNA = 106,
	USCRIPT_LYCIAN = 107,
	USCRIPT_LYDIAN = 108,
	USCRIPT_OL_CHIKI = 109,
	USCRIPT_REJANG = 110,
	USCRIPT_SAURASHTRA = 111,
	USCRIPT_SIGN_WRITING = 112,
	USCRIPT_SUNDANESE = 113,
	USCRIPT_MOON = 114,
	USCRIPT_MEITEI_MAYEK = 115,
	USCRIPT_IMPERIAL_ARAMAIC = 116,
	USCRIPT_AVESTAN = 117,
	USCRIPT_CHAKMA = 118,
	USCRIPT_KOREAN = 119,
	USCRIPT_KAITHI = 120,
	USCRIPT_MANICHAEAN = 121,
	USCRIPT_INSCRIPTIONAL_PAHLAVI = 122,
	USCRIPT_PSALTER_PAHLAVI = 123,
	USCRIPT_BOOK_PAHLAVI = 124,
	USCRIPT_INSCRIPTIONAL_PARTHIAN = 125,
	USCRIPT_SAMARITAN = 126,
	USCRIPT_TAI_VIET = 127,
	USCRIPT_MATHEMATICAL_NOTATION = 128,
	USCRIPT_SYMBOLS = 129,
	USCRIPT_BAMUM = 130,
	USCRIPT_LISU = 131,
	USCRIPT_NAKHI_GEBA = 132,
	USCRIPT_OLD_SOUTH_ARABIAN = 133,
	USCRIPT_BASSA_VAH = 134,
	USCRIPT_DUPLOYAN = 135,
	USCRIPT_ELBASAN = 136,
	USCRIPT_GRANTHA = 137,
	USCRIPT_KPELLE = 138,
	USCRIPT_LOMA = 139,
	USCRIPT_MENDE = 140,
	USCRIPT_MEROITIC_CURSIVE = 141,
	USCRIPT_OLD_NORTH_ARABIAN = 142,
	USCRIPT_NABATAEAN = 143,
	USCRIPT_PALMYRENE = 144,
	USCRIPT_KHUDAWADI = 145,
	USCRIPT_SINDHI = 145,
	USCRIPT_WARANG_CITI = 146,
	USCRIPT_AFAKA = 147,
	USCRIPT_JURCHEN = 148,
	USCRIPT_MRO = 149,
	USCRIPT_NUSHU = 150,
	USCRIPT_SHARADA = 151,
	USCRIPT_SORA_SOMPENG = 152,
	USCRIPT_TAKRI = 153,
	USCRIPT_TANGUT = 154,
	USCRIPT_WOLEAI = 155,
	USCRIPT_ANATOLIAN_HIEROGLYPHS = 156,
	USCRIPT_KHOJKI = 157,
	USCRIPT_TIRHUTA = 158,
	USCRIPT_CAUCASIAN_ALBANIAN = 159,
	USCRIPT_MAHAJANI = 160,
	USCRIPT_AHOM = 161,
	USCRIPT_HATRAN = 162,
	USCRIPT_MODI = 163,
	USCRIPT_MULTANI = 164,
	USCRIPT_PAU_CIN_HAU = 165,
	USCRIPT_SIDDHAM = 166,
	USCRIPT_ADLAM = 167,
	USCRIPT_BHAIKSUKI = 168,
	USCRIPT_MARCHEN = 169,
	USCRIPT_NEWA = 170,
	USCRIPT_OSAGE = 171,
	USCRIPT_HAN_WITH_BOPOMOFO = 172,
	USCRIPT_JAMO = 173,
	USCRIPT_SYMBOLS_EMOJI = 174,
	USCRIPT_MASARAM_GONDI = 175,
	USCRIPT_SOYOMBO = 176,
	USCRIPT_ZANABAZAR_SQUARE = 177,
	USCRIPT_DOGRA = 178,
	USCRIPT_GUNJALA_GONDI = 179,
	USCRIPT_MAKASAR = 180,
	USCRIPT_MEDEFAIDRIN = 181,
	USCRIPT_HANIFI_ROHINGYA = 182,
	USCRIPT_SOGDIAN = 183,
	USCRIPT_OLD_SOGDIAN = 184,
	USCRIPT_ELYMAIC = 185,
	USCRIPT_NYIAKENG_PUACHUE_HMONG = 186,
	USCRIPT_NANDINAGARI = 187,
	USCRIPT_WANCHO = 188,
	USCRIPT_CHORASMIAN = 189,
	USCRIPT_DIVES_AKURU = 190,
	USCRIPT_KHITAN_SMALL_SCRIPT = 191,
	USCRIPT_YEZIDI = 192,
}


[AllowDuplicates]
public enum UScriptUsage : int32
{
	USCRIPT_USAGE_NOT_ENCODED = 0,
	USCRIPT_USAGE_UNKNOWN = 1,
	USCRIPT_USAGE_EXCLUDED = 2,
	USCRIPT_USAGE_LIMITED_USE = 3,
	USCRIPT_USAGE_ASPIRATIONAL = 4,
	USCRIPT_USAGE_RECOMMENDED = 5,
}


[AllowDuplicates]
public enum UCharIteratorOrigin : int32
{
	UITER_START = 0,
	UITER_CURRENT = 1,
	UITER_LIMIT = 2,
	UITER_ZERO = 3,
	UITER_LENGTH = 4,
}


[AllowDuplicates]
public enum ULocDataLocaleType : int32
{
	ULOC_ACTUAL_LOCALE = 0,
	ULOC_VALID_LOCALE = 1,
}


[AllowDuplicates]
public enum ULocAvailableType : int32
{
	ULOC_AVAILABLE_DEFAULT = 0,
	ULOC_AVAILABLE_ONLY_LEGACY_ALIASES = 1,
	ULOC_AVAILABLE_WITH_LEGACY_ALIASES = 2,
}


[AllowDuplicates]
public enum ULayoutType : int32
{
	ULOC_LAYOUT_LTR = 0,
	ULOC_LAYOUT_RTL = 1,
	ULOC_LAYOUT_TTB = 2,
	ULOC_LAYOUT_BTT = 3,
	ULOC_LAYOUT_UNKNOWN = 4,
}


[AllowDuplicates]
public enum UAcceptResult : int32
{
	ULOC_ACCEPT_FAILED = 0,
	ULOC_ACCEPT_VALID = 1,
	ULOC_ACCEPT_FALLBACK = 2,
}


[AllowDuplicates]
public enum UResType : int32
{
	URES_NONE = -1,
	URES_STRING = 0,
	URES_BINARY = 1,
	URES_TABLE = 2,
	URES_ALIAS = 3,
	URES_INT = 7,
	URES_ARRAY = 8,
	URES_INT_VECTOR = 14,
}


[AllowDuplicates]
public enum UDisplayContextType : int32
{
	UDISPCTX_TYPE_DIALECT_HANDLING = 0,
	UDISPCTX_TYPE_CAPITALIZATION = 1,
	UDISPCTX_TYPE_DISPLAY_LENGTH = 2,
	UDISPCTX_TYPE_SUBSTITUTE_HANDLING = 3,
}


[AllowDuplicates]
public enum UDisplayContext : int32
{
	UDISPCTX_STANDARD_NAMES = 0,
	UDISPCTX_DIALECT_NAMES = 1,
	UDISPCTX_CAPITALIZATION_NONE = 256,
	UDISPCTX_CAPITALIZATION_FOR_MIDDLE_OF_SENTENCE = 257,
	UDISPCTX_CAPITALIZATION_FOR_BEGINNING_OF_SENTENCE = 258,
	UDISPCTX_CAPITALIZATION_FOR_UI_LIST_OR_MENU = 259,
	UDISPCTX_CAPITALIZATION_FOR_STANDALONE = 260,
	UDISPCTX_LENGTH_FULL = 512,
	UDISPCTX_LENGTH_SHORT = 513,
	UDISPCTX_SUBSTITUTE = 768,
	UDISPCTX_NO_SUBSTITUTE = 769,
}


[AllowDuplicates]
public enum UDialectHandling : int32
{
	ULDN_STANDARD_NAMES = 0,
	ULDN_DIALECT_NAMES = 1,
}


[AllowDuplicates]
public enum UCurrencyUsage : int32
{
	UCURR_USAGE_STANDARD = 0,
	UCURR_USAGE_CASH = 1,
}


[AllowDuplicates]
public enum UCurrNameStyle : int32
{
	UCURR_SYMBOL_NAME = 0,
	UCURR_LONG_NAME = 1,
	UCURR_NARROW_SYMBOL_NAME = 2,
}


[AllowDuplicates]
public enum UCurrCurrencyType : int32
{
	UCURR_ALL = 2147483647,
	UCURR_COMMON = 1,
	UCURR_UNCOMMON = 2,
	UCURR_DEPRECATED = 4,
	UCURR_NON_DEPRECATED = 8,
}


[AllowDuplicates]
public enum UCPMapRangeOption : int32
{
	UCPMAP_RANGE_NORMAL = 0,
	UCPMAP_RANGE_FIXED_LEAD_SURROGATES = 1,
	UCPMAP_RANGE_FIXED_ALL_SURROGATES = 2,
}


[AllowDuplicates]
public enum UCPTrieType : int32
{
	UCPTRIE_TYPE_ANY = -1,
	UCPTRIE_TYPE_FAST = 0,
	UCPTRIE_TYPE_SMALL = 1,
}


[AllowDuplicates]
public enum UCPTrieValueWidth : int32
{
	UCPTRIE_VALUE_BITS_ANY = -1,
	UCPTRIE_VALUE_BITS_16 = 0,
	UCPTRIE_VALUE_BITS_32 = 1,
	UCPTRIE_VALUE_BITS_8 = 2,
}


[AllowDuplicates]
public enum UConverterCallbackReason : int32
{
	UCNV_UNASSIGNED = 0,
	UCNV_ILLEGAL = 1,
	UCNV_IRREGULAR = 2,
	UCNV_RESET = 3,
	UCNV_CLOSE = 4,
	UCNV_CLONE = 5,
}


[AllowDuplicates]
public enum UConverterType : int32
{
	UCNV_UNSUPPORTED_CONVERTER = -1,
	UCNV_SBCS = 0,
	UCNV_DBCS = 1,
	UCNV_MBCS = 2,
	UCNV_LATIN_1 = 3,
	UCNV_UTF8 = 4,
	UCNV_UTF16_BigEndian = 5,
	UCNV_UTF16_LittleEndian = 6,
	UCNV_UTF32_BigEndian = 7,
	UCNV_UTF32_LittleEndian = 8,
	UCNV_EBCDIC_STATEFUL = 9,
	UCNV_ISO_2022 = 10,
	UCNV_LMBCS_1 = 11,
	UCNV_LMBCS_2 = 12,
	UCNV_LMBCS_3 = 13,
	UCNV_LMBCS_4 = 14,
	UCNV_LMBCS_5 = 15,
	UCNV_LMBCS_6 = 16,
	UCNV_LMBCS_8 = 17,
	UCNV_LMBCS_11 = 18,
	UCNV_LMBCS_16 = 19,
	UCNV_LMBCS_17 = 20,
	UCNV_LMBCS_18 = 21,
	UCNV_LMBCS_19 = 22,
	UCNV_LMBCS_LAST = 22,
	UCNV_HZ = 23,
	UCNV_SCSU = 24,
	UCNV_ISCII = 25,
	UCNV_US_ASCII = 26,
	UCNV_UTF7 = 27,
	UCNV_BOCU1 = 28,
	UCNV_UTF16 = 29,
	UCNV_UTF32 = 30,
	UCNV_CESU8 = 31,
	UCNV_IMAP_MAILBOX = 32,
	UCNV_COMPOUND_TEXT = 33,
	UCNV_NUMBER_OF_SUPPORTED_CONVERTER_TYPES = 34,
}


[AllowDuplicates]
public enum UConverterPlatform : int32
{
	UCNV_UNKNOWN = -1,
	UCNV_IBM = 0,
}


[AllowDuplicates]
public enum UConverterUnicodeSet : int32
{
	UCNV_ROUNDTRIP_SET = 0,
	UCNV_ROUNDTRIP_AND_FALLBACK_SET = 1,
}


[AllowDuplicates]
public enum UProperty : int32
{
	UCHAR_ALPHABETIC = 0,
	UCHAR_BINARY_START = 0,
	UCHAR_ASCII_HEX_DIGIT = 1,
	UCHAR_BIDI_CONTROL = 2,
	UCHAR_BIDI_MIRRORED = 3,
	UCHAR_DASH = 4,
	UCHAR_DEFAULT_IGNORABLE_CODE_POINT = 5,
	UCHAR_DEPRECATED = 6,
	UCHAR_DIACRITIC = 7,
	UCHAR_EXTENDER = 8,
	UCHAR_FULL_COMPOSITION_EXCLUSION = 9,
	UCHAR_GRAPHEME_BASE = 10,
	UCHAR_GRAPHEME_EXTEND = 11,
	UCHAR_GRAPHEME_LINK = 12,
	UCHAR_HEX_DIGIT = 13,
	UCHAR_HYPHEN = 14,
	UCHAR_ID_CONTINUE = 15,
	UCHAR_ID_START = 16,
	UCHAR_IDEOGRAPHIC = 17,
	UCHAR_IDS_BINARY_OPERATOR = 18,
	UCHAR_IDS_TRINARY_OPERATOR = 19,
	UCHAR_JOIN_CONTROL = 20,
	UCHAR_LOGICAL_ORDER_EXCEPTION = 21,
	UCHAR_LOWERCASE = 22,
	UCHAR_MATH = 23,
	UCHAR_NONCHARACTER_CODE_POINT = 24,
	UCHAR_QUOTATION_MARK = 25,
	UCHAR_RADICAL = 26,
	UCHAR_SOFT_DOTTED = 27,
	UCHAR_TERMINAL_PUNCTUATION = 28,
	UCHAR_UNIFIED_IDEOGRAPH = 29,
	UCHAR_UPPERCASE = 30,
	UCHAR_WHITE_SPACE = 31,
	UCHAR_XID_CONTINUE = 32,
	UCHAR_XID_START = 33,
	UCHAR_CASE_SENSITIVE = 34,
	UCHAR_S_TERM = 35,
	UCHAR_VARIATION_SELECTOR = 36,
	UCHAR_NFD_INERT = 37,
	UCHAR_NFKD_INERT = 38,
	UCHAR_NFC_INERT = 39,
	UCHAR_NFKC_INERT = 40,
	UCHAR_SEGMENT_STARTER = 41,
	UCHAR_PATTERN_SYNTAX = 42,
	UCHAR_PATTERN_WHITE_SPACE = 43,
	UCHAR_POSIX_ALNUM = 44,
	UCHAR_POSIX_BLANK = 45,
	UCHAR_POSIX_GRAPH = 46,
	UCHAR_POSIX_PRINT = 47,
	UCHAR_POSIX_XDIGIT = 48,
	UCHAR_CASED = 49,
	UCHAR_CASE_IGNORABLE = 50,
	UCHAR_CHANGES_WHEN_LOWERCASED = 51,
	UCHAR_CHANGES_WHEN_UPPERCASED = 52,
	UCHAR_CHANGES_WHEN_TITLECASED = 53,
	UCHAR_CHANGES_WHEN_CASEFOLDED = 54,
	UCHAR_CHANGES_WHEN_CASEMAPPED = 55,
	UCHAR_CHANGES_WHEN_NFKC_CASEFOLDED = 56,
	UCHAR_EMOJI = 57,
	UCHAR_EMOJI_PRESENTATION = 58,
	UCHAR_EMOJI_MODIFIER = 59,
	UCHAR_EMOJI_MODIFIER_BASE = 60,
	UCHAR_EMOJI_COMPONENT = 61,
	UCHAR_REGIONAL_INDICATOR = 62,
	UCHAR_PREPENDED_CONCATENATION_MARK = 63,
	UCHAR_EXTENDED_PICTOGRAPHIC = 64,
	UCHAR_BIDI_CLASS = 4096,
	UCHAR_INT_START = 4096,
	UCHAR_BLOCK = 4097,
	UCHAR_CANONICAL_COMBINING_CLASS = 4098,
	UCHAR_DECOMPOSITION_TYPE = 4099,
	UCHAR_EAST_ASIAN_WIDTH = 4100,
	UCHAR_GENERAL_CATEGORY = 4101,
	UCHAR_JOINING_GROUP = 4102,
	UCHAR_JOINING_TYPE = 4103,
	UCHAR_LINE_BREAK = 4104,
	UCHAR_NUMERIC_TYPE = 4105,
	UCHAR_SCRIPT = 4106,
	UCHAR_HANGUL_SYLLABLE_TYPE = 4107,
	UCHAR_NFD_QUICK_CHECK = 4108,
	UCHAR_NFKD_QUICK_CHECK = 4109,
	UCHAR_NFC_QUICK_CHECK = 4110,
	UCHAR_NFKC_QUICK_CHECK = 4111,
	UCHAR_LEAD_CANONICAL_COMBINING_CLASS = 4112,
	UCHAR_TRAIL_CANONICAL_COMBINING_CLASS = 4113,
	UCHAR_GRAPHEME_CLUSTER_BREAK = 4114,
	UCHAR_SENTENCE_BREAK = 4115,
	UCHAR_WORD_BREAK = 4116,
	UCHAR_BIDI_PAIRED_BRACKET_TYPE = 4117,
	UCHAR_INDIC_POSITIONAL_CATEGORY = 4118,
	UCHAR_INDIC_SYLLABIC_CATEGORY = 4119,
	UCHAR_VERTICAL_ORIENTATION = 4120,
	UCHAR_GENERAL_CATEGORY_MASK = 8192,
	UCHAR_MASK_START = 8192,
	UCHAR_NUMERIC_VALUE = 12288,
	UCHAR_DOUBLE_START = 12288,
	UCHAR_AGE = 16384,
	UCHAR_STRING_START = 16384,
	UCHAR_BIDI_MIRRORING_GLYPH = 16385,
	UCHAR_CASE_FOLDING = 16386,
	UCHAR_LOWERCASE_MAPPING = 16388,
	UCHAR_NAME = 16389,
	UCHAR_SIMPLE_CASE_FOLDING = 16390,
	UCHAR_SIMPLE_LOWERCASE_MAPPING = 16391,
	UCHAR_SIMPLE_TITLECASE_MAPPING = 16392,
	UCHAR_SIMPLE_UPPERCASE_MAPPING = 16393,
	UCHAR_TITLECASE_MAPPING = 16394,
	UCHAR_UPPERCASE_MAPPING = 16396,
	UCHAR_BIDI_PAIRED_BRACKET = 16397,
	UCHAR_SCRIPT_EXTENSIONS = 28672,
	UCHAR_OTHER_PROPERTY_START = 28672,
	UCHAR_INVALID_CODE = -1,
}


[AllowDuplicates]
public enum UCharCategory : int32
{
	U_UNASSIGNED = 0,
	U_GENERAL_OTHER_TYPES = 0,
	U_UPPERCASE_LETTER = 1,
	U_LOWERCASE_LETTER = 2,
	U_TITLECASE_LETTER = 3,
	U_MODIFIER_LETTER = 4,
	U_OTHER_LETTER = 5,
	U_NON_SPACING_MARK = 6,
	U_ENCLOSING_MARK = 7,
	U_COMBINING_SPACING_MARK = 8,
	U_DECIMAL_DIGIT_NUMBER = 9,
	U_LETTER_NUMBER = 10,
	U_OTHER_NUMBER = 11,
	U_SPACE_SEPARATOR = 12,
	U_LINE_SEPARATOR = 13,
	U_PARAGRAPH_SEPARATOR = 14,
	U_CONTROL_CHAR = 15,
	U_FORMAT_CHAR = 16,
	U_PRIVATE_USE_CHAR = 17,
	U_SURROGATE = 18,
	U_DASH_PUNCTUATION = 19,
	U_START_PUNCTUATION = 20,
	U_END_PUNCTUATION = 21,
	U_CONNECTOR_PUNCTUATION = 22,
	U_OTHER_PUNCTUATION = 23,
	U_MATH_SYMBOL = 24,
	U_CURRENCY_SYMBOL = 25,
	U_MODIFIER_SYMBOL = 26,
	U_OTHER_SYMBOL = 27,
	U_INITIAL_PUNCTUATION = 28,
	U_FINAL_PUNCTUATION = 29,
	U_CHAR_CATEGORY_COUNT = 30,
}


[AllowDuplicates]
public enum UCharDirection : int32
{
	U_LEFT_TO_RIGHT = 0,
	U_RIGHT_TO_LEFT = 1,
	U_EUROPEAN_NUMBER = 2,
	U_EUROPEAN_NUMBER_SEPARATOR = 3,
	U_EUROPEAN_NUMBER_TERMINATOR = 4,
	U_ARABIC_NUMBER = 5,
	U_COMMON_NUMBER_SEPARATOR = 6,
	U_BLOCK_SEPARATOR = 7,
	U_SEGMENT_SEPARATOR = 8,
	U_WHITE_SPACE_NEUTRAL = 9,
	U_OTHER_NEUTRAL = 10,
	U_LEFT_TO_RIGHT_EMBEDDING = 11,
	U_LEFT_TO_RIGHT_OVERRIDE = 12,
	U_RIGHT_TO_LEFT_ARABIC = 13,
	U_RIGHT_TO_LEFT_EMBEDDING = 14,
	U_RIGHT_TO_LEFT_OVERRIDE = 15,
	U_POP_DIRECTIONAL_FORMAT = 16,
	U_DIR_NON_SPACING_MARK = 17,
	U_BOUNDARY_NEUTRAL = 18,
	U_FIRST_STRONG_ISOLATE = 19,
	U_LEFT_TO_RIGHT_ISOLATE = 20,
	U_RIGHT_TO_LEFT_ISOLATE = 21,
	U_POP_DIRECTIONAL_ISOLATE = 22,
}


[AllowDuplicates]
public enum UBidiPairedBracketType : int32
{
	U_BPT_NONE = 0,
	U_BPT_OPEN = 1,
	U_BPT_CLOSE = 2,
}


[AllowDuplicates]
public enum UBlockCode : int32
{
	UBLOCK_NO_BLOCK = 0,
	UBLOCK_BASIC_LATIN = 1,
	UBLOCK_LATIN_1_SUPPLEMENT = 2,
	UBLOCK_LATIN_EXTENDED_A = 3,
	UBLOCK_LATIN_EXTENDED_B = 4,
	UBLOCK_IPA_EXTENSIONS = 5,
	UBLOCK_SPACING_MODIFIER_LETTERS = 6,
	UBLOCK_COMBINING_DIACRITICAL_MARKS = 7,
	UBLOCK_GREEK = 8,
	UBLOCK_CYRILLIC = 9,
	UBLOCK_ARMENIAN = 10,
	UBLOCK_HEBREW = 11,
	UBLOCK_ARABIC = 12,
	UBLOCK_SYRIAC = 13,
	UBLOCK_THAANA = 14,
	UBLOCK_DEVANAGARI = 15,
	UBLOCK_BENGALI = 16,
	UBLOCK_GURMUKHI = 17,
	UBLOCK_GUJARATI = 18,
	UBLOCK_ORIYA = 19,
	UBLOCK_TAMIL = 20,
	UBLOCK_TELUGU = 21,
	UBLOCK_KANNADA = 22,
	UBLOCK_MALAYALAM = 23,
	UBLOCK_SINHALA = 24,
	UBLOCK_THAI = 25,
	UBLOCK_LAO = 26,
	UBLOCK_TIBETAN = 27,
	UBLOCK_MYANMAR = 28,
	UBLOCK_GEORGIAN = 29,
	UBLOCK_HANGUL_JAMO = 30,
	UBLOCK_ETHIOPIC = 31,
	UBLOCK_CHEROKEE = 32,
	UBLOCK_UNIFIED_CANADIAN_ABORIGINAL_SYLLABICS = 33,
	UBLOCK_OGHAM = 34,
	UBLOCK_RUNIC = 35,
	UBLOCK_KHMER = 36,
	UBLOCK_MONGOLIAN = 37,
	UBLOCK_LATIN_EXTENDED_ADDITIONAL = 38,
	UBLOCK_GREEK_EXTENDED = 39,
	UBLOCK_GENERAL_PUNCTUATION = 40,
	UBLOCK_SUPERSCRIPTS_AND_SUBSCRIPTS = 41,
	UBLOCK_CURRENCY_SYMBOLS = 42,
	UBLOCK_COMBINING_MARKS_FOR_SYMBOLS = 43,
	UBLOCK_LETTERLIKE_SYMBOLS = 44,
	UBLOCK_NUMBER_FORMS = 45,
	UBLOCK_ARROWS = 46,
	UBLOCK_MATHEMATICAL_OPERATORS = 47,
	UBLOCK_MISCELLANEOUS_TECHNICAL = 48,
	UBLOCK_CONTROL_PICTURES = 49,
	UBLOCK_OPTICAL_CHARACTER_RECOGNITION = 50,
	UBLOCK_ENCLOSED_ALPHANUMERICS = 51,
	UBLOCK_BOX_DRAWING = 52,
	UBLOCK_BLOCK_ELEMENTS = 53,
	UBLOCK_GEOMETRIC_SHAPES = 54,
	UBLOCK_MISCELLANEOUS_SYMBOLS = 55,
	UBLOCK_DINGBATS = 56,
	UBLOCK_BRAILLE_PATTERNS = 57,
	UBLOCK_CJK_RADICALS_SUPPLEMENT = 58,
	UBLOCK_KANGXI_RADICALS = 59,
	UBLOCK_IDEOGRAPHIC_DESCRIPTION_CHARACTERS = 60,
	UBLOCK_CJK_SYMBOLS_AND_PUNCTUATION = 61,
	UBLOCK_HIRAGANA = 62,
	UBLOCK_KATAKANA = 63,
	UBLOCK_BOPOMOFO = 64,
	UBLOCK_HANGUL_COMPATIBILITY_JAMO = 65,
	UBLOCK_KANBUN = 66,
	UBLOCK_BOPOMOFO_EXTENDED = 67,
	UBLOCK_ENCLOSED_CJK_LETTERS_AND_MONTHS = 68,
	UBLOCK_CJK_COMPATIBILITY = 69,
	UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_A = 70,
	UBLOCK_CJK_UNIFIED_IDEOGRAPHS = 71,
	UBLOCK_YI_SYLLABLES = 72,
	UBLOCK_YI_RADICALS = 73,
	UBLOCK_HANGUL_SYLLABLES = 74,
	UBLOCK_HIGH_SURROGATES = 75,
	UBLOCK_HIGH_PRIVATE_USE_SURROGATES = 76,
	UBLOCK_LOW_SURROGATES = 77,
	UBLOCK_PRIVATE_USE_AREA = 78,
	UBLOCK_PRIVATE_USE = 78,
	UBLOCK_CJK_COMPATIBILITY_IDEOGRAPHS = 79,
	UBLOCK_ALPHABETIC_PRESENTATION_FORMS = 80,
	UBLOCK_ARABIC_PRESENTATION_FORMS_A = 81,
	UBLOCK_COMBINING_HALF_MARKS = 82,
	UBLOCK_CJK_COMPATIBILITY_FORMS = 83,
	UBLOCK_SMALL_FORM_VARIANTS = 84,
	UBLOCK_ARABIC_PRESENTATION_FORMS_B = 85,
	UBLOCK_SPECIALS = 86,
	UBLOCK_HALFWIDTH_AND_FULLWIDTH_FORMS = 87,
	UBLOCK_OLD_ITALIC = 88,
	UBLOCK_GOTHIC = 89,
	UBLOCK_DESERET = 90,
	UBLOCK_BYZANTINE_MUSICAL_SYMBOLS = 91,
	UBLOCK_MUSICAL_SYMBOLS = 92,
	UBLOCK_MATHEMATICAL_ALPHANUMERIC_SYMBOLS = 93,
	UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_B = 94,
	UBLOCK_CJK_COMPATIBILITY_IDEOGRAPHS_SUPPLEMENT = 95,
	UBLOCK_TAGS = 96,
	UBLOCK_CYRILLIC_SUPPLEMENT = 97,
	UBLOCK_CYRILLIC_SUPPLEMENTARY = 97,
	UBLOCK_TAGALOG = 98,
	UBLOCK_HANUNOO = 99,
	UBLOCK_BUHID = 100,
	UBLOCK_TAGBANWA = 101,
	UBLOCK_MISCELLANEOUS_MATHEMATICAL_SYMBOLS_A = 102,
	UBLOCK_SUPPLEMENTAL_ARROWS_A = 103,
	UBLOCK_SUPPLEMENTAL_ARROWS_B = 104,
	UBLOCK_MISCELLANEOUS_MATHEMATICAL_SYMBOLS_B = 105,
	UBLOCK_SUPPLEMENTAL_MATHEMATICAL_OPERATORS = 106,
	UBLOCK_KATAKANA_PHONETIC_EXTENSIONS = 107,
	UBLOCK_VARIATION_SELECTORS = 108,
	UBLOCK_SUPPLEMENTARY_PRIVATE_USE_AREA_A = 109,
	UBLOCK_SUPPLEMENTARY_PRIVATE_USE_AREA_B = 110,
	UBLOCK_LIMBU = 111,
	UBLOCK_TAI_LE = 112,
	UBLOCK_KHMER_SYMBOLS = 113,
	UBLOCK_PHONETIC_EXTENSIONS = 114,
	UBLOCK_MISCELLANEOUS_SYMBOLS_AND_ARROWS = 115,
	UBLOCK_YIJING_HEXAGRAM_SYMBOLS = 116,
	UBLOCK_LINEAR_B_SYLLABARY = 117,
	UBLOCK_LINEAR_B_IDEOGRAMS = 118,
	UBLOCK_AEGEAN_NUMBERS = 119,
	UBLOCK_UGARITIC = 120,
	UBLOCK_SHAVIAN = 121,
	UBLOCK_OSMANYA = 122,
	UBLOCK_CYPRIOT_SYLLABARY = 123,
	UBLOCK_TAI_XUAN_JING_SYMBOLS = 124,
	UBLOCK_VARIATION_SELECTORS_SUPPLEMENT = 125,
	UBLOCK_ANCIENT_GREEK_MUSICAL_NOTATION = 126,
	UBLOCK_ANCIENT_GREEK_NUMBERS = 127,
	UBLOCK_ARABIC_SUPPLEMENT = 128,
	UBLOCK_BUGINESE = 129,
	UBLOCK_CJK_STROKES = 130,
	UBLOCK_COMBINING_DIACRITICAL_MARKS_SUPPLEMENT = 131,
	UBLOCK_COPTIC = 132,
	UBLOCK_ETHIOPIC_EXTENDED = 133,
	UBLOCK_ETHIOPIC_SUPPLEMENT = 134,
	UBLOCK_GEORGIAN_SUPPLEMENT = 135,
	UBLOCK_GLAGOLITIC = 136,
	UBLOCK_KHAROSHTHI = 137,
	UBLOCK_MODIFIER_TONE_LETTERS = 138,
	UBLOCK_NEW_TAI_LUE = 139,
	UBLOCK_OLD_PERSIAN = 140,
	UBLOCK_PHONETIC_EXTENSIONS_SUPPLEMENT = 141,
	UBLOCK_SUPPLEMENTAL_PUNCTUATION = 142,
	UBLOCK_SYLOTI_NAGRI = 143,
	UBLOCK_TIFINAGH = 144,
	UBLOCK_VERTICAL_FORMS = 145,
	UBLOCK_NKO = 146,
	UBLOCK_BALINESE = 147,
	UBLOCK_LATIN_EXTENDED_C = 148,
	UBLOCK_LATIN_EXTENDED_D = 149,
	UBLOCK_PHAGS_PA = 150,
	UBLOCK_PHOENICIAN = 151,
	UBLOCK_CUNEIFORM = 152,
	UBLOCK_CUNEIFORM_NUMBERS_AND_PUNCTUATION = 153,
	UBLOCK_COUNTING_ROD_NUMERALS = 154,
	UBLOCK_SUNDANESE = 155,
	UBLOCK_LEPCHA = 156,
	UBLOCK_OL_CHIKI = 157,
	UBLOCK_CYRILLIC_EXTENDED_A = 158,
	UBLOCK_VAI = 159,
	UBLOCK_CYRILLIC_EXTENDED_B = 160,
	UBLOCK_SAURASHTRA = 161,
	UBLOCK_KAYAH_LI = 162,
	UBLOCK_REJANG = 163,
	UBLOCK_CHAM = 164,
	UBLOCK_ANCIENT_SYMBOLS = 165,
	UBLOCK_PHAISTOS_DISC = 166,
	UBLOCK_LYCIAN = 167,
	UBLOCK_CARIAN = 168,
	UBLOCK_LYDIAN = 169,
	UBLOCK_MAHJONG_TILES = 170,
	UBLOCK_DOMINO_TILES = 171,
	UBLOCK_SAMARITAN = 172,
	UBLOCK_UNIFIED_CANADIAN_ABORIGINAL_SYLLABICS_EXTENDED = 173,
	UBLOCK_TAI_THAM = 174,
	UBLOCK_VEDIC_EXTENSIONS = 175,
	UBLOCK_LISU = 176,
	UBLOCK_BAMUM = 177,
	UBLOCK_COMMON_INDIC_NUMBER_FORMS = 178,
	UBLOCK_DEVANAGARI_EXTENDED = 179,
	UBLOCK_HANGUL_JAMO_EXTENDED_A = 180,
	UBLOCK_JAVANESE = 181,
	UBLOCK_MYANMAR_EXTENDED_A = 182,
	UBLOCK_TAI_VIET = 183,
	UBLOCK_MEETEI_MAYEK = 184,
	UBLOCK_HANGUL_JAMO_EXTENDED_B = 185,
	UBLOCK_IMPERIAL_ARAMAIC = 186,
	UBLOCK_OLD_SOUTH_ARABIAN = 187,
	UBLOCK_AVESTAN = 188,
	UBLOCK_INSCRIPTIONAL_PARTHIAN = 189,
	UBLOCK_INSCRIPTIONAL_PAHLAVI = 190,
	UBLOCK_OLD_TURKIC = 191,
	UBLOCK_RUMI_NUMERAL_SYMBOLS = 192,
	UBLOCK_KAITHI = 193,
	UBLOCK_EGYPTIAN_HIEROGLYPHS = 194,
	UBLOCK_ENCLOSED_ALPHANUMERIC_SUPPLEMENT = 195,
	UBLOCK_ENCLOSED_IDEOGRAPHIC_SUPPLEMENT = 196,
	UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_C = 197,
	UBLOCK_MANDAIC = 198,
	UBLOCK_BATAK = 199,
	UBLOCK_ETHIOPIC_EXTENDED_A = 200,
	UBLOCK_BRAHMI = 201,
	UBLOCK_BAMUM_SUPPLEMENT = 202,
	UBLOCK_KANA_SUPPLEMENT = 203,
	UBLOCK_PLAYING_CARDS = 204,
	UBLOCK_MISCELLANEOUS_SYMBOLS_AND_PICTOGRAPHS = 205,
	UBLOCK_EMOTICONS = 206,
	UBLOCK_TRANSPORT_AND_MAP_SYMBOLS = 207,
	UBLOCK_ALCHEMICAL_SYMBOLS = 208,
	UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_D = 209,
	UBLOCK_ARABIC_EXTENDED_A = 210,
	UBLOCK_ARABIC_MATHEMATICAL_ALPHABETIC_SYMBOLS = 211,
	UBLOCK_CHAKMA = 212,
	UBLOCK_MEETEI_MAYEK_EXTENSIONS = 213,
	UBLOCK_MEROITIC_CURSIVE = 214,
	UBLOCK_MEROITIC_HIEROGLYPHS = 215,
	UBLOCK_MIAO = 216,
	UBLOCK_SHARADA = 217,
	UBLOCK_SORA_SOMPENG = 218,
	UBLOCK_SUNDANESE_SUPPLEMENT = 219,
	UBLOCK_TAKRI = 220,
	UBLOCK_BASSA_VAH = 221,
	UBLOCK_CAUCASIAN_ALBANIAN = 222,
	UBLOCK_COPTIC_EPACT_NUMBERS = 223,
	UBLOCK_COMBINING_DIACRITICAL_MARKS_EXTENDED = 224,
	UBLOCK_DUPLOYAN = 225,
	UBLOCK_ELBASAN = 226,
	UBLOCK_GEOMETRIC_SHAPES_EXTENDED = 227,
	UBLOCK_GRANTHA = 228,
	UBLOCK_KHOJKI = 229,
	UBLOCK_KHUDAWADI = 230,
	UBLOCK_LATIN_EXTENDED_E = 231,
	UBLOCK_LINEAR_A = 232,
	UBLOCK_MAHAJANI = 233,
	UBLOCK_MANICHAEAN = 234,
	UBLOCK_MENDE_KIKAKUI = 235,
	UBLOCK_MODI = 236,
	UBLOCK_MRO = 237,
	UBLOCK_MYANMAR_EXTENDED_B = 238,
	UBLOCK_NABATAEAN = 239,
	UBLOCK_OLD_NORTH_ARABIAN = 240,
	UBLOCK_OLD_PERMIC = 241,
	UBLOCK_ORNAMENTAL_DINGBATS = 242,
	UBLOCK_PAHAWH_HMONG = 243,
	UBLOCK_PALMYRENE = 244,
	UBLOCK_PAU_CIN_HAU = 245,
	UBLOCK_PSALTER_PAHLAVI = 246,
	UBLOCK_SHORTHAND_FORMAT_CONTROLS = 247,
	UBLOCK_SIDDHAM = 248,
	UBLOCK_SINHALA_ARCHAIC_NUMBERS = 249,
	UBLOCK_SUPPLEMENTAL_ARROWS_C = 250,
	UBLOCK_TIRHUTA = 251,
	UBLOCK_WARANG_CITI = 252,
	UBLOCK_AHOM = 253,
	UBLOCK_ANATOLIAN_HIEROGLYPHS = 254,
	UBLOCK_CHEROKEE_SUPPLEMENT = 255,
	UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_E = 256,
	UBLOCK_EARLY_DYNASTIC_CUNEIFORM = 257,
	UBLOCK_HATRAN = 258,
	UBLOCK_MULTANI = 259,
	UBLOCK_OLD_HUNGARIAN = 260,
	UBLOCK_SUPPLEMENTAL_SYMBOLS_AND_PICTOGRAPHS = 261,
	UBLOCK_SUTTON_SIGNWRITING = 262,
	UBLOCK_ADLAM = 263,
	UBLOCK_BHAIKSUKI = 264,
	UBLOCK_CYRILLIC_EXTENDED_C = 265,
	UBLOCK_GLAGOLITIC_SUPPLEMENT = 266,
	UBLOCK_IDEOGRAPHIC_SYMBOLS_AND_PUNCTUATION = 267,
	UBLOCK_MARCHEN = 268,
	UBLOCK_MONGOLIAN_SUPPLEMENT = 269,
	UBLOCK_NEWA = 270,
	UBLOCK_OSAGE = 271,
	UBLOCK_TANGUT = 272,
	UBLOCK_TANGUT_COMPONENTS = 273,
	UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_F = 274,
	UBLOCK_KANA_EXTENDED_A = 275,
	UBLOCK_MASARAM_GONDI = 276,
	UBLOCK_NUSHU = 277,
	UBLOCK_SOYOMBO = 278,
	UBLOCK_SYRIAC_SUPPLEMENT = 279,
	UBLOCK_ZANABAZAR_SQUARE = 280,
	UBLOCK_CHESS_SYMBOLS = 281,
	UBLOCK_DOGRA = 282,
	UBLOCK_GEORGIAN_EXTENDED = 283,
	UBLOCK_GUNJALA_GONDI = 284,
	UBLOCK_HANIFI_ROHINGYA = 285,
	UBLOCK_INDIC_SIYAQ_NUMBERS = 286,
	UBLOCK_MAKASAR = 287,
	UBLOCK_MAYAN_NUMERALS = 288,
	UBLOCK_MEDEFAIDRIN = 289,
	UBLOCK_OLD_SOGDIAN = 290,
	UBLOCK_SOGDIAN = 291,
	UBLOCK_EGYPTIAN_HIEROGLYPH_FORMAT_CONTROLS = 292,
	UBLOCK_ELYMAIC = 293,
	UBLOCK_NANDINAGARI = 294,
	UBLOCK_NYIAKENG_PUACHUE_HMONG = 295,
	UBLOCK_OTTOMAN_SIYAQ_NUMBERS = 296,
	UBLOCK_SMALL_KANA_EXTENSION = 297,
	UBLOCK_SYMBOLS_AND_PICTOGRAPHS_EXTENDED_A = 298,
	UBLOCK_TAMIL_SUPPLEMENT = 299,
	UBLOCK_WANCHO = 300,
	UBLOCK_CHORASMIAN = 301,
	UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_G = 302,
	UBLOCK_DIVES_AKURU = 303,
	UBLOCK_KHITAN_SMALL_SCRIPT = 304,
	UBLOCK_LISU_SUPPLEMENT = 305,
	UBLOCK_SYMBOLS_FOR_LEGACY_COMPUTING = 306,
	UBLOCK_TANGUT_SUPPLEMENT = 307,
	UBLOCK_YEZIDI = 308,
	UBLOCK_INVALID_CODE = -1,
}


[AllowDuplicates]
public enum UEastAsianWidth : int32
{
	U_EA_NEUTRAL = 0,
	U_EA_AMBIGUOUS = 1,
	U_EA_HALFWIDTH = 2,
	U_EA_FULLWIDTH = 3,
	U_EA_NARROW = 4,
	U_EA_WIDE = 5,
}


[AllowDuplicates]
public enum UCharNameChoice : int32
{
	U_UNICODE_CHAR_NAME = 0,
	U_EXTENDED_CHAR_NAME = 2,
	U_CHAR_NAME_ALIAS = 3,
}


[AllowDuplicates]
public enum UPropertyNameChoice : int32
{
	U_SHORT_PROPERTY_NAME = 0,
	U_LONG_PROPERTY_NAME = 1,
}


[AllowDuplicates]
public enum UDecompositionType : int32
{
	U_DT_NONE = 0,
	U_DT_CANONICAL = 1,
	U_DT_COMPAT = 2,
	U_DT_CIRCLE = 3,
	U_DT_FINAL = 4,
	U_DT_FONT = 5,
	U_DT_FRACTION = 6,
	U_DT_INITIAL = 7,
	U_DT_ISOLATED = 8,
	U_DT_MEDIAL = 9,
	U_DT_NARROW = 10,
	U_DT_NOBREAK = 11,
	U_DT_SMALL = 12,
	U_DT_SQUARE = 13,
	U_DT_SUB = 14,
	U_DT_SUPER = 15,
	U_DT_VERTICAL = 16,
	U_DT_WIDE = 17,
}


[AllowDuplicates]
public enum UJoiningType : int32
{
	U_JT_NON_JOINING = 0,
	U_JT_JOIN_CAUSING = 1,
	U_JT_DUAL_JOINING = 2,
	U_JT_LEFT_JOINING = 3,
	U_JT_RIGHT_JOINING = 4,
	U_JT_TRANSPARENT = 5,
}


[AllowDuplicates]
public enum UJoiningGroup : int32
{
	U_JG_NO_JOINING_GROUP = 0,
	U_JG_AIN = 1,
	U_JG_ALAPH = 2,
	U_JG_ALEF = 3,
	U_JG_BEH = 4,
	U_JG_BETH = 5,
	U_JG_DAL = 6,
	U_JG_DALATH_RISH = 7,
	U_JG_E = 8,
	U_JG_FEH = 9,
	U_JG_FINAL_SEMKATH = 10,
	U_JG_GAF = 11,
	U_JG_GAMAL = 12,
	U_JG_HAH = 13,
	U_JG_TEH_MARBUTA_GOAL = 14,
	U_JG_HAMZA_ON_HEH_GOAL = 14,
	U_JG_HE = 15,
	U_JG_HEH = 16,
	U_JG_HEH_GOAL = 17,
	U_JG_HETH = 18,
	U_JG_KAF = 19,
	U_JG_KAPH = 20,
	U_JG_KNOTTED_HEH = 21,
	U_JG_LAM = 22,
	U_JG_LAMADH = 23,
	U_JG_MEEM = 24,
	U_JG_MIM = 25,
	U_JG_NOON = 26,
	U_JG_NUN = 27,
	U_JG_PE = 28,
	U_JG_QAF = 29,
	U_JG_QAPH = 30,
	U_JG_REH = 31,
	U_JG_REVERSED_PE = 32,
	U_JG_SAD = 33,
	U_JG_SADHE = 34,
	U_JG_SEEN = 35,
	U_JG_SEMKATH = 36,
	U_JG_SHIN = 37,
	U_JG_SWASH_KAF = 38,
	U_JG_SYRIAC_WAW = 39,
	U_JG_TAH = 40,
	U_JG_TAW = 41,
	U_JG_TEH_MARBUTA = 42,
	U_JG_TETH = 43,
	U_JG_WAW = 44,
	U_JG_YEH = 45,
	U_JG_YEH_BARREE = 46,
	U_JG_YEH_WITH_TAIL = 47,
	U_JG_YUDH = 48,
	U_JG_YUDH_HE = 49,
	U_JG_ZAIN = 50,
	U_JG_FE = 51,
	U_JG_KHAPH = 52,
	U_JG_ZHAIN = 53,
	U_JG_BURUSHASKI_YEH_BARREE = 54,
	U_JG_FARSI_YEH = 55,
	U_JG_NYA = 56,
	U_JG_ROHINGYA_YEH = 57,
	U_JG_MANICHAEAN_ALEPH = 58,
	U_JG_MANICHAEAN_AYIN = 59,
	U_JG_MANICHAEAN_BETH = 60,
	U_JG_MANICHAEAN_DALETH = 61,
	U_JG_MANICHAEAN_DHAMEDH = 62,
	U_JG_MANICHAEAN_FIVE = 63,
	U_JG_MANICHAEAN_GIMEL = 64,
	U_JG_MANICHAEAN_HETH = 65,
	U_JG_MANICHAEAN_HUNDRED = 66,
	U_JG_MANICHAEAN_KAPH = 67,
	U_JG_MANICHAEAN_LAMEDH = 68,
	U_JG_MANICHAEAN_MEM = 69,
	U_JG_MANICHAEAN_NUN = 70,
	U_JG_MANICHAEAN_ONE = 71,
	U_JG_MANICHAEAN_PE = 72,
	U_JG_MANICHAEAN_QOPH = 73,
	U_JG_MANICHAEAN_RESH = 74,
	U_JG_MANICHAEAN_SADHE = 75,
	U_JG_MANICHAEAN_SAMEKH = 76,
	U_JG_MANICHAEAN_TAW = 77,
	U_JG_MANICHAEAN_TEN = 78,
	U_JG_MANICHAEAN_TETH = 79,
	U_JG_MANICHAEAN_THAMEDH = 80,
	U_JG_MANICHAEAN_TWENTY = 81,
	U_JG_MANICHAEAN_WAW = 82,
	U_JG_MANICHAEAN_YODH = 83,
	U_JG_MANICHAEAN_ZAYIN = 84,
	U_JG_STRAIGHT_WAW = 85,
	U_JG_AFRICAN_FEH = 86,
	U_JG_AFRICAN_NOON = 87,
	U_JG_AFRICAN_QAF = 88,
	U_JG_MALAYALAM_BHA = 89,
	U_JG_MALAYALAM_JA = 90,
	U_JG_MALAYALAM_LLA = 91,
	U_JG_MALAYALAM_LLLA = 92,
	U_JG_MALAYALAM_NGA = 93,
	U_JG_MALAYALAM_NNA = 94,
	U_JG_MALAYALAM_NNNA = 95,
	U_JG_MALAYALAM_NYA = 96,
	U_JG_MALAYALAM_RA = 97,
	U_JG_MALAYALAM_SSA = 98,
	U_JG_MALAYALAM_TTA = 99,
	U_JG_HANIFI_ROHINGYA_KINNA_YA = 100,
	U_JG_HANIFI_ROHINGYA_PA = 101,
}


[AllowDuplicates]
public enum UGraphemeClusterBreak : int32
{
	U_GCB_OTHER = 0,
	U_GCB_CONTROL = 1,
	U_GCB_CR = 2,
	U_GCB_EXTEND = 3,
	U_GCB_L = 4,
	U_GCB_LF = 5,
	U_GCB_LV = 6,
	U_GCB_LVT = 7,
	U_GCB_T = 8,
	U_GCB_V = 9,
	U_GCB_SPACING_MARK = 10,
	U_GCB_PREPEND = 11,
	U_GCB_REGIONAL_INDICATOR = 12,
	U_GCB_E_BASE = 13,
	U_GCB_E_BASE_GAZ = 14,
	U_GCB_E_MODIFIER = 15,
	U_GCB_GLUE_AFTER_ZWJ = 16,
	U_GCB_ZWJ = 17,
}


[AllowDuplicates]
public enum UWordBreakValues : int32
{
	U_WB_OTHER = 0,
	U_WB_ALETTER = 1,
	U_WB_FORMAT = 2,
	U_WB_KATAKANA = 3,
	U_WB_MIDLETTER = 4,
	U_WB_MIDNUM = 5,
	U_WB_NUMERIC = 6,
	U_WB_EXTENDNUMLET = 7,
	U_WB_CR = 8,
	U_WB_EXTEND = 9,
	U_WB_LF = 10,
	U_WB_MIDNUMLET = 11,
	U_WB_NEWLINE = 12,
	U_WB_REGIONAL_INDICATOR = 13,
	U_WB_HEBREW_LETTER = 14,
	U_WB_SINGLE_QUOTE = 15,
	U_WB_DOUBLE_QUOTE = 16,
	U_WB_E_BASE = 17,
	U_WB_E_BASE_GAZ = 18,
	U_WB_E_MODIFIER = 19,
	U_WB_GLUE_AFTER_ZWJ = 20,
	U_WB_ZWJ = 21,
	U_WB_WSEGSPACE = 22,
}


[AllowDuplicates]
public enum USentenceBreak : int32
{
	U_SB_OTHER = 0,
	U_SB_ATERM = 1,
	U_SB_CLOSE = 2,
	U_SB_FORMAT = 3,
	U_SB_LOWER = 4,
	U_SB_NUMERIC = 5,
	U_SB_OLETTER = 6,
	U_SB_SEP = 7,
	U_SB_SP = 8,
	U_SB_STERM = 9,
	U_SB_UPPER = 10,
	U_SB_CR = 11,
	U_SB_EXTEND = 12,
	U_SB_LF = 13,
	U_SB_SCONTINUE = 14,
}


[AllowDuplicates]
public enum ULineBreak : int32
{
	U_LB_UNKNOWN = 0,
	U_LB_AMBIGUOUS = 1,
	U_LB_ALPHABETIC = 2,
	U_LB_BREAK_BOTH = 3,
	U_LB_BREAK_AFTER = 4,
	U_LB_BREAK_BEFORE = 5,
	U_LB_MANDATORY_BREAK = 6,
	U_LB_CONTINGENT_BREAK = 7,
	U_LB_CLOSE_PUNCTUATION = 8,
	U_LB_COMBINING_MARK = 9,
	U_LB_CARRIAGE_RETURN = 10,
	U_LB_EXCLAMATION = 11,
	U_LB_GLUE = 12,
	U_LB_HYPHEN = 13,
	U_LB_IDEOGRAPHIC = 14,
	U_LB_INSEPARABLE = 15,
	U_LB_INSEPERABLE = 15,
	U_LB_INFIX_NUMERIC = 16,
	U_LB_LINE_FEED = 17,
	U_LB_NONSTARTER = 18,
	U_LB_NUMERIC = 19,
	U_LB_OPEN_PUNCTUATION = 20,
	U_LB_POSTFIX_NUMERIC = 21,
	U_LB_PREFIX_NUMERIC = 22,
	U_LB_QUOTATION = 23,
	U_LB_COMPLEX_CONTEXT = 24,
	U_LB_SURROGATE = 25,
	U_LB_SPACE = 26,
	U_LB_BREAK_SYMBOLS = 27,
	U_LB_ZWSPACE = 28,
	U_LB_NEXT_LINE = 29,
	U_LB_WORD_JOINER = 30,
	U_LB_H2 = 31,
	U_LB_H3 = 32,
	U_LB_JL = 33,
	U_LB_JT = 34,
	U_LB_JV = 35,
	U_LB_CLOSE_PARENTHESIS = 36,
	U_LB_CONDITIONAL_JAPANESE_STARTER = 37,
	U_LB_HEBREW_LETTER = 38,
	U_LB_REGIONAL_INDICATOR = 39,
	U_LB_E_BASE = 40,
	U_LB_E_MODIFIER = 41,
	U_LB_ZWJ = 42,
}


[AllowDuplicates]
public enum UNumericType : int32
{
	U_NT_NONE = 0,
	U_NT_DECIMAL = 1,
	U_NT_DIGIT = 2,
	U_NT_NUMERIC = 3,
}


[AllowDuplicates]
public enum UHangulSyllableType : int32
{
	U_HST_NOT_APPLICABLE = 0,
	U_HST_LEADING_JAMO = 1,
	U_HST_VOWEL_JAMO = 2,
	U_HST_TRAILING_JAMO = 3,
	U_HST_LV_SYLLABLE = 4,
	U_HST_LVT_SYLLABLE = 5,
}


[AllowDuplicates]
public enum UIndicPositionalCategory : int32
{
	U_INPC_NA = 0,
	U_INPC_BOTTOM = 1,
	U_INPC_BOTTOM_AND_LEFT = 2,
	U_INPC_BOTTOM_AND_RIGHT = 3,
	U_INPC_LEFT = 4,
	U_INPC_LEFT_AND_RIGHT = 5,
	U_INPC_OVERSTRUCK = 6,
	U_INPC_RIGHT = 7,
	U_INPC_TOP = 8,
	U_INPC_TOP_AND_BOTTOM = 9,
	U_INPC_TOP_AND_BOTTOM_AND_RIGHT = 10,
	U_INPC_TOP_AND_LEFT = 11,
	U_INPC_TOP_AND_LEFT_AND_RIGHT = 12,
	U_INPC_TOP_AND_RIGHT = 13,
	U_INPC_VISUAL_ORDER_LEFT = 14,
	U_INPC_TOP_AND_BOTTOM_AND_LEFT = 15,
}


[AllowDuplicates]
public enum UIndicSyllabicCategory : int32
{
	U_INSC_OTHER = 0,
	U_INSC_AVAGRAHA = 1,
	U_INSC_BINDU = 2,
	U_INSC_BRAHMI_JOINING_NUMBER = 3,
	U_INSC_CANTILLATION_MARK = 4,
	U_INSC_CONSONANT = 5,
	U_INSC_CONSONANT_DEAD = 6,
	U_INSC_CONSONANT_FINAL = 7,
	U_INSC_CONSONANT_HEAD_LETTER = 8,
	U_INSC_CONSONANT_INITIAL_POSTFIXED = 9,
	U_INSC_CONSONANT_KILLER = 10,
	U_INSC_CONSONANT_MEDIAL = 11,
	U_INSC_CONSONANT_PLACEHOLDER = 12,
	U_INSC_CONSONANT_PRECEDING_REPHA = 13,
	U_INSC_CONSONANT_PREFIXED = 14,
	U_INSC_CONSONANT_SUBJOINED = 15,
	U_INSC_CONSONANT_SUCCEEDING_REPHA = 16,
	U_INSC_CONSONANT_WITH_STACKER = 17,
	U_INSC_GEMINATION_MARK = 18,
	U_INSC_INVISIBLE_STACKER = 19,
	U_INSC_JOINER = 20,
	U_INSC_MODIFYING_LETTER = 21,
	U_INSC_NON_JOINER = 22,
	U_INSC_NUKTA = 23,
	U_INSC_NUMBER = 24,
	U_INSC_NUMBER_JOINER = 25,
	U_INSC_PURE_KILLER = 26,
	U_INSC_REGISTER_SHIFTER = 27,
	U_INSC_SYLLABLE_MODIFIER = 28,
	U_INSC_TONE_LETTER = 29,
	U_INSC_TONE_MARK = 30,
	U_INSC_VIRAMA = 31,
	U_INSC_VISARGA = 32,
	U_INSC_VOWEL = 33,
	U_INSC_VOWEL_DEPENDENT = 34,
	U_INSC_VOWEL_INDEPENDENT = 35,
}


[AllowDuplicates]
public enum UVerticalOrientation : int32
{
	U_VO_ROTATED = 0,
	U_VO_TRANSFORMED_ROTATED = 1,
	U_VO_TRANSFORMED_UPRIGHT = 2,
	U_VO_UPRIGHT = 3,
}


[AllowDuplicates]
public enum UBiDiDirection : int32
{
	UBIDI_LTR = 0,
	UBIDI_RTL = 1,
	UBIDI_MIXED = 2,
	UBIDI_NEUTRAL = 3,
}


[AllowDuplicates]
public enum UBiDiReorderingMode : int32
{
	UBIDI_REORDER_DEFAULT = 0,
	UBIDI_REORDER_NUMBERS_SPECIAL = 1,
	UBIDI_REORDER_GROUP_NUMBERS_WITH_R = 2,
	UBIDI_REORDER_RUNS_ONLY = 3,
	UBIDI_REORDER_INVERSE_NUMBERS_AS_L = 4,
	UBIDI_REORDER_INVERSE_LIKE_DIRECT = 5,
	UBIDI_REORDER_INVERSE_FOR_NUMBERS_SPECIAL = 6,
}


[AllowDuplicates]
public enum UBiDiReorderingOption : int32
{
	UBIDI_OPTION_DEFAULT = 0,
	UBIDI_OPTION_INSERT_MARKS = 1,
	UBIDI_OPTION_REMOVE_CONTROLS = 2,
	UBIDI_OPTION_STREAMING = 4,
}


[AllowDuplicates]
public enum UBiDiOrder : int32
{
	UBIDI_LOGICAL = 0,
	UBIDI_VISUAL = 1,
}


[AllowDuplicates]
public enum UBiDiMirroring : int32
{
	UBIDI_MIRRORING_OFF = 0,
	UBIDI_MIRRORING_ON = 1,
}


[AllowDuplicates]
public enum USetSpanCondition : int32
{
	USET_SPAN_NOT_CONTAINED = 0,
	USET_SPAN_CONTAINED = 1,
	USET_SPAN_SIMPLE = 2,
}


[AllowDuplicates]
public enum UNormalization2Mode : int32
{
	UNORM2_COMPOSE = 0,
	UNORM2_DECOMPOSE = 1,
	UNORM2_FCD = 2,
	UNORM2_COMPOSE_CONTIGUOUS = 3,
}


[AllowDuplicates]
public enum UNormalizationCheckResult : int32
{
	UNORM_NO = 0,
	UNORM_YES = 1,
	UNORM_MAYBE = 2,
}


[AllowDuplicates]
public enum UNormalizationMode : int32
{
	UNORM_NONE = 1,
	UNORM_NFD = 2,
	UNORM_NFKD = 3,
	UNORM_NFC = 4,
	UNORM_DEFAULT = 4,
	UNORM_NFKC = 5,
	UNORM_FCD = 6,
	UNORM_MODE_COUNT = 7,
}


[AllowDuplicates]
public enum UStringPrepProfileType : int32
{
	USPREP_RFC3491_NAMEPREP = 0,
	USPREP_RFC3530_NFS4_CS_PREP = 1,
	USPREP_RFC3530_NFS4_CS_PREP_CI = 2,
	USPREP_RFC3530_NFS4_CIS_PREP = 3,
	USPREP_RFC3530_NFS4_MIXED_PREP_PREFIX = 4,
	USPREP_RFC3530_NFS4_MIXED_PREP_SUFFIX = 5,
	USPREP_RFC3722_ISCSI = 6,
	USPREP_RFC3920_NODEPREP = 7,
	USPREP_RFC3920_RESOURCEPREP = 8,
	USPREP_RFC4011_MIB = 9,
	USPREP_RFC4013_SASLPREP = 10,
	USPREP_RFC4505_TRACE = 11,
	USPREP_RFC4518_LDAP = 12,
	USPREP_RFC4518_LDAP_CI = 13,
}


[AllowDuplicates]
public enum UBreakIteratorType : int32
{
	UBRK_CHARACTER = 0,
	UBRK_WORD = 1,
	UBRK_LINE = 2,
	UBRK_SENTENCE = 3,
}


[AllowDuplicates]
public enum UWordBreak : int32
{
	UBRK_WORD_NONE = 0,
	UBRK_WORD_NONE_LIMIT = 100,
	UBRK_WORD_NUMBER = 100,
	UBRK_WORD_NUMBER_LIMIT = 200,
	UBRK_WORD_LETTER = 200,
	UBRK_WORD_LETTER_LIMIT = 300,
	UBRK_WORD_KANA = 300,
	UBRK_WORD_KANA_LIMIT = 400,
	UBRK_WORD_IDEO = 400,
	UBRK_WORD_IDEO_LIMIT = 500,
}


[AllowDuplicates]
public enum ULineBreakTag : int32
{
	UBRK_LINE_SOFT = 0,
	UBRK_LINE_SOFT_LIMIT = 100,
	UBRK_LINE_HARD = 100,
	UBRK_LINE_HARD_LIMIT = 200,
}


[AllowDuplicates]
public enum USentenceBreakTag : int32
{
	UBRK_SENTENCE_TERM = 0,
	UBRK_SENTENCE_TERM_LIMIT = 100,
	UBRK_SENTENCE_SEP = 100,
	UBRK_SENTENCE_SEP_LIMIT = 200,
}


[AllowDuplicates]
public enum UCalendarType : int32
{
	UCAL_TRADITIONAL = 0,
	UCAL_DEFAULT = 0,
	UCAL_GREGORIAN = 1,
}


[AllowDuplicates]
public enum UCalendarDateFields : int32
{
	UCAL_ERA = 0,
	UCAL_YEAR = 1,
	UCAL_MONTH = 2,
	UCAL_WEEK_OF_YEAR = 3,
	UCAL_WEEK_OF_MONTH = 4,
	UCAL_DATE = 5,
	UCAL_DAY_OF_YEAR = 6,
	UCAL_DAY_OF_WEEK = 7,
	UCAL_DAY_OF_WEEK_IN_MONTH = 8,
	UCAL_AM_PM = 9,
	UCAL_HOUR = 10,
	UCAL_HOUR_OF_DAY = 11,
	UCAL_MINUTE = 12,
	UCAL_SECOND = 13,
	UCAL_MILLISECOND = 14,
	UCAL_ZONE_OFFSET = 15,
	UCAL_DST_OFFSET = 16,
	UCAL_YEAR_WOY = 17,
	UCAL_DOW_LOCAL = 18,
	UCAL_EXTENDED_YEAR = 19,
	UCAL_JULIAN_DAY = 20,
	UCAL_MILLISECONDS_IN_DAY = 21,
	UCAL_IS_LEAP_MONTH = 22,
	UCAL_FIELD_COUNT = 23,
	UCAL_DAY_OF_MONTH = 5,
}


[AllowDuplicates]
public enum UCalendarDaysOfWeek : int32
{
	UCAL_SUNDAY = 1,
	UCAL_MONDAY = 2,
	UCAL_TUESDAY = 3,
	UCAL_WEDNESDAY = 4,
	UCAL_THURSDAY = 5,
	UCAL_FRIDAY = 6,
	UCAL_SATURDAY = 7,
}


[AllowDuplicates]
public enum UCalendarMonths : int32
{
	UCAL_JANUARY = 0,
	UCAL_FEBRUARY = 1,
	UCAL_MARCH = 2,
	UCAL_APRIL = 3,
	UCAL_MAY = 4,
	UCAL_JUNE = 5,
	UCAL_JULY = 6,
	UCAL_AUGUST = 7,
	UCAL_SEPTEMBER = 8,
	UCAL_OCTOBER = 9,
	UCAL_NOVEMBER = 10,
	UCAL_DECEMBER = 11,
	UCAL_UNDECIMBER = 12,
}


[AllowDuplicates]
public enum UCalendarAMPMs : int32
{
	UCAL_AM = 0,
	UCAL_PM = 1,
}


[AllowDuplicates]
public enum USystemTimeZoneType : int32
{
	UCAL_ZONE_TYPE_ANY = 0,
	UCAL_ZONE_TYPE_CANONICAL = 1,
	UCAL_ZONE_TYPE_CANONICAL_LOCATION = 2,
}


[AllowDuplicates]
public enum UCalendarDisplayNameType : int32
{
	UCAL_STANDARD = 0,
	UCAL_SHORT_STANDARD = 1,
	UCAL_DST = 2,
	UCAL_SHORT_DST = 3,
}


[AllowDuplicates]
public enum UCalendarAttribute : int32
{
	UCAL_LENIENT = 0,
	UCAL_FIRST_DAY_OF_WEEK = 1,
	UCAL_MINIMAL_DAYS_IN_FIRST_WEEK = 2,
	UCAL_REPEATED_WALL_TIME = 3,
	UCAL_SKIPPED_WALL_TIME = 4,
}


[AllowDuplicates]
public enum UCalendarWallTimeOption : int32
{
	UCAL_WALLTIME_LAST = 0,
	UCAL_WALLTIME_FIRST = 1,
	UCAL_WALLTIME_NEXT_VALID = 2,
}


[AllowDuplicates]
public enum UCalendarLimitType : int32
{
	UCAL_MINIMUM = 0,
	UCAL_MAXIMUM = 1,
	UCAL_GREATEST_MINIMUM = 2,
	UCAL_LEAST_MAXIMUM = 3,
	UCAL_ACTUAL_MINIMUM = 4,
	UCAL_ACTUAL_MAXIMUM = 5,
}


[AllowDuplicates]
public enum UCalendarWeekdayType : int32
{
	UCAL_WEEKDAY = 0,
	UCAL_WEEKEND = 1,
	UCAL_WEEKEND_ONSET = 2,
	UCAL_WEEKEND_CEASE = 3,
}


[AllowDuplicates]
public enum UTimeZoneTransitionType : int32
{
	UCAL_TZ_TRANSITION_NEXT = 0,
	UCAL_TZ_TRANSITION_NEXT_INCLUSIVE = 1,
	UCAL_TZ_TRANSITION_PREVIOUS = 2,
	UCAL_TZ_TRANSITION_PREVIOUS_INCLUSIVE = 3,
}


[AllowDuplicates]
public enum UCollationResult : int32
{
	UCOL_EQUAL = 0,
	UCOL_GREATER = 1,
	UCOL_LESS = -1,
}


[AllowDuplicates]
public enum UColAttributeValue : int32
{
	UCOL_DEFAULT = -1,
	UCOL_PRIMARY = 0,
	UCOL_SECONDARY = 1,
	UCOL_TERTIARY = 2,
	UCOL_DEFAULT_STRENGTH = 2,
	UCOL_CE_STRENGTH_LIMIT = 3,
	UCOL_QUATERNARY = 3,
	UCOL_IDENTICAL = 15,
	UCOL_STRENGTH_LIMIT = 16,
	UCOL_OFF = 16,
	UCOL_ON = 17,
	UCOL_SHIFTED = 20,
	UCOL_NON_IGNORABLE = 21,
	UCOL_LOWER_FIRST = 24,
	UCOL_UPPER_FIRST = 25,
}


[AllowDuplicates]
public enum UColReorderCode : int32
{
	UCOL_REORDER_CODE_DEFAULT = -1,
	UCOL_REORDER_CODE_NONE = 103,
	UCOL_REORDER_CODE_OTHERS = 103,
	UCOL_REORDER_CODE_SPACE = 4096,
	UCOL_REORDER_CODE_FIRST = 4096,
	UCOL_REORDER_CODE_PUNCTUATION = 4097,
	UCOL_REORDER_CODE_SYMBOL = 4098,
	UCOL_REORDER_CODE_CURRENCY = 4099,
	UCOL_REORDER_CODE_DIGIT = 4100,
}


[AllowDuplicates]
public enum UColAttribute : int32
{
	UCOL_FRENCH_COLLATION = 0,
	UCOL_ALTERNATE_HANDLING = 1,
	UCOL_CASE_FIRST = 2,
	UCOL_CASE_LEVEL = 3,
	UCOL_NORMALIZATION_MODE = 4,
	UCOL_DECOMPOSITION_MODE = 4,
	UCOL_STRENGTH = 5,
	UCOL_NUMERIC_COLLATION = 7,
	UCOL_ATTRIBUTE_COUNT = 8,
}


[AllowDuplicates]
public enum UColRuleOption : int32
{
	UCOL_TAILORING_ONLY = 0,
	UCOL_FULL_RULES = 1,
}


[AllowDuplicates]
public enum UColBoundMode : int32
{
	UCOL_BOUND_LOWER = 0,
	UCOL_BOUND_UPPER = 1,
	UCOL_BOUND_UPPER_LONG = 2,
}


[AllowDuplicates]
public enum UFormattableType : int32
{
	UFMT_DATE = 0,
	UFMT_DOUBLE = 1,
	UFMT_LONG = 2,
	UFMT_STRING = 3,
	UFMT_ARRAY = 4,
	UFMT_INT64 = 5,
	UFMT_OBJECT = 6,
}


[AllowDuplicates]
public enum UFieldCategory : int32
{
	UFIELD_CATEGORY_UNDEFINED = 0,
	UFIELD_CATEGORY_DATE = 1,
	UFIELD_CATEGORY_NUMBER = 2,
	UFIELD_CATEGORY_LIST = 3,
	UFIELD_CATEGORY_RELATIVE_DATETIME = 4,
	UFIELD_CATEGORY_DATE_INTERVAL = 5,
	UFIELD_CATEGORY_LIST_SPAN = 4099,
	UFIELD_CATEGORY_DATE_INTERVAL_SPAN = 4101,
}


[AllowDuplicates]
public enum UGender : int32
{
	UGENDER_MALE = 0,
	UGENDER_FEMALE = 1,
	UGENDER_OTHER = 2,
}


[AllowDuplicates]
public enum UListFormatterField : int32
{
	ULISTFMT_LITERAL_FIELD = 0,
	ULISTFMT_ELEMENT_FIELD = 1,
}


[AllowDuplicates]
public enum UListFormatterType : int32
{
	ULISTFMT_TYPE_AND = 0,
	ULISTFMT_TYPE_OR = 1,
	ULISTFMT_TYPE_UNITS = 2,
}


[AllowDuplicates]
public enum UListFormatterWidth : int32
{
	ULISTFMT_WIDTH_WIDE = 0,
	ULISTFMT_WIDTH_SHORT = 1,
	ULISTFMT_WIDTH_NARROW = 2,
}


[AllowDuplicates]
public enum ULocaleDataExemplarSetType : int32
{
	ULOCDATA_ES_STANDARD = 0,
	ULOCDATA_ES_AUXILIARY = 1,
	ULOCDATA_ES_INDEX = 2,
	ULOCDATA_ES_PUNCTUATION = 3,
}


[AllowDuplicates]
public enum ULocaleDataDelimiterType : int32
{
	ULOCDATA_QUOTATION_START = 0,
	ULOCDATA_QUOTATION_END = 1,
	ULOCDATA_ALT_QUOTATION_START = 2,
	ULOCDATA_ALT_QUOTATION_END = 3,
}


[AllowDuplicates]
public enum UMeasurementSystem : int32
{
	UMS_SI = 0,
	UMS_US = 1,
	UMS_UK = 2,
}


[AllowDuplicates]
public enum UNumberFormatStyle : int32
{
	UNUM_PATTERN_DECIMAL = 0,
	UNUM_DECIMAL = 1,
	UNUM_CURRENCY = 2,
	UNUM_PERCENT = 3,
	UNUM_SCIENTIFIC = 4,
	UNUM_SPELLOUT = 5,
	UNUM_ORDINAL = 6,
	UNUM_DURATION = 7,
	UNUM_NUMBERING_SYSTEM = 8,
	UNUM_PATTERN_RULEBASED = 9,
	UNUM_CURRENCY_ISO = 10,
	UNUM_CURRENCY_PLURAL = 11,
	UNUM_CURRENCY_ACCOUNTING = 12,
	UNUM_CASH_CURRENCY = 13,
	UNUM_DECIMAL_COMPACT_SHORT = 14,
	UNUM_DECIMAL_COMPACT_LONG = 15,
	UNUM_CURRENCY_STANDARD = 16,
	UNUM_DEFAULT = 1,
	UNUM_IGNORE = 0,
}


[AllowDuplicates]
public enum UNumberFormatRoundingMode : int32
{
	UNUM_ROUND_CEILING = 0,
	UNUM_ROUND_FLOOR = 1,
	UNUM_ROUND_DOWN = 2,
	UNUM_ROUND_UP = 3,
	UNUM_ROUND_HALFEVEN = 4,
	UNUM_ROUND_HALFDOWN = 5,
	UNUM_ROUND_HALFUP = 6,
	UNUM_ROUND_UNNECESSARY = 7,
}


[AllowDuplicates]
public enum UNumberFormatPadPosition : int32
{
	UNUM_PAD_BEFORE_PREFIX = 0,
	UNUM_PAD_AFTER_PREFIX = 1,
	UNUM_PAD_BEFORE_SUFFIX = 2,
	UNUM_PAD_AFTER_SUFFIX = 3,
}


[AllowDuplicates]
public enum UNumberCompactStyle : int32
{
	UNUM_SHORT = 0,
	UNUM_LONG = 1,
}


[AllowDuplicates]
public enum UCurrencySpacing : int32
{
	UNUM_CURRENCY_MATCH = 0,
	UNUM_CURRENCY_SURROUNDING_MATCH = 1,
	UNUM_CURRENCY_INSERT = 2,
	UNUM_CURRENCY_SPACING_COUNT = 3,
}


[AllowDuplicates]
public enum UNumberFormatFields : int32
{
	UNUM_INTEGER_FIELD = 0,
	UNUM_FRACTION_FIELD = 1,
	UNUM_DECIMAL_SEPARATOR_FIELD = 2,
	UNUM_EXPONENT_SYMBOL_FIELD = 3,
	UNUM_EXPONENT_SIGN_FIELD = 4,
	UNUM_EXPONENT_FIELD = 5,
	UNUM_GROUPING_SEPARATOR_FIELD = 6,
	UNUM_CURRENCY_FIELD = 7,
	UNUM_PERCENT_FIELD = 8,
	UNUM_PERMILL_FIELD = 9,
	UNUM_SIGN_FIELD = 10,
	UNUM_MEASURE_UNIT_FIELD = 11,
	UNUM_COMPACT_FIELD = 12,
}


[AllowDuplicates]
public enum UNumberFormatAttributeValue : int32
{
	UNUM_FORMAT_ATTRIBUTE_VALUE_HIDDEN = 0,
}


[AllowDuplicates]
public enum UNumberFormatAttribute : int32
{
	UNUM_PARSE_INT_ONLY = 0,
	UNUM_GROUPING_USED = 1,
	UNUM_DECIMAL_ALWAYS_SHOWN = 2,
	UNUM_MAX_INTEGER_DIGITS = 3,
	UNUM_MIN_INTEGER_DIGITS = 4,
	UNUM_INTEGER_DIGITS = 5,
	UNUM_MAX_FRACTION_DIGITS = 6,
	UNUM_MIN_FRACTION_DIGITS = 7,
	UNUM_FRACTION_DIGITS = 8,
	UNUM_MULTIPLIER = 9,
	UNUM_GROUPING_SIZE = 10,
	UNUM_ROUNDING_MODE = 11,
	UNUM_ROUNDING_INCREMENT = 12,
	UNUM_FORMAT_WIDTH = 13,
	UNUM_PADDING_POSITION = 14,
	UNUM_SECONDARY_GROUPING_SIZE = 15,
	UNUM_SIGNIFICANT_DIGITS_USED = 16,
	UNUM_MIN_SIGNIFICANT_DIGITS = 17,
	UNUM_MAX_SIGNIFICANT_DIGITS = 18,
	UNUM_LENIENT_PARSE = 19,
	UNUM_PARSE_ALL_INPUT = 20,
	UNUM_SCALE = 21,
	UNUM_MINIMUM_GROUPING_DIGITS = 22,
	UNUM_CURRENCY_USAGE = 23,
	UNUM_FORMAT_FAIL_IF_MORE_THAN_MAX_DIGITS = 4096,
	UNUM_PARSE_NO_EXPONENT = 4097,
	UNUM_PARSE_DECIMAL_MARK_REQUIRED = 4098,
	UNUM_PARSE_CASE_SENSITIVE = 4099,
	UNUM_SIGN_ALWAYS_SHOWN = 4100,
}


[AllowDuplicates]
public enum UNumberFormatTextAttribute : int32
{
	UNUM_POSITIVE_PREFIX = 0,
	UNUM_POSITIVE_SUFFIX = 1,
	UNUM_NEGATIVE_PREFIX = 2,
	UNUM_NEGATIVE_SUFFIX = 3,
	UNUM_PADDING_CHARACTER = 4,
	UNUM_CURRENCY_CODE = 5,
	UNUM_DEFAULT_RULESET = 6,
	UNUM_PUBLIC_RULESETS = 7,
}


[AllowDuplicates]
public enum UNumberFormatSymbol : int32
{
	UNUM_DECIMAL_SEPARATOR_SYMBOL = 0,
	UNUM_GROUPING_SEPARATOR_SYMBOL = 1,
	UNUM_PATTERN_SEPARATOR_SYMBOL = 2,
	UNUM_PERCENT_SYMBOL = 3,
	UNUM_ZERO_DIGIT_SYMBOL = 4,
	UNUM_DIGIT_SYMBOL = 5,
	UNUM_MINUS_SIGN_SYMBOL = 6,
	UNUM_PLUS_SIGN_SYMBOL = 7,
	UNUM_CURRENCY_SYMBOL = 8,
	UNUM_INTL_CURRENCY_SYMBOL = 9,
	UNUM_MONETARY_SEPARATOR_SYMBOL = 10,
	UNUM_EXPONENTIAL_SYMBOL = 11,
	UNUM_PERMILL_SYMBOL = 12,
	UNUM_PAD_ESCAPE_SYMBOL = 13,
	UNUM_INFINITY_SYMBOL = 14,
	UNUM_NAN_SYMBOL = 15,
	UNUM_SIGNIFICANT_DIGIT_SYMBOL = 16,
	UNUM_MONETARY_GROUPING_SEPARATOR_SYMBOL = 17,
	UNUM_ONE_DIGIT_SYMBOL = 18,
	UNUM_TWO_DIGIT_SYMBOL = 19,
	UNUM_THREE_DIGIT_SYMBOL = 20,
	UNUM_FOUR_DIGIT_SYMBOL = 21,
	UNUM_FIVE_DIGIT_SYMBOL = 22,
	UNUM_SIX_DIGIT_SYMBOL = 23,
	UNUM_SEVEN_DIGIT_SYMBOL = 24,
	UNUM_EIGHT_DIGIT_SYMBOL = 25,
	UNUM_NINE_DIGIT_SYMBOL = 26,
	UNUM_EXPONENT_MULTIPLICATION_SYMBOL = 27,
}


[AllowDuplicates]
public enum UDateFormatStyle : int32
{
	UDAT_FULL = 0,
	UDAT_LONG = 1,
	UDAT_MEDIUM = 2,
	UDAT_SHORT = 3,
	UDAT_DEFAULT = 2,
	UDAT_RELATIVE = 128,
	UDAT_FULL_RELATIVE = 128,
	UDAT_LONG_RELATIVE = 129,
	UDAT_MEDIUM_RELATIVE = 130,
	UDAT_SHORT_RELATIVE = 131,
	UDAT_NONE = -1,
	UDAT_PATTERN = -2,
}


[AllowDuplicates]
public enum UDateFormatField : int32
{
	UDAT_ERA_FIELD = 0,
	UDAT_YEAR_FIELD = 1,
	UDAT_MONTH_FIELD = 2,
	UDAT_DATE_FIELD = 3,
	UDAT_HOUR_OF_DAY1_FIELD = 4,
	UDAT_HOUR_OF_DAY0_FIELD = 5,
	UDAT_MINUTE_FIELD = 6,
	UDAT_SECOND_FIELD = 7,
	UDAT_FRACTIONAL_SECOND_FIELD = 8,
	UDAT_DAY_OF_WEEK_FIELD = 9,
	UDAT_DAY_OF_YEAR_FIELD = 10,
	UDAT_DAY_OF_WEEK_IN_MONTH_FIELD = 11,
	UDAT_WEEK_OF_YEAR_FIELD = 12,
	UDAT_WEEK_OF_MONTH_FIELD = 13,
	UDAT_AM_PM_FIELD = 14,
	UDAT_HOUR1_FIELD = 15,
	UDAT_HOUR0_FIELD = 16,
	UDAT_TIMEZONE_FIELD = 17,
	UDAT_YEAR_WOY_FIELD = 18,
	UDAT_DOW_LOCAL_FIELD = 19,
	UDAT_EXTENDED_YEAR_FIELD = 20,
	UDAT_JULIAN_DAY_FIELD = 21,
	UDAT_MILLISECONDS_IN_DAY_FIELD = 22,
	UDAT_TIMEZONE_RFC_FIELD = 23,
	UDAT_TIMEZONE_GENERIC_FIELD = 24,
	UDAT_STANDALONE_DAY_FIELD = 25,
	UDAT_STANDALONE_MONTH_FIELD = 26,
	UDAT_QUARTER_FIELD = 27,
	UDAT_STANDALONE_QUARTER_FIELD = 28,
	UDAT_TIMEZONE_SPECIAL_FIELD = 29,
	UDAT_YEAR_NAME_FIELD = 30,
	UDAT_TIMEZONE_LOCALIZED_GMT_OFFSET_FIELD = 31,
	UDAT_TIMEZONE_ISO_FIELD = 32,
	UDAT_TIMEZONE_ISO_LOCAL_FIELD = 33,
	UDAT_AM_PM_MIDNIGHT_NOON_FIELD = 35,
	UDAT_FLEXIBLE_DAY_PERIOD_FIELD = 36,
}


[AllowDuplicates]
public enum UDateFormatBooleanAttribute : int32
{
	UDAT_PARSE_ALLOW_WHITESPACE = 0,
	UDAT_PARSE_ALLOW_NUMERIC = 1,
	UDAT_PARSE_PARTIAL_LITERAL_MATCH = 2,
	UDAT_PARSE_MULTIPLE_PATTERNS_FOR_MATCH = 3,
	UDAT_BOOLEAN_ATTRIBUTE_COUNT = 4,
}


[AllowDuplicates]
public enum UDateFormatSymbolType : int32
{
	UDAT_ERAS = 0,
	UDAT_MONTHS = 1,
	UDAT_SHORT_MONTHS = 2,
	UDAT_WEEKDAYS = 3,
	UDAT_SHORT_WEEKDAYS = 4,
	UDAT_AM_PMS = 5,
	UDAT_LOCALIZED_CHARS = 6,
	UDAT_ERA_NAMES = 7,
	UDAT_NARROW_MONTHS = 8,
	UDAT_NARROW_WEEKDAYS = 9,
	UDAT_STANDALONE_MONTHS = 10,
	UDAT_STANDALONE_SHORT_MONTHS = 11,
	UDAT_STANDALONE_NARROW_MONTHS = 12,
	UDAT_STANDALONE_WEEKDAYS = 13,
	UDAT_STANDALONE_SHORT_WEEKDAYS = 14,
	UDAT_STANDALONE_NARROW_WEEKDAYS = 15,
	UDAT_QUARTERS = 16,
	UDAT_SHORT_QUARTERS = 17,
	UDAT_STANDALONE_QUARTERS = 18,
	UDAT_STANDALONE_SHORT_QUARTERS = 19,
	UDAT_SHORTER_WEEKDAYS = 20,
	UDAT_STANDALONE_SHORTER_WEEKDAYS = 21,
	UDAT_CYCLIC_YEARS_WIDE = 22,
	UDAT_CYCLIC_YEARS_ABBREVIATED = 23,
	UDAT_CYCLIC_YEARS_NARROW = 24,
	UDAT_ZODIAC_NAMES_WIDE = 25,
	UDAT_ZODIAC_NAMES_ABBREVIATED = 26,
	UDAT_ZODIAC_NAMES_NARROW = 27,
}


[AllowDuplicates]
public enum UDateTimePatternField : int32
{
	UDATPG_ERA_FIELD = 0,
	UDATPG_YEAR_FIELD = 1,
	UDATPG_QUARTER_FIELD = 2,
	UDATPG_MONTH_FIELD = 3,
	UDATPG_WEEK_OF_YEAR_FIELD = 4,
	UDATPG_WEEK_OF_MONTH_FIELD = 5,
	UDATPG_WEEKDAY_FIELD = 6,
	UDATPG_DAY_OF_YEAR_FIELD = 7,
	UDATPG_DAY_OF_WEEK_IN_MONTH_FIELD = 8,
	UDATPG_DAY_FIELD = 9,
	UDATPG_DAYPERIOD_FIELD = 10,
	UDATPG_HOUR_FIELD = 11,
	UDATPG_MINUTE_FIELD = 12,
	UDATPG_SECOND_FIELD = 13,
	UDATPG_FRACTIONAL_SECOND_FIELD = 14,
	UDATPG_ZONE_FIELD = 15,
	UDATPG_FIELD_COUNT = 16,
}


[AllowDuplicates]
public enum UDateTimePGDisplayWidth : int32
{
	UDATPG_WIDE = 0,
	UDATPG_ABBREVIATED = 1,
	UDATPG_NARROW = 2,
}


[AllowDuplicates]
public enum UDateTimePatternMatchOptions : int32
{
	UDATPG_MATCH_NO_OPTIONS = 0,
	UDATPG_MATCH_HOUR_FIELD_LENGTH = 2048,
	UDATPG_MATCH_ALL_FIELDS_LENGTH = 65535,
}


[AllowDuplicates]
public enum UDateTimePatternConflict : int32
{
	UDATPG_NO_CONFLICT = 0,
	UDATPG_BASE_CONFLICT = 1,
	UDATPG_CONFLICT = 2,
}


[AllowDuplicates]
public enum UNumberUnitWidth : int32
{
	UNUM_UNIT_WIDTH_NARROW = 0,
	UNUM_UNIT_WIDTH_SHORT = 1,
	UNUM_UNIT_WIDTH_FULL_NAME = 2,
	UNUM_UNIT_WIDTH_ISO_CODE = 3,
	UNUM_UNIT_WIDTH_HIDDEN = 4,
	UNUM_UNIT_WIDTH_COUNT = 5,
}


[AllowDuplicates]
public enum UNumberGroupingStrategy : int32
{
	UNUM_GROUPING_OFF = 0,
	UNUM_GROUPING_MIN2 = 1,
	UNUM_GROUPING_AUTO = 2,
	UNUM_GROUPING_ON_ALIGNED = 3,
	UNUM_GROUPING_THOUSANDS = 4,
}


[AllowDuplicates]
public enum UNumberSignDisplay : int32
{
	UNUM_SIGN_AUTO = 0,
	UNUM_SIGN_ALWAYS = 1,
	UNUM_SIGN_NEVER = 2,
	UNUM_SIGN_ACCOUNTING = 3,
	UNUM_SIGN_ACCOUNTING_ALWAYS = 4,
	UNUM_SIGN_EXCEPT_ZERO = 5,
	UNUM_SIGN_ACCOUNTING_EXCEPT_ZERO = 6,
	UNUM_SIGN_COUNT = 7,
}


[AllowDuplicates]
public enum UNumberDecimalSeparatorDisplay : int32
{
	UNUM_DECIMAL_SEPARATOR_AUTO = 0,
	UNUM_DECIMAL_SEPARATOR_ALWAYS = 1,
	UNUM_DECIMAL_SEPARATOR_COUNT = 2,
}


[AllowDuplicates]
public enum UNumberRangeCollapse : int32
{
	UNUM_RANGE_COLLAPSE_AUTO = 0,
	UNUM_RANGE_COLLAPSE_NONE = 1,
	UNUM_RANGE_COLLAPSE_UNIT = 2,
	UNUM_RANGE_COLLAPSE_ALL = 3,
}


[AllowDuplicates]
public enum UNumberRangeIdentityFallback : int32
{
	UNUM_IDENTITY_FALLBACK_SINGLE_VALUE = 0,
	UNUM_IDENTITY_FALLBACK_APPROXIMATELY_OR_SINGLE_VALUE = 1,
	UNUM_IDENTITY_FALLBACK_APPROXIMATELY = 2,
	UNUM_IDENTITY_FALLBACK_RANGE = 3,
}


[AllowDuplicates]
public enum UNumberRangeIdentityResult : int32
{
	UNUM_IDENTITY_RESULT_EQUAL_BEFORE_ROUNDING = 0,
	UNUM_IDENTITY_RESULT_EQUAL_AFTER_ROUNDING = 1,
	UNUM_IDENTITY_RESULT_NOT_EQUAL = 2,
}


[AllowDuplicates]
public enum UPluralType : int32
{
	UPLURAL_TYPE_CARDINAL = 0,
	UPLURAL_TYPE_ORDINAL = 1,
}


[AllowDuplicates]
public enum URegexpFlag : int32
{
	UREGEX_CASE_INSENSITIVE = 2,
	UREGEX_COMMENTS = 4,
	UREGEX_DOTALL = 32,
	UREGEX_LITERAL = 16,
	UREGEX_MULTILINE = 8,
	UREGEX_UNIX_LINES = 1,
	UREGEX_UWORD = 256,
	UREGEX_ERROR_ON_UNKNOWN_ESCAPES = 512,
}


[AllowDuplicates]
public enum URegionType : int32
{
	URGN_UNKNOWN = 0,
	URGN_TERRITORY = 1,
	URGN_WORLD = 2,
	URGN_CONTINENT = 3,
	URGN_SUBCONTINENT = 4,
	URGN_GROUPING = 5,
	URGN_DEPRECATED = 6,
}


[AllowDuplicates]
public enum UDateRelativeDateTimeFormatterStyle : int32
{
	UDAT_STYLE_LONG = 0,
	UDAT_STYLE_SHORT = 1,
	UDAT_STYLE_NARROW = 2,
}


[AllowDuplicates]
public enum URelativeDateTimeUnit : int32
{
	UDAT_REL_UNIT_YEAR = 0,
	UDAT_REL_UNIT_QUARTER = 1,
	UDAT_REL_UNIT_MONTH = 2,
	UDAT_REL_UNIT_WEEK = 3,
	UDAT_REL_UNIT_DAY = 4,
	UDAT_REL_UNIT_HOUR = 5,
	UDAT_REL_UNIT_MINUTE = 6,
	UDAT_REL_UNIT_SECOND = 7,
	UDAT_REL_UNIT_SUNDAY = 8,
	UDAT_REL_UNIT_MONDAY = 9,
	UDAT_REL_UNIT_TUESDAY = 10,
	UDAT_REL_UNIT_WEDNESDAY = 11,
	UDAT_REL_UNIT_THURSDAY = 12,
	UDAT_REL_UNIT_FRIDAY = 13,
	UDAT_REL_UNIT_SATURDAY = 14,
}


[AllowDuplicates]
public enum URelativeDateTimeFormatterField : int32
{
	UDAT_REL_LITERAL_FIELD = 0,
	UDAT_REL_NUMERIC_FIELD = 1,
}


[AllowDuplicates]
public enum USearchAttribute : int32
{
	USEARCH_OVERLAP = 0,
	USEARCH_ELEMENT_COMPARISON = 2,
}


[AllowDuplicates]
public enum USearchAttributeValue : int32
{
	USEARCH_DEFAULT = -1,
	USEARCH_OFF = 0,
	USEARCH_ON = 1,
	USEARCH_STANDARD_ELEMENT_COMPARISON = 2,
	USEARCH_PATTERN_BASE_WEIGHT_IS_WILDCARD = 3,
	USEARCH_ANY_BASE_WEIGHT_IS_WILDCARD = 4,
}


[AllowDuplicates]
public enum USpoofChecks : int32
{
	USPOOF_SINGLE_SCRIPT_CONFUSABLE = 1,
	USPOOF_MIXED_SCRIPT_CONFUSABLE = 2,
	USPOOF_WHOLE_SCRIPT_CONFUSABLE = 4,
	USPOOF_CONFUSABLE = 7,
	USPOOF_RESTRICTION_LEVEL = 16,
	USPOOF_INVISIBLE = 32,
	USPOOF_CHAR_LIMIT = 64,
	USPOOF_MIXED_NUMBERS = 128,
	USPOOF_HIDDEN_OVERLAY = 256,
	USPOOF_ALL_CHECKS = 65535,
	USPOOF_AUX_INFO = 1073741824,
}


[AllowDuplicates]
public enum URestrictionLevel : int32
{
	USPOOF_ASCII = 268435456,
	USPOOF_SINGLE_SCRIPT_RESTRICTIVE = 536870912,
	USPOOF_HIGHLY_RESTRICTIVE = 805306368,
	USPOOF_MODERATELY_RESTRICTIVE = 1073741824,
	USPOOF_MINIMALLY_RESTRICTIVE = 1342177280,
	USPOOF_UNRESTRICTIVE = 1610612736,
	USPOOF_RESTRICTION_LEVEL_MASK = 2130706432,
}


[AllowDuplicates]
public enum UDateTimeScale : int32
{
	UDTS_JAVA_TIME = 0,
	UDTS_UNIX_TIME = 1,
	UDTS_ICU4C_TIME = 2,
	UDTS_WINDOWS_FILE_TIME = 3,
	UDTS_DOTNET_DATE_TIME = 4,
	UDTS_MAC_OLD_TIME = 5,
	UDTS_MAC_TIME = 6,
	UDTS_EXCEL_TIME = 7,
	UDTS_DB2_TIME = 8,
	UDTS_UNIX_MICROSECONDS_TIME = 9,
}


[AllowDuplicates]
public enum UTimeScaleValue : int32
{
	UTSV_UNITS_VALUE = 0,
	UTSV_EPOCH_OFFSET_VALUE = 1,
	UTSV_FROM_MIN_VALUE = 2,
	UTSV_FROM_MAX_VALUE = 3,
	UTSV_TO_MIN_VALUE = 4,
	UTSV_TO_MAX_VALUE = 5,
}


[AllowDuplicates]
public enum UTransDirection : int32
{
	UTRANS_FORWARD = 0,
	UTRANS_REVERSE = 1,
}


[AllowDuplicates]
public enum UStringTrieBuildOption : int32
{
	USTRINGTRIE_BUILD_FAST = 0,
	USTRINGTRIE_BUILD_SMALL = 1,
}


[AllowDuplicates]
public enum UMessagePatternApostropheMode : int32
{
	UMSGPAT_APOS_DOUBLE_OPTIONAL = 0,
	UMSGPAT_APOS_DOUBLE_REQUIRED = 1,
}


[AllowDuplicates]
public enum UMessagePatternPartType : int32
{
	UMSGPAT_PART_TYPE_MSG_START = 0,
	UMSGPAT_PART_TYPE_MSG_LIMIT = 1,
	UMSGPAT_PART_TYPE_SKIP_SYNTAX = 2,
	UMSGPAT_PART_TYPE_INSERT_CHAR = 3,
	UMSGPAT_PART_TYPE_REPLACE_NUMBER = 4,
	UMSGPAT_PART_TYPE_ARG_START = 5,
	UMSGPAT_PART_TYPE_ARG_LIMIT = 6,
	UMSGPAT_PART_TYPE_ARG_NUMBER = 7,
	UMSGPAT_PART_TYPE_ARG_NAME = 8,
	UMSGPAT_PART_TYPE_ARG_TYPE = 9,
	UMSGPAT_PART_TYPE_ARG_STYLE = 10,
	UMSGPAT_PART_TYPE_ARG_SELECTOR = 11,
	UMSGPAT_PART_TYPE_ARG_INT = 12,
	UMSGPAT_PART_TYPE_ARG_DOUBLE = 13,
}


[AllowDuplicates]
public enum UMessagePatternArgType : int32
{
	UMSGPAT_ARG_TYPE_NONE = 0,
	UMSGPAT_ARG_TYPE_SIMPLE = 1,
	UMSGPAT_ARG_TYPE_CHOICE = 2,
	UMSGPAT_ARG_TYPE_PLURAL = 3,
	UMSGPAT_ARG_TYPE_SELECT = 4,
	UMSGPAT_ARG_TYPE_SELECTORDINAL = 5,
}


[AllowDuplicates]
public enum UAlphabeticIndexLabelType : int32
{
	U_ALPHAINDEX_NORMAL = 0,
	U_ALPHAINDEX_UNDERFLOW = 1,
	U_ALPHAINDEX_INFLOW = 2,
	U_ALPHAINDEX_OVERFLOW = 3,
}


[AllowDuplicates]
public enum UTimeZoneNameType : int32
{
	UTZNM_UNKNOWN = 0,
	UTZNM_LONG_GENERIC = 1,
	UTZNM_LONG_STANDARD = 2,
	UTZNM_LONG_DAYLIGHT = 4,
	UTZNM_SHORT_GENERIC = 8,
	UTZNM_SHORT_STANDARD = 16,
	UTZNM_SHORT_DAYLIGHT = 32,
	UTZNM_EXEMPLAR_LOCATION = 64,
}


[AllowDuplicates]
public enum UTimeZoneFormatStyle : int32
{
	UTZFMT_STYLE_GENERIC_LOCATION = 0,
	UTZFMT_STYLE_GENERIC_LONG = 1,
	UTZFMT_STYLE_GENERIC_SHORT = 2,
	UTZFMT_STYLE_SPECIFIC_LONG = 3,
	UTZFMT_STYLE_SPECIFIC_SHORT = 4,
	UTZFMT_STYLE_LOCALIZED_GMT = 5,
	UTZFMT_STYLE_LOCALIZED_GMT_SHORT = 6,
	UTZFMT_STYLE_ISO_BASIC_SHORT = 7,
	UTZFMT_STYLE_ISO_BASIC_LOCAL_SHORT = 8,
	UTZFMT_STYLE_ISO_BASIC_FIXED = 9,
	UTZFMT_STYLE_ISO_BASIC_LOCAL_FIXED = 10,
	UTZFMT_STYLE_ISO_BASIC_FULL = 11,
	UTZFMT_STYLE_ISO_BASIC_LOCAL_FULL = 12,
	UTZFMT_STYLE_ISO_EXTENDED_FIXED = 13,
	UTZFMT_STYLE_ISO_EXTENDED_LOCAL_FIXED = 14,
	UTZFMT_STYLE_ISO_EXTENDED_FULL = 15,
	UTZFMT_STYLE_ISO_EXTENDED_LOCAL_FULL = 16,
	UTZFMT_STYLE_ZONE_ID = 17,
	UTZFMT_STYLE_ZONE_ID_SHORT = 18,
	UTZFMT_STYLE_EXEMPLAR_LOCATION = 19,
}


[AllowDuplicates]
public enum UTimeZoneFormatGMTOffsetPatternType : int32
{
	UTZFMT_PAT_POSITIVE_HM = 0,
	UTZFMT_PAT_POSITIVE_HMS = 1,
	UTZFMT_PAT_NEGATIVE_HM = 2,
	UTZFMT_PAT_NEGATIVE_HMS = 3,
	UTZFMT_PAT_POSITIVE_H = 4,
	UTZFMT_PAT_NEGATIVE_H = 5,
	UTZFMT_PAT_COUNT = 6,
}


[AllowDuplicates]
public enum UTimeZoneFormatTimeType : int32
{
	UTZFMT_TIME_TYPE_UNKNOWN = 0,
	UTZFMT_TIME_TYPE_STANDARD = 1,
	UTZFMT_TIME_TYPE_DAYLIGHT = 2,
}


[AllowDuplicates]
public enum UTimeZoneFormatParseOption : int32
{
	UTZFMT_PARSE_OPTION_NONE = 0,
	UTZFMT_PARSE_OPTION_ALL_STYLES = 1,
	UTZFMT_PARSE_OPTION_TZ_DATABASE_ABBREVIATIONS = 2,
}


[AllowDuplicates]
public enum UMeasureFormatWidth : int32
{
	UMEASFMT_WIDTH_WIDE = 0,
	UMEASFMT_WIDTH_SHORT = 1,
	UMEASFMT_WIDTH_NARROW = 2,
	UMEASFMT_WIDTH_NUMERIC = 3,
	UMEASFMT_WIDTH_COUNT = 4,
}


[AllowDuplicates]
public enum UDateRelativeUnit : int32
{
	UDAT_RELATIVE_SECONDS = 0,
	UDAT_RELATIVE_MINUTES = 1,
	UDAT_RELATIVE_HOURS = 2,
	UDAT_RELATIVE_DAYS = 3,
	UDAT_RELATIVE_WEEKS = 4,
	UDAT_RELATIVE_MONTHS = 5,
	UDAT_RELATIVE_YEARS = 6,
	UDAT_RELATIVE_UNIT_COUNT = 7,
}


[AllowDuplicates]
public enum UDateAbsoluteUnit : int32
{
	UDAT_ABSOLUTE_SUNDAY = 0,
	UDAT_ABSOLUTE_MONDAY = 1,
	UDAT_ABSOLUTE_TUESDAY = 2,
	UDAT_ABSOLUTE_WEDNESDAY = 3,
	UDAT_ABSOLUTE_THURSDAY = 4,
	UDAT_ABSOLUTE_FRIDAY = 5,
	UDAT_ABSOLUTE_SATURDAY = 6,
	UDAT_ABSOLUTE_DAY = 7,
	UDAT_ABSOLUTE_WEEK = 8,
	UDAT_ABSOLUTE_MONTH = 9,
	UDAT_ABSOLUTE_YEAR = 10,
	UDAT_ABSOLUTE_NOW = 11,
	UDAT_ABSOLUTE_UNIT_COUNT = 12,
}


[AllowDuplicates]
public enum UDateDirection : int32
{
	UDAT_DIRECTION_LAST_2 = 0,
	UDAT_DIRECTION_LAST = 1,
	UDAT_DIRECTION_THIS = 2,
	UDAT_DIRECTION_NEXT = 3,
	UDAT_DIRECTION_NEXT_2 = 4,
	UDAT_DIRECTION_PLAIN = 5,
	UDAT_DIRECTION_COUNT = 6,
}


[AllowDuplicates]
public enum MIMECONTF : int32
{
	MIMECONTF_MAILNEWS = 1,
	MIMECONTF_BROWSER = 2,
	MIMECONTF_MINIMAL = 4,
	MIMECONTF_IMPORT = 8,
	MIMECONTF_SAVABLE_MAILNEWS = 256,
	MIMECONTF_SAVABLE_BROWSER = 512,
	MIMECONTF_EXPORT = 1024,
	MIMECONTF_PRIVCONVERTER = 65536,
	MIMECONTF_VALID = 131072,
	MIMECONTF_VALID_NLS = 262144,
	MIMECONTF_MIME_IE4 = 268435456,
	MIMECONTF_MIME_LATEST = 536870912,
	MIMECONTF_MIME_REGISTRY = 1073741824,
}


[AllowDuplicates]
public enum SCRIPTCONTF : int32
{
	sidDefault = 0,
	sidMerge = 1,
	sidAsciiSym = 2,
	sidAsciiLatin = 3,
	sidLatin = 4,
	sidGreek = 5,
	sidCyrillic = 6,
	sidArmenian = 7,
	sidHebrew = 8,
	sidArabic = 9,
	sidDevanagari = 10,
	sidBengali = 11,
	sidGurmukhi = 12,
	sidGujarati = 13,
	sidOriya = 14,
	sidTamil = 15,
	sidTelugu = 16,
	sidKannada = 17,
	sidMalayalam = 18,
	sidThai = 19,
	sidLao = 20,
	sidTibetan = 21,
	sidGeorgian = 22,
	sidHangul = 23,
	sidKana = 24,
	sidBopomofo = 25,
	sidHan = 26,
	sidEthiopic = 27,
	sidCanSyllabic = 28,
	sidCherokee = 29,
	sidYi = 30,
	sidBraille = 31,
	sidRunic = 32,
	sidOgham = 33,
	sidSinhala = 34,
	sidSyriac = 35,
	sidBurmese = 36,
	sidKhmer = 37,
	sidThaana = 38,
	sidMongolian = 39,
	sidUserDefined = 40,
	sidLim = 41,
	sidFEFirst = 23,
	sidFELast = 26,
}


[AllowDuplicates]
public enum MLCONVCHAR : int32
{
	MLCONVCHARF_AUTODETECT = 1,
	MLCONVCHARF_ENTITIZE = 2,
	MLCONVCHARF_NCR_ENTITIZE = 2,
	MLCONVCHARF_NAME_ENTITIZE = 4,
	MLCONVCHARF_USEDEFCHAR = 8,
	MLCONVCHARF_NOBESTFITCHARS = 16,
	MLCONVCHARF_DETECTJPN = 32,
}


[AllowDuplicates]
public enum MLCP : int32
{
	MLDETECTF_MAILNEWS = 1,
	MLDETECTF_BROWSER = 2,
	MLDETECTF_VALID = 4,
	MLDETECTF_VALID_NLS = 8,
	MLDETECTF_PRESERVE_ORDER = 16,
	MLDETECTF_PREFERRED_ONLY = 32,
	MLDETECTF_FILTER_SPECIALCHAR = 64,
	MLDETECTF_EURO_UTF8 = 128,
}


[AllowDuplicates]
public enum MLDETECTCP : int32
{
	MLDETECTCP_NONE = 0,
	MLDETECTCP_7BIT = 1,
	MLDETECTCP_8BIT = 2,
	MLDETECTCP_DBCS = 4,
	MLDETECTCP_HTML = 8,
	MLDETECTCP_NUMBER = 16,
}


[AllowDuplicates]
public enum SCRIPTFONTCONTF : int32
{
	SCRIPTCONTF_FIXED_FONT = 1,
	SCRIPTCONTF_PROPORTIONAL_FONT = 2,
	SCRIPTCONTF_SCRIPT_USER = 65536,
	SCRIPTCONTF_SCRIPT_HIDE = 131072,
	SCRIPTCONTF_SCRIPT_SYSTEM = 262144,
}


[AllowDuplicates]
public enum MLSTR_FLAGS : int32
{
	MLSTR_READ = 1,
	MLSTR_WRITE = 2,
}

#endregion

#region Function Pointers
public function BOOL LOCALE_ENUMPROCA(PSTR param0);

public function BOOL LOCALE_ENUMPROCW(PWSTR param0);

public function BOOL LANGUAGEGROUP_ENUMPROCA(uint32 param0, PSTR param1, PSTR param2, uint32 param3, int param4);

public function BOOL LANGGROUPLOCALE_ENUMPROCA(uint32 param0, uint32 param1, PSTR param2, int param3);

public function BOOL UILANGUAGE_ENUMPROCA(PSTR param0, int param1);

public function BOOL CODEPAGE_ENUMPROCA(PSTR param0);

public function BOOL DATEFMT_ENUMPROCA(PSTR param0);

public function BOOL DATEFMT_ENUMPROCEXA(PSTR param0, uint32 param1);

public function BOOL TIMEFMT_ENUMPROCA(PSTR param0);

public function BOOL CALINFO_ENUMPROCA(PSTR param0);

public function BOOL CALINFO_ENUMPROCEXA(PSTR param0, uint32 param1);

public function BOOL LANGUAGEGROUP_ENUMPROCW(uint32 param0, PWSTR param1, PWSTR param2, uint32 param3, int param4);

public function BOOL LANGGROUPLOCALE_ENUMPROCW(uint32 param0, uint32 param1, PWSTR param2, int param3);

public function BOOL UILANGUAGE_ENUMPROCW(PWSTR param0, int param1);

public function BOOL CODEPAGE_ENUMPROCW(PWSTR param0);

public function BOOL DATEFMT_ENUMPROCW(PWSTR param0);

public function BOOL DATEFMT_ENUMPROCEXW(PWSTR param0, uint32 param1);

public function BOOL TIMEFMT_ENUMPROCW(PWSTR param0);

public function BOOL CALINFO_ENUMPROCW(PWSTR param0);

public function BOOL CALINFO_ENUMPROCEXW(PWSTR param0, uint32 param1);

public function BOOL GEO_ENUMPROC(int32 param0);

public function BOOL GEO_ENUMNAMEPROC(PWSTR param0, LPARAM param1);

public function BOOL CALINFO_ENUMPROCEXEX(PWSTR param0, uint32 param1, PWSTR param2, LPARAM param3);

public function BOOL DATEFMT_ENUMPROCEXEX(PWSTR param0, uint32 param1, LPARAM param2);

public function BOOL TIMEFMT_ENUMPROCEX(PWSTR param0, LPARAM param1);

public function BOOL LOCALE_ENUMPROCEX(PWSTR param0, uint32 param1, LPARAM param2);

public function void PFN_MAPPINGCALLBACKPROC(MAPPING_PROPERTY_BAG* pBag, void* data, uint32 dwDataSize, HRESULT Result);

public function void UTraceEntry(void* context, int32 fnNumber);

public function void UTraceExit(void* context, int32 fnNumber, PSTR fmt, int8* args);

public function void UTraceData(void* context, int32 fnNumber, int32 level, PSTR fmt, int8* args);

public function int32 UCharIteratorGetIndex(UCharIterator* iter, UCharIteratorOrigin origin);

public function int32 UCharIteratorMove(UCharIterator* iter, int32 delta, UCharIteratorOrigin origin);

public function int8 UCharIteratorHasNext(UCharIterator* iter);

public function int8 UCharIteratorHasPrevious(UCharIterator* iter);

public function int32 UCharIteratorCurrent(UCharIterator* iter);

public function int32 UCharIteratorNext(UCharIterator* iter);

public function int32 UCharIteratorPrevious(UCharIterator* iter);

public function int32 UCharIteratorReserved(UCharIterator* iter, int32 something);

public function uint32 UCharIteratorGetState(UCharIterator* iter);

public function void UCharIteratorSetState(UCharIterator* iter, uint32 state, UErrorCode* pErrorCode);

public function uint32 UCPMapValueFilter(void* context, uint32 value);

public function void UConverterToUCallback(void* context, UConverterToUnicodeArgs* args, PSTR codeUnits, int32 length, UConverterCallbackReason reason, UErrorCode* pErrorCode);

public function void UConverterFromUCallback(void* context, UConverterFromUnicodeArgs* args, uint16* codeUnits, int32 length, int32 codePoint, UConverterCallbackReason reason, UErrorCode* pErrorCode);

public function void* UMemAllocFn(void* context, uint size);

public function void* UMemReallocFn(void* context, void* mem, uint size);

public function void UMemFreeFn(void* context, void* mem);

public function int8 UCharEnumTypeRange(void* context, int32 start, int32 limit, UCharCategory type);

public function int8 UEnumCharNamesFn(void* context, int32 code, UCharNameChoice nameChoice, PSTR name, int32 length);

public function UCharDirection UBiDiClassCallback(void* context, int32 c);

public function UText* UTextClone(UText* dest, UText* src, int8 deep, UErrorCode* status);

public function int64 UTextNativeLength(UText* ut);

public function int8 UTextAccess(UText* ut, int64 nativeIndex, int8 forward);

public function int32 UTextExtract(UText* ut, int64 nativeStart, int64 nativeLimit, uint16* dest, int32 destCapacity, UErrorCode* status);

public function int32 UTextReplace(UText* ut, int64 nativeStart, int64 nativeLimit, uint16* replacementText, int32 replacmentLength, UErrorCode* status);

public function void UTextCopy(UText* ut, int64 nativeStart, int64 nativeLimit, int64 nativeDest, int8 move, UErrorCode* status);

public function int64 UTextMapOffsetToNative(UText* ut);

public function int32 UTextMapNativeIndexToUTF16(UText* ut, int64 nativeIndex);

public function void UTextClose(UText* ut);

public function uint16 UNESCAPE_CHAR_AT(int32 offset, void* context);

public function int8 URegexMatchCallback(void* context, int32 steps);

public function int8 URegexFindProgressCallback(void* context, int64 matchIndex);

public function int32 UStringCaseMapper(UCaseMap* csm, uint16* dest, int32 destCapacity, uint16* src, int32 srcLength, UErrorCode* pErrorCode);

#endregion

#region Structs
[CRepr]
public struct FONTSIGNATURE
{
	public uint32[4] fsUsb;
	public uint32[2] fsCsb;
}

[CRepr]
public struct CHARSETINFO
{
	public uint32 ciCharset;
	public uint32 ciACP;
	public FONTSIGNATURE fs;
}

[CRepr]
public struct LOCALESIGNATURE
{
	public uint32[4] lsUsb;
	public uint32[2] lsCsbDefault;
	public uint32[2] lsCsbSupported;
}

[CRepr]
public struct NEWTEXTMETRICEXA
{
	public NEWTEXTMETRICA ntmTm;
	public FONTSIGNATURE ntmFontSig;
}

[CRepr]
public struct NEWTEXTMETRICEXW
{
	public NEWTEXTMETRICW ntmTm;
	public FONTSIGNATURE ntmFontSig;
}

[CRepr]
public struct ENUMTEXTMETRICA
{
	public NEWTEXTMETRICEXA etmNewTextMetricEx;
	public AXESLISTA etmAxesList;
}

[CRepr]
public struct ENUMTEXTMETRICW
{
	public NEWTEXTMETRICEXW etmNewTextMetricEx;
	public AXESLISTW etmAxesList;
}

[CRepr]
public struct CPINFO
{
	public uint32 MaxCharSize;
	public uint8[2] DefaultChar;
	public uint8[12] LeadByte;
}

[CRepr]
public struct CPINFOEXA
{
	public uint32 MaxCharSize;
	public uint8[2] DefaultChar;
	public uint8[12] LeadByte;
	public char16 UnicodeDefaultChar;
	public uint32 CodePage;
	public CHAR[260] CodePageName;
}

[CRepr]
public struct CPINFOEXW
{
	public uint32 MaxCharSize;
	public uint8[2] DefaultChar;
	public uint8[12] LeadByte;
	public char16 UnicodeDefaultChar;
	public uint32 CodePage;
	public char16[260] CodePageName;
}

[CRepr]
public struct NUMBERFMTA
{
	public uint32 NumDigits;
	public uint32 LeadingZero;
	public uint32 Grouping;
	public PSTR lpDecimalSep;
	public PSTR lpThousandSep;
	public uint32 NegativeOrder;
}

[CRepr]
public struct NUMBERFMTW
{
	public uint32 NumDigits;
	public uint32 LeadingZero;
	public uint32 Grouping;
	public PWSTR lpDecimalSep;
	public PWSTR lpThousandSep;
	public uint32 NegativeOrder;
}

[CRepr]
public struct CURRENCYFMTA
{
	public uint32 NumDigits;
	public uint32 LeadingZero;
	public uint32 Grouping;
	public PSTR lpDecimalSep;
	public PSTR lpThousandSep;
	public uint32 NegativeOrder;
	public uint32 PositiveOrder;
	public PSTR lpCurrencySymbol;
}

[CRepr]
public struct CURRENCYFMTW
{
	public uint32 NumDigits;
	public uint32 LeadingZero;
	public uint32 Grouping;
	public PWSTR lpDecimalSep;
	public PWSTR lpThousandSep;
	public uint32 NegativeOrder;
	public uint32 PositiveOrder;
	public PWSTR lpCurrencySymbol;
}

[CRepr]
public struct NLSVERSIONINFO
{
	public uint32 dwNLSVersionInfoSize;
	public uint32 dwNLSVersion;
	public uint32 dwDefinedVersion;
	public uint32 dwEffectiveId;
	public Guid guidCustomVersion;
}

[CRepr]
public struct NLSVERSIONINFOEX
{
	public uint32 dwNLSVersionInfoSize;
	public uint32 dwNLSVersion;
	public uint32 dwDefinedVersion;
	public uint32 dwEffectiveId;
	public Guid guidCustomVersion;
}

[CRepr]
public struct FILEMUIINFO
{
	public uint32 dwSize;
	public uint32 dwVersion;
	public uint32 dwFileType;
	public uint8[16] pChecksum;
	public uint8[16] pServiceChecksum;
	public uint32 dwLanguageNameOffset;
	public uint32 dwTypeIDMainSize;
	public uint32 dwTypeIDMainOffset;
	public uint32 dwTypeNameMainOffset;
	public uint32 dwTypeIDMUISize;
	public uint32 dwTypeIDMUIOffset;
	public uint32 dwTypeNameMUIOffset;
	public uint8[8] abBuffer;
}

[CRepr]
public struct MAPPING_SERVICE_INFO
{
	public uint Size;
	public PWSTR pszCopyright;
	public uint16 wMajorVersion;
	public uint16 wMinorVersion;
	public uint16 wBuildVersion;
	public uint16 wStepVersion;
	public uint32 dwInputContentTypesCount;
	public PWSTR* prgInputContentTypes;
	public uint32 dwOutputContentTypesCount;
	public PWSTR* prgOutputContentTypes;
	public uint32 dwInputLanguagesCount;
	public PWSTR* prgInputLanguages;
	public uint32 dwOutputLanguagesCount;
	public PWSTR* prgOutputLanguages;
	public uint32 dwInputScriptsCount;
	public PWSTR* prgInputScripts;
	public uint32 dwOutputScriptsCount;
	public PWSTR* prgOutputScripts;
	public Guid guid;
	public PWSTR pszCategory;
	public PWSTR pszDescription;
	public uint32 dwPrivateDataSize;
	public void* pPrivateData;
	public void* pContext;
	public uint32 _bitfield;
}

[CRepr]
public struct MAPPING_ENUM_OPTIONS
{
	public uint Size;
	public PWSTR pszCategory;
	public PWSTR pszInputLanguage;
	public PWSTR pszOutputLanguage;
	public PWSTR pszInputScript;
	public PWSTR pszOutputScript;
	public PWSTR pszInputContentType;
	public PWSTR pszOutputContentType;
	public Guid* pGuid;
	public uint32 _bitfield;
}

[CRepr]
public struct MAPPING_OPTIONS
{
	public uint Size;
	public PWSTR pszInputLanguage;
	public PWSTR pszOutputLanguage;
	public PWSTR pszInputScript;
	public PWSTR pszOutputScript;
	public PWSTR pszInputContentType;
	public PWSTR pszOutputContentType;
	public PWSTR pszUILanguage;
	public PFN_MAPPINGCALLBACKPROC pfnRecognizeCallback;
	public void* pRecognizeCallerData;
	public uint32 dwRecognizeCallerDataSize;
	public PFN_MAPPINGCALLBACKPROC pfnActionCallback;
	public void* pActionCallerData;
	public uint32 dwActionCallerDataSize;
	public uint32 dwServiceFlag;
	public uint32 _bitfield;
}

[CRepr]
public struct MAPPING_DATA_RANGE
{
	public uint32 dwStartIndex;
	public uint32 dwEndIndex;
	public PWSTR pszDescription;
	public uint32 dwDescriptionLength;
	public void* pData;
	public uint32 dwDataSize;
	public PWSTR pszContentType;
	public PWSTR* prgActionIds;
	public uint32 dwActionsCount;
	public PWSTR* prgActionDisplayNames;
}

[CRepr]
public struct MAPPING_PROPERTY_BAG
{
	public uint Size;
	public MAPPING_DATA_RANGE* prgResultRanges;
	public uint32 dwRangesCount;
	public void* pServiceData;
	public uint32 dwServiceDataSize;
	public void* pCallerData;
	public uint32 dwCallerDataSize;
	public void* pContext;
}

[CRepr]
public struct SCRIPT_CONTROL
{
	public uint32 _bitfield;
}

[CRepr]
public struct SCRIPT_STATE
{
	public uint16 _bitfield;
}

[CRepr]
public struct SCRIPT_ANALYSIS
{
	public uint16 _bitfield;
	public SCRIPT_STATE s;
}

[CRepr]
public struct SCRIPT_ITEM
{
	public int32 iCharPos;
	public SCRIPT_ANALYSIS a;
}

[CRepr]
public struct SCRIPT_VISATTR
{
	public uint16 _bitfield;
}

[CRepr]
public struct GOFFSET
{
	public int32 du;
	public int32 dv;
}

[CRepr]
public struct SCRIPT_LOGATTR
{
	public uint8 _bitfield;
}

[CRepr]
public struct SCRIPT_PROPERTIES
{
	public uint32 _bitfield1;
	public uint32 _bitfield2;
}

[CRepr]
public struct SCRIPT_FONTPROPERTIES
{
	public int32 cBytes;
	public uint16 wgBlank;
	public uint16 wgDefault;
	public uint16 wgInvalid;
	public uint16 wgKashida;
	public int32 iKashidaWidth;
}

[CRepr]
public struct SCRIPT_TABDEF
{
	public int32 cTabStops;
	public int32 iScale;
	public int32* pTabStops;
	public int32 iTabOrigin;
}

[CRepr]
public struct SCRIPT_DIGITSUBSTITUTE
{
	public uint32 _bitfield1;
	public uint32 _bitfield2;
	public uint32 dwReserved;
}

[CRepr]
public struct OPENTYPE_FEATURE_RECORD
{
	public uint32 tagFeature;
	public int32 lParameter;
}

[CRepr]
public struct TEXTRANGE_PROPERTIES
{
	public OPENTYPE_FEATURE_RECORD* potfRecords;
	public int32 cotfRecords;
}

[CRepr]
public struct SCRIPT_CHARPROP
{
	public uint16 _bitfield;
}

[CRepr]
public struct SCRIPT_GLYPHPROP
{
	public SCRIPT_VISATTR sva;
	public uint16 reserved;
}

[CRepr]
public struct UReplaceableCallbacks
{
	public int length;
	public int charAt;
	public int char32At;
	public int replace;
	public int extract;
	public int copy;
}

[CRepr]
public struct UFieldPosition
{
	public int32 field;
	public int32 beginIndex;
	public int32 endIndex;
}

[CRepr]
public struct UCharIterator
{
	public void* context;
	public int32 length;
	public int32 start;
	public int32 index;
	public int32 limit;
	public int32 reservedField;
	public UCharIteratorGetIndex getIndex;
	public UCharIteratorMove move;
	public UCharIteratorHasNext hasNext;
	public UCharIteratorHasPrevious hasPrevious;
	public UCharIteratorCurrent current;
	public UCharIteratorNext next;
	public UCharIteratorPrevious previous;
	public UCharIteratorReserved reservedFn;
	public UCharIteratorGetState getState;
	public UCharIteratorSetState setState;
}

[CRepr]
public struct UEnumeration
{
}

[CRepr]
public struct UResourceBundle
{
}

[CRepr]
public struct ULocaleDisplayNames
{
}

[CRepr]
public struct UCPMap
{
}

[CRepr, Union]
public struct UCPTrieData
{
	public void* ptr0;
	public uint16* ptr16;
	public uint32* ptr32;
	public uint8* ptr8;
}

[CRepr]
public struct UCPTrie
{
	public uint16* index;
	public UCPTrieData data;
	public int32 indexLength;
	public int32 dataLength;
	public int32 highStart;
	public uint16 shifted12HighStart;
	public int8 type;
	public int8 valueWidth;
	public uint32 reserved32;
	public uint16 reserved16;
	public uint16 index3NullOffset;
	public int32 dataNullOffset;
	public uint32 nullValue;
}

[CRepr]
public struct UMutableCPTrie
{
}

[CRepr]
public struct UConverter
{
}

[CRepr]
public struct UConverterFromUnicodeArgs
{
	public uint16 size;
	public int8 flush;
	public UConverter* converter;
	public uint16* source;
	public uint16* sourceLimit;
	public PSTR target;
	public PSTR targetLimit;
	public int32* offsets;
}

[CRepr]
public struct UConverterToUnicodeArgs
{
	public uint16 size;
	public int8 flush;
	public UConverter* converter;
	public PSTR source;
	public PSTR sourceLimit;
	public uint16* target;
	public uint16* targetLimit;
	public int32* offsets;
}

[CRepr]
public struct USet
{
}

[CRepr]
public struct UBiDi
{
}

[CRepr]
public struct UBiDiTransform
{
}

[CRepr]
public struct UTextFuncs
{
	public int32 tableSize;
	public int32 reserved1;
	public int32 reserved2;
	public int32 reserved3;
	public UTextClone clone;
	public UTextNativeLength nativeLength;
	public UTextAccess access;
	public UTextExtract extract;
	public UTextReplace replace;
	public UTextCopy copy;
	public UTextMapOffsetToNative mapOffsetToNative;
	public UTextMapNativeIndexToUTF16 mapNativeIndexToUTF16;
	public UTextClose close;
	public UTextClose spare1;
	public UTextClose spare2;
	public UTextClose spare3;
}

[CRepr]
public struct UText
{
	public uint32 magic;
	public int32 flags;
	public int32 providerProperties;
	public int32 sizeOfStruct;
	public int64 chunkNativeLimit;
	public int32 extraSize;
	public int32 nativeIndexingLimit;
	public int64 chunkNativeStart;
	public int32 chunkOffset;
	public int32 chunkLength;
	public uint16* chunkContents;
	public UTextFuncs* pFuncs;
	public void* pExtra;
	public void* context;
	public void* p;
	public void* q;
	public void* r;
	public void* privP;
	public int64 a;
	public int32 b;
	public int32 c;
	public int64 privA;
	public int32 privB;
	public int32 privC;
}

[CRepr]
public struct USerializedSet
{
	public uint16* array;
	public int32 bmpLength;
	public int32 length;
	public uint16[8] staticArray;
}

[CRepr]
public struct UNormalizer2
{
}

[CRepr]
public struct UConverterSelector
{
}

[CRepr]
public struct UBreakIterator
{
}

[CRepr]
public struct UCaseMap
{
}

[CRepr]
public struct UParseError
{
	public int32 line;
	public int32 offset;
	public uint16[16] preContext;
	public uint16[16] postContext;
}

[CRepr]
public struct UStringPrepProfile
{
}

[CRepr]
public struct UIDNA
{
}

[CRepr]
public struct UIDNAInfo
{
	public int16 size;
	public int8 isTransitionalDifferent;
	public int8 reservedB3;
	public uint32 errors;
	public int32 reservedI2;
	public int32 reservedI3;
}

[CRepr]
public struct UCollator
{
}

[CRepr]
public struct UCollationElements
{
}

[CRepr]
public struct UCharsetDetector
{
}

[CRepr]
public struct UCharsetMatch
{
}

[CRepr]
public struct UFieldPositionIterator
{
}

[CRepr]
public struct UConstrainedFieldPosition
{
}

[CRepr]
public struct UFormattedValue
{
}

[CRepr]
public struct UDateIntervalFormat
{
}

[CRepr]
public struct UFormattedDateInterval
{
}

[CRepr]
public struct UGenderInfo
{
}

[CRepr]
public struct UListFormatter
{
}

[CRepr]
public struct UFormattedList
{
}

[CRepr]
public struct ULocaleData
{
}

[CRepr]
public struct UDateFormatSymbols
{
}

[CRepr]
public struct UNumberFormatter
{
}

[CRepr]
public struct UFormattedNumber
{
}

[CRepr]
public struct UNumberingSystem
{
}

[CRepr]
public struct UFormattedNumberRange
{
}

[CRepr]
public struct UPluralRules
{
}

[CRepr]
public struct URegularExpression
{
}

[CRepr]
public struct URegion
{
}

[CRepr]
public struct URelativeDateTimeFormatter
{
}

[CRepr]
public struct UFormattedRelativeDateTime
{
}

[CRepr]
public struct UStringSearch
{
}

[CRepr]
public struct USpoofChecker
{
}

[CRepr]
public struct USpoofCheckResult
{
}

[CRepr]
public struct UTransPosition
{
	public int32 contextStart;
	public int32 contextLimit;
	public int32 start;
	public int32 limit;
}

[CRepr]
public struct UHashtable
{
}

[CRepr]
public struct USearch
{
}

[CRepr]
public struct MIMECPINFO
{
	public uint32 dwFlags;
	public uint32 uiCodePage;
	public uint32 uiFamilyCodePage;
	public char16[64] wszDescription;
	public char16[50] wszWebCharset;
	public char16[50] wszHeaderCharset;
	public char16[50] wszBodyCharset;
	public char16[32] wszFixedWidthFont;
	public char16[32] wszProportionalFont;
	public uint8 bGDICharset;
}

[CRepr]
public struct MIMECSETINFO
{
	public uint32 uiCodePage;
	public uint32 uiInternetEncoding;
	public char16[50] wszCharset;
}

[CRepr]
public struct RFC1766INFO
{
	public uint32 lcid;
	public char16[6] wszRfc1766;
	public char16[32] wszLocaleName;
}

[CRepr]
public struct SCRIPTINFO
{
	public uint8 ScriptId;
	public uint32 uiCodePage;
	public char16[48] wszDescription;
	public char16[32] wszFixedWidthFont;
	public char16[32] wszProportionalFont;
}

[CRepr]
public struct DetectEncodingInfo
{
	public uint32 nLangID;
	public uint32 nCodePage;
	public int32 nDocPercent;
	public int32 nConfidence;
}

[CRepr]
public struct SCRIPTFONTINFO
{
	public int64 scripts;
	public char16[32] wszFont;
}

[CRepr]
public struct UNICODERANGE
{
	public char16 wcFrom;
	public char16 wcTo;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_SpellCheckerFactory = .(0x7ab36653, 0x1796, 0x484b, 0xbd, 0xfa, 0xe7, 0x4f, 0x1d, 0xb7, 0xc1, 0xdc);


	public const Guid CLSID_CMLangString = .(0xc04d65cf, 0xb70d, 0x11d0, 0xb1, 0x88, 0x00, 0xaa, 0x00, 0x38, 0xc9, 0x69);


	public const Guid CLSID_CMLangConvertCharset = .(0xd66d6f99, 0xcdaa, 0x11d0, 0xb8, 0x22, 0x00, 0xc0, 0x4f, 0xc9, 0xb3, 0x1f);


	public const Guid CLSID_CMultiLanguage = .(0x275c23e2, 0x3747, 0x11d0, 0x9f, 0xea, 0x00, 0xaa, 0x00, 0x3f, 0x86, 0x46);


}
#endregion

#region COM Types
[CRepr]struct ISpellingError : IUnknown
{
	public new const Guid IID = .(0xb7c82d61, 0xfbe8, 0x4b47, 0x9b, 0x27, 0x6c, 0x0d, 0x2e, 0x0d, 0xe0, 0xa3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* value) get_StartIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* value) get_Length;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CORRECTIVE_ACTION* value) get_CorrectiveAction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* value) get_Replacement;
	}


	public HRESULT get_StartIndex(uint32* value) mut => VT.[Friend]get_StartIndex(&this, value);

	public HRESULT get_Length(uint32* value) mut => VT.[Friend]get_Length(&this, value);

	public HRESULT get_CorrectiveAction(CORRECTIVE_ACTION* value) mut => VT.[Friend]get_CorrectiveAction(&this, value);

	public HRESULT get_Replacement(PWSTR* value) mut => VT.[Friend]get_Replacement(&this, value);
}

[CRepr]struct IEnumSpellingError : IUnknown
{
	public new const Guid IID = .(0x803e3bd4, 0x2828, 0x4410, 0x82, 0x90, 0x41, 0x8d, 0x1d, 0x73, 0xc7, 0x62);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpellingError** value) Next;
	}


	public HRESULT Next(ISpellingError** value) mut => VT.[Friend]Next(&this, value);
}

[CRepr]struct IOptionDescription : IUnknown
{
	public new const Guid IID = .(0x432e5f85, 0x35cf, 0x4606, 0xa8, 0x01, 0x6f, 0x70, 0x27, 0x7e, 0x1d, 0x7a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* value) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* value) get_Heading;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* value) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumString** value) get_Labels;
	}


	public HRESULT get_Id(PWSTR* value) mut => VT.[Friend]get_Id(&this, value);

	public HRESULT get_Heading(PWSTR* value) mut => VT.[Friend]get_Heading(&this, value);

	public HRESULT get_Description(PWSTR* value) mut => VT.[Friend]get_Description(&this, value);

	public HRESULT get_Labels(IEnumString** value) mut => VT.[Friend]get_Labels(&this, value);
}

[CRepr]struct ISpellCheckerChangedEventHandler : IUnknown
{
	public new const Guid IID = .(0x0b83a5b0, 0x792f, 0x4eab, 0x97, 0x99, 0xac, 0xf5, 0x2c, 0x5e, 0xd0, 0x8a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpellChecker* sender) Invoke;
	}


	public HRESULT Invoke(ISpellChecker* sender) mut => VT.[Friend]Invoke(&this, sender);
}

[CRepr]struct ISpellChecker : IUnknown
{
	public new const Guid IID = .(0xb6fd0b71, 0xe2bc, 0x4653, 0x8d, 0x05, 0xf1, 0x97, 0xe4, 0x12, 0x77, 0x0b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* value) get_LanguageTag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR text, IEnumSpellingError** value) Check;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR word, IEnumString** value) Suggest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR word) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR word) Ignore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR from, PWSTR to) AutoCorrect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR optionId, uint8* value) GetOptionValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumString** value) get_OptionIds;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* value) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* value) get_LocalizedName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpellCheckerChangedEventHandler* handler, uint32* eventCookie) add_SpellCheckerChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 eventCookie) remove_SpellCheckerChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR optionId, IOptionDescription** value) GetOptionDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR text, IEnumSpellingError** value) ComprehensiveCheck;
	}


	public HRESULT get_LanguageTag(PWSTR* value) mut => VT.[Friend]get_LanguageTag(&this, value);

	public HRESULT Check(PWSTR text, IEnumSpellingError** value) mut => VT.[Friend]Check(&this, text, value);

	public HRESULT Suggest(PWSTR word, IEnumString** value) mut => VT.[Friend]Suggest(&this, word, value);

	public HRESULT Add(PWSTR word) mut => VT.[Friend]Add(&this, word);

	public HRESULT Ignore(PWSTR word) mut => VT.[Friend]Ignore(&this, word);

	public HRESULT AutoCorrect(PWSTR from, PWSTR to) mut => VT.[Friend]AutoCorrect(&this, from, to);

	public HRESULT GetOptionValue(PWSTR optionId, uint8* value) mut => VT.[Friend]GetOptionValue(&this, optionId, value);

	public HRESULT get_OptionIds(IEnumString** value) mut => VT.[Friend]get_OptionIds(&this, value);

	public HRESULT get_Id(PWSTR* value) mut => VT.[Friend]get_Id(&this, value);

	public HRESULT get_LocalizedName(PWSTR* value) mut => VT.[Friend]get_LocalizedName(&this, value);

	public HRESULT add_SpellCheckerChanged(ISpellCheckerChangedEventHandler* handler, uint32* eventCookie) mut => VT.[Friend]add_SpellCheckerChanged(&this, handler, eventCookie);

	public HRESULT remove_SpellCheckerChanged(uint32 eventCookie) mut => VT.[Friend]remove_SpellCheckerChanged(&this, eventCookie);

	public HRESULT GetOptionDescription(PWSTR optionId, IOptionDescription** value) mut => VT.[Friend]GetOptionDescription(&this, optionId, value);

	public HRESULT ComprehensiveCheck(PWSTR text, IEnumSpellingError** value) mut => VT.[Friend]ComprehensiveCheck(&this, text, value);
}

[CRepr]struct ISpellChecker2 : ISpellChecker
{
	public new const Guid IID = .(0xe7ed1c71, 0x87f7, 0x4378, 0xa8, 0x40, 0xc9, 0x20, 0x0d, 0xac, 0xee, 0x47);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISpellChecker.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR word) Remove;
	}


	public HRESULT Remove(PWSTR word) mut => VT.[Friend]Remove(&this, word);
}

[CRepr]struct ISpellCheckerFactory : IUnknown
{
	public new const Guid IID = .(0x8e018a9d, 0x2415, 0x4677, 0xbf, 0x08, 0x79, 0x4e, 0xa6, 0x1f, 0x94, 0xbb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumString** value) get_SupportedLanguages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR languageTag, BOOL* value) IsSupported;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR languageTag, ISpellChecker** value) CreateSpellChecker;
	}


	public HRESULT get_SupportedLanguages(IEnumString** value) mut => VT.[Friend]get_SupportedLanguages(&this, value);

	public HRESULT IsSupported(PWSTR languageTag, BOOL* value) mut => VT.[Friend]IsSupported(&this, languageTag, value);

	public HRESULT CreateSpellChecker(PWSTR languageTag, ISpellChecker** value) mut => VT.[Friend]CreateSpellChecker(&this, languageTag, value);
}

[CRepr]struct IUserDictionariesRegistrar : IUnknown
{
	public new const Guid IID = .(0xaa176b85, 0x0e12, 0x4844, 0x8e, 0x1a, 0xee, 0xf1, 0xda, 0x77, 0xf5, 0x86);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR dictionaryPath, PWSTR languageTag) RegisterUserDictionary;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR dictionaryPath, PWSTR languageTag) UnregisterUserDictionary;
	}


	public HRESULT RegisterUserDictionary(PWSTR dictionaryPath, PWSTR languageTag) mut => VT.[Friend]RegisterUserDictionary(&this, dictionaryPath, languageTag);

	public HRESULT UnregisterUserDictionary(PWSTR dictionaryPath, PWSTR languageTag) mut => VT.[Friend]UnregisterUserDictionary(&this, dictionaryPath, languageTag);
}

[CRepr]struct ISpellCheckProvider : IUnknown
{
	public new const Guid IID = .(0x73e976e0, 0x8ed4, 0x4eb1, 0x80, 0xd7, 0x1b, 0xe0, 0xa1, 0x6b, 0x0c, 0x38);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* value) get_LanguageTag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR text, IEnumSpellingError** value) Check;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR word, IEnumString** value) Suggest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR optionId, uint8* value) GetOptionValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR optionId, uint8 value) SetOptionValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumString** value) get_OptionIds;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* value) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* value) get_LocalizedName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR optionId, IOptionDescription** value) GetOptionDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WORDLIST_TYPE wordlistType, IEnumString* words) InitializeWordlist;
	}


	public HRESULT get_LanguageTag(PWSTR* value) mut => VT.[Friend]get_LanguageTag(&this, value);

	public HRESULT Check(PWSTR text, IEnumSpellingError** value) mut => VT.[Friend]Check(&this, text, value);

	public HRESULT Suggest(PWSTR word, IEnumString** value) mut => VT.[Friend]Suggest(&this, word, value);

	public HRESULT GetOptionValue(PWSTR optionId, uint8* value) mut => VT.[Friend]GetOptionValue(&this, optionId, value);

	public HRESULT SetOptionValue(PWSTR optionId, uint8 value) mut => VT.[Friend]SetOptionValue(&this, optionId, value);

	public HRESULT get_OptionIds(IEnumString** value) mut => VT.[Friend]get_OptionIds(&this, value);

	public HRESULT get_Id(PWSTR* value) mut => VT.[Friend]get_Id(&this, value);

	public HRESULT get_LocalizedName(PWSTR* value) mut => VT.[Friend]get_LocalizedName(&this, value);

	public HRESULT GetOptionDescription(PWSTR optionId, IOptionDescription** value) mut => VT.[Friend]GetOptionDescription(&this, optionId, value);

	public HRESULT InitializeWordlist(WORDLIST_TYPE wordlistType, IEnumString* words) mut => VT.[Friend]InitializeWordlist(&this, wordlistType, words);
}

[CRepr]struct IComprehensiveSpellCheckProvider : IUnknown
{
	public new const Guid IID = .(0x0c58f8de, 0x8e94, 0x479e, 0x97, 0x17, 0x70, 0xc4, 0x2c, 0x4a, 0xd2, 0xc3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR text, IEnumSpellingError** value) ComprehensiveCheck;
	}


	public HRESULT ComprehensiveCheck(PWSTR text, IEnumSpellingError** value) mut => VT.[Friend]ComprehensiveCheck(&this, text, value);
}

[CRepr]struct ISpellCheckProviderFactory : IUnknown
{
	public new const Guid IID = .(0x9f671e11, 0x77d6, 0x4c92, 0xae, 0xfb, 0x61, 0x52, 0x15, 0xe3, 0xa4, 0xbe);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumString** value) get_SupportedLanguages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR languageTag, BOOL* value) IsSupported;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR languageTag, ISpellCheckProvider** value) CreateSpellCheckProvider;
	}


	public HRESULT get_SupportedLanguages(IEnumString** value) mut => VT.[Friend]get_SupportedLanguages(&this, value);

	public HRESULT IsSupported(PWSTR languageTag, BOOL* value) mut => VT.[Friend]IsSupported(&this, languageTag, value);

	public HRESULT CreateSpellCheckProvider(PWSTR languageTag, ISpellCheckProvider** value) mut => VT.[Friend]CreateSpellCheckProvider(&this, languageTag, value);
}

[CRepr]struct IMLangStringBufW : IUnknown
{
	public new const Guid IID = .(0xd24acd21, 0xba72, 0x11d0, 0xb1, 0x88, 0x00, 0xaa, 0x00, 0x38, 0xc9, 0x69);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plFlags, int32* pcchBuf) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cchOffset, int32 cchMaxLock, uint16** ppszBuf, int32* pcchBuf) LockBuf;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszBuf, int32 cchOffset, int32 cchWrite) UnlockBuf;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cchOffset, int32 cchMaxInsert, int32* pcchActual) Insert;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cchOffset, int32 cchDelete) Delete;
	}


	public HRESULT GetStatus(int32* plFlags, int32* pcchBuf) mut => VT.[Friend]GetStatus(&this, plFlags, pcchBuf);

	public HRESULT LockBuf(int32 cchOffset, int32 cchMaxLock, uint16** ppszBuf, int32* pcchBuf) mut => VT.[Friend]LockBuf(&this, cchOffset, cchMaxLock, ppszBuf, pcchBuf);

	public HRESULT UnlockBuf(PWSTR pszBuf, int32 cchOffset, int32 cchWrite) mut => VT.[Friend]UnlockBuf(&this, pszBuf, cchOffset, cchWrite);

	public HRESULT Insert(int32 cchOffset, int32 cchMaxInsert, int32* pcchActual) mut => VT.[Friend]Insert(&this, cchOffset, cchMaxInsert, pcchActual);

	public HRESULT Delete(int32 cchOffset, int32 cchDelete) mut => VT.[Friend]Delete(&this, cchOffset, cchDelete);
}

[CRepr]struct IMLangStringBufA : IUnknown
{
	public new const Guid IID = .(0xd24acd23, 0xba72, 0x11d0, 0xb1, 0x88, 0x00, 0xaa, 0x00, 0x38, 0xc9, 0x69);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plFlags, int32* pcchBuf) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cchOffset, int32 cchMaxLock, CHAR** ppszBuf, int32* pcchBuf) LockBuf;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR pszBuf, int32 cchOffset, int32 cchWrite) UnlockBuf;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cchOffset, int32 cchMaxInsert, int32* pcchActual) Insert;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cchOffset, int32 cchDelete) Delete;
	}


	public HRESULT GetStatus(int32* plFlags, int32* pcchBuf) mut => VT.[Friend]GetStatus(&this, plFlags, pcchBuf);

	public HRESULT LockBuf(int32 cchOffset, int32 cchMaxLock, CHAR** ppszBuf, int32* pcchBuf) mut => VT.[Friend]LockBuf(&this, cchOffset, cchMaxLock, ppszBuf, pcchBuf);

	public HRESULT UnlockBuf(PSTR pszBuf, int32 cchOffset, int32 cchWrite) mut => VT.[Friend]UnlockBuf(&this, pszBuf, cchOffset, cchWrite);

	public HRESULT Insert(int32 cchOffset, int32 cchMaxInsert, int32* pcchActual) mut => VT.[Friend]Insert(&this, cchOffset, cchMaxInsert, pcchActual);

	public HRESULT Delete(int32 cchOffset, int32 cchDelete) mut => VT.[Friend]Delete(&this, cchOffset, cchDelete);
}

[CRepr]struct IMLangString : IUnknown
{
	public new const Guid IID = .(0xc04d65ce, 0xb70d, 0x11d0, 0xb1, 0x88, 0x00, 0xaa, 0x00, 0x38, 0xc9, 0x69);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fNoAccess) Sync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plLen) GetLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lDestPos, int32 lDestLen, IUnknown* pSrcMLStr, int32 lSrcPos, int32 lSrcLen) SetMLStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lSrcPos, int32 lSrcLen, IUnknown* pUnkOuter, uint32 dwClsContext, in Guid piid, IUnknown** ppDestMLStr, int32* plDestPos, int32* plDestLen) GetMLStr;
	}


	public HRESULT Sync(BOOL fNoAccess) mut => VT.[Friend]Sync(&this, fNoAccess);

	public HRESULT GetLength(int32* plLen) mut => VT.[Friend]GetLength(&this, plLen);

	public HRESULT SetMLStr(int32 lDestPos, int32 lDestLen, IUnknown* pSrcMLStr, int32 lSrcPos, int32 lSrcLen) mut => VT.[Friend]SetMLStr(&this, lDestPos, lDestLen, pSrcMLStr, lSrcPos, lSrcLen);

	public HRESULT GetMLStr(int32 lSrcPos, int32 lSrcLen, IUnknown* pUnkOuter, uint32 dwClsContext, in Guid piid, IUnknown** ppDestMLStr, int32* plDestPos, int32* plDestLen) mut => VT.[Friend]GetMLStr(&this, lSrcPos, lSrcLen, pUnkOuter, dwClsContext, piid, ppDestMLStr, plDestPos, plDestLen);
}

[CRepr]struct IMLangStringWStr : IMLangString
{
	public new const Guid IID = .(0xc04d65d0, 0xb70d, 0x11d0, 0xb1, 0x88, 0x00, 0xaa, 0x00, 0x38, 0xc9, 0x69);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMLangString.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lDestPos, int32 lDestLen, char16* pszSrc, int32 cchSrc, int32* pcchActual, int32* plActualLen) SetWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lDestPos, int32 lDestLen, IMLangStringBufW* pSrcBuf, int32* pcchActual, int32* plActualLen) SetStrBufW;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lSrcPos, int32 lSrcLen, char16* pszDest, int32 cchDest, int32* pcchActual, int32* plActualLen) GetWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lSrcPos, int32 lSrcMaxLen, IMLangStringBufW** ppDestBuf, int32* plDestLen) GetStrBufW;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lSrcPos, int32 lSrcLen, int32 lFlags, int32 cchRequest, PWSTR* ppszDest, int32* pcchDest, int32* plDestLen) LockWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszSrc, int32 cchSrc, int32* pcchActual, int32* plActualLen) UnlockWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lDestPos, int32 lDestLen, uint32 locale) SetLocale;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lSrcPos, int32 lSrcMaxLen, uint32* plocale, int32* plLocalePos, int32* plLocaleLen) GetLocale;
	}


	public HRESULT SetWStr(int32 lDestPos, int32 lDestLen, char16* pszSrc, int32 cchSrc, int32* pcchActual, int32* plActualLen) mut => VT.[Friend]SetWStr(&this, lDestPos, lDestLen, pszSrc, cchSrc, pcchActual, plActualLen);

	public HRESULT SetStrBufW(int32 lDestPos, int32 lDestLen, IMLangStringBufW* pSrcBuf, int32* pcchActual, int32* plActualLen) mut => VT.[Friend]SetStrBufW(&this, lDestPos, lDestLen, pSrcBuf, pcchActual, plActualLen);

	public HRESULT GetWStr(int32 lSrcPos, int32 lSrcLen, char16* pszDest, int32 cchDest, int32* pcchActual, int32* plActualLen) mut => VT.[Friend]GetWStr(&this, lSrcPos, lSrcLen, pszDest, cchDest, pcchActual, plActualLen);

	public HRESULT GetStrBufW(int32 lSrcPos, int32 lSrcMaxLen, IMLangStringBufW** ppDestBuf, int32* plDestLen) mut => VT.[Friend]GetStrBufW(&this, lSrcPos, lSrcMaxLen, ppDestBuf, plDestLen);

	public HRESULT LockWStr(int32 lSrcPos, int32 lSrcLen, int32 lFlags, int32 cchRequest, PWSTR* ppszDest, int32* pcchDest, int32* plDestLen) mut => VT.[Friend]LockWStr(&this, lSrcPos, lSrcLen, lFlags, cchRequest, ppszDest, pcchDest, plDestLen);

	public HRESULT UnlockWStr(char16* pszSrc, int32 cchSrc, int32* pcchActual, int32* plActualLen) mut => VT.[Friend]UnlockWStr(&this, pszSrc, cchSrc, pcchActual, plActualLen);

	public HRESULT SetLocale(int32 lDestPos, int32 lDestLen, uint32 locale) mut => VT.[Friend]SetLocale(&this, lDestPos, lDestLen, locale);

	public HRESULT GetLocale(int32 lSrcPos, int32 lSrcMaxLen, uint32* plocale, int32* plLocalePos, int32* plLocaleLen) mut => VT.[Friend]GetLocale(&this, lSrcPos, lSrcMaxLen, plocale, plLocalePos, plLocaleLen);
}

[CRepr]struct IMLangStringAStr : IMLangString
{
	public new const Guid IID = .(0xc04d65d2, 0xb70d, 0x11d0, 0xb1, 0x88, 0x00, 0xaa, 0x00, 0x38, 0xc9, 0x69);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMLangString.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lDestPos, int32 lDestLen, uint32 uCodePage, uint8* pszSrc, int32 cchSrc, int32* pcchActual, int32* plActualLen) SetAStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lDestPos, int32 lDestLen, uint32 uCodePage, IMLangStringBufA* pSrcBuf, int32* pcchActual, int32* plActualLen) SetStrBufA;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lSrcPos, int32 lSrcLen, uint32 uCodePageIn, uint32* puCodePageOut, uint8* pszDest, int32 cchDest, int32* pcchActual, int32* plActualLen) GetAStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lSrcPos, int32 lSrcMaxLen, uint32* puDestCodePage, IMLangStringBufA** ppDestBuf, int32* plDestLen) GetStrBufA;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lSrcPos, int32 lSrcLen, int32 lFlags, uint32 uCodePageIn, int32 cchRequest, uint32* puCodePageOut, PSTR* ppszDest, int32* pcchDest, int32* plDestLen) LockAStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pszSrc, int32 cchSrc, int32* pcchActual, int32* plActualLen) UnlockAStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lDestPos, int32 lDestLen, uint32 locale) SetLocale;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lSrcPos, int32 lSrcMaxLen, uint32* plocale, int32* plLocalePos, int32* plLocaleLen) GetLocale;
	}


	public HRESULT SetAStr(int32 lDestPos, int32 lDestLen, uint32 uCodePage, uint8* pszSrc, int32 cchSrc, int32* pcchActual, int32* plActualLen) mut => VT.[Friend]SetAStr(&this, lDestPos, lDestLen, uCodePage, pszSrc, cchSrc, pcchActual, plActualLen);

	public HRESULT SetStrBufA(int32 lDestPos, int32 lDestLen, uint32 uCodePage, IMLangStringBufA* pSrcBuf, int32* pcchActual, int32* plActualLen) mut => VT.[Friend]SetStrBufA(&this, lDestPos, lDestLen, uCodePage, pSrcBuf, pcchActual, plActualLen);

	public HRESULT GetAStr(int32 lSrcPos, int32 lSrcLen, uint32 uCodePageIn, uint32* puCodePageOut, uint8* pszDest, int32 cchDest, int32* pcchActual, int32* plActualLen) mut => VT.[Friend]GetAStr(&this, lSrcPos, lSrcLen, uCodePageIn, puCodePageOut, pszDest, cchDest, pcchActual, plActualLen);

	public HRESULT GetStrBufA(int32 lSrcPos, int32 lSrcMaxLen, uint32* puDestCodePage, IMLangStringBufA** ppDestBuf, int32* plDestLen) mut => VT.[Friend]GetStrBufA(&this, lSrcPos, lSrcMaxLen, puDestCodePage, ppDestBuf, plDestLen);

	public HRESULT LockAStr(int32 lSrcPos, int32 lSrcLen, int32 lFlags, uint32 uCodePageIn, int32 cchRequest, uint32* puCodePageOut, PSTR* ppszDest, int32* pcchDest, int32* plDestLen) mut => VT.[Friend]LockAStr(&this, lSrcPos, lSrcLen, lFlags, uCodePageIn, cchRequest, puCodePageOut, ppszDest, pcchDest, plDestLen);

	public HRESULT UnlockAStr(uint8* pszSrc, int32 cchSrc, int32* pcchActual, int32* plActualLen) mut => VT.[Friend]UnlockAStr(&this, pszSrc, cchSrc, pcchActual, plActualLen);

	public HRESULT SetLocale(int32 lDestPos, int32 lDestLen, uint32 locale) mut => VT.[Friend]SetLocale(&this, lDestPos, lDestLen, locale);

	public HRESULT GetLocale(int32 lSrcPos, int32 lSrcMaxLen, uint32* plocale, int32* plLocalePos, int32* plLocaleLen) mut => VT.[Friend]GetLocale(&this, lSrcPos, lSrcMaxLen, plocale, plLocalePos, plLocaleLen);
}

[CRepr]struct IMLangLineBreakConsole : IUnknown
{
	public new const Guid IID = .(0xf5be2ee1, 0xbfd7, 0x11d0, 0xb1, 0x88, 0x00, 0xaa, 0x00, 0x38, 0xc9, 0x69);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMLangString* pSrcMLStr, int32 lSrcPos, int32 lSrcLen, int32 cMinColumns, int32 cMaxColumns, int32* plLineLen, int32* plSkipLen) BreakLineML;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 locale, char16* pszSrc, int32 cchSrc, int32 cMaxColumns, int32* pcchLine, int32* pcchSkip) BreakLineW;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 locale, uint32 uCodePage, uint8* pszSrc, int32 cchSrc, int32 cMaxColumns, int32* pcchLine, int32* pcchSkip) BreakLineA;
	}


	public HRESULT BreakLineML(IMLangString* pSrcMLStr, int32 lSrcPos, int32 lSrcLen, int32 cMinColumns, int32 cMaxColumns, int32* plLineLen, int32* plSkipLen) mut => VT.[Friend]BreakLineML(&this, pSrcMLStr, lSrcPos, lSrcLen, cMinColumns, cMaxColumns, plLineLen, plSkipLen);

	public HRESULT BreakLineW(uint32 locale, char16* pszSrc, int32 cchSrc, int32 cMaxColumns, int32* pcchLine, int32* pcchSkip) mut => VT.[Friend]BreakLineW(&this, locale, pszSrc, cchSrc, cMaxColumns, pcchLine, pcchSkip);

	public HRESULT BreakLineA(uint32 locale, uint32 uCodePage, uint8* pszSrc, int32 cchSrc, int32 cMaxColumns, int32* pcchLine, int32* pcchSkip) mut => VT.[Friend]BreakLineA(&this, locale, uCodePage, pszSrc, cchSrc, cMaxColumns, pcchLine, pcchSkip);
}

[CRepr]struct IEnumCodePage : IUnknown
{
	public new const Guid IID = .(0x275c23e3, 0x3747, 0x11d0, 0x9f, 0xea, 0x00, 0xaa, 0x00, 0x3f, 0x86, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumCodePage** ppEnum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, MIMECPINFO* rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
	}


	public HRESULT Clone(IEnumCodePage** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);

	public HRESULT Next(uint32 celt, MIMECPINFO* rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);
}

[CRepr]struct IEnumRfc1766 : IUnknown
{
	public new const Guid IID = .(0x3dc39d1d, 0xc030, 0x11d0, 0xb8, 0x1b, 0x00, 0xc0, 0x4f, 0xc9, 0xb3, 0x1f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumRfc1766** ppEnum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, RFC1766INFO* rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
	}


	public HRESULT Clone(IEnumRfc1766** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);

	public HRESULT Next(uint32 celt, RFC1766INFO* rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);
}

[CRepr]struct IEnumScript : IUnknown
{
	public new const Guid IID = .(0xae5f1430, 0x388b, 0x11d2, 0x83, 0x80, 0x00, 0xc0, 0x4f, 0x8f, 0x5d, 0xa1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumScript** ppEnum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, SCRIPTINFO* rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
	}


	public HRESULT Clone(IEnumScript** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);

	public HRESULT Next(uint32 celt, SCRIPTINFO* rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);
}

[CRepr]struct IMLangConvertCharset : IUnknown
{
	public new const Guid IID = .(0xd66d6f98, 0xcdaa, 0x11d0, 0xb8, 0x22, 0x00, 0xc0, 0x4f, 0xc9, 0xb3, 0x1f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiSrcCodePage, uint32 uiDstCodePage, uint32 dwProperty) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puiSrcCodePage) GetSourceCodePage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puiDstCodePage) GetDestinationCodePage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwProperty) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pSrcStr, uint32* pcSrcSize, uint8* pDstStr, uint32* pcDstSize) DoConversion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR pSrcStr, uint32* pcSrcSize, char16* pDstStr, uint32* pcDstSize) DoConversionToUnicode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pSrcStr, uint32* pcSrcSize, PSTR pDstStr, uint32* pcDstSize) DoConversionFromUnicode;
	}


	public HRESULT Initialize(uint32 uiSrcCodePage, uint32 uiDstCodePage, uint32 dwProperty) mut => VT.[Friend]Initialize(&this, uiSrcCodePage, uiDstCodePage, dwProperty);

	public HRESULT GetSourceCodePage(uint32* puiSrcCodePage) mut => VT.[Friend]GetSourceCodePage(&this, puiSrcCodePage);

	public HRESULT GetDestinationCodePage(uint32* puiDstCodePage) mut => VT.[Friend]GetDestinationCodePage(&this, puiDstCodePage);

	public HRESULT GetProperty(uint32* pdwProperty) mut => VT.[Friend]GetProperty(&this, pdwProperty);

	public HRESULT DoConversion(uint8* pSrcStr, uint32* pcSrcSize, uint8* pDstStr, uint32* pcDstSize) mut => VT.[Friend]DoConversion(&this, pSrcStr, pcSrcSize, pDstStr, pcDstSize);

	public HRESULT DoConversionToUnicode(PSTR pSrcStr, uint32* pcSrcSize, char16* pDstStr, uint32* pcDstSize) mut => VT.[Friend]DoConversionToUnicode(&this, pSrcStr, pcSrcSize, pDstStr, pcDstSize);

	public HRESULT DoConversionFromUnicode(char16* pSrcStr, uint32* pcSrcSize, PSTR pDstStr, uint32* pcDstSize) mut => VT.[Friend]DoConversionFromUnicode(&this, pSrcStr, pcSrcSize, pDstStr, pcDstSize);
}

[CRepr]struct IMultiLanguage : IUnknown
{
	public new const Guid IID = .(0x275c23e1, 0x3747, 0x11d0, 0x9f, 0xea, 0x00, 0xaa, 0x00, 0x3f, 0x86, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcCodePage) GetNumberOfCodePageInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiCodePage, MIMECPINFO* pCodePageInfo) GetCodePageInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiCodePage, uint32* puiFamilyCodePage) GetFamilyCodePage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 grfFlags, IEnumCodePage** ppEnumCodePage) EnumCodePages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Charset, MIMECSETINFO* pCharsetInfo) GetCharsetInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSrcEncoding, uint32 dwDstEncoding) IsConvertible;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwMode, uint32 dwSrcEncoding, uint32 dwDstEncoding, uint8* pSrcStr, uint32* pcSrcSize, uint8* pDstStr, uint32* pcDstSize) ConvertString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwMode, uint32 dwEncoding, PSTR pSrcStr, uint32* pcSrcSize, char16* pDstStr, uint32* pcDstSize) ConvertStringToUnicode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwMode, uint32 dwEncoding, char16* pSrcStr, uint32* pcSrcSize, PSTR pDstStr, uint32* pcDstSize) ConvertStringFromUnicode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ConvertStringReset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Locale, BSTR* pbstrRfc1766) GetRfc1766FromLcid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pLocale, BSTR bstrRfc1766) GetLcidFromRfc1766;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumRfc1766** ppEnumRfc1766) EnumRfc1766;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Locale, RFC1766INFO* pRfc1766Info) GetRfc1766Info;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiSrcCodePage, uint32 uiDstCodePage, uint32 dwProperty, IMLangConvertCharset** ppMLangConvertCharset) CreateConvertCharset;
	}


	public HRESULT GetNumberOfCodePageInfo(uint32* pcCodePage) mut => VT.[Friend]GetNumberOfCodePageInfo(&this, pcCodePage);

	public HRESULT GetCodePageInfo(uint32 uiCodePage, MIMECPINFO* pCodePageInfo) mut => VT.[Friend]GetCodePageInfo(&this, uiCodePage, pCodePageInfo);

	public HRESULT GetFamilyCodePage(uint32 uiCodePage, uint32* puiFamilyCodePage) mut => VT.[Friend]GetFamilyCodePage(&this, uiCodePage, puiFamilyCodePage);

	public HRESULT EnumCodePages(uint32 grfFlags, IEnumCodePage** ppEnumCodePage) mut => VT.[Friend]EnumCodePages(&this, grfFlags, ppEnumCodePage);

	public HRESULT GetCharsetInfo(BSTR Charset, MIMECSETINFO* pCharsetInfo) mut => VT.[Friend]GetCharsetInfo(&this, Charset, pCharsetInfo);

	public HRESULT IsConvertible(uint32 dwSrcEncoding, uint32 dwDstEncoding) mut => VT.[Friend]IsConvertible(&this, dwSrcEncoding, dwDstEncoding);

	public HRESULT ConvertString(uint32* pdwMode, uint32 dwSrcEncoding, uint32 dwDstEncoding, uint8* pSrcStr, uint32* pcSrcSize, uint8* pDstStr, uint32* pcDstSize) mut => VT.[Friend]ConvertString(&this, pdwMode, dwSrcEncoding, dwDstEncoding, pSrcStr, pcSrcSize, pDstStr, pcDstSize);

	public HRESULT ConvertStringToUnicode(uint32* pdwMode, uint32 dwEncoding, PSTR pSrcStr, uint32* pcSrcSize, char16* pDstStr, uint32* pcDstSize) mut => VT.[Friend]ConvertStringToUnicode(&this, pdwMode, dwEncoding, pSrcStr, pcSrcSize, pDstStr, pcDstSize);

	public HRESULT ConvertStringFromUnicode(uint32* pdwMode, uint32 dwEncoding, char16* pSrcStr, uint32* pcSrcSize, PSTR pDstStr, uint32* pcDstSize) mut => VT.[Friend]ConvertStringFromUnicode(&this, pdwMode, dwEncoding, pSrcStr, pcSrcSize, pDstStr, pcDstSize);

	public HRESULT ConvertStringReset() mut => VT.[Friend]ConvertStringReset(&this);

	public HRESULT GetRfc1766FromLcid(uint32 Locale, BSTR* pbstrRfc1766) mut => VT.[Friend]GetRfc1766FromLcid(&this, Locale, pbstrRfc1766);

	public HRESULT GetLcidFromRfc1766(uint32* pLocale, BSTR bstrRfc1766) mut => VT.[Friend]GetLcidFromRfc1766(&this, pLocale, bstrRfc1766);

	public HRESULT EnumRfc1766(IEnumRfc1766** ppEnumRfc1766) mut => VT.[Friend]EnumRfc1766(&this, ppEnumRfc1766);

	public HRESULT GetRfc1766Info(uint32 Locale, RFC1766INFO* pRfc1766Info) mut => VT.[Friend]GetRfc1766Info(&this, Locale, pRfc1766Info);

	public HRESULT CreateConvertCharset(uint32 uiSrcCodePage, uint32 uiDstCodePage, uint32 dwProperty, IMLangConvertCharset** ppMLangConvertCharset) mut => VT.[Friend]CreateConvertCharset(&this, uiSrcCodePage, uiDstCodePage, dwProperty, ppMLangConvertCharset);
}

[CRepr]struct IMultiLanguage2 : IUnknown
{
	public new const Guid IID = .(0xdccfc164, 0x2b38, 0x11d2, 0xb7, 0xec, 0x00, 0xc0, 0x4f, 0x8f, 0x5d, 0x9a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcCodePage) GetNumberOfCodePageInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiCodePage, uint16 LangId, MIMECPINFO* pCodePageInfo) GetCodePageInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiCodePage, uint32* puiFamilyCodePage) GetFamilyCodePage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 grfFlags, uint16 LangId, IEnumCodePage** ppEnumCodePage) EnumCodePages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Charset, MIMECSETINFO* pCharsetInfo) GetCharsetInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSrcEncoding, uint32 dwDstEncoding) IsConvertible;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwMode, uint32 dwSrcEncoding, uint32 dwDstEncoding, uint8* pSrcStr, uint32* pcSrcSize, uint8* pDstStr, uint32* pcDstSize) ConvertString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwMode, uint32 dwEncoding, PSTR pSrcStr, uint32* pcSrcSize, char16* pDstStr, uint32* pcDstSize) ConvertStringToUnicode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwMode, uint32 dwEncoding, char16* pSrcStr, uint32* pcSrcSize, PSTR pDstStr, uint32* pcDstSize) ConvertStringFromUnicode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ConvertStringReset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Locale, BSTR* pbstrRfc1766) GetRfc1766FromLcid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pLocale, BSTR bstrRfc1766) GetLcidFromRfc1766;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 LangId, IEnumRfc1766** ppEnumRfc1766) EnumRfc1766;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Locale, uint16 LangId, RFC1766INFO* pRfc1766Info) GetRfc1766Info;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiSrcCodePage, uint32 uiDstCodePage, uint32 dwProperty, IMLangConvertCharset** ppMLangConvertCharset) CreateConvertCharset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwMode, uint32 dwFlag, PWSTR lpFallBack, uint32 dwSrcEncoding, uint32 dwDstEncoding, IStream* pstmIn, IStream* pstmOut) ConvertStringInIStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwMode, uint32 dwEncoding, PSTR pSrcStr, uint32* pcSrcSize, char16* pDstStr, uint32* pcDstSize, uint32 dwFlag, PWSTR lpFallBack) ConvertStringToUnicodeEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwMode, uint32 dwEncoding, char16* pSrcStr, uint32* pcSrcSize, PSTR pDstStr, uint32* pcDstSize, uint32 dwFlag, PWSTR lpFallBack) ConvertStringFromUnicodeEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlag, uint32 dwPrefWinCodePage, IStream* pstmIn, DetectEncodingInfo* lpEncoding, int32* pnScores) DetectCodepageInIStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlag, uint32 dwPrefWinCodePage, PSTR pSrcStr, int32* pcSrcSize, DetectEncodingInfo* lpEncoding, int32* pnScores) DetectInputCodepage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiCodePage, HWND hwnd) ValidateCodePage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiCodePage, uint32 lcid, char16* lpWideCharStr, int32 cchWideChar) GetCodePageDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiCodePage) IsCodePageInstallable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MIMECONTF dwSource) SetMimeDBSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pnScripts) GetNumberOfScripts;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, uint16 LangId, IEnumScript** ppEnumScript) EnumScripts;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiCodePage, HWND hwnd, uint32 dwfIODControl) ValidateCodePageEx;
	}


	public HRESULT GetNumberOfCodePageInfo(uint32* pcCodePage) mut => VT.[Friend]GetNumberOfCodePageInfo(&this, pcCodePage);

	public HRESULT GetCodePageInfo(uint32 uiCodePage, uint16 LangId, MIMECPINFO* pCodePageInfo) mut => VT.[Friend]GetCodePageInfo(&this, uiCodePage, LangId, pCodePageInfo);

	public HRESULT GetFamilyCodePage(uint32 uiCodePage, uint32* puiFamilyCodePage) mut => VT.[Friend]GetFamilyCodePage(&this, uiCodePage, puiFamilyCodePage);

	public HRESULT EnumCodePages(uint32 grfFlags, uint16 LangId, IEnumCodePage** ppEnumCodePage) mut => VT.[Friend]EnumCodePages(&this, grfFlags, LangId, ppEnumCodePage);

	public HRESULT GetCharsetInfo(BSTR Charset, MIMECSETINFO* pCharsetInfo) mut => VT.[Friend]GetCharsetInfo(&this, Charset, pCharsetInfo);

	public HRESULT IsConvertible(uint32 dwSrcEncoding, uint32 dwDstEncoding) mut => VT.[Friend]IsConvertible(&this, dwSrcEncoding, dwDstEncoding);

	public HRESULT ConvertString(uint32* pdwMode, uint32 dwSrcEncoding, uint32 dwDstEncoding, uint8* pSrcStr, uint32* pcSrcSize, uint8* pDstStr, uint32* pcDstSize) mut => VT.[Friend]ConvertString(&this, pdwMode, dwSrcEncoding, dwDstEncoding, pSrcStr, pcSrcSize, pDstStr, pcDstSize);

	public HRESULT ConvertStringToUnicode(uint32* pdwMode, uint32 dwEncoding, PSTR pSrcStr, uint32* pcSrcSize, char16* pDstStr, uint32* pcDstSize) mut => VT.[Friend]ConvertStringToUnicode(&this, pdwMode, dwEncoding, pSrcStr, pcSrcSize, pDstStr, pcDstSize);

	public HRESULT ConvertStringFromUnicode(uint32* pdwMode, uint32 dwEncoding, char16* pSrcStr, uint32* pcSrcSize, PSTR pDstStr, uint32* pcDstSize) mut => VT.[Friend]ConvertStringFromUnicode(&this, pdwMode, dwEncoding, pSrcStr, pcSrcSize, pDstStr, pcDstSize);

	public HRESULT ConvertStringReset() mut => VT.[Friend]ConvertStringReset(&this);

	public HRESULT GetRfc1766FromLcid(uint32 Locale, BSTR* pbstrRfc1766) mut => VT.[Friend]GetRfc1766FromLcid(&this, Locale, pbstrRfc1766);

	public HRESULT GetLcidFromRfc1766(uint32* pLocale, BSTR bstrRfc1766) mut => VT.[Friend]GetLcidFromRfc1766(&this, pLocale, bstrRfc1766);

	public HRESULT EnumRfc1766(uint16 LangId, IEnumRfc1766** ppEnumRfc1766) mut => VT.[Friend]EnumRfc1766(&this, LangId, ppEnumRfc1766);

	public HRESULT GetRfc1766Info(uint32 Locale, uint16 LangId, RFC1766INFO* pRfc1766Info) mut => VT.[Friend]GetRfc1766Info(&this, Locale, LangId, pRfc1766Info);

	public HRESULT CreateConvertCharset(uint32 uiSrcCodePage, uint32 uiDstCodePage, uint32 dwProperty, IMLangConvertCharset** ppMLangConvertCharset) mut => VT.[Friend]CreateConvertCharset(&this, uiSrcCodePage, uiDstCodePage, dwProperty, ppMLangConvertCharset);

	public HRESULT ConvertStringInIStream(uint32* pdwMode, uint32 dwFlag, PWSTR lpFallBack, uint32 dwSrcEncoding, uint32 dwDstEncoding, IStream* pstmIn, IStream* pstmOut) mut => VT.[Friend]ConvertStringInIStream(&this, pdwMode, dwFlag, lpFallBack, dwSrcEncoding, dwDstEncoding, pstmIn, pstmOut);

	public HRESULT ConvertStringToUnicodeEx(uint32* pdwMode, uint32 dwEncoding, PSTR pSrcStr, uint32* pcSrcSize, char16* pDstStr, uint32* pcDstSize, uint32 dwFlag, PWSTR lpFallBack) mut => VT.[Friend]ConvertStringToUnicodeEx(&this, pdwMode, dwEncoding, pSrcStr, pcSrcSize, pDstStr, pcDstSize, dwFlag, lpFallBack);

	public HRESULT ConvertStringFromUnicodeEx(uint32* pdwMode, uint32 dwEncoding, char16* pSrcStr, uint32* pcSrcSize, PSTR pDstStr, uint32* pcDstSize, uint32 dwFlag, PWSTR lpFallBack) mut => VT.[Friend]ConvertStringFromUnicodeEx(&this, pdwMode, dwEncoding, pSrcStr, pcSrcSize, pDstStr, pcDstSize, dwFlag, lpFallBack);

	public HRESULT DetectCodepageInIStream(uint32 dwFlag, uint32 dwPrefWinCodePage, IStream* pstmIn, DetectEncodingInfo* lpEncoding, int32* pnScores) mut => VT.[Friend]DetectCodepageInIStream(&this, dwFlag, dwPrefWinCodePage, pstmIn, lpEncoding, pnScores);

	public HRESULT DetectInputCodepage(uint32 dwFlag, uint32 dwPrefWinCodePage, PSTR pSrcStr, int32* pcSrcSize, DetectEncodingInfo* lpEncoding, int32* pnScores) mut => VT.[Friend]DetectInputCodepage(&this, dwFlag, dwPrefWinCodePage, pSrcStr, pcSrcSize, lpEncoding, pnScores);

	public HRESULT ValidateCodePage(uint32 uiCodePage, HWND hwnd) mut => VT.[Friend]ValidateCodePage(&this, uiCodePage, hwnd);

	public HRESULT GetCodePageDescription(uint32 uiCodePage, uint32 lcid, char16* lpWideCharStr, int32 cchWideChar) mut => VT.[Friend]GetCodePageDescription(&this, uiCodePage, lcid, lpWideCharStr, cchWideChar);

	public HRESULT IsCodePageInstallable(uint32 uiCodePage) mut => VT.[Friend]IsCodePageInstallable(&this, uiCodePage);

	public HRESULT SetMimeDBSource(MIMECONTF dwSource) mut => VT.[Friend]SetMimeDBSource(&this, dwSource);

	public HRESULT GetNumberOfScripts(uint32* pnScripts) mut => VT.[Friend]GetNumberOfScripts(&this, pnScripts);

	public HRESULT EnumScripts(uint32 dwFlags, uint16 LangId, IEnumScript** ppEnumScript) mut => VT.[Friend]EnumScripts(&this, dwFlags, LangId, ppEnumScript);

	public HRESULT ValidateCodePageEx(uint32 uiCodePage, HWND hwnd, uint32 dwfIODControl) mut => VT.[Friend]ValidateCodePageEx(&this, uiCodePage, hwnd, dwfIODControl);
}

[CRepr]struct IMLangCodePages : IUnknown
{
	public new const Guid IID = .(0x359f3443, 0xbd4a, 0x11d0, 0xb1, 0x88, 0x00, 0xaa, 0x00, 0x38, 0xc9, 0x69);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16 chSrc, uint32* pdwCodePages) GetCharCodePages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszSrc, int32 cchSrc, uint32 dwPriorityCodePages, uint32* pdwCodePages, int32* pcchCodePages) GetStrCodePages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uCodePage, uint32* pdwCodePages) CodePageToCodePages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCodePages, uint32 uDefaultCodePage, uint32* puCodePage) CodePagesToCodePage;
	}


	public HRESULT GetCharCodePages(char16 chSrc, uint32* pdwCodePages) mut => VT.[Friend]GetCharCodePages(&this, chSrc, pdwCodePages);

	public HRESULT GetStrCodePages(char16* pszSrc, int32 cchSrc, uint32 dwPriorityCodePages, uint32* pdwCodePages, int32* pcchCodePages) mut => VT.[Friend]GetStrCodePages(&this, pszSrc, cchSrc, dwPriorityCodePages, pdwCodePages, pcchCodePages);

	public HRESULT CodePageToCodePages(uint32 uCodePage, uint32* pdwCodePages) mut => VT.[Friend]CodePageToCodePages(&this, uCodePage, pdwCodePages);

	public HRESULT CodePagesToCodePage(uint32 dwCodePages, uint32 uDefaultCodePage, uint32* puCodePage) mut => VT.[Friend]CodePagesToCodePage(&this, dwCodePages, uDefaultCodePage, puCodePage);
}

[CRepr]struct IMLangFontLink : IMLangCodePages
{
	public new const Guid IID = .(0x359f3441, 0xbd4a, 0x11d0, 0xb1, 0x88, 0x00, 0xaa, 0x00, 0x38, 0xc9, 0x69);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMLangCodePages.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC hDC, HFONT hFont, uint32* pdwCodePages) GetFontCodePages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC hDC, uint32 dwCodePages, HFONT hSrcFont, HFONT* phDestFont) MapFont;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HFONT hFont) ReleaseFont;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ResetFontMapping;
	}


	public HRESULT GetFontCodePages(HDC hDC, HFONT hFont, uint32* pdwCodePages) mut => VT.[Friend]GetFontCodePages(&this, hDC, hFont, pdwCodePages);

	public HRESULT MapFont(HDC hDC, uint32 dwCodePages, HFONT hSrcFont, HFONT* phDestFont) mut => VT.[Friend]MapFont(&this, hDC, dwCodePages, hSrcFont, phDestFont);

	public HRESULT ReleaseFont(HFONT hFont) mut => VT.[Friend]ReleaseFont(&this, hFont);

	public HRESULT ResetFontMapping() mut => VT.[Friend]ResetFontMapping(&this);
}

[CRepr]struct IMLangFontLink2 : IMLangCodePages
{
	public new const Guid IID = .(0xdccfc162, 0x2b38, 0x11d2, 0xb7, 0xec, 0x00, 0xc0, 0x4f, 0x8f, 0x5d, 0x9a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMLangCodePages.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC hDC, HFONT hFont, uint32* pdwCodePages) GetFontCodePages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HFONT hFont) ReleaseFont;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ResetFontMapping;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC hDC, uint32 dwCodePages, char16 chSrc, HFONT* pFont) MapFont;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC hDC, uint32* puiRanges, UNICODERANGE* pUranges) GetFontUnicodeRanges;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8 sid, uint32 dwFlags, uint32* puiFonts, SCRIPTFONTINFO* pScriptFont) GetScriptFontInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiCodePage, uint8* pSid) CodePageToScriptID;
	}


	public HRESULT GetFontCodePages(HDC hDC, HFONT hFont, uint32* pdwCodePages) mut => VT.[Friend]GetFontCodePages(&this, hDC, hFont, pdwCodePages);

	public HRESULT ReleaseFont(HFONT hFont) mut => VT.[Friend]ReleaseFont(&this, hFont);

	public HRESULT ResetFontMapping() mut => VT.[Friend]ResetFontMapping(&this);

	public HRESULT MapFont(HDC hDC, uint32 dwCodePages, char16 chSrc, HFONT* pFont) mut => VT.[Friend]MapFont(&this, hDC, dwCodePages, chSrc, pFont);

	public HRESULT GetFontUnicodeRanges(HDC hDC, uint32* puiRanges, UNICODERANGE* pUranges) mut => VT.[Friend]GetFontUnicodeRanges(&this, hDC, puiRanges, pUranges);

	public HRESULT GetScriptFontInfo(uint8 sid, uint32 dwFlags, uint32* puiFonts, SCRIPTFONTINFO* pScriptFont) mut => VT.[Friend]GetScriptFontInfo(&this, sid, dwFlags, puiFonts, pScriptFont);

	public HRESULT CodePageToScriptID(uint32 uiCodePage, uint8* pSid) mut => VT.[Friend]CodePageToScriptID(&this, uiCodePage, pSid);
}

[CRepr]struct IMultiLanguage3 : IMultiLanguage2
{
	public new const Guid IID = .(0x4e5868ab, 0xb157, 0x4623, 0x9a, 0xcc, 0x6a, 0x1d, 0x9c, 0xae, 0xbe, 0x04);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMultiLanguage2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, char16* lpWideCharStr, uint32 cchWideChar, uint32* puiPreferredCodePages, uint32 nPreferredCodePages, uint32* puiDetectedCodePages, uint32* pnDetectedCodePages, PWSTR lpSpecialChar) DetectOutboundCodePage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IStream* pStrIn, uint32* puiPreferredCodePages, uint32 nPreferredCodePages, uint32* puiDetectedCodePages, uint32* pnDetectedCodePages, PWSTR lpSpecialChar) DetectOutboundCodePageInIStream;
	}


	public HRESULT DetectOutboundCodePage(uint32 dwFlags, char16* lpWideCharStr, uint32 cchWideChar, uint32* puiPreferredCodePages, uint32 nPreferredCodePages, uint32* puiDetectedCodePages, uint32* pnDetectedCodePages, PWSTR lpSpecialChar) mut => VT.[Friend]DetectOutboundCodePage(&this, dwFlags, lpWideCharStr, cchWideChar, puiPreferredCodePages, nPreferredCodePages, puiDetectedCodePages, pnDetectedCodePages, lpSpecialChar);

	public HRESULT DetectOutboundCodePageInIStream(uint32 dwFlags, IStream* pStrIn, uint32* puiPreferredCodePages, uint32 nPreferredCodePages, uint32* puiDetectedCodePages, uint32* pnDetectedCodePages, PWSTR lpSpecialChar) mut => VT.[Friend]DetectOutboundCodePageInIStream(&this, dwFlags, pStrIn, puiPreferredCodePages, nPreferredCodePages, puiDetectedCodePages, pnDetectedCodePages, lpSpecialChar);
}

#endregion

#region Functions
public static
{
	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetTextCharset(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetTextCharsetInfo(HDC hdc, FONTSIGNATURE* lpSig, uint32 dwFlags);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TranslateCharsetInfo(uint32* lpSrc, CHARSETINFO* lpCs, TRANSLATE_CHARSET_INFO_FLAGS dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetDateFormatA(uint32 Locale, uint32 dwFlags, SYSTEMTIME* lpDate, PSTR lpFormat, uint8* lpDateStr, int32 cchDate);
	public static int32 GetDateFormat(uint32 Locale, uint32 dwFlags, SYSTEMTIME* lpDate, PSTR lpFormat, uint8* lpDateStr, int32 cchDate) => GetDateFormatA(Locale, dwFlags, lpDate, lpFormat, lpDateStr, cchDate);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetDateFormatW(uint32 Locale, uint32 dwFlags, SYSTEMTIME* lpDate, PWSTR lpFormat, char16* lpDateStr, int32 cchDate);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetTimeFormatA(uint32 Locale, uint32 dwFlags, SYSTEMTIME* lpTime, PSTR lpFormat, uint8* lpTimeStr, int32 cchTime);
	public static int32 GetTimeFormat(uint32 Locale, uint32 dwFlags, SYSTEMTIME* lpTime, PSTR lpFormat, uint8* lpTimeStr, int32 cchTime) => GetTimeFormatA(Locale, dwFlags, lpTime, lpFormat, lpTimeStr, cchTime);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetTimeFormatW(uint32 Locale, uint32 dwFlags, SYSTEMTIME* lpTime, PWSTR lpFormat, char16* lpTimeStr, int32 cchTime);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetTimeFormatEx(PWSTR lpLocaleName, TIME_FORMAT_FLAGS dwFlags, SYSTEMTIME* lpTime, PWSTR lpFormat, char16* lpTimeStr, int32 cchTime);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetDateFormatEx(PWSTR lpLocaleName, ENUM_DATE_FORMATS_FLAGS dwFlags, SYSTEMTIME* lpDate, PWSTR lpFormat, char16* lpDateStr, int32 cchDate, PWSTR lpCalendar);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetDurationFormatEx(PWSTR lpLocaleName, uint32 dwFlags, SYSTEMTIME* lpDuration, uint64 ullDuration, PWSTR lpFormat, char16* lpDurationStr, int32 cchDuration);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 CompareStringEx(PWSTR lpLocaleName, COMPARE_STRING_FLAGS dwCmpFlags, char16* lpString1, int32 cchCount1, char16* lpString2, int32 cchCount2, NLSVERSIONINFO* lpVersionInformation, void* lpReserved, LPARAM lParam);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 CompareStringOrdinal(char16* lpString1, int32 cchCount1, char16* lpString2, int32 cchCount2, BOOL bIgnoreCase);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 CompareStringW(uint32 Locale, uint32 dwCmpFlags, char16* lpString1, int32 cchCount1, char16* lpString2, int32 cchCount2);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 FoldStringW(FOLD_STRING_MAP_FLAGS dwMapFlags, char16* lpSrcStr, int32 cchSrc, char16* lpDestStr, int32 cchDest);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetStringTypeExW(uint32 Locale, uint32 dwInfoType, char16* lpSrcStr, int32 cchSrc, uint16* lpCharType);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetStringTypeW(uint32 dwInfoType, char16* lpSrcStr, int32 cchSrc, uint16* lpCharType);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 MultiByteToWideChar(uint32 CodePage, MULTI_BYTE_TO_WIDE_CHAR_FLAGS dwFlags, uint8* lpMultiByteStr, int32 cbMultiByte, char16* lpWideCharStr, int32 cchWideChar);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 WideCharToMultiByte(uint32 CodePage, uint32 dwFlags, char16* lpWideCharStr, int32 cchWideChar, PSTR lpMultiByteStr, int32 cbMultiByte, PSTR lpDefaultChar, int32* lpUsedDefaultChar);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsValidCodePage(uint32 CodePage);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetACP();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetOEMCP();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCPInfo(uint32 CodePage, CPINFO* lpCPInfo);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCPInfoExA(uint32 CodePage, uint32 dwFlags, CPINFOEXA* lpCPInfoEx);
	public static BOOL GetCPInfoEx(uint32 CodePage, uint32 dwFlags, CPINFOEXA* lpCPInfoEx) => GetCPInfoExA(CodePage, dwFlags, lpCPInfoEx);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCPInfoExW(uint32 CodePage, uint32 dwFlags, CPINFOEXW* lpCPInfoEx);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 CompareStringA(uint32 Locale, uint32 dwCmpFlags, int8* lpString1, int32 cchCount1, int8* lpString2, int32 cchCount2);
	public static int32 CompareString(uint32 Locale, uint32 dwCmpFlags, int8* lpString1, int32 cchCount1, int8* lpString2, int32 cchCount2) => CompareStringA(Locale, dwCmpFlags, lpString1, cchCount1, lpString2, cchCount2);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 FindNLSString(uint32 Locale, uint32 dwFindNLSStringFlags, char16* lpStringSource, int32 cchSource, char16* lpStringValue, int32 cchValue, int32* pcchFound);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 LCMapStringW(uint32 Locale, uint32 dwMapFlags, char16* lpSrcStr, int32 cchSrc, PWSTR lpDestStr, int32 cchDest);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 LCMapStringA(uint32 Locale, uint32 dwMapFlags, uint8* lpSrcStr, int32 cchSrc, PSTR lpDestStr, int32 cchDest);
	public static int32 LCMapString(uint32 Locale, uint32 dwMapFlags, uint8* lpSrcStr, int32 cchSrc, PSTR lpDestStr, int32 cchDest) => LCMapStringA(Locale, dwMapFlags, lpSrcStr, cchSrc, lpDestStr, cchDest);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetLocaleInfoW(uint32 Locale, uint32 LCType, char16* lpLCData, int32 cchData);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetLocaleInfoA(uint32 Locale, uint32 LCType, uint8* lpLCData, int32 cchData);
	public static int32 GetLocaleInfo(uint32 Locale, uint32 LCType, uint8* lpLCData, int32 cchData) => GetLocaleInfoA(Locale, LCType, lpLCData, cchData);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetLocaleInfoA(uint32 Locale, uint32 LCType, PSTR lpLCData);
	public static BOOL SetLocaleInfo(uint32 Locale, uint32 LCType, PSTR lpLCData) => SetLocaleInfoA(Locale, LCType, lpLCData);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetLocaleInfoW(uint32 Locale, uint32 LCType, PWSTR lpLCData);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetCalendarInfoA(uint32 Locale, uint32 Calendar, uint32 CalType, uint8* lpCalData, int32 cchData, uint32* lpValue);
	public static int32 GetCalendarInfo(uint32 Locale, uint32 Calendar, uint32 CalType, uint8* lpCalData, int32 cchData, uint32* lpValue) => GetCalendarInfoA(Locale, Calendar, CalType, lpCalData, cchData, lpValue);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetCalendarInfoW(uint32 Locale, uint32 Calendar, uint32 CalType, char16* lpCalData, int32 cchData, uint32* lpValue);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetCalendarInfoA(uint32 Locale, uint32 Calendar, uint32 CalType, PSTR lpCalData);
	public static BOOL SetCalendarInfo(uint32 Locale, uint32 Calendar, uint32 CalType, PSTR lpCalData) => SetCalendarInfoA(Locale, Calendar, CalType, lpCalData);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetCalendarInfoW(uint32 Locale, uint32 Calendar, uint32 CalType, PWSTR lpCalData);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsDBCSLeadByte(uint8 TestChar);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsDBCSLeadByteEx(uint32 CodePage, uint8 TestChar);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 LocaleNameToLCID(PWSTR lpName, uint32 dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 LCIDToLocaleName(uint32 Locale, char16* lpName, int32 cchName, uint32 dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetDurationFormat(uint32 Locale, uint32 dwFlags, SYSTEMTIME* lpDuration, uint64 ullDuration, PWSTR lpFormat, char16* lpDurationStr, int32 cchDuration);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetNumberFormatA(uint32 Locale, uint32 dwFlags, PSTR lpValue, NUMBERFMTA* lpFormat, uint8* lpNumberStr, int32 cchNumber);
	public static int32 GetNumberFormat(uint32 Locale, uint32 dwFlags, PSTR lpValue, NUMBERFMTA* lpFormat, uint8* lpNumberStr, int32 cchNumber) => GetNumberFormatA(Locale, dwFlags, lpValue, lpFormat, lpNumberStr, cchNumber);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetNumberFormatW(uint32 Locale, uint32 dwFlags, PWSTR lpValue, NUMBERFMTW* lpFormat, char16* lpNumberStr, int32 cchNumber);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetCurrencyFormatA(uint32 Locale, uint32 dwFlags, PSTR lpValue, CURRENCYFMTA* lpFormat, uint8* lpCurrencyStr, int32 cchCurrency);
	public static int32 GetCurrencyFormat(uint32 Locale, uint32 dwFlags, PSTR lpValue, CURRENCYFMTA* lpFormat, uint8* lpCurrencyStr, int32 cchCurrency) => GetCurrencyFormatA(Locale, dwFlags, lpValue, lpFormat, lpCurrencyStr, cchCurrency);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetCurrencyFormatW(uint32 Locale, uint32 dwFlags, PWSTR lpValue, CURRENCYFMTW* lpFormat, char16* lpCurrencyStr, int32 cchCurrency);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumCalendarInfoA(CALINFO_ENUMPROCA lpCalInfoEnumProc, uint32 Locale, uint32 Calendar, uint32 CalType);
	public static BOOL EnumCalendarInfo(CALINFO_ENUMPROCA lpCalInfoEnumProc, uint32 Locale, uint32 Calendar, uint32 CalType) => EnumCalendarInfoA(lpCalInfoEnumProc, Locale, Calendar, CalType);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumCalendarInfoW(CALINFO_ENUMPROCW lpCalInfoEnumProc, uint32 Locale, uint32 Calendar, uint32 CalType);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumCalendarInfoExA(CALINFO_ENUMPROCEXA lpCalInfoEnumProcEx, uint32 Locale, uint32 Calendar, uint32 CalType);
	public static BOOL EnumCalendarInfoEx(CALINFO_ENUMPROCEXA lpCalInfoEnumProcEx, uint32 Locale, uint32 Calendar, uint32 CalType) => EnumCalendarInfoExA(lpCalInfoEnumProcEx, Locale, Calendar, CalType);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumCalendarInfoExW(CALINFO_ENUMPROCEXW lpCalInfoEnumProcEx, uint32 Locale, uint32 Calendar, uint32 CalType);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumTimeFormatsA(TIMEFMT_ENUMPROCA lpTimeFmtEnumProc, uint32 Locale, TIME_FORMAT_FLAGS dwFlags);
	public static BOOL EnumTimeFormats(TIMEFMT_ENUMPROCA lpTimeFmtEnumProc, uint32 Locale, TIME_FORMAT_FLAGS dwFlags) => EnumTimeFormatsA(lpTimeFmtEnumProc, Locale, dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumTimeFormatsW(TIMEFMT_ENUMPROCW lpTimeFmtEnumProc, uint32 Locale, TIME_FORMAT_FLAGS dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumDateFormatsA(DATEFMT_ENUMPROCA lpDateFmtEnumProc, uint32 Locale, uint32 dwFlags);
	public static BOOL EnumDateFormats(DATEFMT_ENUMPROCA lpDateFmtEnumProc, uint32 Locale, uint32 dwFlags) => EnumDateFormatsA(lpDateFmtEnumProc, Locale, dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumDateFormatsW(DATEFMT_ENUMPROCW lpDateFmtEnumProc, uint32 Locale, uint32 dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumDateFormatsExA(DATEFMT_ENUMPROCEXA lpDateFmtEnumProcEx, uint32 Locale, uint32 dwFlags);
	public static BOOL EnumDateFormatsEx(DATEFMT_ENUMPROCEXA lpDateFmtEnumProcEx, uint32 Locale, uint32 dwFlags) => EnumDateFormatsExA(lpDateFmtEnumProcEx, Locale, dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumDateFormatsExW(DATEFMT_ENUMPROCEXW lpDateFmtEnumProcEx, uint32 Locale, uint32 dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsValidLanguageGroup(uint32 LanguageGroup, ENUM_SYSTEM_LANGUAGE_GROUPS_FLAGS dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNLSVersion(uint32 Function, uint32 Locale, NLSVERSIONINFO* lpVersionInformation);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsValidLocale(uint32 Locale, IS_VALID_LOCALE_FLAGS dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetGeoInfoA(int32 Location, uint32 GeoType, uint8* lpGeoData, int32 cchData, uint16 LangId);
	public static int32 GetGeoInfo(int32 Location, uint32 GeoType, uint8* lpGeoData, int32 cchData, uint16 LangId) => GetGeoInfoA(Location, GeoType, lpGeoData, cchData, LangId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetGeoInfoW(int32 Location, uint32 GeoType, char16* lpGeoData, int32 cchData, uint16 LangId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetGeoInfoEx(PWSTR location, uint32 geoType, char16* geoData, int32 geoDataCount);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumSystemGeoID(uint32 GeoClass, int32 ParentGeoId, GEO_ENUMPROC lpGeoEnumProc);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumSystemGeoNames(uint32 geoClass, GEO_ENUMNAMEPROC geoEnumProc, LPARAM data);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetUserGeoID(uint32 GeoClass);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetUserDefaultGeoName(char16* geoName, int32 geoNameCount);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetUserGeoID(int32 GeoId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetUserGeoName(PWSTR geoName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ConvertDefaultLocale(uint32 Locale);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 GetSystemDefaultUILanguage();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetThreadLocale();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetThreadLocale(uint32 Locale);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 GetUserDefaultUILanguage();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 GetUserDefaultLangID();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 GetSystemDefaultLangID();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetSystemDefaultLCID();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetUserDefaultLCID();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 SetThreadUILanguage(uint16 LangId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 GetThreadUILanguage();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetProcessPreferredUILanguages(uint32 dwFlags, uint32* pulNumLanguages, char16* pwszLanguagesBuffer, uint32* pcchLanguagesBuffer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetProcessPreferredUILanguages(uint32 dwFlags, PWSTR pwszLanguagesBuffer, uint32* pulNumLanguages);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetUserPreferredUILanguages(uint32 dwFlags, uint32* pulNumLanguages, char16* pwszLanguagesBuffer, uint32* pcchLanguagesBuffer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetSystemPreferredUILanguages(uint32 dwFlags, uint32* pulNumLanguages, char16* pwszLanguagesBuffer, uint32* pcchLanguagesBuffer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetThreadPreferredUILanguages(uint32 dwFlags, uint32* pulNumLanguages, char16* pwszLanguagesBuffer, uint32* pcchLanguagesBuffer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetThreadPreferredUILanguages(uint32 dwFlags, PWSTR pwszLanguagesBuffer, uint32* pulNumLanguages);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetFileMUIInfo(uint32 dwFlags, PWSTR pcwszFilePath, FILEMUIINFO* pFileMUIInfo, uint32* pcbFileMUIInfo);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetFileMUIPath(uint32 dwFlags, PWSTR pcwszFilePath, char16* pwszLanguage, uint32* pcchLanguage, char16* pwszFileMUIPath, uint32* pcchFileMUIPath, uint64* pululEnumerator);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetUILanguageInfo(uint32 dwFlags, PWSTR pwmszLanguage, char16* pwszFallbackLanguages, uint32* pcchFallbackLanguages, uint32* pAttributes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetThreadPreferredUILanguages2(uint32 flags, PWSTR languages, uint32* numLanguagesSet, HSAVEDUILANGUAGES* snapshot);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RestoreThreadPreferredUILanguages(HSAVEDUILANGUAGES snapshot);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL NotifyUILanguageChange(uint32 dwFlags, PWSTR pcwstrNewLanguage, PWSTR pcwstrPreviousLanguage, uint32 dwReserved, uint32* pdwStatusRtrn);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetStringTypeExA(uint32 Locale, uint32 dwInfoType, uint8* lpSrcStr, int32 cchSrc, uint16* lpCharType);
	public static BOOL GetStringTypeEx(uint32 Locale, uint32 dwInfoType, uint8* lpSrcStr, int32 cchSrc, uint16* lpCharType) => GetStringTypeExA(Locale, dwInfoType, lpSrcStr, cchSrc, lpCharType);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetStringTypeA(uint32 Locale, uint32 dwInfoType, uint8* lpSrcStr, int32 cchSrc, uint16* lpCharType);
	public static BOOL GetStringType(uint32 Locale, uint32 dwInfoType, uint8* lpSrcStr, int32 cchSrc, uint16* lpCharType) => GetStringTypeA(Locale, dwInfoType, lpSrcStr, cchSrc, lpCharType);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 FoldStringA(FOLD_STRING_MAP_FLAGS dwMapFlags, uint8* lpSrcStr, int32 cchSrc, uint8* lpDestStr, int32 cchDest);
	public static int32 FoldString(FOLD_STRING_MAP_FLAGS dwMapFlags, uint8* lpSrcStr, int32 cchSrc, uint8* lpDestStr, int32 cchDest) => FoldStringA(dwMapFlags, lpSrcStr, cchSrc, lpDestStr, cchDest);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumSystemLocalesA(LOCALE_ENUMPROCA lpLocaleEnumProc, uint32 dwFlags);
	public static BOOL EnumSystemLocales(LOCALE_ENUMPROCA lpLocaleEnumProc, uint32 dwFlags) => EnumSystemLocalesA(lpLocaleEnumProc, dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumSystemLocalesW(LOCALE_ENUMPROCW lpLocaleEnumProc, uint32 dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumSystemLanguageGroupsA(LANGUAGEGROUP_ENUMPROCA lpLanguageGroupEnumProc, ENUM_SYSTEM_LANGUAGE_GROUPS_FLAGS dwFlags, int lParam);
	public static BOOL EnumSystemLanguageGroups(LANGUAGEGROUP_ENUMPROCA lpLanguageGroupEnumProc, ENUM_SYSTEM_LANGUAGE_GROUPS_FLAGS dwFlags, int lParam) => EnumSystemLanguageGroupsA(lpLanguageGroupEnumProc, dwFlags, lParam);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumSystemLanguageGroupsW(LANGUAGEGROUP_ENUMPROCW lpLanguageGroupEnumProc, ENUM_SYSTEM_LANGUAGE_GROUPS_FLAGS dwFlags, int lParam);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumLanguageGroupLocalesA(LANGGROUPLOCALE_ENUMPROCA lpLangGroupLocaleEnumProc, uint32 LanguageGroup, uint32 dwFlags, int lParam);
	public static BOOL EnumLanguageGroupLocales(LANGGROUPLOCALE_ENUMPROCA lpLangGroupLocaleEnumProc, uint32 LanguageGroup, uint32 dwFlags, int lParam) => EnumLanguageGroupLocalesA(lpLangGroupLocaleEnumProc, LanguageGroup, dwFlags, lParam);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumLanguageGroupLocalesW(LANGGROUPLOCALE_ENUMPROCW lpLangGroupLocaleEnumProc, uint32 LanguageGroup, uint32 dwFlags, int lParam);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumUILanguagesA(UILANGUAGE_ENUMPROCA lpUILanguageEnumProc, uint32 dwFlags, int lParam);
	public static BOOL EnumUILanguages(UILANGUAGE_ENUMPROCA lpUILanguageEnumProc, uint32 dwFlags, int lParam) => EnumUILanguagesA(lpUILanguageEnumProc, dwFlags, lParam);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumUILanguagesW(UILANGUAGE_ENUMPROCW lpUILanguageEnumProc, uint32 dwFlags, int lParam);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumSystemCodePagesA(CODEPAGE_ENUMPROCA lpCodePageEnumProc, ENUM_SYSTEM_CODE_PAGES_FLAGS dwFlags);
	public static BOOL EnumSystemCodePages(CODEPAGE_ENUMPROCA lpCodePageEnumProc, ENUM_SYSTEM_CODE_PAGES_FLAGS dwFlags) => EnumSystemCodePagesA(lpCodePageEnumProc, dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumSystemCodePagesW(CODEPAGE_ENUMPROCW lpCodePageEnumProc, ENUM_SYSTEM_CODE_PAGES_FLAGS dwFlags);

	[Import("NORMALIZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 IdnToAscii(uint32 dwFlags, char16* lpUnicodeCharStr, int32 cchUnicodeChar, char16* lpASCIICharStr, int32 cchASCIIChar);

	[Import("NORMALIZ.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 IdnToUnicode(uint32 dwFlags, char16* lpASCIICharStr, int32 cchASCIIChar, char16* lpUnicodeCharStr, int32 cchUnicodeChar);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 IdnToNameprepUnicode(uint32 dwFlags, char16* lpUnicodeCharStr, int32 cchUnicodeChar, char16* lpNameprepCharStr, int32 cchNameprepChar);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 NormalizeString(NORM_FORM NormForm, char16* lpSrcString, int32 cwSrcLength, char16* lpDstString, int32 cwDstLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsNormalizedString(NORM_FORM NormForm, char16* lpString, int32 cwLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL VerifyScripts(uint32 dwFlags, PWSTR lpLocaleScripts, int32 cchLocaleScripts, PWSTR lpTestScripts, int32 cchTestScripts);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetStringScripts(uint32 dwFlags, PWSTR lpString, int32 cchString, char16* lpScripts, int32 cchScripts);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetLocaleInfoEx(PWSTR lpLocaleName, uint32 LCType, char16* lpLCData, int32 cchData);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetCalendarInfoEx(PWSTR lpLocaleName, uint32 Calendar, PWSTR lpReserved, uint32 CalType, char16* lpCalData, int32 cchData, uint32* lpValue);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetNumberFormatEx(PWSTR lpLocaleName, uint32 dwFlags, PWSTR lpValue, NUMBERFMTW* lpFormat, char16* lpNumberStr, int32 cchNumber);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetCurrencyFormatEx(PWSTR lpLocaleName, uint32 dwFlags, PWSTR lpValue, CURRENCYFMTW* lpFormat, char16* lpCurrencyStr, int32 cchCurrency);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetUserDefaultLocaleName(char16* lpLocaleName, int32 cchLocaleName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetSystemDefaultLocaleName(char16* lpLocaleName, int32 cchLocaleName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsNLSDefinedString(uint32 Function, uint32 dwFlags, NLSVERSIONINFO* lpVersionInformation, char16* lpString, int32 cchStr);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNLSVersionEx(uint32 @function, PWSTR lpLocaleName, NLSVERSIONINFOEX* lpVersionInformation);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IsValidNLSVersion(uint32 @function, PWSTR lpLocaleName, NLSVERSIONINFOEX* lpVersionInformation);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 FindNLSStringEx(PWSTR lpLocaleName, uint32 dwFindNLSStringFlags, char16* lpStringSource, int32 cchSource, char16* lpStringValue, int32 cchValue, int32* pcchFound, NLSVERSIONINFO* lpVersionInformation, void* lpReserved, LPARAM sortHandle);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 LCMapStringEx(PWSTR lpLocaleName, uint32 dwMapFlags, char16* lpSrcStr, int32 cchSrc, char16* lpDestStr, int32 cchDest, NLSVERSIONINFO* lpVersionInformation, void* lpReserved, LPARAM sortHandle);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsValidLocaleName(PWSTR lpLocaleName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumCalendarInfoExEx(CALINFO_ENUMPROCEXEX pCalInfoEnumProcExEx, PWSTR lpLocaleName, uint32 Calendar, PWSTR lpReserved, uint32 CalType, LPARAM lParam);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumDateFormatsExEx(DATEFMT_ENUMPROCEXEX lpDateFmtEnumProcExEx, PWSTR lpLocaleName, ENUM_DATE_FORMATS_FLAGS dwFlags, LPARAM lParam);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumTimeFormatsEx(TIMEFMT_ENUMPROCEX lpTimeFmtEnumProcEx, PWSTR lpLocaleName, uint32 dwFlags, LPARAM lParam);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumSystemLocalesEx(LOCALE_ENUMPROCEX lpLocaleEnumProcEx, uint32 dwFlags, LPARAM lParam, void* lpReserved);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ResolveLocaleName(PWSTR lpNameToResolve, char16* lpLocaleName, int32 cchLocaleName);

	[Import("elscore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT MappingGetServices(MAPPING_ENUM_OPTIONS* pOptions, MAPPING_SERVICE_INFO** prgServices, uint32* pdwServicesCount);

	[Import("elscore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT MappingFreeServices(MAPPING_SERVICE_INFO* pServiceInfo);

	[Import("elscore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT MappingRecognizeText(MAPPING_SERVICE_INFO* pServiceInfo, char16* pszText, uint32 dwLength, uint32 dwIndex, MAPPING_OPTIONS* pOptions, MAPPING_PROPERTY_BAG* pbag);

	[Import("elscore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT MappingDoAction(MAPPING_PROPERTY_BAG* pBag, uint32 dwRangeIndex, PWSTR pszActionId);

	[Import("elscore.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT MappingFreePropertyBag(MAPPING_PROPERTY_BAG* pBag);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptFreeCache(void** psc);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptItemize(char16* pwcInChars, int32 cInChars, int32 cMaxItems, SCRIPT_CONTROL* psControl, SCRIPT_STATE* psState, SCRIPT_ITEM* pItems, int32* pcItems);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptLayout(int32 cRuns, uint8* pbLevel, int32* piVisualToLogical, int32* piLogicalToVisual);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptShape(HDC hdc, void** psc, char16* pwcChars, int32 cChars, int32 cMaxGlyphs, SCRIPT_ANALYSIS* psa, uint16* pwOutGlyphs, uint16* pwLogClust, SCRIPT_VISATTR* psva, int32* pcGlyphs);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptPlace(HDC hdc, void** psc, uint16* pwGlyphs, int32 cGlyphs, SCRIPT_VISATTR* psva, SCRIPT_ANALYSIS* psa, int32* piAdvance, GOFFSET* pGoffset, ABC* pABC);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptTextOut(HDC hdc, void** psc, int32 x, int32 y, uint32 fuOptions, RECT* lprc, SCRIPT_ANALYSIS* psa, PWSTR pwcReserved, int32 iReserved, uint16* pwGlyphs, int32 cGlyphs, int32* piAdvance, int32* piJustify, GOFFSET* pGoffset);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptJustify(SCRIPT_VISATTR* psva, int32* piAdvance, int32 cGlyphs, int32 iDx, int32 iMinKashida, int32* piJustify);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptBreak(char16* pwcChars, int32 cChars, SCRIPT_ANALYSIS* psa, SCRIPT_LOGATTR* psla);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptCPtoX(int32 iCP, BOOL fTrailing, int32 cChars, int32 cGlyphs, uint16* pwLogClust, SCRIPT_VISATTR* psva, int32* piAdvance, SCRIPT_ANALYSIS* psa, int32* piX);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptXtoCP(int32 iX, int32 cChars, int32 cGlyphs, uint16* pwLogClust, SCRIPT_VISATTR* psva, int32* piAdvance, SCRIPT_ANALYSIS* psa, int32* piCP, int32* piTrailing);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptGetLogicalWidths(SCRIPT_ANALYSIS* psa, int32 cChars, int32 cGlyphs, int32* piGlyphWidth, uint16* pwLogClust, SCRIPT_VISATTR* psva, int32* piDx);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptApplyLogicalWidth(int32* piDx, int32 cChars, int32 cGlyphs, uint16* pwLogClust, SCRIPT_VISATTR* psva, int32* piAdvance, SCRIPT_ANALYSIS* psa, ABC* pABC, int32* piJustify);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptGetCMap(HDC hdc, void** psc, char16* pwcInChars, int32 cChars, uint32 dwFlags, uint16* pwOutGlyphs);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptGetGlyphABCWidth(HDC hdc, void** psc, uint16 wGlyph, ABC* pABC);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptGetProperties(SCRIPT_PROPERTIES*** ppSp, int32* piNumScripts);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptGetFontProperties(HDC hdc, void** psc, SCRIPT_FONTPROPERTIES* sfp);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptCacheGetHeight(HDC hdc, void** psc, int32* tmHeight);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptStringAnalyse(HDC hdc, void* pString, int32 cString, int32 cGlyphs, int32 iCharset, uint32 dwFlags, int32 iReqWidth, SCRIPT_CONTROL* psControl, SCRIPT_STATE* psState, int32* piDx, SCRIPT_TABDEF* pTabdef, uint8* pbInClass, void** pssa);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptStringFree(void** pssa);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SIZE* ScriptString_pSize(void* ssa);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32* ScriptString_pcOutChars(void* ssa);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SCRIPT_LOGATTR* ScriptString_pLogAttr(void* ssa);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptStringGetOrder(void* ssa, uint32* puOrder);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptStringCPtoX(void* ssa, int32 icp, BOOL fTrailing, int32* pX);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptStringXtoCP(void* ssa, int32 iX, int32* piCh, int32* piTrailing);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptStringGetLogicalWidths(void* ssa, int32* piDx);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptStringValidate(void* ssa);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptStringOut(void* ssa, int32 iX, int32 iY, ETO_OPTIONS uOptions, RECT* prc, int32 iMinSel, int32 iMaxSel, BOOL fDisabled);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptIsComplex(char16* pwcInChars, int32 cInChars, SCRIPT_IS_COMPLEX_FLAGS dwFlags);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptRecordDigitSubstitution(uint32 Locale, SCRIPT_DIGITSUBSTITUTE* psds);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptApplyDigitSubstitution(SCRIPT_DIGITSUBSTITUTE* psds, SCRIPT_CONTROL* psc, SCRIPT_STATE* pss);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptShapeOpenType(HDC hdc, void** psc, SCRIPT_ANALYSIS* psa, uint32 tagScript, uint32 tagLangSys, int32* rcRangeChars, TEXTRANGE_PROPERTIES** rpRangeProperties, int32 cRanges, char16* pwcChars, int32 cChars, int32 cMaxGlyphs, uint16* pwLogClust, SCRIPT_CHARPROP* pCharProps, uint16* pwOutGlyphs, SCRIPT_GLYPHPROP* pOutGlyphProps, int32* pcGlyphs);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptPlaceOpenType(HDC hdc, void** psc, SCRIPT_ANALYSIS* psa, uint32 tagScript, uint32 tagLangSys, int32* rcRangeChars, TEXTRANGE_PROPERTIES** rpRangeProperties, int32 cRanges, char16* pwcChars, uint16* pwLogClust, SCRIPT_CHARPROP* pCharProps, int32 cChars, uint16* pwGlyphs, SCRIPT_GLYPHPROP* pGlyphProps, int32 cGlyphs, int32* piAdvance, GOFFSET* pGoffset, ABC* pABC);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptItemizeOpenType(char16* pwcInChars, int32 cInChars, int32 cMaxItems, SCRIPT_CONTROL* psControl, SCRIPT_STATE* psState, SCRIPT_ITEM* pItems, uint32* pScriptTags, int32* pcItems);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptGetFontScriptTags(HDC hdc, void** psc, SCRIPT_ANALYSIS* psa, int32 cMaxTags, uint32* pScriptTags, int32* pcTags);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptGetFontLanguageTags(HDC hdc, void** psc, SCRIPT_ANALYSIS* psa, uint32 tagScript, int32 cMaxTags, uint32* pLangsysTags, int32* pcTags);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptGetFontFeatureTags(HDC hdc, void** psc, SCRIPT_ANALYSIS* psa, uint32 tagScript, uint32 tagLangSys, int32 cMaxTags, uint32* pFeatureTags, int32* pcTags);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptGetFontAlternateGlyphs(HDC hdc, void** psc, SCRIPT_ANALYSIS* psa, uint32 tagScript, uint32 tagLangSys, uint32 tagFeature, uint16 wGlyphId, int32 cMaxAlternates, uint16* pAlternateGlyphs, int32* pcAlternates);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptSubstituteSingleGlyph(HDC hdc, void** psc, SCRIPT_ANALYSIS* psa, uint32 tagScript, uint32 tagLangSys, uint32 tagFeature, int32 lParameter, uint16 wGlyphId, uint16* pwOutGlyphId);

	[Import("USP10.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ScriptPositionSingleGlyph(HDC hdc, void** psc, SCRIPT_ANALYSIS* psa, uint32 tagScript, uint32 tagLangSys, uint32 tagFeature, int32 lParameter, uint16 wGlyphId, int32 iAdvance, GOFFSET GOffset, int32* piOutAdvance, GOFFSET* pOutGoffset);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 utf8_nextCharSafeBody(uint8* s, int32* pi, int32 length, int32 c, int8 strict);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 utf8_appendCharSafeBody(uint8* s, int32 i, int32 length, int32 c, int8* pIsError);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 utf8_prevCharSafeBody(uint8* s, int32 start, int32* pi, int32 c, int8 strict);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 utf8_back1SafeBody(uint8* s, int32 start, int32 i);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void u_versionFromString(uint8* versionArray, PSTR versionString);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void u_versionFromUString(uint8* versionArray, uint16* versionString);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void u_versionToString(uint8* versionArray, PSTR versionString);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void u_getVersion(uint8* versionArray);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR u_errorName(UErrorCode code);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void utrace_setLevel(int32 traceLevel);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 utrace_getLevel();

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void utrace_setFunctions(void* context, UTraceEntry e, UTraceExit x, UTraceData d);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void utrace_getFunctions(void** context, UTraceEntry* e, UTraceExit* x, UTraceData* d);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 utrace_vformat(PSTR outBuf, int32 capacity, int32 indent, PSTR fmt, int8* args);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 utrace_format(PSTR outBuf, int32 capacity, int32 indent, PSTR fmt);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR utrace_functionName(int32 fnNumber);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_shapeArabic(uint16* source, int32 sourceLength, uint16* dest, int32 destSize, uint32 options, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uscript_getCode(PSTR nameOrAbbrOrLocale, UScriptCode* fillIn, int32 capacity, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR uscript_getName(UScriptCode scriptCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR uscript_getShortName(UScriptCode scriptCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UScriptCode uscript_getScript(int32 codepoint, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uscript_hasScript(int32 c, UScriptCode sc);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uscript_getScriptExtensions(int32 c, UScriptCode* scripts, int32 capacity, UErrorCode* errorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uscript_getSampleString(UScriptCode script, uint16* dest, int32 capacity, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UScriptUsage uscript_getUsage(UScriptCode script);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uscript_isRightToLeft(UScriptCode script);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uscript_breaksBetweenLetters(UScriptCode script);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uscript_isCased(UScriptCode script);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uiter_current32(UCharIterator* iter);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uiter_next32(UCharIterator* iter);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uiter_previous32(UCharIterator* iter);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 uiter_getState(UCharIterator* iter);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uiter_setState(UCharIterator* iter, uint32 state, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uiter_setString(UCharIterator* iter, uint16* s, int32 length);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uiter_setUTF16BE(UCharIterator* iter, PSTR s, int32 length);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uiter_setUTF8(UCharIterator* iter, PSTR s, int32 length);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uenum_close(UEnumeration* en);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uenum_count(UEnumeration* en, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* uenum_unext(UEnumeration* en, int32* resultLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR uenum_next(UEnumeration* en, int32* resultLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uenum_reset(UEnumeration* en, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* uenum_openUCharStringsEnumeration(uint16** strings, int32 count, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* uenum_openCharStringsEnumeration(int8** strings, int32 count, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR uloc_getDefault();

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uloc_setDefault(PSTR localeID, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uloc_getLanguage(PSTR localeID, PSTR language, int32 languageCapacity, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uloc_getScript(PSTR localeID, PSTR script, int32 scriptCapacity, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uloc_getCountry(PSTR localeID, PSTR country, int32 countryCapacity, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uloc_getVariant(PSTR localeID, PSTR variant, int32 variantCapacity, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uloc_getName(PSTR localeID, PSTR name, int32 nameCapacity, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uloc_canonicalize(PSTR localeID, PSTR name, int32 nameCapacity, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR uloc_getISO3Language(PSTR localeID);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR uloc_getISO3Country(PSTR localeID);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 uloc_getLCID(PSTR localeID);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uloc_getDisplayLanguage(PSTR locale, PSTR displayLocale, uint16* language, int32 languageCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uloc_getDisplayScript(PSTR locale, PSTR displayLocale, uint16* script, int32 scriptCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uloc_getDisplayCountry(PSTR locale, PSTR displayLocale, uint16* country, int32 countryCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uloc_getDisplayVariant(PSTR locale, PSTR displayLocale, uint16* variant, int32 variantCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uloc_getDisplayKeyword(PSTR keyword, PSTR displayLocale, uint16* dest, int32 destCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uloc_getDisplayKeywordValue(PSTR locale, PSTR keyword, PSTR displayLocale, uint16* dest, int32 destCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uloc_getDisplayName(PSTR localeID, PSTR inLocaleID, uint16* result, int32 maxResultSize, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR uloc_getAvailable(int32 n);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uloc_countAvailable();

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* uloc_openAvailableByType(ULocAvailableType type, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8** uloc_getISOLanguages();

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8** uloc_getISOCountries();

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uloc_getParent(PSTR localeID, PSTR parent, int32 parentCapacity, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uloc_getBaseName(PSTR localeID, PSTR name, int32 nameCapacity, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* uloc_openKeywords(PSTR localeID, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uloc_getKeywordValue(PSTR localeID, PSTR keywordName, PSTR buffer, int32 bufferCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uloc_setKeywordValue(PSTR keywordName, PSTR keywordValue, PSTR buffer, int32 bufferCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uloc_isRightToLeft(PSTR locale);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern ULayoutType uloc_getCharacterOrientation(PSTR localeId, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern ULayoutType uloc_getLineOrientation(PSTR localeId, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uloc_acceptLanguageFromHTTP(PSTR result, int32 resultAvailable, UAcceptResult* outResult, PSTR httpAcceptLanguage, UEnumeration* availableLocales, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uloc_acceptLanguage(PSTR result, int32 resultAvailable, UAcceptResult* outResult, int8** acceptList, int32 acceptListCount, UEnumeration* availableLocales, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uloc_getLocaleForLCID(uint32 hostID, PSTR locale, int32 localeCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uloc_addLikelySubtags(PSTR localeID, PSTR maximizedLocaleID, int32 maximizedLocaleIDCapacity, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uloc_minimizeSubtags(PSTR localeID, PSTR minimizedLocaleID, int32 minimizedLocaleIDCapacity, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uloc_forLanguageTag(PSTR langtag, PSTR localeID, int32 localeIDCapacity, int32* parsedLength, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uloc_toLanguageTag(PSTR localeID, PSTR langtag, int32 langtagCapacity, int8 strict, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR uloc_toUnicodeLocaleKey(PSTR keyword);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR uloc_toUnicodeLocaleType(PSTR keyword, PSTR value);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR uloc_toLegacyKey(PSTR keyword);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR uloc_toLegacyType(PSTR keyword, PSTR value);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UResourceBundle* ures_open(PSTR packageName, PSTR locale, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UResourceBundle* ures_openDirect(PSTR packageName, PSTR locale, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UResourceBundle* ures_openU(uint16* packageName, PSTR locale, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ures_close(UResourceBundle* resourceBundle);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ures_getVersion(UResourceBundle* resB, uint8* versionInfo);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ures_getLocaleByType(UResourceBundle* resourceBundle, ULocDataLocaleType type, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* ures_getString(UResourceBundle* resourceBundle, int32* len, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ures_getUTF8String(UResourceBundle* resB, PSTR dest, int32* length, int8 forceCopy, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* ures_getBinary(UResourceBundle* resourceBundle, int32* len, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32* ures_getIntVector(UResourceBundle* resourceBundle, int32* len, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ures_getUInt(UResourceBundle* resourceBundle, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ures_getInt(UResourceBundle* resourceBundle, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ures_getSize(UResourceBundle* resourceBundle);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UResType ures_getType(UResourceBundle* resourceBundle);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ures_getKey(UResourceBundle* resourceBundle);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ures_resetIterator(UResourceBundle* resourceBundle);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 ures_hasNext(UResourceBundle* resourceBundle);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UResourceBundle* ures_getNextResource(UResourceBundle* resourceBundle, UResourceBundle* fillIn, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* ures_getNextString(UResourceBundle* resourceBundle, int32* len, int8** key, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UResourceBundle* ures_getByIndex(UResourceBundle* resourceBundle, int32 indexR, UResourceBundle* fillIn, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* ures_getStringByIndex(UResourceBundle* resourceBundle, int32 indexS, int32* len, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ures_getUTF8StringByIndex(UResourceBundle* resB, int32 stringIndex, PSTR dest, int32* pLength, int8 forceCopy, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UResourceBundle* ures_getByKey(UResourceBundle* resourceBundle, PSTR key, UResourceBundle* fillIn, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* ures_getStringByKey(UResourceBundle* resB, PSTR key, int32* len, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ures_getUTF8StringByKey(UResourceBundle* resB, PSTR key, PSTR dest, int32* pLength, int8 forceCopy, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* ures_openAvailableLocales(PSTR packageName, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern ULocaleDisplayNames* uldn_open(PSTR locale, UDialectHandling dialectHandling, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uldn_close(ULocaleDisplayNames* ldn);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR uldn_getLocale(ULocaleDisplayNames* ldn);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UDialectHandling uldn_getDialectHandling(ULocaleDisplayNames* ldn);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uldn_localeDisplayName(ULocaleDisplayNames* ldn, PSTR locale, uint16* result, int32 maxResultSize, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uldn_languageDisplayName(ULocaleDisplayNames* ldn, PSTR lang, uint16* result, int32 maxResultSize, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uldn_scriptDisplayName(ULocaleDisplayNames* ldn, PSTR script, uint16* result, int32 maxResultSize, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uldn_scriptCodeDisplayName(ULocaleDisplayNames* ldn, UScriptCode scriptCode, uint16* result, int32 maxResultSize, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uldn_regionDisplayName(ULocaleDisplayNames* ldn, PSTR region, uint16* result, int32 maxResultSize, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uldn_variantDisplayName(ULocaleDisplayNames* ldn, PSTR variant, uint16* result, int32 maxResultSize, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uldn_keyDisplayName(ULocaleDisplayNames* ldn, PSTR key, uint16* result, int32 maxResultSize, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uldn_keyValueDisplayName(ULocaleDisplayNames* ldn, PSTR key, PSTR value, uint16* result, int32 maxResultSize, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern ULocaleDisplayNames* uldn_openForContext(PSTR locale, UDisplayContext* contexts, int32 length, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UDisplayContext uldn_getContext(ULocaleDisplayNames* ldn, UDisplayContextType type, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucurr_forLocale(PSTR locale, uint16* buff, int32 buffCapacity, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* ucurr_register(uint16* isoCode, PSTR locale, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 ucurr_unregister(void* key, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* ucurr_getName(uint16* currency, PSTR locale, UCurrNameStyle nameStyle, int8* isChoiceFormat, int32* len, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* ucurr_getPluralName(uint16* currency, PSTR locale, int8* isChoiceFormat, PSTR pluralCount, int32* len, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucurr_getDefaultFractionDigits(uint16* currency, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucurr_getDefaultFractionDigitsForUsage(uint16* currency, UCurrencyUsage usage, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern double ucurr_getRoundingIncrement(uint16* currency, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern double ucurr_getRoundingIncrementForUsage(uint16* currency, UCurrencyUsage usage, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* ucurr_openISOCurrencies(uint32 currType, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 ucurr_isAvailable(uint16* isoCode, double from, double to, UErrorCode* errorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucurr_countCurrencies(PSTR locale, double date, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucurr_forLocaleAndDate(PSTR locale, double date, int32 index, uint16* buff, int32 buffCapacity, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* ucurr_getKeywordValuesForLocale(PSTR key, PSTR locale, int8 commonlyUsed, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucurr_getNumericCode(uint16* currency);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ucpmap_get(UCPMap* map, int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucpmap_getRange(UCPMap* map, int32 start, UCPMapRangeOption option, uint32 surrogateValue, UCPMapValueFilter* filter, void* context, uint32* pValue);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UCPTrie* ucptrie_openFromBinary(UCPTrieType type, UCPTrieValueWidth valueWidth, void* data, int32 length, int32* pActualLength, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucptrie_close(UCPTrie* trie);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UCPTrieType ucptrie_getType(UCPTrie* trie);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UCPTrieValueWidth ucptrie_getValueWidth(UCPTrie* trie);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ucptrie_get(UCPTrie* trie, int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucptrie_getRange(UCPTrie* trie, int32 start, UCPMapRangeOption option, uint32 surrogateValue, UCPMapValueFilter* filter, void* context, uint32* pValue);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucptrie_toBinary(UCPTrie* trie, void* data, int32 capacity, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucptrie_internalSmallIndex(UCPTrie* trie, int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucptrie_internalSmallU8Index(UCPTrie* trie, int32 lt1, uint8 t2, uint8 t3);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucptrie_internalU8PrevIndex(UCPTrie* trie, int32 c, uint8* start, uint8* src);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UMutableCPTrie* umutablecptrie_open(uint32 initialValue, uint32 errorValue, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UMutableCPTrie* umutablecptrie_clone(UMutableCPTrie* other, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void umutablecptrie_close(UMutableCPTrie* trie);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UMutableCPTrie* umutablecptrie_fromUCPMap(UCPMap* map, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UMutableCPTrie* umutablecptrie_fromUCPTrie(UCPTrie* trie, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 umutablecptrie_get(UMutableCPTrie* trie, int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 umutablecptrie_getRange(UMutableCPTrie* trie, int32 start, UCPMapRangeOption option, uint32 surrogateValue, UCPMapValueFilter* filter, void* context, uint32* pValue);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void umutablecptrie_set(UMutableCPTrie* trie, int32 c, uint32 value, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void umutablecptrie_setRange(UMutableCPTrie* trie, int32 start, int32 end, uint32 value, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UCPTrie* umutablecptrie_buildImmutable(UMutableCPTrie* trie, UCPTrieType type, UCPTrieValueWidth valueWidth, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void UCNV_FROM_U_CALLBACK_STOP(void* context, UConverterFromUnicodeArgs* fromUArgs, uint16* codeUnits, int32 length, int32 codePoint, UConverterCallbackReason reason, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void UCNV_TO_U_CALLBACK_STOP(void* context, UConverterToUnicodeArgs* toUArgs, PSTR codeUnits, int32 length, UConverterCallbackReason reason, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void UCNV_FROM_U_CALLBACK_SKIP(void* context, UConverterFromUnicodeArgs* fromUArgs, uint16* codeUnits, int32 length, int32 codePoint, UConverterCallbackReason reason, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void UCNV_FROM_U_CALLBACK_SUBSTITUTE(void* context, UConverterFromUnicodeArgs* fromUArgs, uint16* codeUnits, int32 length, int32 codePoint, UConverterCallbackReason reason, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void UCNV_FROM_U_CALLBACK_ESCAPE(void* context, UConverterFromUnicodeArgs* fromUArgs, uint16* codeUnits, int32 length, int32 codePoint, UConverterCallbackReason reason, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void UCNV_TO_U_CALLBACK_SKIP(void* context, UConverterToUnicodeArgs* toUArgs, PSTR codeUnits, int32 length, UConverterCallbackReason reason, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void UCNV_TO_U_CALLBACK_SUBSTITUTE(void* context, UConverterToUnicodeArgs* toUArgs, PSTR codeUnits, int32 length, UConverterCallbackReason reason, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void UCNV_TO_U_CALLBACK_ESCAPE(void* context, UConverterToUnicodeArgs* toUArgs, PSTR codeUnits, int32 length, UConverterCallbackReason reason, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucnv_compareNames(PSTR name1, PSTR name2);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UConverter* ucnv_open(PSTR converterName, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UConverter* ucnv_openU(uint16* name, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UConverter* ucnv_openCCSID(int32 codepage, UConverterPlatform platform, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UConverter* ucnv_openPackage(PSTR packageName, PSTR converterName, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UConverter* ucnv_safeClone(UConverter* cnv, void* stackBuffer, int32* pBufferSize, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucnv_close(UConverter* converter);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucnv_getSubstChars(UConverter* converter, PSTR subChars, int8* len, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucnv_setSubstChars(UConverter* converter, PSTR subChars, int8 len, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucnv_setSubstString(UConverter* cnv, uint16* s, int32 length, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucnv_getInvalidChars(UConverter* converter, PSTR errBytes, int8* len, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucnv_getInvalidUChars(UConverter* converter, uint16* errUChars, int8* len, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucnv_reset(UConverter* converter);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucnv_resetToUnicode(UConverter* converter);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucnv_resetFromUnicode(UConverter* converter);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 ucnv_getMaxCharSize(UConverter* converter);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 ucnv_getMinCharSize(UConverter* converter);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucnv_getDisplayName(UConverter* converter, PSTR displayLocale, uint16* displayName, int32 displayNameCapacity, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ucnv_getName(UConverter* converter, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucnv_getCCSID(UConverter* converter, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UConverterPlatform ucnv_getPlatform(UConverter* converter, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UConverterType ucnv_getType(UConverter* converter);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucnv_getStarters(UConverter* converter, int8* starters, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucnv_getUnicodeSet(UConverter* cnv, USet* setFillIn, UConverterUnicodeSet whichSet, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucnv_getToUCallBack(UConverter* converter, UConverterToUCallback* action, void** context);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucnv_getFromUCallBack(UConverter* converter, UConverterFromUCallback* action, void** context);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucnv_setToUCallBack(UConverter* converter, UConverterToUCallback newAction, void* newContext, UConverterToUCallback* oldAction, void** oldContext, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucnv_setFromUCallBack(UConverter* converter, UConverterFromUCallback newAction, void* newContext, UConverterFromUCallback* oldAction, void** oldContext, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucnv_fromUnicode(UConverter* converter, int8** target, PSTR targetLimit, uint16** source, uint16* sourceLimit, int32* offsets, int8 flush, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucnv_toUnicode(UConverter* converter, uint16** target, uint16* targetLimit, int8** source, PSTR sourceLimit, int32* offsets, int8 flush, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucnv_fromUChars(UConverter* cnv, PSTR dest, int32 destCapacity, uint16* src, int32 srcLength, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucnv_toUChars(UConverter* cnv, uint16* dest, int32 destCapacity, PSTR src, int32 srcLength, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucnv_getNextUChar(UConverter* converter, int8** source, PSTR sourceLimit, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucnv_convertEx(UConverter* targetCnv, UConverter* sourceCnv, int8** target, PSTR targetLimit, int8** source, PSTR sourceLimit, uint16* pivotStart, uint16** pivotSource, uint16** pivotTarget, uint16* pivotLimit, int8 reset, int8 flush, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucnv_convert(PSTR toConverterName, PSTR fromConverterName, PSTR target, int32 targetCapacity, PSTR source, int32 sourceLength, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucnv_toAlgorithmic(UConverterType algorithmicType, UConverter* cnv, PSTR target, int32 targetCapacity, PSTR source, int32 sourceLength, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucnv_fromAlgorithmic(UConverter* cnv, UConverterType algorithmicType, PSTR target, int32 targetCapacity, PSTR source, int32 sourceLength, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucnv_flushCache();

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucnv_countAvailable();

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ucnv_getAvailableName(int32 n);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* ucnv_openAllNames(UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 ucnv_countAliases(PSTR alias, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ucnv_getAlias(PSTR alias, uint16 n, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucnv_getAliases(PSTR alias, int8** aliases, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* ucnv_openStandardNames(PSTR convName, PSTR standard, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 ucnv_countStandards();

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ucnv_getStandard(uint16 n, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ucnv_getStandardName(PSTR name, PSTR standard, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ucnv_getCanonicalName(PSTR alias, PSTR standard, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ucnv_getDefaultName();

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucnv_setDefaultName(PSTR name);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucnv_fixFileSeparator(UConverter* cnv, uint16* source, int32 sourceLen);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 ucnv_isAmbiguous(UConverter* cnv);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucnv_setFallback(UConverter* cnv, int8 usesFallback);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 ucnv_usesFallback(UConverter* cnv);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ucnv_detectUnicodeSignature(PSTR source, int32 sourceLength, int32* signatureLength, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucnv_fromUCountPending(UConverter* cnv, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucnv_toUCountPending(UConverter* cnv, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 ucnv_isFixedWidth(UConverter* cnv, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucnv_cbFromUWriteBytes(UConverterFromUnicodeArgs* args, PSTR source, int32 length, int32 offsetIndex, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucnv_cbFromUWriteSub(UConverterFromUnicodeArgs* args, int32 offsetIndex, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucnv_cbFromUWriteUChars(UConverterFromUnicodeArgs* args, uint16** source, uint16* sourceLimit, int32 offsetIndex, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucnv_cbToUWriteUChars(UConverterToUnicodeArgs* args, uint16* source, int32 length, int32 offsetIndex, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucnv_cbToUWriteSub(UConverterToUnicodeArgs* args, int32 offsetIndex, UErrorCode* err);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void u_init(UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void u_cleanup();

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void u_setMemoryFunctions(void* context, UMemAllocFn* a, UMemReallocFn* r, UMemFreeFn* f, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UResourceBundle* u_catopen(PSTR name, PSTR locale, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void u_catclose(UResourceBundle* catd);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_catgets(UResourceBundle* catd, int32 set_num, int32 msg_num, uint16* s, int32* len, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_hasBinaryProperty(int32 c, UProperty which);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern USet* u_getBinaryPropertySet(UProperty property, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_isUAlphabetic(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_isULowercase(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_isUUppercase(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_isUWhiteSpace(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_getIntPropertyValue(int32 c, UProperty which);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_getIntPropertyMinValue(UProperty which);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_getIntPropertyMaxValue(UProperty which);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UCPMap* u_getIntPropertyMap(UProperty property, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern double u_getNumericValue(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_islower(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_isupper(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_istitle(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_isdigit(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_isalpha(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_isalnum(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_isxdigit(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_ispunct(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_isgraph(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_isblank(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_isdefined(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_isspace(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_isJavaSpaceChar(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_isWhitespace(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_iscntrl(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_isISOControl(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_isprint(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_isbase(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UCharDirection u_charDirection(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_isMirrored(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_charMirror(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_getBidiPairedBracket(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_charType(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void u_enumCharTypes(UCharEnumTypeRange* enumRange, void* context);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8 u_getCombiningClass(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_charDigitValue(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UBlockCode ublock_getCode(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_charName(int32 code, UCharNameChoice nameChoice, PSTR buffer, int32 bufferLength, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_charFromName(UCharNameChoice nameChoice, PSTR name, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void u_enumCharNames(int32 start, int32 limit, UEnumCharNamesFn* fn, void* context, UCharNameChoice nameChoice, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR u_getPropertyName(UProperty property, UPropertyNameChoice nameChoice);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UProperty u_getPropertyEnum(PSTR alias);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR u_getPropertyValueName(UProperty property, int32 value, UPropertyNameChoice nameChoice);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_getPropertyValueEnum(UProperty property, PSTR alias);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_isIDStart(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_isIDPart(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_isIDIgnorable(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_isJavaIDStart(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_isJavaIDPart(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_tolower(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_toupper(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_totitle(int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_foldCase(int32 c, uint32 options);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_digit(int32 ch, int8 radix);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_forDigit(int32 digit, int8 radix);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void u_charAge(int32 c, uint8* versionArray);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void u_getUnicodeVersion(uint8* versionArray);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_getFC_NFKC_Closure(int32 c, uint16* dest, int32 destCapacity, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UBiDi* ubidi_open();

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UBiDi* ubidi_openSized(int32 maxLength, int32 maxRunCount, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ubidi_close(UBiDi* pBiDi);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ubidi_setInverse(UBiDi* pBiDi, int8 isInverse);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 ubidi_isInverse(UBiDi* pBiDi);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ubidi_orderParagraphsLTR(UBiDi* pBiDi, int8 orderParagraphsLTR);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 ubidi_isOrderParagraphsLTR(UBiDi* pBiDi);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ubidi_setReorderingMode(UBiDi* pBiDi, UBiDiReorderingMode reorderingMode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UBiDiReorderingMode ubidi_getReorderingMode(UBiDi* pBiDi);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ubidi_setReorderingOptions(UBiDi* pBiDi, uint32 reorderingOptions);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ubidi_getReorderingOptions(UBiDi* pBiDi);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ubidi_setContext(UBiDi* pBiDi, uint16* prologue, int32 proLength, uint16* epilogue, int32 epiLength, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ubidi_setPara(UBiDi* pBiDi, uint16* text, int32 length, uint8 paraLevel, uint8* embeddingLevels, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ubidi_setLine(UBiDi* pParaBiDi, int32 start, int32 limit, UBiDi* pLineBiDi, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UBiDiDirection ubidi_getDirection(UBiDi* pBiDi);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UBiDiDirection ubidi_getBaseDirection(uint16* text, int32 length);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* ubidi_getText(UBiDi* pBiDi);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ubidi_getLength(UBiDi* pBiDi);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8 ubidi_getParaLevel(UBiDi* pBiDi);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ubidi_countParagraphs(UBiDi* pBiDi);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ubidi_getParagraph(UBiDi* pBiDi, int32 charIndex, int32* pParaStart, int32* pParaLimit, uint8* pParaLevel, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ubidi_getParagraphByIndex(UBiDi* pBiDi, int32 paraIndex, int32* pParaStart, int32* pParaLimit, uint8* pParaLevel, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8 ubidi_getLevelAt(UBiDi* pBiDi, int32 charIndex);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* ubidi_getLevels(UBiDi* pBiDi, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ubidi_getLogicalRun(UBiDi* pBiDi, int32 logicalPosition, int32* pLogicalLimit, uint8* pLevel);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ubidi_countRuns(UBiDi* pBiDi, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UBiDiDirection ubidi_getVisualRun(UBiDi* pBiDi, int32 runIndex, int32* pLogicalStart, int32* pLength);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ubidi_getVisualIndex(UBiDi* pBiDi, int32 logicalIndex, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ubidi_getLogicalIndex(UBiDi* pBiDi, int32 visualIndex, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ubidi_getLogicalMap(UBiDi* pBiDi, int32* indexMap, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ubidi_getVisualMap(UBiDi* pBiDi, int32* indexMap, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ubidi_reorderLogical(uint8* levels, int32 length, int32* indexMap);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ubidi_reorderVisual(uint8* levels, int32 length, int32* indexMap);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ubidi_invertMap(int32* srcMap, int32* destMap, int32 length);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ubidi_getProcessedLength(UBiDi* pBiDi);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ubidi_getResultLength(UBiDi* pBiDi);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UCharDirection ubidi_getCustomizedClass(UBiDi* pBiDi, int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ubidi_setClassCallback(UBiDi* pBiDi, UBiDiClassCallback newFn, void* newContext, UBiDiClassCallback* oldFn, void** oldContext, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ubidi_getClassCallback(UBiDi* pBiDi, UBiDiClassCallback* fn, void** context);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ubidi_writeReordered(UBiDi* pBiDi, uint16* dest, int32 destSize, uint16 options, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ubidi_writeReverse(uint16* src, int32 srcLength, uint16* dest, int32 destSize, uint16 options, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ubiditransform_transform(UBiDiTransform* pBiDiTransform, uint16* src, int32 srcLength, uint16* dest, int32 destSize, uint8 inParaLevel, UBiDiOrder inOrder, uint8 outParaLevel, UBiDiOrder outOrder, UBiDiMirroring doMirroring, uint32 shapingOptions, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UBiDiTransform* ubiditransform_open(UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ubiditransform_close(UBiDiTransform* pBidiTransform);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UText* utext_close(UText* ut);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UText* utext_openUTF8(UText* ut, PSTR s, int64 length, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UText* utext_openUChars(UText* ut, uint16* s, int64 length, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UText* utext_clone(UText* dest, UText* src, int8 deep, int8 readOnly, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 utext_equals(UText* a, UText* b);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int64 utext_nativeLength(UText* ut);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 utext_isLengthExpensive(UText* ut);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 utext_char32At(UText* ut, int64 nativeIndex);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 utext_current32(UText* ut);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 utext_next32(UText* ut);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 utext_previous32(UText* ut);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 utext_next32From(UText* ut, int64 nativeIndex);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 utext_previous32From(UText* ut, int64 nativeIndex);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int64 utext_getNativeIndex(UText* ut);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void utext_setNativeIndex(UText* ut, int64 nativeIndex);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 utext_moveIndex32(UText* ut, int32 delta);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int64 utext_getPreviousNativeIndex(UText* ut);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 utext_extract(UText* ut, int64 nativeStart, int64 nativeLimit, uint16* dest, int32 destCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 utext_isWritable(UText* ut);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 utext_hasMetaData(UText* ut);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 utext_replace(UText* ut, int64 nativeStart, int64 nativeLimit, uint16* replacementText, int32 replacementLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void utext_copy(UText* ut, int64 nativeStart, int64 nativeLimit, int64 destIndex, int8 move, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void utext_freeze(UText* ut);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UText* utext_setup(UText* ut, int32 extraSpace, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern USet* uset_openEmpty();

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern USet* uset_open(int32 start, int32 end);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern USet* uset_openPattern(uint16* pattern, int32 patternLength, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern USet* uset_openPatternOptions(uint16* pattern, int32 patternLength, uint32 options, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uset_close(USet* set);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern USet* uset_clone(USet* set);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uset_isFrozen(USet* set);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uset_freeze(USet* set);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern USet* uset_cloneAsThawed(USet* set);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uset_set(USet* set, int32 start, int32 end);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uset_applyPattern(USet* set, uint16* pattern, int32 patternLength, uint32 options, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uset_applyIntPropertyValue(USet* set, UProperty prop, int32 value, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uset_applyPropertyAlias(USet* set, uint16* prop, int32 propLength, uint16* value, int32 valueLength, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uset_resemblesPattern(uint16* pattern, int32 patternLength, int32 pos);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uset_toPattern(USet* set, uint16* result, int32 resultCapacity, int8 escapeUnprintable, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uset_add(USet* set, int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uset_addAll(USet* set, USet* additionalSet);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uset_addRange(USet* set, int32 start, int32 end);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uset_addString(USet* set, uint16* str, int32 strLen);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uset_addAllCodePoints(USet* set, uint16* str, int32 strLen);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uset_remove(USet* set, int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uset_removeRange(USet* set, int32 start, int32 end);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uset_removeString(USet* set, uint16* str, int32 strLen);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uset_removeAll(USet* set, USet* removeSet);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uset_retain(USet* set, int32 start, int32 end);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uset_retainAll(USet* set, USet* retain);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uset_compact(USet* set);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uset_complement(USet* set);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uset_complementAll(USet* set, USet* complement);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uset_clear(USet* set);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uset_closeOver(USet* set, int32 attributes);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uset_removeAllStrings(USet* set);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uset_isEmpty(USet* set);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uset_contains(USet* set, int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uset_containsRange(USet* set, int32 start, int32 end);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uset_containsString(USet* set, uint16* str, int32 strLen);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uset_indexOf(USet* set, int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uset_charAt(USet* set, int32 charIndex);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uset_size(USet* set);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uset_getItemCount(USet* set);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uset_getItem(USet* set, int32 itemIndex, int32* start, int32* end, uint16* str, int32 strCapacity, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uset_containsAll(USet* set1, USet* set2);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uset_containsAllCodePoints(USet* set, uint16* str, int32 strLen);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uset_containsNone(USet* set1, USet* set2);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uset_containsSome(USet* set1, USet* set2);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uset_span(USet* set, uint16* s, int32 length, USetSpanCondition spanCondition);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uset_spanBack(USet* set, uint16* s, int32 length, USetSpanCondition spanCondition);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uset_spanUTF8(USet* set, PSTR s, int32 length, USetSpanCondition spanCondition);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uset_spanBackUTF8(USet* set, PSTR s, int32 length, USetSpanCondition spanCondition);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uset_equals(USet* set1, USet* set2);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uset_serialize(USet* set, uint16* dest, int32 destCapacity, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uset_getSerializedSet(USerializedSet* fillSet, uint16* src, int32 srcLength);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uset_setSerializedToOne(USerializedSet* fillSet, int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uset_serializedContains(USerializedSet* set, int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uset_getSerializedRangeCount(USerializedSet* set);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uset_getSerializedRange(USerializedSet* set, int32 rangeIndex, int32* pStart, int32* pEnd);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UNormalizer2* unorm2_getNFCInstance(UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UNormalizer2* unorm2_getNFDInstance(UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UNormalizer2* unorm2_getNFKCInstance(UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UNormalizer2* unorm2_getNFKDInstance(UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UNormalizer2* unorm2_getNFKCCasefoldInstance(UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UNormalizer2* unorm2_getInstance(PSTR packageName, PSTR name, UNormalization2Mode mode, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UNormalizer2* unorm2_openFiltered(UNormalizer2* norm2, USet* filterSet, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void unorm2_close(UNormalizer2* norm2);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 unorm2_normalize(UNormalizer2* norm2, uint16* src, int32 length, uint16* dest, int32 capacity, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 unorm2_normalizeSecondAndAppend(UNormalizer2* norm2, uint16* first, int32 firstLength, int32 firstCapacity, uint16* second, int32 secondLength, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 unorm2_append(UNormalizer2* norm2, uint16* first, int32 firstLength, int32 firstCapacity, uint16* second, int32 secondLength, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 unorm2_getDecomposition(UNormalizer2* norm2, int32 c, uint16* decomposition, int32 capacity, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 unorm2_getRawDecomposition(UNormalizer2* norm2, int32 c, uint16* decomposition, int32 capacity, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 unorm2_composePair(UNormalizer2* norm2, int32 a, int32 b);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8 unorm2_getCombiningClass(UNormalizer2* norm2, int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 unorm2_isNormalized(UNormalizer2* norm2, uint16* s, int32 length, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UNormalizationCheckResult unorm2_quickCheck(UNormalizer2* norm2, uint16* s, int32 length, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 unorm2_spanQuickCheckYes(UNormalizer2* norm2, uint16* s, int32 length, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 unorm2_hasBoundaryBefore(UNormalizer2* norm2, int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 unorm2_hasBoundaryAfter(UNormalizer2* norm2, int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 unorm2_isInert(UNormalizer2* norm2, int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 unorm_compare(uint16* s1, int32 length1, uint16* s2, int32 length2, uint32 options, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UConverterSelector* ucnvsel_open(int8** converterList, int32 converterListSize, USet* excludedCodePoints, UConverterUnicodeSet whichSet, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucnvsel_close(UConverterSelector* sel);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UConverterSelector* ucnvsel_openFromSerialized(void* buffer, int32 length, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucnvsel_serialize(UConverterSelector* sel, void* buffer, int32 bufferCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* ucnvsel_selectForString(UConverterSelector* sel, uint16* s, int32 length, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* ucnvsel_selectForUTF8(UConverterSelector* sel, PSTR s, int32 length, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void u_charsToUChars(PSTR cs, uint16* us, int32 length);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void u_UCharsToChars(uint16* us, PSTR cs, int32 length);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_strlen(uint16* s);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_countChar32(uint16* s, int32 length);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 u_strHasMoreChar32Than(uint16* s, int32 length, int32 number);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_strcat(uint16* dst, uint16* src);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_strncat(uint16* dst, uint16* src, int32 n);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_strstr(uint16* s, uint16* substring);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_strFindFirst(uint16* s, int32 length, uint16* substring, int32 subLength);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_strchr(uint16* s, uint16 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_strchr32(uint16* s, int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_strrstr(uint16* s, uint16* substring);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_strFindLast(uint16* s, int32 length, uint16* substring, int32 subLength);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_strrchr(uint16* s, uint16 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_strrchr32(uint16* s, int32 c);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_strpbrk(uint16* string, uint16* matchSet);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_strcspn(uint16* string, uint16* matchSet);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_strspn(uint16* string, uint16* matchSet);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_strtok_r(uint16* src, uint16* delim, uint16** saveState);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_strcmp(uint16* s1, uint16* s2);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_strcmpCodePointOrder(uint16* s1, uint16* s2);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_strCompare(uint16* s1, int32 length1, uint16* s2, int32 length2, int8 codePointOrder);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_strCompareIter(UCharIterator* iter1, UCharIterator* iter2, int8 codePointOrder);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_strCaseCompare(uint16* s1, int32 length1, uint16* s2, int32 length2, uint32 options, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_strncmp(uint16* ucs1, uint16* ucs2, int32 n);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_strncmpCodePointOrder(uint16* s1, uint16* s2, int32 n);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_strcasecmp(uint16* s1, uint16* s2, uint32 options);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_strncasecmp(uint16* s1, uint16* s2, int32 n, uint32 options);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_memcasecmp(uint16* s1, uint16* s2, int32 length, uint32 options);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_strcpy(uint16* dst, uint16* src);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_strncpy(uint16* dst, uint16* src, int32 n);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_uastrcpy(uint16* dst, PSTR src);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_uastrncpy(uint16* dst, PSTR src, int32 n);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR u_austrcpy(PSTR dst, uint16* src);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR u_austrncpy(PSTR dst, uint16* src, int32 n);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_memcpy(uint16* dest, uint16* src, int32 count);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_memmove(uint16* dest, uint16* src, int32 count);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_memset(uint16* dest, uint16 c, int32 count);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_memcmp(uint16* buf1, uint16* buf2, int32 count);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_memcmpCodePointOrder(uint16* s1, uint16* s2, int32 count);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_memchr(uint16* s, uint16 c, int32 count);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_memchr32(uint16* s, int32 c, int32 count);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_memrchr(uint16* s, uint16 c, int32 count);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_memrchr32(uint16* s, int32 c, int32 count);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_unescape(PSTR src, uint16* dest, int32 destCapacity);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_unescapeAt(UNESCAPE_CHAR_AT charAt, int32* offset, int32 length, void* context);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_strToUpper(uint16* dest, int32 destCapacity, uint16* src, int32 srcLength, PSTR locale, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_strToLower(uint16* dest, int32 destCapacity, uint16* src, int32 srcLength, PSTR locale, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_strToTitle(uint16* dest, int32 destCapacity, uint16* src, int32 srcLength, UBreakIterator* titleIter, PSTR locale, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_strFoldCase(uint16* dest, int32 destCapacity, uint16* src, int32 srcLength, uint32 options, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR u_strToWCS(PWSTR dest, int32 destCapacity, int32* pDestLength, uint16* src, int32 srcLength, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_strFromWCS(uint16* dest, int32 destCapacity, int32* pDestLength, PWSTR src, int32 srcLength, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR u_strToUTF8(PSTR dest, int32 destCapacity, int32* pDestLength, uint16* src, int32 srcLength, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_strFromUTF8(uint16* dest, int32 destCapacity, int32* pDestLength, PSTR src, int32 srcLength, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR u_strToUTF8WithSub(PSTR dest, int32 destCapacity, int32* pDestLength, uint16* src, int32 srcLength, int32 subchar, int32* pNumSubstitutions, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_strFromUTF8WithSub(uint16* dest, int32 destCapacity, int32* pDestLength, PSTR src, int32 srcLength, int32 subchar, int32* pNumSubstitutions, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_strFromUTF8Lenient(uint16* dest, int32 destCapacity, int32* pDestLength, PSTR src, int32 srcLength, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32* u_strToUTF32(int32* dest, int32 destCapacity, int32* pDestLength, uint16* src, int32 srcLength, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_strFromUTF32(uint16* dest, int32 destCapacity, int32* pDestLength, int32* src, int32 srcLength, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32* u_strToUTF32WithSub(int32* dest, int32 destCapacity, int32* pDestLength, uint16* src, int32 srcLength, int32 subchar, int32* pNumSubstitutions, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_strFromUTF32WithSub(uint16* dest, int32 destCapacity, int32* pDestLength, int32* src, int32 srcLength, int32 subchar, int32* pNumSubstitutions, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR u_strToJavaModifiedUTF8(PSTR dest, int32 destCapacity, int32* pDestLength, uint16* src, int32 srcLength, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* u_strFromJavaModifiedUTF8WithSub(uint16* dest, int32 destCapacity, int32* pDestLength, PSTR src, int32 srcLength, int32 subchar, int32* pNumSubstitutions, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UCaseMap* ucasemap_open(PSTR locale, uint32 options, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucasemap_close(UCaseMap* csm);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ucasemap_getLocale(UCaseMap* csm);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ucasemap_getOptions(UCaseMap* csm);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucasemap_setLocale(UCaseMap* csm, PSTR locale, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucasemap_setOptions(UCaseMap* csm, uint32 options, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UBreakIterator* ucasemap_getBreakIterator(UCaseMap* csm);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucasemap_setBreakIterator(UCaseMap* csm, UBreakIterator* iterToAdopt, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucasemap_toTitle(UCaseMap* csm, uint16* dest, int32 destCapacity, uint16* src, int32 srcLength, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucasemap_utf8ToLower(UCaseMap* csm, PSTR dest, int32 destCapacity, PSTR src, int32 srcLength, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucasemap_utf8ToUpper(UCaseMap* csm, PSTR dest, int32 destCapacity, PSTR src, int32 srcLength, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucasemap_utf8ToTitle(UCaseMap* csm, PSTR dest, int32 destCapacity, PSTR src, int32 srcLength, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucasemap_utf8FoldCase(UCaseMap* csm, PSTR dest, int32 destCapacity, PSTR src, int32 srcLength, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UStringPrepProfile* usprep_open(PSTR path, PSTR fileName, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UStringPrepProfile* usprep_openByType(UStringPrepProfileType type, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void usprep_close(UStringPrepProfile* profile);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 usprep_prepare(UStringPrepProfile* prep, uint16* src, int32 srcLength, uint16* dest, int32 destCapacity, int32 options, UParseError* parseError, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UIDNA* uidna_openUTS46(uint32 options, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uidna_close(UIDNA* idna);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uidna_labelToASCII(UIDNA* idna, uint16* label, int32 length, uint16* dest, int32 capacity, UIDNAInfo* pInfo, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uidna_labelToUnicode(UIDNA* idna, uint16* label, int32 length, uint16* dest, int32 capacity, UIDNAInfo* pInfo, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uidna_nameToASCII(UIDNA* idna, uint16* name, int32 length, uint16* dest, int32 capacity, UIDNAInfo* pInfo, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uidna_nameToUnicode(UIDNA* idna, uint16* name, int32 length, uint16* dest, int32 capacity, UIDNAInfo* pInfo, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uidna_labelToASCII_UTF8(UIDNA* idna, PSTR label, int32 length, PSTR dest, int32 capacity, UIDNAInfo* pInfo, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uidna_labelToUnicodeUTF8(UIDNA* idna, PSTR label, int32 length, PSTR dest, int32 capacity, UIDNAInfo* pInfo, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uidna_nameToASCII_UTF8(UIDNA* idna, PSTR name, int32 length, PSTR dest, int32 capacity, UIDNAInfo* pInfo, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uidna_nameToUnicodeUTF8(UIDNA* idna, PSTR name, int32 length, PSTR dest, int32 capacity, UIDNAInfo* pInfo, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UBreakIterator* ubrk_open(UBreakIteratorType type, PSTR locale, uint16* text, int32 textLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UBreakIterator* ubrk_openRules(uint16* rules, int32 rulesLength, uint16* text, int32 textLength, UParseError* parseErr, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UBreakIterator* ubrk_openBinaryRules(uint8* binaryRules, int32 rulesLength, uint16* text, int32 textLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UBreakIterator* ubrk_safeClone(UBreakIterator* bi, void* stackBuffer, int32* pBufferSize, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ubrk_close(UBreakIterator* bi);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ubrk_setText(UBreakIterator* bi, uint16* text, int32 textLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ubrk_setUText(UBreakIterator* bi, UText* text, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ubrk_current(UBreakIterator* bi);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ubrk_next(UBreakIterator* bi);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ubrk_previous(UBreakIterator* bi);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ubrk_first(UBreakIterator* bi);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ubrk_last(UBreakIterator* bi);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ubrk_preceding(UBreakIterator* bi, int32 offset);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ubrk_following(UBreakIterator* bi, int32 offset);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ubrk_getAvailable(int32 index);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ubrk_countAvailable();

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 ubrk_isBoundary(UBreakIterator* bi, int32 offset);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ubrk_getRuleStatus(UBreakIterator* bi);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ubrk_getRuleStatusVec(UBreakIterator* bi, int32* fillInVec, int32 capacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ubrk_getLocaleByType(UBreakIterator* bi, ULocDataLocaleType type, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ubrk_refreshUText(UBreakIterator* bi, UText* text, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ubrk_getBinaryRules(UBreakIterator* bi, uint8* binaryRules, int32 rulesCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void u_getDataVersion(uint8* dataVersionFillin, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* ucal_openTimeZoneIDEnumeration(USystemTimeZoneType zoneType, PSTR region, int32* rawOffset, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* ucal_openTimeZones(UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* ucal_openCountryTimeZones(PSTR country, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucal_getDefaultTimeZone(uint16* result, int32 resultCapacity, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucal_setDefaultTimeZone(uint16* zoneID, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucal_getHostTimeZone(uint16* result, int32 resultCapacity, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucal_getDSTSavings(uint16* zoneID, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern double ucal_getNow();

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void** ucal_open(uint16* zoneID, int32 len, PSTR locale, UCalendarType type, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucal_close(void** cal);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void** ucal_clone(void** cal, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucal_setTimeZone(void** cal, uint16* zoneID, int32 len, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucal_getTimeZoneID(void** cal, uint16* result, int32 resultLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucal_getTimeZoneDisplayName(void** cal, UCalendarDisplayNameType type, PSTR locale, uint16* result, int32 resultLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 ucal_inDaylightTime(void** cal, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucal_setGregorianChange(void** cal, double date, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern double ucal_getGregorianChange(void** cal, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucal_getAttribute(void** cal, UCalendarAttribute attr);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucal_setAttribute(void** cal, UCalendarAttribute attr, int32 newValue);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ucal_getAvailable(int32 localeIndex);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucal_countAvailable();

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern double ucal_getMillis(void** cal, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucal_setMillis(void** cal, double dateTime, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucal_setDate(void** cal, int32 year, int32 month, int32 date, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucal_setDateTime(void** cal, int32 year, int32 month, int32 date, int32 hour, int32 minute, int32 second, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 ucal_equivalentTo(void** cal1, void** cal2);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucal_add(void** cal, UCalendarDateFields field, int32 amount, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucal_roll(void** cal, UCalendarDateFields field, int32 amount, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucal_get(void** cal, UCalendarDateFields field, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucal_set(void** cal, UCalendarDateFields field, int32 value);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 ucal_isSet(void** cal, UCalendarDateFields field);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucal_clearField(void** cal, UCalendarDateFields field);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucal_clear(void** calendar);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucal_getLimit(void** cal, UCalendarDateFields field, UCalendarLimitType type, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ucal_getLocaleByType(void** cal, ULocDataLocaleType type, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ucal_getTZDataVersion(UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucal_getCanonicalTimeZoneID(uint16* id, int32 len, uint16* result, int32 resultCapacity, int8* isSystemID, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ucal_getType(void** cal, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* ucal_getKeywordValuesForLocale(PSTR key, PSTR locale, int8 commonlyUsed, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UCalendarWeekdayType ucal_getDayOfWeekType(void** cal, UCalendarDaysOfWeek dayOfWeek, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucal_getWeekendTransition(void** cal, UCalendarDaysOfWeek dayOfWeek, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 ucal_isWeekend(void** cal, double date, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucal_getFieldDifference(void** cal, double target, UCalendarDateFields field, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 ucal_getTimeZoneTransitionDate(void** cal, UTimeZoneTransitionType type, double* transition, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucal_getWindowsTimeZoneID(uint16* id, int32 len, uint16* winid, int32 winidCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucal_getTimeZoneIDForWindowsID(uint16* winid, int32 len, PSTR region, uint16* id, int32 idCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UCollator* ucol_open(PSTR loc, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UCollator* ucol_openRules(uint16* rules, int32 rulesLength, UColAttributeValue normalizationMode, UColAttributeValue strength, UParseError* parseError, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucol_getContractionsAndExpansions(UCollator* coll, USet* contractions, USet* expansions, int8 addPrefixes, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucol_close(UCollator* coll);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UCollationResult ucol_strcoll(UCollator* coll, uint16* source, int32 sourceLength, uint16* target, int32 targetLength);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UCollationResult ucol_strcollUTF8(UCollator* coll, PSTR source, int32 sourceLength, PSTR target, int32 targetLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 ucol_greater(UCollator* coll, uint16* source, int32 sourceLength, uint16* target, int32 targetLength);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 ucol_greaterOrEqual(UCollator* coll, uint16* source, int32 sourceLength, uint16* target, int32 targetLength);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 ucol_equal(UCollator* coll, uint16* source, int32 sourceLength, uint16* target, int32 targetLength);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UCollationResult ucol_strcollIter(UCollator* coll, UCharIterator* sIter, UCharIterator* tIter, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UColAttributeValue ucol_getStrength(UCollator* coll);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucol_setStrength(UCollator* coll, UColAttributeValue strength);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucol_getReorderCodes(UCollator* coll, int32* dest, int32 destCapacity, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucol_setReorderCodes(UCollator* coll, int32* reorderCodes, int32 reorderCodesLength, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucol_getEquivalentReorderCodes(int32 reorderCode, int32* dest, int32 destCapacity, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucol_getDisplayName(PSTR objLoc, PSTR dispLoc, uint16* result, int32 resultLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ucol_getAvailable(int32 localeIndex);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucol_countAvailable();

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* ucol_openAvailableLocales(UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* ucol_getKeywords(UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* ucol_getKeywordValues(PSTR keyword, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* ucol_getKeywordValuesForLocale(PSTR key, PSTR locale, int8 commonlyUsed, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucol_getFunctionalEquivalent(PSTR result, int32 resultCapacity, PSTR keyword, PSTR locale, int8* isAvailable, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* ucol_getRules(UCollator* coll, int32* length);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucol_getSortKey(UCollator* coll, uint16* source, int32 sourceLength, uint8* result, int32 resultLength);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucol_nextSortKeyPart(UCollator* coll, UCharIterator* iter, uint32* state, uint8* dest, int32 count, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucol_getBound(uint8* source, int32 sourceLength, UColBoundMode boundType, uint32 noOfLevels, uint8* result, int32 resultLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucol_getVersion(UCollator* coll, uint8* info);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucol_getUCAVersion(UCollator* coll, uint8* info);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucol_mergeSortkeys(uint8* src1, int32 src1Length, uint8* src2, int32 src2Length, uint8* dest, int32 destCapacity);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucol_setAttribute(UCollator* coll, UColAttribute attr, UColAttributeValue value, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UColAttributeValue ucol_getAttribute(UCollator* coll, UColAttribute attr, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucol_setMaxVariable(UCollator* coll, UColReorderCode group, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UColReorderCode ucol_getMaxVariable(UCollator* coll);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ucol_getVariableTop(UCollator* coll, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UCollator* ucol_safeClone(UCollator* coll, void* stackBuffer, int32* pBufferSize, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucol_getRulesEx(UCollator* coll, UColRuleOption delta, uint16* buffer, int32 bufferLen);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ucol_getLocaleByType(UCollator* coll, ULocDataLocaleType type, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern USet* ucol_getTailoredSet(UCollator* coll, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucol_cloneBinary(UCollator* coll, uint8* buffer, int32 capacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UCollator* ucol_openBinary(uint8* bin, int32 length, UCollator* @base, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UCollationElements* ucol_openElements(UCollator* coll, uint16* text, int32 textLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucol_keyHashCode(uint8* key, int32 length);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucol_closeElements(UCollationElements* elems);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucol_reset(UCollationElements* elems);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucol_next(UCollationElements* elems, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucol_previous(UCollationElements* elems, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucol_getMaxExpansion(UCollationElements* elems, int32 order);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucol_setText(UCollationElements* elems, uint16* text, int32 textLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucol_getOffset(UCollationElements* elems);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucol_setOffset(UCollationElements* elems, int32 offset, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucol_primaryOrder(int32 order);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucol_secondaryOrder(int32 order);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucol_tertiaryOrder(int32 order);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UCharsetDetector* ucsdet_open(UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucsdet_close(UCharsetDetector* ucsd);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucsdet_setText(UCharsetDetector* ucsd, PSTR textIn, int32 len, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucsdet_setDeclaredEncoding(UCharsetDetector* ucsd, PSTR encoding, int32 length, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UCharsetMatch* ucsdet_detect(UCharsetDetector* ucsd, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UCharsetMatch** ucsdet_detectAll(UCharsetDetector* ucsd, int32* matchesFound, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ucsdet_getName(UCharsetMatch* ucsm, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucsdet_getConfidence(UCharsetMatch* ucsm, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ucsdet_getLanguage(UCharsetMatch* ucsm, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucsdet_getUChars(UCharsetMatch* ucsm, uint16* buf, int32 cap, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* ucsdet_getAllDetectableCharsets(UCharsetDetector* ucsd, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 ucsdet_isInputFilterEnabled(UCharsetDetector* ucsd);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 ucsdet_enableInputFilter(UCharsetDetector* ucsd, int8 filter);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UFieldPositionIterator* ufieldpositer_open(UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ufieldpositer_close(UFieldPositionIterator* fpositer);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ufieldpositer_next(UFieldPositionIterator* fpositer, int32* beginIndex, int32* endIndex);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void** ufmt_open(UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ufmt_close(void** fmt);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UFormattableType ufmt_getType(void** fmt, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 ufmt_isNumeric(void** fmt);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern double ufmt_getDate(void** fmt, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern double ufmt_getDouble(void** fmt, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ufmt_getLong(void** fmt, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int64 ufmt_getInt64(void** fmt, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* ufmt_getObject(void** fmt, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* ufmt_getUChars(void** fmt, int32* len, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ufmt_getArrayLength(void** fmt, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void** ufmt_getArrayItemByIndex(void** fmt, int32 n, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR ufmt_getDecNumChars(void** fmt, int32* len, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UConstrainedFieldPosition* ucfpos_open(UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucfpos_reset(UConstrainedFieldPosition* ucfpos, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucfpos_close(UConstrainedFieldPosition* ucfpos);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucfpos_constrainCategory(UConstrainedFieldPosition* ucfpos, int32 category, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucfpos_constrainField(UConstrainedFieldPosition* ucfpos, int32 category, int32 field, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucfpos_getCategory(UConstrainedFieldPosition* ucfpos, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ucfpos_getField(UConstrainedFieldPosition* ucfpos, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucfpos_getIndexes(UConstrainedFieldPosition* ucfpos, int32* pStart, int32* pLimit, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int64 ucfpos_getInt64IterationContext(UConstrainedFieldPosition* ucfpos, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucfpos_setInt64IterationContext(UConstrainedFieldPosition* ucfpos, int64 context, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 ucfpos_matchesField(UConstrainedFieldPosition* ucfpos, int32 category, int32 field, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ucfpos_setState(UConstrainedFieldPosition* ucfpos, int32 category, int32 field, int32 start, int32 limit, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* ufmtval_getString(UFormattedValue* ufmtval, int32* pLength, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 ufmtval_nextPosition(UFormattedValue* ufmtval, UConstrainedFieldPosition* ucfpos, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UDateIntervalFormat* udtitvfmt_open(PSTR locale, uint16* skeleton, int32 skeletonLength, uint16* tzID, int32 tzIDLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void udtitvfmt_close(UDateIntervalFormat* formatter);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UFormattedDateInterval* udtitvfmt_openResult(UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UFormattedValue* udtitvfmt_resultAsValue(UFormattedDateInterval* uresult, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void udtitvfmt_closeResult(UFormattedDateInterval* uresult);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 udtitvfmt_format(UDateIntervalFormat* formatter, double fromDate, double toDate, uint16* result, int32 resultCapacity, UFieldPosition* position, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UGenderInfo* ugender_getInstance(PSTR locale, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UGender ugender_getListGender(UGenderInfo* genderInfo, UGender* genders, int32 size, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UListFormatter* ulistfmt_open(PSTR locale, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UListFormatter* ulistfmt_openForType(PSTR locale, UListFormatterType type, UListFormatterWidth width, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ulistfmt_close(UListFormatter* listfmt);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UFormattedList* ulistfmt_openResult(UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UFormattedValue* ulistfmt_resultAsValue(UFormattedList* uresult, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ulistfmt_closeResult(UFormattedList* uresult);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ulistfmt_format(UListFormatter* listfmt, uint16** strings, int32* stringLengths, int32 stringCount, uint16* result, int32 resultCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ulistfmt_formatStringsToResult(UListFormatter* listfmt, uint16** strings, int32* stringLengths, int32 stringCount, UFormattedList* uresult, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern ULocaleData* ulocdata_open(PSTR localeID, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ulocdata_close(ULocaleData* uld);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ulocdata_setNoSubstitute(ULocaleData* uld, int8 setting);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 ulocdata_getNoSubstitute(ULocaleData* uld);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern USet* ulocdata_getExemplarSet(ULocaleData* uld, USet* fillIn, uint32 options, ULocaleDataExemplarSetType extype, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ulocdata_getDelimiter(ULocaleData* uld, ULocaleDataDelimiterType type, uint16* result, int32 resultLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UMeasurementSystem ulocdata_getMeasurementSystem(PSTR localeID, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ulocdata_getPaperSize(PSTR localeID, int32* height, int32* width, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ulocdata_getCLDRVersion(uint8* versionArray, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ulocdata_getLocaleDisplayPattern(ULocaleData* uld, uint16* pattern, int32 patternCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ulocdata_getLocaleSeparator(ULocaleData* uld, uint16* separator, int32 separatorCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_formatMessage(PSTR locale, uint16* pattern, int32 patternLength, uint16* result, int32 resultLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_vformatMessage(PSTR locale, uint16* pattern, int32 patternLength, uint16* result, int32 resultLength, int8* ap, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void u_parseMessage(PSTR locale, uint16* pattern, int32 patternLength, uint16* source, int32 sourceLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void u_vparseMessage(PSTR locale, uint16* pattern, int32 patternLength, uint16* source, int32 sourceLength, int8* ap, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_formatMessageWithError(PSTR locale, uint16* pattern, int32 patternLength, uint16* result, int32 resultLength, UParseError* parseError, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 u_vformatMessageWithError(PSTR locale, uint16* pattern, int32 patternLength, uint16* result, int32 resultLength, UParseError* parseError, int8* ap, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void u_parseMessageWithError(PSTR locale, uint16* pattern, int32 patternLength, uint16* source, int32 sourceLength, UParseError* parseError, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void u_vparseMessageWithError(PSTR locale, uint16* pattern, int32 patternLength, uint16* source, int32 sourceLength, int8* ap, UParseError* parseError, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void** umsg_open(uint16* pattern, int32 patternLength, PSTR locale, UParseError* parseError, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void umsg_close(void** format);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* umsg_clone(void** fmt, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void umsg_setLocale(void** fmt, PSTR locale);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR umsg_getLocale(void** fmt);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void umsg_applyPattern(void** fmt, uint16* pattern, int32 patternLength, UParseError* parseError, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 umsg_toPattern(void** fmt, uint16* result, int32 resultLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 umsg_format(void** fmt, uint16* result, int32 resultLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 umsg_vformat(void** fmt, uint16* result, int32 resultLength, int8* ap, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void umsg_parse(void** fmt, uint16* source, int32 sourceLength, int32* count, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void umsg_vparse(void** fmt, uint16* source, int32 sourceLength, int32* count, int8* ap, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 umsg_autoQuoteApostrophe(uint16* pattern, int32 patternLength, uint16* dest, int32 destCapacity, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void** unum_open(UNumberFormatStyle style, uint16* pattern, int32 patternLength, PSTR locale, UParseError* parseErr, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void unum_close(void** fmt);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void** unum_clone(void** fmt, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 unum_format(void** fmt, int32 number, uint16* result, int32 resultLength, UFieldPosition* pos, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 unum_formatInt64(void** fmt, int64 number, uint16* result, int32 resultLength, UFieldPosition* pos, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 unum_formatDouble(void** fmt, double number, uint16* result, int32 resultLength, UFieldPosition* pos, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 unum_formatDoubleForFields(void** format, double number, uint16* result, int32 resultLength, UFieldPositionIterator* fpositer, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 unum_formatDecimal(void** fmt, PSTR number, int32 length, uint16* result, int32 resultLength, UFieldPosition* pos, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 unum_formatDoubleCurrency(void** fmt, double number, uint16* currency, uint16* result, int32 resultLength, UFieldPosition* pos, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 unum_formatUFormattable(void** fmt, void** number, uint16* result, int32 resultLength, UFieldPosition* pos, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 unum_parse(void** fmt, uint16* text, int32 textLength, int32* parsePos, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int64 unum_parseInt64(void** fmt, uint16* text, int32 textLength, int32* parsePos, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern double unum_parseDouble(void** fmt, uint16* text, int32 textLength, int32* parsePos, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 unum_parseDecimal(void** fmt, uint16* text, int32 textLength, int32* parsePos, PSTR outBuf, int32 outBufLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern double unum_parseDoubleCurrency(void** fmt, uint16* text, int32 textLength, int32* parsePos, uint16* currency, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void** unum_parseToUFormattable(void** fmt, void** result, uint16* text, int32 textLength, int32* parsePos, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void unum_applyPattern(void** format, int8 localized, uint16* pattern, int32 patternLength, UParseError* parseError, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR unum_getAvailable(int32 localeIndex);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 unum_countAvailable();

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 unum_getAttribute(void** fmt, UNumberFormatAttribute attr);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void unum_setAttribute(void** fmt, UNumberFormatAttribute attr, int32 newValue);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern double unum_getDoubleAttribute(void** fmt, UNumberFormatAttribute attr);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void unum_setDoubleAttribute(void** fmt, UNumberFormatAttribute attr, double newValue);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 unum_getTextAttribute(void** fmt, UNumberFormatTextAttribute tag, uint16* result, int32 resultLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void unum_setTextAttribute(void** fmt, UNumberFormatTextAttribute tag, uint16* newValue, int32 newValueLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 unum_toPattern(void** fmt, int8 isPatternLocalized, uint16* result, int32 resultLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 unum_getSymbol(void** fmt, UNumberFormatSymbol symbol, uint16* buffer, int32 size, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void unum_setSymbol(void** fmt, UNumberFormatSymbol symbol, uint16* value, int32 length, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR unum_getLocaleByType(void** fmt, ULocDataLocaleType type, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void unum_setContext(void** fmt, UDisplayContext value, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UDisplayContext unum_getContext(void** fmt, UDisplayContextType type, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UCalendarDateFields udat_toCalendarDateField(UDateFormatField field);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void** udat_open(UDateFormatStyle timeStyle, UDateFormatStyle dateStyle, PSTR locale, uint16* tzID, int32 tzIDLength, uint16* pattern, int32 patternLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void udat_close(void** format);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 udat_getBooleanAttribute(void** fmt, UDateFormatBooleanAttribute attr, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void udat_setBooleanAttribute(void** fmt, UDateFormatBooleanAttribute attr, int8 newValue, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void** udat_clone(void** fmt, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 udat_format(void** format, double dateToFormat, uint16* result, int32 resultLength, UFieldPosition* position, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 udat_formatCalendar(void** format, void** calendar, uint16* result, int32 capacity, UFieldPosition* position, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 udat_formatForFields(void** format, double dateToFormat, uint16* result, int32 resultLength, UFieldPositionIterator* fpositer, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 udat_formatCalendarForFields(void** format, void** calendar, uint16* result, int32 capacity, UFieldPositionIterator* fpositer, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern double udat_parse(void** format, uint16* text, int32 textLength, int32* parsePos, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void udat_parseCalendar(void** format, void** calendar, uint16* text, int32 textLength, int32* parsePos, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 udat_isLenient(void** fmt);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void udat_setLenient(void** fmt, int8 isLenient);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void** udat_getCalendar(void** fmt);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void udat_setCalendar(void** fmt, void** calendarToSet);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void** udat_getNumberFormat(void** fmt);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void** udat_getNumberFormatForField(void** fmt, uint16 field);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void udat_adoptNumberFormatForFields(void** fmt, uint16* fields, void** numberFormatToSet, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void udat_setNumberFormat(void** fmt, void** numberFormatToSet);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void udat_adoptNumberFormat(void** fmt, void** numberFormatToAdopt);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR udat_getAvailable(int32 localeIndex);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 udat_countAvailable();

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern double udat_get2DigitYearStart(void** fmt, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void udat_set2DigitYearStart(void** fmt, double d, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 udat_toPattern(void** fmt, int8 localized, uint16* result, int32 resultLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void udat_applyPattern(void** format, int8 localized, uint16* pattern, int32 patternLength);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 udat_getSymbols(void** fmt, UDateFormatSymbolType type, int32 symbolIndex, uint16* result, int32 resultLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 udat_countSymbols(void** fmt, UDateFormatSymbolType type);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void udat_setSymbols(void** format, UDateFormatSymbolType type, int32 symbolIndex, uint16* value, int32 valueLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR udat_getLocaleByType(void** fmt, ULocDataLocaleType type, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void udat_setContext(void** fmt, UDisplayContext value, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UDisplayContext udat_getContext(void** fmt, UDisplayContextType type, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void** udatpg_open(PSTR locale, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void** udatpg_openEmpty(UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void udatpg_close(void** dtpg);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void** udatpg_clone(void** dtpg, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 udatpg_getBestPattern(void** dtpg, uint16* skeleton, int32 length, uint16* bestPattern, int32 capacity, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 udatpg_getBestPatternWithOptions(void** dtpg, uint16* skeleton, int32 length, UDateTimePatternMatchOptions options, uint16* bestPattern, int32 capacity, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 udatpg_getSkeleton(void** unusedDtpg, uint16* pattern, int32 length, uint16* skeleton, int32 capacity, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 udatpg_getBaseSkeleton(void** unusedDtpg, uint16* pattern, int32 length, uint16* baseSkeleton, int32 capacity, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UDateTimePatternConflict udatpg_addPattern(void** dtpg, uint16* pattern, int32 patternLength, int8 @override, uint16* conflictingPattern, int32 capacity, int32* pLength, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void udatpg_setAppendItemFormat(void** dtpg, UDateTimePatternField field, uint16* value, int32 length);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* udatpg_getAppendItemFormat(void** dtpg, UDateTimePatternField field, int32* pLength);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void udatpg_setAppendItemName(void** dtpg, UDateTimePatternField field, uint16* value, int32 length);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* udatpg_getAppendItemName(void** dtpg, UDateTimePatternField field, int32* pLength);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 udatpg_getFieldDisplayName(void** dtpg, UDateTimePatternField field, UDateTimePGDisplayWidth width, uint16* fieldName, int32 capacity, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void udatpg_setDateTimeFormat(void** dtpg, uint16* dtFormat, int32 length);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* udatpg_getDateTimeFormat(void** dtpg, int32* pLength);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void udatpg_setDecimal(void** dtpg, uint16* decimal, int32 length);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* udatpg_getDecimal(void** dtpg, int32* pLength);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 udatpg_replaceFieldTypes(void** dtpg, uint16* pattern, int32 patternLength, uint16* skeleton, int32 skeletonLength, uint16* dest, int32 destCapacity, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 udatpg_replaceFieldTypesWithOptions(void** dtpg, uint16* pattern, int32 patternLength, uint16* skeleton, int32 skeletonLength, UDateTimePatternMatchOptions options, uint16* dest, int32 destCapacity, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* udatpg_openSkeletons(void** dtpg, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* udatpg_openBaseSkeletons(void** dtpg, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* udatpg_getPatternForSkeleton(void** dtpg, uint16* skeleton, int32 skeletonLength, int32* pLength);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UNumberFormatter* unumf_openForSkeletonAndLocale(uint16* skeleton, int32 skeletonLen, PSTR locale, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UNumberFormatter* unumf_openForSkeletonAndLocaleWithError(uint16* skeleton, int32 skeletonLen, PSTR locale, UParseError* perror, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UFormattedNumber* unumf_openResult(UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void unumf_formatInt(UNumberFormatter* uformatter, int64 value, UFormattedNumber* uresult, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void unumf_formatDouble(UNumberFormatter* uformatter, double value, UFormattedNumber* uresult, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void unumf_formatDecimal(UNumberFormatter* uformatter, PSTR value, int32 valueLen, UFormattedNumber* uresult, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UFormattedValue* unumf_resultAsValue(UFormattedNumber* uresult, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 unumf_resultToString(UFormattedNumber* uresult, uint16* buffer, int32 bufferCapacity, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 unumf_resultNextFieldPosition(UFormattedNumber* uresult, UFieldPosition* ufpos, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void unumf_resultGetAllFieldPositions(UFormattedNumber* uresult, UFieldPositionIterator* ufpositer, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void unumf_close(UNumberFormatter* uformatter);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void unumf_closeResult(UFormattedNumber* uresult);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UNumberingSystem* unumsys_open(PSTR locale, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UNumberingSystem* unumsys_openByName(PSTR name, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void unumsys_close(UNumberingSystem* unumsys);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* unumsys_openAvailableNames(UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR unumsys_getName(UNumberingSystem* unumsys);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 unumsys_isAlgorithmic(UNumberingSystem* unumsys);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 unumsys_getRadix(UNumberingSystem* unumsys);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 unumsys_getDescription(UNumberingSystem* unumsys, uint16* result, int32 resultLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UPluralRules* uplrules_open(PSTR locale, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UPluralRules* uplrules_openForType(PSTR locale, UPluralType type, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uplrules_close(UPluralRules* uplrules);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uplrules_select(UPluralRules* uplrules, double number, uint16* keyword, int32 capacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uplrules_selectFormatted(UPluralRules* uplrules, UFormattedNumber* number, uint16* keyword, int32 capacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* uplrules_getKeywords(UPluralRules* uplrules, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern URegularExpression* uregex_open(uint16* pattern, int32 patternLength, uint32 flags, UParseError* pe, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern URegularExpression* uregex_openUText(UText* pattern, uint32 flags, UParseError* pe, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern URegularExpression* uregex_openC(PSTR pattern, uint32 flags, UParseError* pe, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uregex_close(URegularExpression* regexp);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern URegularExpression* uregex_clone(URegularExpression* regexp, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* uregex_pattern(URegularExpression* regexp, int32* patLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UText* uregex_patternUText(URegularExpression* regexp, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uregex_flags(URegularExpression* regexp, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uregex_setText(URegularExpression* regexp, uint16* text, int32 textLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uregex_setUText(URegularExpression* regexp, UText* text, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* uregex_getText(URegularExpression* regexp, int32* textLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UText* uregex_getUText(URegularExpression* regexp, UText* dest, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uregex_refreshUText(URegularExpression* regexp, UText* text, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uregex_matches(URegularExpression* regexp, int32 startIndex, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uregex_matches64(URegularExpression* regexp, int64 startIndex, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uregex_lookingAt(URegularExpression* regexp, int32 startIndex, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uregex_lookingAt64(URegularExpression* regexp, int64 startIndex, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uregex_find(URegularExpression* regexp, int32 startIndex, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uregex_find64(URegularExpression* regexp, int64 startIndex, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uregex_findNext(URegularExpression* regexp, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uregex_groupCount(URegularExpression* regexp, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uregex_groupNumberFromName(URegularExpression* regexp, uint16* groupName, int32 nameLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uregex_groupNumberFromCName(URegularExpression* regexp, PSTR groupName, int32 nameLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uregex_group(URegularExpression* regexp, int32 groupNum, uint16* dest, int32 destCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UText* uregex_groupUText(URegularExpression* regexp, int32 groupNum, UText* dest, int64* groupLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uregex_start(URegularExpression* regexp, int32 groupNum, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int64 uregex_start64(URegularExpression* regexp, int32 groupNum, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uregex_end(URegularExpression* regexp, int32 groupNum, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int64 uregex_end64(URegularExpression* regexp, int32 groupNum, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uregex_reset(URegularExpression* regexp, int32 index, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uregex_reset64(URegularExpression* regexp, int64 index, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uregex_setRegion(URegularExpression* regexp, int32 regionStart, int32 regionLimit, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uregex_setRegion64(URegularExpression* regexp, int64 regionStart, int64 regionLimit, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uregex_setRegionAndStart(URegularExpression* regexp, int64 regionStart, int64 regionLimit, int64 startIndex, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uregex_regionStart(URegularExpression* regexp, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int64 uregex_regionStart64(URegularExpression* regexp, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uregex_regionEnd(URegularExpression* regexp, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int64 uregex_regionEnd64(URegularExpression* regexp, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uregex_hasTransparentBounds(URegularExpression* regexp, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uregex_useTransparentBounds(URegularExpression* regexp, int8 b, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uregex_hasAnchoringBounds(URegularExpression* regexp, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uregex_useAnchoringBounds(URegularExpression* regexp, int8 b, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uregex_hitEnd(URegularExpression* regexp, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uregex_requireEnd(URegularExpression* regexp, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uregex_replaceAll(URegularExpression* regexp, uint16* replacementText, int32 replacementLength, uint16* destBuf, int32 destCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UText* uregex_replaceAllUText(URegularExpression* regexp, UText* replacement, UText* dest, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uregex_replaceFirst(URegularExpression* regexp, uint16* replacementText, int32 replacementLength, uint16* destBuf, int32 destCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UText* uregex_replaceFirstUText(URegularExpression* regexp, UText* replacement, UText* dest, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uregex_appendReplacement(URegularExpression* regexp, uint16* replacementText, int32 replacementLength, uint16** destBuf, int32* destCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uregex_appendReplacementUText(URegularExpression* regexp, UText* replacementText, UText* dest, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uregex_appendTail(URegularExpression* regexp, uint16** destBuf, int32* destCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UText* uregex_appendTailUText(URegularExpression* regexp, UText* dest, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uregex_split(URegularExpression* regexp, uint16* destBuf, int32 destCapacity, int32* requiredCapacity, uint16** destFields, int32 destFieldsCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uregex_splitUText(URegularExpression* regexp, UText** destFields, int32 destFieldsCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uregex_setTimeLimit(URegularExpression* regexp, int32 limit, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uregex_getTimeLimit(URegularExpression* regexp, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uregex_setStackLimit(URegularExpression* regexp, int32 limit, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uregex_getStackLimit(URegularExpression* regexp, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uregex_setMatchCallback(URegularExpression* regexp, URegexMatchCallback callback, void* context, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uregex_getMatchCallback(URegularExpression* regexp, URegexMatchCallback* callback, void** context, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uregex_setFindProgressCallback(URegularExpression* regexp, URegexFindProgressCallback callback, void* context, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uregex_getFindProgressCallback(URegularExpression* regexp, URegexFindProgressCallback* callback, void** context, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern URegion* uregion_getRegionFromCode(PSTR regionCode, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern URegion* uregion_getRegionFromNumericCode(int32 code, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* uregion_getAvailable(URegionType type, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uregion_areEqual(URegion* uregion, URegion* otherRegion);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern URegion* uregion_getContainingRegion(URegion* uregion);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern URegion* uregion_getContainingRegionOfType(URegion* uregion, URegionType type);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* uregion_getContainedRegions(URegion* uregion, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* uregion_getContainedRegionsOfType(URegion* uregion, URegionType type, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8 uregion_contains(URegion* uregion, URegion* otherRegion);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* uregion_getPreferredValues(URegion* uregion, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR uregion_getRegionCode(URegion* uregion);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uregion_getNumericCode(URegion* uregion);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern URegionType uregion_getType(URegion* uregion);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern URelativeDateTimeFormatter* ureldatefmt_open(PSTR locale, void** nfToAdopt, UDateRelativeDateTimeFormatterStyle width, UDisplayContext capitalizationContext, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ureldatefmt_close(URelativeDateTimeFormatter* reldatefmt);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UFormattedRelativeDateTime* ureldatefmt_openResult(UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UFormattedValue* ureldatefmt_resultAsValue(UFormattedRelativeDateTime* ufrdt, UErrorCode* ec);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ureldatefmt_closeResult(UFormattedRelativeDateTime* ufrdt);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ureldatefmt_formatNumeric(URelativeDateTimeFormatter* reldatefmt, double offset, URelativeDateTimeUnit unit, uint16* result, int32 resultCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ureldatefmt_formatNumericToResult(URelativeDateTimeFormatter* reldatefmt, double offset, URelativeDateTimeUnit unit, UFormattedRelativeDateTime* result, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ureldatefmt_format(URelativeDateTimeFormatter* reldatefmt, double offset, URelativeDateTimeUnit unit, uint16* result, int32 resultCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ureldatefmt_formatToResult(URelativeDateTimeFormatter* reldatefmt, double offset, URelativeDateTimeUnit unit, UFormattedRelativeDateTime* result, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ureldatefmt_combineDateAndTime(URelativeDateTimeFormatter* reldatefmt, uint16* relativeDateString, int32 relativeDateStringLen, uint16* timeString, int32 timeStringLen, uint16* result, int32 resultCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UStringSearch* usearch_open(uint16* pattern, int32 patternlength, uint16* text, int32 textlength, PSTR locale, UBreakIterator* breakiter, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UStringSearch* usearch_openFromCollator(uint16* pattern, int32 patternlength, uint16* text, int32 textlength, UCollator* collator, UBreakIterator* breakiter, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void usearch_close(UStringSearch* searchiter);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void usearch_setOffset(UStringSearch* strsrch, int32 position, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 usearch_getOffset(UStringSearch* strsrch);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void usearch_setAttribute(UStringSearch* strsrch, USearchAttribute attribute, USearchAttributeValue value, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern USearchAttributeValue usearch_getAttribute(UStringSearch* strsrch, USearchAttribute attribute);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 usearch_getMatchedStart(UStringSearch* strsrch);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 usearch_getMatchedLength(UStringSearch* strsrch);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 usearch_getMatchedText(UStringSearch* strsrch, uint16* result, int32 resultCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void usearch_setBreakIterator(UStringSearch* strsrch, UBreakIterator* breakiter, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UBreakIterator* usearch_getBreakIterator(UStringSearch* strsrch);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void usearch_setText(UStringSearch* strsrch, uint16* text, int32 textlength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* usearch_getText(UStringSearch* strsrch, int32* length);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UCollator* usearch_getCollator(UStringSearch* strsrch);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void usearch_setCollator(UStringSearch* strsrch, UCollator* collator, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void usearch_setPattern(UStringSearch* strsrch, uint16* pattern, int32 patternlength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* usearch_getPattern(UStringSearch* strsrch, int32* length);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 usearch_first(UStringSearch* strsrch, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 usearch_following(UStringSearch* strsrch, int32 position, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 usearch_last(UStringSearch* strsrch, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 usearch_preceding(UStringSearch* strsrch, int32 position, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 usearch_next(UStringSearch* strsrch, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 usearch_previous(UStringSearch* strsrch, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void usearch_reset(UStringSearch* strsrch);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern USpoofChecker* uspoof_open(UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern USpoofChecker* uspoof_openFromSerialized(void* data, int32 length, int32* pActualLength, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern USpoofChecker* uspoof_openFromSource(PSTR confusables, int32 confusablesLen, PSTR confusablesWholeScript, int32 confusablesWholeScriptLen, int32* errType, UParseError* pe, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uspoof_close(USpoofChecker* sc);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern USpoofChecker* uspoof_clone(USpoofChecker* sc, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uspoof_setChecks(USpoofChecker* sc, int32 checks, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uspoof_getChecks(USpoofChecker* sc, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uspoof_setRestrictionLevel(USpoofChecker* sc, URestrictionLevel restrictionLevel);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern URestrictionLevel uspoof_getRestrictionLevel(USpoofChecker* sc);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uspoof_setAllowedLocales(USpoofChecker* sc, PSTR localesList, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR uspoof_getAllowedLocales(USpoofChecker* sc, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uspoof_setAllowedChars(USpoofChecker* sc, USet* chars, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern USet* uspoof_getAllowedChars(USpoofChecker* sc, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uspoof_check(USpoofChecker* sc, uint16* id, int32 length, int32* position, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uspoof_checkUTF8(USpoofChecker* sc, PSTR id, int32 length, int32* position, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uspoof_check2(USpoofChecker* sc, uint16* id, int32 length, USpoofCheckResult* checkResult, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uspoof_check2UTF8(USpoofChecker* sc, PSTR id, int32 length, USpoofCheckResult* checkResult, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern USpoofCheckResult* uspoof_openCheckResult(UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void uspoof_closeCheckResult(USpoofCheckResult* checkResult);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uspoof_getCheckResultChecks(USpoofCheckResult* checkResult, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern URestrictionLevel uspoof_getCheckResultRestrictionLevel(USpoofCheckResult* checkResult, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern USet* uspoof_getCheckResultNumerics(USpoofCheckResult* checkResult, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uspoof_areConfusable(USpoofChecker* sc, uint16* id1, int32 length1, uint16* id2, int32 length2, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uspoof_areConfusableUTF8(USpoofChecker* sc, PSTR id1, int32 length1, PSTR id2, int32 length2, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uspoof_getSkeleton(USpoofChecker* sc, uint32 type, uint16* id, int32 length, uint16* dest, int32 destCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uspoof_getSkeletonUTF8(USpoofChecker* sc, uint32 type, PSTR id, int32 length, PSTR dest, int32 destCapacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern USet* uspoof_getInclusionSet(UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern USet* uspoof_getRecommendedSet(UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 uspoof_serialize(USpoofChecker* sc, void* data, int32 capacity, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int64 utmscale_getTimeScaleValue(UDateTimeScale timeScale, UTimeScaleValue value, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int64 utmscale_fromInt64(int64 otherTime, UDateTimeScale timeScale, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int64 utmscale_toInt64(int64 universalTime, UDateTimeScale timeScale, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void** utrans_openU(uint16* id, int32 idLength, UTransDirection dir, uint16* rules, int32 rulesLength, UParseError* parseError, UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void** utrans_openInverse(void** trans, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void** utrans_clone(void** trans, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void utrans_close(void** trans);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16* utrans_getUnicodeID(void** trans, int32* resultLength);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void utrans_register(void** adoptedTrans, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void utrans_unregisterID(uint16* id, int32 idLength);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void utrans_setFilter(void** trans, uint16* filterPattern, int32 filterPatternLen, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 utrans_countAvailableIDs();

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern UEnumeration* utrans_openIDs(UErrorCode* pErrorCode);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void utrans_trans(void** trans, void** rep, UReplaceableCallbacks* repFunc, int32 start, int32* limit, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void utrans_transIncremental(void** trans, void** rep, UReplaceableCallbacks* repFunc, UTransPosition* pos, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void utrans_transUChars(void** trans, uint16* text, int32* textLength, int32 textCapacity, int32 start, int32* limit, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void utrans_transIncrementalUChars(void** trans, uint16* text, int32* textLength, int32 textCapacity, UTransPosition* pos, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 utrans_toRules(void** trans, int8 escapeUnprintable, uint16* result, int32 resultLength, UErrorCode* status);

	[Import("icu.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern USet* utrans_getSourceSet(void** trans, int8 ignoreFilter, USet* fillIn, UErrorCode* status);

	[Import("bcp47mrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetDistanceOfClosestLanguageInList(PWSTR pszLanguage, PWSTR pszLanguagesList, char16 wchListDelimiter, double* pClosestDistance);

	[Import("bcp47mrm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8 IsWellFormedTag(PWSTR pszTag);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 FindStringOrdinal(uint32 dwFindStringOrdinalFlags, char16* lpStringSource, int32 cchSource, char16* lpStringValue, int32 cchValue, BOOL bIgnoreCase);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 lstrcmpA(PSTR lpString1, PSTR lpString2);
	public static int32 lstrcmp(PSTR lpString1, PSTR lpString2) => lstrcmpA(lpString1, lpString2);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 lstrcmpW(PWSTR lpString1, PWSTR lpString2);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 lstrcmpiA(PSTR lpString1, PSTR lpString2);
	public static int32 lstrcmpi(PSTR lpString1, PSTR lpString2) => lstrcmpiA(lpString1, lpString2);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 lstrcmpiW(PWSTR lpString1, PWSTR lpString2);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR lstrcpynA(uint8* lpString1, PSTR lpString2, int32 iMaxLength);
	public static PSTR lstrcpyn(uint8* lpString1, PSTR lpString2, int32 iMaxLength) => lstrcpynA(lpString1, lpString2, iMaxLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR lstrcpynW(char16* lpString1, PWSTR lpString2, int32 iMaxLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR lstrcpyA(PSTR lpString1, PSTR lpString2);
	public static PSTR lstrcpy(PSTR lpString1, PSTR lpString2) => lstrcpyA(lpString1, lpString2);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR lstrcpyW(PWSTR lpString1, PWSTR lpString2);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR lstrcatA(PSTR lpString1, PSTR lpString2);
	public static PSTR lstrcat(PSTR lpString1, PSTR lpString2) => lstrcatA(lpString1, lpString2);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR lstrcatW(PWSTR lpString1, PWSTR lpString2);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 lstrlenA(PSTR lpString);
	public static int32 lstrlen(PSTR lpString) => lstrlenA(lpString);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 lstrlenW(PWSTR lpString);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsTextUnicode(void* lpv, int32 iSize, IS_TEXT_UNICODE_RESULT* lpiResult);

}
#endregion

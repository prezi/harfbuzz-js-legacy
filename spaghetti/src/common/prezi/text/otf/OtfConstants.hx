package prezi.text.otf;

class OtfConstants
{
	public static inline var MISSING_GLYPH_CODE:Int = 0;

	public static inline var GLYPH_TYPE_SIMPLE:Int = 0x01;
	public static inline var GLYPH_TYPE_COMPOSITE_TTF:Int = 0x10;
	public static inline var GLYPH_TYPE_COMPOSITE_CFF:Int = 0x11;

	// Drawing commands
	public static inline var COMMAND_MOVE_TO:Int = 1;
	public static inline var COMMAND_LINE_TO:Int = 2;
	public static inline var COMMAND_CURVE_TO:Int = 3;
	public static inline var COMMAND_CUBIC_CURVE_TO:Int = 4;
}

package prezi.text.otf;

/**
 * OS/2 - OS/2 - OS/2 and Windows Metrics
 * http://www.microsoft.com/typography/otspec/this.htm
 */
class OtfOs2Table
{
	public var fsSelection (default, null):Int;
	public var sTypoAscender (default, null):Int;
	public var sTypoDescender (default, null):Int;
	public var sTypoLineGap (default, null):Int;
	public var usWinAscent (default, null):Int;
	public var usWinDescent (default, null):Int;

	public function new(reader:IFontFileReader, header:OtfTableHeader)
	{
		reader.seek(header.offset);
		reader.readUShort(); // version
		reader.readShort(); // xAvgCharWidth
		reader.readUShort(); // usWeightClass
		reader.readUShort(); // usWidthClass
		reader.readUShort(); // fsType
		reader.readShort(); // ySubscriptXSize
		reader.readShort(); // ySubscriptYSize
		reader.readShort(); // ySubscriptXOffset
		reader.readShort(); // ySubscriptYOffset
		reader.readShort(); // ySuperscriptXSize
		reader.readShort(); // ySuperscriptYSize
		reader.readShort(); // ySuperscriptXOffset
		reader.readShort(); // ySuperscriptYOffset
		reader.readShort(); // strikeOutSize
		reader.readShort(); // strikeOutPosition
		reader.readShort(); // familyClass
		reader.readByte(); // bFamilyType
		reader.readByte(); // bSerifStyle
		reader.readByte(); // bWeight
		reader.readByte(); // bProportion
		reader.readByte(); // bContrast
		reader.readByte(); // bStrokeVariation
		reader.readByte(); // bArmStyle
		reader.readByte(); // bLetterform
		reader.readByte(); // bMidline
		reader.readByte(); // bXHeight
		reader.readULong(); // ulUnicodeRange1
		reader.readULong(); // ulUnicodeRange2
		reader.readULong(); // ulUnicodeRange3
		reader.readULong(); // ulUnicodeRange4
		reader.readByte(); // achVendID1
		reader.readByte(); // achVendID2
		reader.readByte(); // achVendID3
		reader.readByte(); // achVendID4
		this.fsSelection = reader.readUShort(); // fsSelection
		reader.readUShort(); // usFirstCharIndex
		reader.readUShort(); // usLastCharIndex
		this.sTypoAscender = reader.readShort(); // sTypoAscender
		this.sTypoDescender = reader.readShort(); // sTypoDescender
		this.sTypoLineGap = reader.readShort(); // sTypoLineGap
		this.usWinAscent = reader.readUShort(); // usWinAscent
		this.usWinDescent = reader.readUShort(); // usWinDescent
		// reader.readULong(); // ulCodePageRange1
		// reader.readULong(); // ulCodePageRange2
		// reader.readShort(); // sxHeight
		// reader.readShort(); // sCapHeight
		// reader.readUShort(); // usDefaultChar
		// reader.readUShort(); // usBreakChar
		// reader.readUShort(); // usMaxContext
	}
}

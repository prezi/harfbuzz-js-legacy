package prezi.text.otf;

/**
 * head - Font Header
 * http://www.microsoft.com/typography/otspec/this.htm
 */
class OtfHeadTable
{
	private static inline var MAGIC_NUMBER:Int = 0x5F0F3CF5;

	public var flags (default, null):Int;
	public var unitsPerEm (default, null):Int;
	public var xMin (default, null):Int;
	public var yMin (default, null):Int;
	public var xMax (default, null):Int;
	public var yMax (default, null):Int;
	public var macStyle (default, null):Int;
	public var indexToLocFormat (default, null):Int;

	public function new(reader:IFontFileReader, header:OtfTableHeader)
	{
		reader.seek(header.offset);
		reader.readFixed(); // version
		reader.readFixed(); // fontRevision
		reader.readULong(); // checkSumAdjustment
		var magicNumber = reader.readULong();
		if (magicNumber != MAGIC_NUMBER)
		{
			throw "Invalid font magic number: " + magicNumber;
		}
		this.flags = reader.readUShort();
		this.unitsPerEm = reader.readUShort();
		reader.readLongDateTime(); // created
		reader.readLongDateTime(); // modified
		this.xMin = reader.readShort();
		this.yMin = reader.readShort();
		this.xMax = reader.readShort();
		this.yMax = reader.readShort();
		this.macStyle = reader.readUShort();
		reader.readUShort(); // lowestRecPPEM
		reader.readShort(); // fontDirectionHint
		this.indexToLocFormat = reader.readShort();
		reader.readShort(); // glyphDataFormat
	}
}

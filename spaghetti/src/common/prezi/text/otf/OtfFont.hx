package prezi.text.otf;

class OtfFont
{
	public static inline var USE_TYPO_METRICS:Int = 1<<7;

	public static inline var TAG_CODE_SFNT:Int = 0x00010000;
	public static inline var TAG_CODE_OTTO:Int = 0x4F54544F;

	public var tag (default, null):Int;
	public var unitsPerEm (default, null):Int;
	public var ttfScale (default, null):Int;
	public var numGlyphs (default, null):Int;
	public var ascent (default, null):Int;
	public var descent (default, null):Int;
	public var lineGap (default, null):Int;
	public var lineHeight (default, null):Int;
	public var numberOfHMetrics (default, null):Int;
	public var italicAngle (default, null):Float;
	public var underlinePosition (default, null):Int;
	public var underlineThickness (default, null):Int;

	private var tableHeaders:Map<String,OtfTableHeader>;

	private var reader:IFontFileReader;
	private var glyphs:IGlyphLookup;
	private var cmap:OtfCmapTable;
	private var hmtx:OtfHmtxTable;

	public function new(reader:IFontFileReader)
	{
		this.reader = reader;

		this.tag = reader.readULong();
		var numTables = reader.readUShort();
		reader.readUShort(); // searchRange
		reader.readUShort(); // entrySelector
		reader.readUShort(); // rangeShift
		this.tableHeaders = new Map<String,OtfTableHeader>();
		for (tableIdx in 0...numTables)
		{
			var tableHeader = new OtfTableHeader(reader);
			tableHeaders.set(getTagName(tableHeader.tag), tableHeader);
		}

		// TrueType outlines return each coordinate, advance with
		// and any other font parameter measured in font units
		// multiplied by two. This is because TrueType uses a storage
		// mechanism that requires us to calculate points halfway
		// between two points. Had we not multiplied all coordinates,
		// by two, the midpoints could end up on non-integer
		// coordinates, and thus we couldn't use integer logic. So
		// we multiply instead. This should be transparent to any
		// calling code.
		this.ttfScale = (tag == TAG_CODE_SFNT) ? 2 : 1;

		var head = new OtfHeadTable(reader, tableHeaders.get("head"));
		var hhea = new OtfHheaTable(reader, tableHeaders.get("hhea"));
		this.numberOfHMetrics = hhea.numberOfHMetrics;
		this.hmtx = new OtfHmtxTable(reader, tableHeaders.get("hmtx"), numberOfHMetrics);

		this.cmap = new OtfCmapTable(reader, tableHeaders.get("cmap"));
		var post = new OtfPostTable(reader, tableHeaders.get("post"));
		var os2 = null;
		if (tableHeaders.get("OS/2") != null)
		{
			os2 = new OtfOs2Table(reader, tableHeaders.get("OS/2"));
		}

		switch (tag)
		{
			case TAG_CODE_SFNT:
				var maxp = new OtfMaxpTable(reader, tableHeaders.get("maxp"));
				this.glyphs = new TtfGlyfTable(reader, head.indexToLocFormat,
					tableHeaders.get("loca"), tableHeaders.get("glyf"));
				this.numGlyphs = maxp.numGlyphs;
			case TAG_CODE_OTTO:
				var glyphs = new CffTable(reader, tableHeaders.get("CFF "));
				this.numGlyphs = glyphs.charStringsIndex.count;
				this.glyphs = glyphs;
		}

		this.unitsPerEm = head.unitsPerEm * ttfScale;

		var useTypoMetrics = (os2 != null)
			&& ((os2.fsSelection & USE_TYPO_METRICS) != 0);
		if (useTypoMetrics || hhea.ascent == 0)
		{
			this.ascent = os2.sTypoAscender * ttfScale;
			this.descent = os2.sTypoDescender * ttfScale;
			this.lineGap = os2.sTypoLineGap * ttfScale;
		}
		else
		{
			this.ascent = hhea.ascent * ttfScale;
			this.descent = hhea.descent * ttfScale;
			this.lineGap = hhea.lineGap * ttfScale;
		}

		this.lineHeight = ascent - descent + lineGap;

		this.italicAngle = post.italicAngle;
		this.underlinePosition = post.underlinePosition * ttfScale;
		if (underlinePosition == 0)
		{
			underlinePosition = descent >> 1;
		}
		this.underlineThickness = post.underlineThickness * ttfScale;
		if (underlineThickness == 0)
		{
			underlineThickness = (-descent) >> 2;
		}
	}
		
	public function advanceWidth(glyphCode:Int):Int
	{
		return ttfScale * hmtx.advanceWidth(glyphCode);
	}

	public function unicodeToGlyphCode(unicode:Int):Int
	{
		return cmap.unicodeToGlyphCode(unicode);
	}

	public function glyphOutline(glyphCode:Int):Array<Int>
	{
		return glyphs.glyphOutline(glyphCode);
	}

	private static inline function getTagName(code:Int):String
	{
		return String.fromCharCode(code >>> 24)
			+ String.fromCharCode((code >>> 16) & 0xFF)
			+ String.fromCharCode((code >>> 8) & 0xFF)
			+ String.fromCharCode(code & 0xFF);
	}
}

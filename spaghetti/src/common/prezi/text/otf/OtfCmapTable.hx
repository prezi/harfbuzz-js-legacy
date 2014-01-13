package prezi.text.otf;

/**
 * cmap - Character To Glyph Index Mapping Table
 * http://www.microsoft.com/typography/otspec/cmap.htm
 */
class OtfCmapTable
{
	private var cmap314:OtfCmap314;

	public function new(reader:IFontFileReader, header:OtfTableHeader)
	{
		reader.seek(header.offset);
		var cmap314:OtfCmap314 = null;
		reader.readUShort(); // version
		var numCmapTables = reader.readUShort();

		for (i in 0...numCmapTables)
		{
			var platformId = reader.readUShort();
			var encodingId = reader.readUShort();
			var offset = reader.readULong();

			var pos = reader.position();
			reader.seek(header.offset + offset);
			var format = reader.readUShort();

			// We only parse 3/1/4 (99% of our fonts support this),
			// and probably 3/10/12 later (we have 6 of these)

			// "All Microsoft Unicode BMP encodings (Platform ID = 3,
			// Encoding ID = 1) must provide at least a Format 4 'cmap'
			// subtable. If the font is meant to support supplementary
			// (non-BMP) Unicode characters, it will additionally need
			// a Format 12 subtable with a platform encoding ID 10. The
			// contents of the Format 12 subtable need to be a superset
			// of the contents of the Format 4 subtable. Microsoft
			// strongly recommends using a BMP Unicode 'cmap' for all
			// fonts."
			// http://www.microsoft.com/typography/otspec/cmap.htm
	
			if (platformId == 3 && encodingId == 1 && format == 4)
			{
				cmap314 = new OtfCmap314(reader);
			}

			// Seek back to the list of tables
			reader.seek(pos);

			if (cmap314 != null)
			{
				break;
			}
		}

		if (cmap314 == null)
		{
			throw "No suitable cmap found in font";
		}
		this.cmap314 = cmap314;
	}

	public inline function unicodeToGlyphCode(unicode:Int):Int
	{
		return cmap314.unicodeToGlyphCode(unicode);
	}
}

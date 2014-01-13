package prezi.text.otf;

class OtfCmap314
{
	private var reader:IFontFileReader;
	private var startCount:Array<Int>;
	private var endCount:Array<Int>;
	private var idDelta:Array<Int>;
	private var idRangeOffsetPosition:Int;
	private var idRangeOffset:Array<Int>;

	public function new(reader:IFontFileReader)
	{
		this.reader = reader;
		reader.readUShort(); // length
		reader.readUShort(); // language
		var segCount = reader.readUShort() >> 1; // segCountX2
		reader.readUShort(); // searchRange
		reader.readUShort(); // entrySelector
		reader.readUShort(); // rangeShift

		this.endCount = new Array<Int>();
		for (i in 0...segCount)
		{
			endCount.push(reader.readUShort());
		}

		reader.readUShort(); // reservedPad

		this.startCount = new Array<Int>();
		for (i in 0...segCount)
		{
			startCount.push(reader.readUShort());
		}

		this.idDelta = new Array<Int>();
		for (i in 0...segCount)
		{
			idDelta.push(reader.readShort());
		}

		this.idRangeOffsetPosition = reader.position();

		this.idRangeOffset = new Array<Int>();
		for (i in 0...segCount)
		{
			idRangeOffset.push(reader.readUShort());
		}
	}

	public function unicodeToGlyphCode(unicode:Int)
	{
		// "For the search to terminate, the final endCode value must
		// "be 0xFFFF. This segment need not contain any valid
		// "mappings. (It can just map the single character code 0xFFFF
		// "to missingGlyph). However, the segment must be present."

		var idx = 0;
		while (idx < endCount.length)
		{
			if (endCount[idx] >= unicode)
			{
				break;
			}
			idx++;
		}
		
		if (startCount[idx] > unicode)
		{
			return OtfConstants.MISSING_GLYPH_CODE; // missing glyph
		}

		var offset = idRangeOffset[idx];

		// If the idRangeOffset is 0, the idDelta value is added
		// directly to the character code offset (i.e. idDelta[i] + c)
		// to get the corresponding glyph index. Again, the idDelta
		// arithmetic is modulo 65536.
		if (offset == 0)
		{
			return (idDelta[idx] + unicode) % 0x10000;
		}
		else
		{
			var glyphIdOffset = idRangeOffsetPosition
				+ 2 * idx + offset + 2 * (unicode - startCount[idx]);
			return reader.peekUShort(glyphIdOffset);
		}
	}
}

package prezi.text.otf;

class CffTable implements IGlyphLookup
{
	public var charStringsIndex (default, null):ICffIndex;

	private var outlineProcessor:CffCharStringProcessor;

	public function new(reader:IFontFileReader, cffHeader:OtfTableHeader)
	{
		reader.seek(cffHeader.offset);

		// Header
		var major = reader.readByte(); // major
		var minor = reader.readByte(); // minor
		if (major != 1 || minor != 0)
		{
			throw "Unknown CFF format: " + major + "." + minor;
		}

		var hdrSize = reader.readByte(); // hdrSize
		reader.readByte(); // offSize

		// Skip past the header
		reader.seek(cffHeader.offset + hdrSize);

		// Name INDEX
		var nameIndex = new CffIndex("Name", reader);

		// Top DICT INDEX
		var topDictIndex = new CffIndex("Top DICT", reader);

		// String INDEX
		var tringIndex = new CffIndex("String", reader);

		// Global Subr INDEX
		var globalSubrIndex = new CffIndex("Global Subr", reader);

		// Read the global and local stuff for font //1
		var topDict = new CffTopDict(reader, cffHeader.offset);
		var topDictLocation = topDictIndex.lookup(0);
		topDict.process(topDictLocation.offset, topDictLocation.length);
		var privateDict = topDict.privateDict;

		// Get us some CharStrings
		this.charStringsIndex = new CffIndex("CharStrings", reader, topDict.charStringsOffset);

		// Get the private subroutines
		var localSubrsOffset = privateDict.localSubrsOffset;
		var localSubrIndex:ICffIndex;
		if (localSubrsOffset != null)
		{
			localSubrIndex = new CffIndex("Local Subr", reader, localSubrsOffset);
		}
		else
		{
			localSubrIndex = new EmptyCffIndex();
		}

		this.outlineProcessor = new CffCharStringProcessor(
			reader,
			privateDict.defaultWidthX, privateDict.nominalWidthX,
			globalSubrIndex, localSubrIndex);
	}

	public function glyphOutline(glyphIndex:Int):Array<Int>
	{
		var glyphLocation = charStringsIndex.lookup(glyphIndex);
		return outlineProcessor.process(glyphLocation.offset, glyphLocation.length);
	}
}

private class EmptyCffIndex implements ICffIndex
{
	public var count (default, null):Int;

	public function new()
	{
		this.count = 0;
	}

	public function lookup(index:Int):{ offset:Int, length:Int }
	{
		return throw "No local subroutines, cannot look up index " + index;
	}
}

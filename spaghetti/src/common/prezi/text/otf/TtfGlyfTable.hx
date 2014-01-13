package prezi.text.otf;

class TtfGlyfTable implements IGlyphLookup
{
	private static inline var INDEX_TO_LOC_SHORT:Int = 0;
	private static inline var INDEX_TO_LOC_LONG:Int = 1;

	private static inline var GLYF_FLAG_ON_CURVE:Int = 0x01;
	private static inline var GLYF_FLAG_X_SHORT_VECTOR:Int = 0x02;
	private static inline var GLYF_FLAG_Y_SHORT_VECTOR:Int = 0x04;
	private static inline var GLYF_FLAG_REPEAT:Int = 0x08;
	private static inline var GLYF_FLAG_X_IS_SAME:Int = 0x10;
	private static inline var GLYF_FLAG_Y_IS_SAME:Int = 0x20;

	private static inline var GLYF_COMP_FLAG_ARG_1_AND_2_ARE_WORDS:Int = 0x01;
	private static inline var GLYF_COMP_FLAG_ARGS_ARE_XY_VALUES:Int = 0x02;
	private static inline var GLYF_COMP_FLAG_ROUND_XY_TO_GRID:Int = 0x04;
	private static inline var GLYF_COMP_FLAG_WE_HAVE_A_SCALE:Int = 0x08;
	// 0x10 is reserved
	private static inline var GLYF_COMP_FLAG_MORE_COMPONENTS:Int = 0x20;
	private static inline var GLYF_COMP_FLAG_WE_HAVE_AN_X_AND_Y_SCALE:Int = 0x40;
	private static inline var GLYF_COMP_FLAG_WE_HAVE_A_TWO_BY_TWO:Int = 0x80;

	private var reader:IFontFileReader;
	private var indexToLocFormat:Int;
	private var locaHeader:OtfTableHeader;
	private var glyfHeader:OtfTableHeader;

	public function new(reader:IFontFileReader, indexToLocFormat:Int, locaHeader:OtfTableHeader, glyfHeader:OtfTableHeader)
	{
		this.reader = reader;
		this.indexToLocFormat = indexToLocFormat;
		this.locaHeader = locaHeader;
		this.glyfHeader = glyfHeader;
	}

	public function glyphOutline(glyphCode:Int):Array<Int>
	{
		var relativeOffset = lookupGlyph(glyphCode);
		var length = lookupGlyph(glyphCode + 1) - relativeOffset;
		if (length == 0)
		{
			return [ OtfConstants.GLYPH_TYPE_SIMPLE ];
		}

		reader.seek(glyfHeader.offset + relativeOffset);

		var numberOfContours = reader.readShort();
		reader.readShort(); // xMin
		reader.readShort(); // yMin
		reader.readShort(); // xMax
		reader.readShort(); // yMax

		var commands = new Array<Int>();
		if (numberOfContours != -1)
		{
			// We have a simple glyph
			commands.push(OtfConstants.GLYPH_TYPE_SIMPLE);

			var endPtsOfContours = new Array<Int>();
			for (i in 0...numberOfContours)
			{
				endPtsOfContours[i] = reader.readUShort();
			}
			var nPoints = endPtsOfContours[endPtsOfContours.length - 1] + 1;

			// Skip instructions
			var instructionLength = reader.readUShort();
			reader.skip(instructionLength);

			var flags = readFlags(nPoints);

			var xCoords = readCoords(flags, numberOfContours, GLYF_FLAG_X_SHORT_VECTOR, GLYF_FLAG_X_IS_SAME);
			var yCoords = readCoords(flags, numberOfContours, GLYF_FLAG_Y_SHORT_VECTOR, GLYF_FLAG_Y_IS_SAME);

			var pen = new Pen(commands);
			var contourStart = 0;
			for (contourEnd in endPtsOfContours)
			{
				var previousControlPoint = null;
				for (pointNo in contourStart...(contourEnd + 1))
				{
					var point = { x: xCoords[pointNo], y: yCoords[pointNo] };
					var onCurve = (flags[pointNo] & GLYF_FLAG_ON_CURVE) != 0;

					// Check if first curve point is not on curve -- we need to find
					// a start point in this case
					if (pointNo == contourStart)
					{
						if (onCurve)
						{
							pen.moveTo(point);
							continue;
						}
						else
						{
							var lastPoint = { x: xCoords[contourEnd], y: yCoords[contourEnd] };
							var lastPointOnCurve = (flags[contourEnd] & GLYF_FLAG_ON_CURVE) != 0;
							if (lastPointOnCurve)
							{
								pen.moveTo(lastPoint);
							}
							else
							{
								pen.moveTo(midPoint(lastPoint, point));
							}
						}
					}

					if (!onCurve)
					{
						// We have an off-curve point
						if (previousControlPoint != null)
						{
							// The previous was an off-curve point, too,
							// so we define a midpoint
							pen.curveTo(previousControlPoint, midPoint(point, previousControlPoint));
						}
						previousControlPoint = point;
					}
					// This is an on-curve point
					else if (previousControlPoint != null)
					{
						// The previous point was an off-curve point
						pen.curveTo(previousControlPoint, point);
						previousControlPoint = null;
					}
					else
					{
						// The previous point was an on-curve point
						pen.lineTo(point);
					}
				}

				// Finish contour
				// Let's close it with a curve if we need to
				if (previousControlPoint != null)
				{
					pen.curveTo(previousControlPoint, pen.startPoint);
				}
				// We don't have to close a path that ends in a line
				// else
				// 	commands.append COMMAND_LINE_TO, start.x, start.y

				pen.closePath();
				contourStart = contourEnd + 1;
			}
		}
		else
		{
			// We have a composite glyph here
			commands.push(OtfConstants.GLYPH_TYPE_COMPOSITE_TTF);

			while (true)
			{
				var flags = reader.readUShort();
				var glyphIndex = reader.readUShort();
				commands.push(flags);
				commands.push(glyphIndex);

				if ((flags & GLYF_COMP_FLAG_ARG_1_AND_2_ARE_WORDS) != 0)
				{
					var arg1:Int;
					var arg2:Int;
					if ((flags & GLYF_COMP_FLAG_ARGS_ARE_XY_VALUES) != 0)
					{
						arg1 = reader.readShort();
						arg2 = reader.readShort();
					}
					else
					{
						arg1 = reader.readUShort();
						arg2 = reader.readUShort();
					}
					commands.push(arg1);
					commands.push(arg2);
				}
				else
				{
					// These will be unpacked on the caller side
					var args = reader.readUShort();
					commands.push(args);
				}

				if ((flags & GLYF_COMP_FLAG_WE_HAVE_A_SCALE) != 0)
				{
					var scale = reader.readUShort();
					commands.push(scale);
				}
				else if ((flags & GLYF_COMP_FLAG_WE_HAVE_AN_X_AND_Y_SCALE) != 0)
				{
					var xscale = reader.readUShort();
					var yscale = reader.readUShort();
					commands.push(xscale);
					commands.push(yscale);
				}
				else if ((flags & GLYF_COMP_FLAG_WE_HAVE_A_TWO_BY_TWO) != 0)
				{
					var xscale = reader.readUShort();
					var scale01 = reader.readUShort();
					var scale10 = reader.readUShort();
					var yscale = reader.readUShort();
					commands.push(xscale);
					commands.push(scale01);
					commands.push(scale10);
					commands.push(yscale);
				}
				// We don't care about instructions here

				if ((flags & GLYF_COMP_FLAG_MORE_COMPONENTS) == 0)
				{
					break;
				}
			}
		}
		return commands;
	}

	private inline function lookupGlyph(glyphCode:Int):Int
	{
		var glyphIndex:Int;
		switch (indexToLocFormat)
		{
			case INDEX_TO_LOC_SHORT:
				glyphIndex = reader.peekUShort(locaHeader.offset + glyphCode * 2) * 2;
			case INDEX_TO_LOC_LONG:
				glyphIndex = reader.peekULong(locaHeader.offset + glyphCode * 4);
			default:
				throw "Unknonw indexToLocFormat: " + indexToLocFormat;
		}
		return glyphIndex;
	}

	private static inline function midPoint(a:IntPoint, b:IntPoint):IntPoint
	{
		return {
			x: (a.x + b.x) >> 1,
			y: (a.y + b.y) >> 1
		};
	}

	private function readFlags(nPoints:Int):Array<Int>
	{
		var flags = new Array<Int>();
		var i = 0;
		while (i < nPoints)
		{
			var flag = reader.readByte();
			var count = 1;
			if ((flag & GLYF_FLAG_REPEAT) != 0)
			{
				count += reader.readByte();
			}
			for (c in 1...count + 1)
			{
				flags[i++] = flag;
			}
		}
		return flags;
	}

	private function readCoords(flags:Array<Int>, numberOfContours:Int, shortVectorFlag:Int, isSameFlag:Int):Array<Int>
	{
		var nPoints = flags.length;
		var coords = new Array<Int>();
		var coord = 0;
		for (i in 0...nPoints)
		{
			var flag = flags[i];
			var d:Int;
			if ((flag & shortVectorFlag) != 0)
			{
				d = reader.readByte();
				if ((flag & isSameFlag) == 0)
				{
					d = -d;
				}
			}
			else
			{
				if ((flag & isSameFlag) != 0)
				{
					d = 0;
				}
				else
				{
					d = reader.readShort();
				}
			}
			coord += d;
			// Multiply by two to avoid midpoints having non-integer values
			coords[i] = coord << 1;
		}
		return coords;
	}
}

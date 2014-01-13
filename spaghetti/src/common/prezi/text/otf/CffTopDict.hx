package prezi.text.otf;

class CffTopDict extends CffDict
{
	public var privateDict (default, null):CffPrivateDict;
	public var charStringsOffset (default, null):Int;

	private var operators:Array<Void->Void>;
	private var extendedOperators:Array<Void->Void>;
	private var privateDictOffset:Int;
	private var privateDictLength:Int;

	public function new(reader:IFontFileReader, cffStartOffset:Int)
	{
		super(reader);

		operators = [];
		operators[0] = function() { pop(); };  // version:SID
		operators[1] = function() { pop(); };  // Notice:SID
		operators[2] = function() { pop(); };  // FullName:SID
		operators[3] = function() { pop(); };  // FamilyName:SID
		operators[4] = function() { pop(); };  // Weight:SID
		operators[5] = function() { popall(); }; // FontBBox:array, default=[0,0,0,0]
		operators[13] = function() { pop(); }; // UniqueID:number
		operators[14] = function() { popall(); }; // XUID:array
		operators[15] = function() { pop(); }; // charset:number, default=0
		operators[16] = function() { pop(); }; // Encoding:number, default=0
		operators[17] = function()             // CharStrings:number
		{
			charStringsOffset = Std.int(pop()) + cffStartOffset;
		}
		operators[18] = function()             // Private:number,number
		{
			privateDictOffset = Std.int(pop()) + cffStartOffset;
			privateDictLength = Std.int(pop());
		}

		extendedOperators = [];
		extendedOperators[0] = function() { pop(); };  // Copyright:SID
		extendedOperators[1] = function() { pop(); };  // isFixedPitch:number, default=0
		extendedOperators[2] = function() { pop(); };  // ItalicAngle:number, default=0
		extendedOperators[3] = function() { pop(); };  // UnderlinePosition:number
		extendedOperators[4] = function() { pop(); };  // UnderlineThickness:number, default=50
		extendedOperators[5] = function() { pop(); };  // PaintType:number, default=0
		extendedOperators[6] = function()              // CharstringType:number, default=2
		{
			var charStringType = Std.int(pop());
			if (charStringType != 2)
			{
				throw "Unsupported charstring type " + charStringType;
			}
		}
		extendedOperators[7] = function() { popall(); };  // FontMatrix:array, default=[0.001,0,0,0.001,0,0]
		extendedOperators[8] = function() { pop(); };  // StrokeWidth:number, default=0
		extendedOperators[20] = function() { pop(); }; // SyntheticBase:number
		extendedOperators[21] = function() { pop(); }; // PostScript:SID
		extendedOperators[22] = function() { pop(); }; // BaseFontName:SID
		extendedOperators[23] = function() { popall(); }; // BaseFontBlend:delta
		extendedOperators[30] = function() { pop(); pop(); pop(); }; // ROS:SID,SID,number
		extendedOperators[31] = function() { pop(); }; // CIDFontVersion:number, default=0
		extendedOperators[32] = function() { pop(); }; // CIDFontRevision:number, default=0
		extendedOperators[33] = function() { pop(); }; // CIDFontType:number, default=0
		extendedOperators[34] = function() { pop(); }; // CIDCount:number, default=8720
		extendedOperators[35] = function() { pop(); }; // UIDBase:number
		extendedOperators[36] = function() { pop(); }; // FDArray:number
		extendedOperators[37] = function() { pop(); }; // FDSelect:number
		extendedOperators[38] = function() { pop(); }; // FontName:SID
	}

	override public function process(offset:Int, length:Int):Dynamic
	{
		super.process(offset, length);

		privateDict = new CffPrivateDict(reader);
		return privateDict.process(privateDictOffset, privateDictLength);
	}

	override private function getOperators():Array<Void->Void>
	{
		return operators;
	}

	override private function getExtendedOperators():Array<Void->Void>
	{
		return extendedOperators;
	}
}

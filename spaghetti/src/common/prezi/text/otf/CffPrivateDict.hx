package prezi.text.otf;

class CffPrivateDict extends CffDict
{
	public var localSubrsOffset (default, null):Null<Int>;
	public var defaultWidthX (default, null):Float;
	public var nominalWidthX (default, null):Float;

	private var operators:Array<Void->Void>;
	private var extendedOperators:Array<Void->Void>;

	public function new(reader:IFontFileReader)
	{
		super(reader);

		this.operators = [];
		operators[6] = function() { popall(); }; // BlueValues:delta
		operators[7] = function() { popall(); }; // OtherBlues:delta
		operators[8] = function() { popall(); }; // FamilyBlues:delta
		operators[9] = function() { popall(); }; // FamilyOtherBlues:delta
		operators[10] = function() { pop(); };   // SrdHW:number
		operators[11] = function() { pop(); };   // SrdVW:number
		operators[19] = function()                // Subrs:number
		{
			localSubrsOffset = Std.int(pop()) + dictStartOffset;
		}
		operators[20] = function()                // defaultWidthX:number, default=0
		{
			defaultWidthX = pop();
		}
		operators[21] = function()                // nominalWidthX:number, default=0
		{
			nominalWidthX = pop();
		}

		extendedOperators = [];
		extendedOperators[9] = function() { pop(); };  // BlueScale:number, default=0.039625
		extendedOperators[10] = function() { pop(); }; // BlueShift:number, default=7
		extendedOperators[11] = function() { pop(); }; // BlueFuzz:number, default=1
		extendedOperators[12] = function() { popall(); }; // StemSnapH:delta
		extendedOperators[13] = function() { popall(); }; // StemSnapV:delta
		extendedOperators[14] = function() { pop(); }; // ForceBold:number, default=0
		extendedOperators[15] = function() { pop(); }; // ForceBoldTreshold:number, deprecated
		extendedOperators[16] = function() { pop(); }; // lenIV:number, deprecated
		extendedOperators[17] = function() { pop(); }; // LanguageGroup:number, default=0
		extendedOperators[18] = function() { pop(); }; // ExpansionFactor:number, default=0.06
		extendedOperators[19] = function() { pop(); }; // initialRandomSeed:number, default=0
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

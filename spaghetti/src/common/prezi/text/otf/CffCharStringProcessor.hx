package prezi.text.otf;

class CffCharStringProcessor extends CffDict
{
	private var operators:Array<Void->Void>;
	private var extendedOperators:Array<Void->Void>;
	private var defaultWidthX:Float;
	private var nominalWidthX:Float;
	private var globalSubrs:ICffIndex;
	private var localSubrs:ICffIndex;
	private var globalSubrsBias:Int;
	private var localSubrsBias:Int;

	private var callingStack:Array<Int>;
	private var hintCount:Int;
	private var hintMaskBytes:Int;
	private var commands:Array<Int>;
	private var finished:Bool;
	private var pen:Pen;
	private var gotWidth:Bool;
	private var width:Float;

	public function new(reader:IFontFileReader, defaultWidthX:Float, nominalWidthX:Float, globalSubrs:ICffIndex, localSubrs:ICffIndex)
	{
		super(reader);
		this.defaultWidthX = defaultWidthX;
		this.nominalWidthX = nominalWidthX;
		this.globalSubrs = globalSubrs;
		this.localSubrs = localSubrs;

		this.globalSubrsBias = calcSubrBias(globalSubrs);
		this.localSubrsBias = calcSubrBias(localSubrs);

		this.operatorEncoding = [];
		for (i in 0...(31 + 1))
		{
			operatorEncoding[i] = function(b0:Int) { doOperator(b0); };
		}
		for (i in 32...(246 + 1))
		{
			operatorEncoding[i] = function(b0:Int) { pushByte(b0); };
		}
		for (i in 247...(250 + 1))
		{
			operatorEncoding[i] = function(b0:Int) { pushSmallInt1(b0); };
		}
		for (i in 251...(254 + 1))
		{
			operatorEncoding[i] = function(b0:Int) { pushSmallInt2(b0); };
		}
		operatorEncoding[28] = function(b0:Int) { pushShortInt(b0); };
		operatorEncoding[255] = function(b0:Int) { pushFixed1616(b0); };

		this.operators = [];
		operators[1] = function() { op_hstem(); };
		operators[3] = function() { op_vstem(); };
		operators[4] = function() { op_vmoveto(); };
		operators[5] = function() { op_rlineto(); };
		operators[6] = function() { op_hlineto(); };
		operators[7] = function() { op_vlineto(); };
		operators[8] = function() { op_rrcurveto(); };
		operators[10] = function() { op_callsubr(); };
		operators[11] = function() { op_return(); };
		operators[14] = function() { op_endchar(); };
		operators[16] = function() { op_blend(); };
		operators[18] = function() { op_hstemhm(); };
		operators[19] = function() { op_hintmask(); };
		operators[20] = function() { op_cntrmask(); };
		operators[21] = function() { op_rmoveto(); };
		operators[22] = function() { op_hmoveto(); };
		operators[23] = function() { op_vstemhm(); };
		operators[24] = function() { op_rcurveline(); };
		operators[25] = function() { op_rlinecurve(); };
		operators[26] = function() { op_vvcurveto(); };
		operators[27] = function() { op_hhcurveto(); };
		// operators[28] = function() { op_shortint(); }; // not really an operator
		operators[29] = function() { op_callgsubr(); };
		operators[30] = function() { op_vhcurveto(); };
		operators[31] = function() { op_hvcurveto(); };

		this.extendedOperators = [];
		// Yes, there a few very early OTF/CFF
		// fonts with this deprecated operator. Just ignore it.
		extendedOperators[0] = function() { op_dotsection(); };
		extendedOperators[3] = function() { op_and(); };
		extendedOperators[4] = function() { op_or(); };
		extendedOperators[5] = function() { op_not(); };
		extendedOperators[8] = function() { op_store(); };
		extendedOperators[9] = function() { op_abs(); };
		extendedOperators[10] = function() { op_add(); };
		extendedOperators[11] = function() { op_sub(); };
		extendedOperators[12] = function() { op_div(); };
		extendedOperators[13] = function() { op_load(); };
		extendedOperators[14] = function() { op_neg(); };
		extendedOperators[15] = function() { op_eq(); };
		extendedOperators[18] = function() { op_drop(); };
		extendedOperators[20] = function() { op_put(); };
		extendedOperators[21] = function() { op_get(); };
		extendedOperators[22] = function() { op_ifelse(); };
		extendedOperators[23] = function() { op_random(); };
		extendedOperators[24] = function() { op_mul(); };
		extendedOperators[26] = function() { op_sqrt(); };
		extendedOperators[27] = function() { op_dup(); };
		extendedOperators[28] = function() { op_exch(); };
		extendedOperators[29] = function() { op_index(); };
		extendedOperators[30] = function() { op_roll(); };
		extendedOperators[34] = function() { op_hflex(); };
		extendedOperators[35] = function() { op_flex(); };
		extendedOperators[36] = function() { op_hflex1(); };
		extendedOperators[37] = function() { op_flex1(); };
	}

	override private function getOperators():Array<Void->Void>
	{
		return operators;
	}

	override private function getExtendedOperators():Array<Void->Void>
	{
		return extendedOperators;
	}

	private function calcSubrBias(subrs:ICffIndex):Int
	{
		var nSubrs = subrs.count;
		var bias:Int;
		if (nSubrs < 1240)
		{
			bias = 107;
		}
		else if (nSubrs < 33900)
		{
			bias = 1131;
		}
		else
		{
			bias = 32768;
		}
		return bias;
	}

	override private function reset()
	{
		super.reset();

		this.callingStack = [];
		this.hintCount = 0;
		this.hintMaskBytes = 0;
		this.commands = [ OtfConstants.GLYPH_TYPE_SIMPLE ];
		this.finished = false;
		this.pen = new Pen(commands);
		this.gotWidth = false;
		this.width = 0;
	}

	override public function process(charStringOffset:Int, length:Int):Dynamic
	{
		reset();
		callCharString(charStringOffset, length);
		// We don't care about width, as it is already retrieved from hmtx
		return pen.commands;
	}

	private function callCharString(charStringOffset:Int, length:Int)
	{
		// Save current location
		callingStack.push(reader.position());

		// Move to the CharString
		reader.seek(charStringOffset);

		// Process tokens until @finished or we run out of tokens
		var end = charStringOffset + length;
		while (!finished && reader.position() < end)
		{
			processNextToken();
		}

		// Reset finished for calling CharString
		finished = false;

		// Move back to calling position
		reader.seek(callingStack.pop());
	}

	private function popallWidth(evenOdd:Int = 0):Array<Float>
	{
		var args = popall();
		if (!gotWidth)
		{
			if ((evenOdd ^ (args.length % 2)) != 0)
			{
				width = nominalWidthX + args.shift();
			}
			else
			{
				width = defaultWidthX;
			}
			gotWidth = true;
		}
		return args;
	}

	//
	// Operands
	//
	
	private function op_return()
	{
		// console.log "<<< return"
		finished = true;
	}

	private function op_endchar()
	{
		pen.closePath();
		popallWidth();
		// Handle standard encoding
		//if args.length > 0
		//	// endchar can do seac accent bulding; The T2 spec says it's deprecated,
		//	// but recent software that shall remain nameless does output it.
		//	adx, ady, bchar, achar = args
		//	baseGlyph = StandardEncoding[bchar]
		//	@pen.addComponent(baseGlyph, (1, 0, 0, 1, 0, 0))
		//	accentGlyph = StandardEncoding[achar]
		//	@pen.addComponent(accentGlyph, (1, 0, 0, 1, adx, ady))
		finished = true;
	}
	
	private function op_dotsection()
	{
	}

	private function op_callsubr()
	{
		var subrIdx = Std.int(pop());
		// console.log ">>> Subr: #{subrIdx} + #{@localSubrsBias}"
		var subr = localSubrs.lookup(subrIdx + localSubrsBias);
		callCharString(subr.offset, subr.length);
	}

	private function op_callgsubr()
	{
		var subrIdx = Std.int(pop());
		// console.log ">>> GSubr: #{subrIdx} + #{@globalSubrsBias}"
		var subr = globalSubrs.lookup(subrIdx + globalSubrsBias);
		callCharString(subr.offset, subr.length);
	}

	//
	// Hintmask handling
	//

	private function op_hstem()
	{
		countHints();
	}
	private function op_vstem()
	{
		countHints();
	}
	private function op_hstemhm()
	{
		countHints();
	}
	private function op_vstemhm()
	{
		countHints();
	}
	private function op_hintmask()
	{
		if (hintMaskBytes == 0)
		{
			countHints();
			hintMaskBytes = (hintCount + 7) >> 3; // integer div 8
		}
		// Skip hintmask
		reader.skip(hintMaskBytes);
	}
	private function op_cntrmask()
	{
		op_hintmask();
	}
	private function countHints()
	{
		var args = popallWidth();
		hintCount += args.length >> 1; // integer div 2
	}

	//
	// Path constructors, moveto
	//
	private function op_rmoveto()
	{
		pen.closePath();
		var args = popallWidth();
		pen.rMoveTo(intPoint(args[0], args[1]));
	}
	
	private function op_hmoveto()
	{
		pen.closePath();
		var args = popallWidth(1);
		pen.rMoveTo(intPoint(args[0], 0));
	}

	private function op_vmoveto()
	{
		pen.closePath();
		var args = popallWidth(1);
		pen.rMoveTo(intPoint(0, args[0]));
	}

	//
	// Path constructors, lines
	//
	private function op_rlineto()
	{
		var args = popall();
		var i = 0;
		while (i < args.length)
		{
			pen.rLineTo(intPoint(args[i], args[i + 1]));
			i += 2;
		}
	}
	private function op_hlineto()
	{
		alternatingLineTo(true);
	}
	private function op_vlineto()
	{
		alternatingLineTo(false);
	}

	//
	// Path constructors, curves
	//

	// {dxa dya dxb dyb dxc dyc}+ rrcurveto
	private function op_rrcurveto()
	{
		var args = popall();
		var i = 0;
		while (i < args.length)
		{
			var dxa = args[i + 0];
			var dya = args[i + 1];
			var dxb = args[i + 2];
			var dyb = args[i + 3];
			var dxc = args[i + 4];
			var dyc = args[i + 5];
			pen.rCubicCurveTo(intPoint(dxa, dya), intPoint(dxb, dyb), intPoint(dxc, dyc));
			i += 6;
		}
	}	

	// {dxa dya dxb dyb dxc dyc}+ dxd dyd rcurveline
	private function op_rcurveline()
	{
		var args = popall();
		var i = 0;
		while (i < args.length - 2)
		{
			var dxb = args[i + 0];
			var dyb = args[i + 1];
			var dxc = args[i + 2];
			var dyc = args[i + 3];
			var dxd = args[i + 4];
			var dyd = args[i + 5];
			pen.rCubicCurveTo(intPoint(dxb, dyb), intPoint(dxc, dyc), intPoint(dxd, dyd));
			i += 6;
		}
		pen.rLineTo(intPoint(args[args.length - 2], args[args.length - 1]));
	}

	// {dxa dya}+ dxb dyb dxc dyc dxd dyd rlinecurve
	private function op_rlinecurve()
	{
		var args = popall();
		var i = 0;
		while (i < args.length - 6)
		{
			pen.rLineTo(intPoint(args[i], args[i + 1]));
			i += 2;
		}
		var dxb = args[args.length - 6];
		var dyb = args[args.length - 5];
		var dxc = args[args.length - 4];
		var dyc = args[args.length - 3];
		var dxd = args[args.length - 2];
		var dyd = args[args.length - 1];
		pen.rCubicCurveTo(intPoint(dxb, dyb), intPoint(dxc, dyc), intPoint(dxd, dyd));
	}
	
	// dx1? {dya dxb dyb dyc}+ vvcurveto
	private function op_vvcurveto()
	{
		var args = popall();
		var dx1:Float;
		if ((args.length % 2) != 0)
		{
			dx1 = args.shift();
		}
		else
		{
			dx1 = 0;
		}
		var i = 0;
		while (i < args.length)
		{
			var dya = args[i + 0];
			var dxb = args[i + 1];
			var dyb = args[i + 2];
			var dyc = args[i + 3];
			pen.rCubicCurveTo(intPoint(dx1, dya), intPoint(dxb, dyb), intPoint(0, dyc));
			dx1 = 0;
			i += 4;
		}
	}

	// dy1? {dxa dxb dyb dxc}+ hhcurveto
	private function op_hhcurveto()
	{
		var args = popall();
		var dy1:Float;
		if ((args.length % 2) != 0)
		{
			dy1 = args.shift();
		}
		else
		{
			dy1 = 0;
		}
		var i = 0;
		while (i < args.length)
		{
			var dxa = args[i + 0];
			var dxb = args[i + 1];
			var dyb = args[i + 2];
			var dxc = args[i + 3];
			pen.rCubicCurveTo(intPoint(dxa, dy1), intPoint(dxb, dyb), intPoint(dxc, 0));
			dy1 = 0;
			i += 4;
		}
	}

	// dy1 dx2 dy2 dx3 {dxa dxb dyb dyc dyd dxe dye dxf}* dyf? vhcurveto (30)
	// {dya dxb dyb dxc dxd dxe dye dyf}+ dxf? vhcurveto
	private function op_vhcurveto()
	{
		var args = popall();
		while (args.length > 0)
		{
			args = vcurveto(args);
			if (args.length > 0)
			{
				args = hcurveto(args);
			}
		}
	}
	
	// dx1 dx2 dy2 dy3 {dya dxb dyb dxc dxd dxe dye dyf}* dxf?
	// {dxa dxb dyb dyc dyd dxe dye dxf}+ dyf?
	private function op_hvcurveto()
	{
		var args = popall();
		while (args.length > 0)
		{
			args = hcurveto(args);
			if (args.length > 0)
			{
				args = vcurveto(args);
			}
		}
	}

	//
	// Path constructors, flex
	//
	private function op_hflex()
	{
		var args = popall();
		var dx1 = args[0];
		var dy1 = 0;
		var dx2 = args[1];
		var dy2 = args[2];
		var dx3 = args[3];
		var dy3 = 0;
		var dx4 = args[4];
		var dy4 = 0;
		var dx5 = args[5];
		var dy5 = -dy2;
		var dx6 = args[6];
		var dy6 = 0;

		pen.rCubicCurveTo(intPoint(dx1, dy1), intPoint(dx2, dy2), intPoint(dx3, dy3));
		pen.rCubicCurveTo(intPoint(dx4, dy4), intPoint(dx5, dy5), intPoint(dx6, dy6));
	}

	private function op_flex()
	{
		var args = popall();
		var dx1 = args[0];
		var dy1 = args[1];
		var dx2 = args[2];
		var dy2 = args[3];
		var dx3 = args[4];
		var dy3 = args[5];
		var dx4 = args[6];
		var dy4 = args[7];
		var dx5 = args[8];
		var dy5 = args[9];
		var dx6 = args[10];
		var dy6 = args[11];
		var fd  = args[12];

		pen.rCubicCurveTo(intPoint(dx1, dy1), intPoint(dx2, dy2), intPoint(dx3, dy3));
		pen.rCubicCurveTo(intPoint(dx4, dy4), intPoint(dx5, dy5), intPoint(dx6, dy6));
	}

	private function op_hflex1()
	{
		var args = popall();
		var dx1 = args[0];
		var dy1 = args[1];
		var dx2 = args[2];
		var dy2 = args[3];
		var dx3 = args[4];
		var dy3 = 0;
		var dx4 = args[5];
		var dy4 = 0;
		var dx5 = args[6];
		var dy5 = args[7];
		var dx6 = args[8];
		var dy6 = - (dy1 + dy2 + dy3 + dy4 + dy5);

		pen.rCubicCurveTo(intPoint(dx1, dy1), intPoint(dx2, dy2), intPoint(dx3, dy3));
		pen.rCubicCurveTo(intPoint(dx4, dy4), intPoint(dx5, dy5), intPoint(dx6, dy6));
	}

	private function op_flex1()
	{
		var args = popall();
		var dx1 = args[0];
		var dy1 = args[1];
		var dx2 = args[2];
		var dy2 = args[3];
		var dx3 = args[4];
		var dy3 = args[5];
		var dx4 = args[6];
		var dy4 = args[7];
		var dx5 = args[8];
		var dy5 = args[9];
		var d6  = args[10];

		var dx = dx1 + dx2 + dx3 + dx4 + dx5;
		var dy = dy1 + dy2 + dy3 + dy4 + dy5;
		var dx6:Float;
		var dy6:Float;
		if (Math.abs(dx) > Math.abs(dy))
		{
			dx6 = d6;
			dy6 = -dy;
		}
		else
		{
			dx6 = -dx;
			dy6 = d6;
		}
		pen.rCubicCurveTo(intPoint(dx1, dy1), intPoint(dx2, dy2), intPoint(dx3, dy3));
		pen.rCubicCurveTo(intPoint(dx4, dy4), intPoint(dx5, dy5), intPoint(dx6, dy6));
	}

	//
	// MultipleMaster. Well...
	//
	private function op_blend()
	{
		popall();
	}
	
	// misc
	private function op_and()
	{
		throw "NotImplemented";
	}
	private function op_or()
	{
		throw "NotImplemented";
	}
	private function op_not()
	{
		throw "NotImplemented";
	}
	private function op_store()
	{
		throw "NotImplemented";
	}
	private function op_abs()
	{
		throw "NotImplemented";
	}
	private function op_add()
	{
		throw "NotImplemented";
	}
	private function op_sub()
	{
		throw "NotImplemented";
	}
	private function op_div()
	{
		throw "NotImplemented";
		/*
		var num2 = pop();
		var num1 = pop();
		var d1 = Std.int(num1 / num2);
		var d2 = num1 / num2;
		if (d1 == d2)
		{
			push(d1);
		}
		else
		{
			push(d2);
		}
		*/
	}
	private function op_load()
	{
		throw "NotImplemented";
	}
	private function op_neg()
	{
		throw "NotImplemented";
	}
	private function op_eq()
	{
		throw "NotImplemented";
	}
	private function op_drop()
	{
		throw "NotImplemented";
	}
	private function op_put()
	{
		throw "NotImplemented";
	}
	private function op_get()
	{
		throw "NotImplemented";
	}
	private function op_ifelse()
	{
		throw "NotImplemented";
	}
	private function op_random()
	{
		throw "NotImplemented";
	}
	private function op_mul()
	{
		throw "NotImplemented";
	}
	private function op_sqrt()
	{
		throw "NotImplemented";
	}
	private function op_dup()
	{
		throw "NotImplemented";
	}
	private function op_exch()
	{
		throw "NotImplemented";
	}
	private function op_index()
	{
		throw "NotImplemented";
	}
	private function op_roll()
	{
		throw "NotImplemented";
	}
	
	//
	// miscelaneous helpers
	//

	private function alternatingLineTo(isHorizontal:Bool)
	{
		for (arg in popall())
		{
			var delta:IntPoint;
			if (isHorizontal)
			{
				delta = intPoint(arg, 0);
			}
			else
			{
				delta = intPoint(0, arg);
			}
			pen.rLineTo(delta);
			isHorizontal = !isHorizontal;
		}
	}
	
	private function vcurveto(args:Array<Float>):Array<Float>
	{
		var args2 = args.splice(0, 4);
		var dya = args2[0];
		var dxb = args2[1];
		var dyb = args2[2];
		var dxc = args2[3];

		var dyc:Float;
		if (args.length == 1)
		{
			dyc = args[0];
			args = [];
		}
		else
		{
			dyc = 0;
		}
		pen.rCubicCurveTo(intPoint(0, dya), intPoint(dxb, dyb), intPoint(dxc, dyc));
		return args;
	}
	
	private function hcurveto(args:Array<Float>):Array<Float>
	{
		var args2 = args.splice(0, 4);
		var dxa = args2[0];
		var dxb = args2[1];
		var dyb = args2[2];
		var dyc = args2[3];

		var dxc:Float;
		if (args.length == 1)
		{
			dxc = args[0];
			args = [];
		}
		else
		{
			dxc = 0;
		}
		pen.rCubicCurveTo(intPoint(dxa, 0), intPoint(dxb, dyb), intPoint(dxc, dyc));
		return args;
	}

	private static inline function intPoint(x:Float, y:Float):IntPoint
	{
		return { x: Std.int(x), y: Std.int(y) };
	}
}

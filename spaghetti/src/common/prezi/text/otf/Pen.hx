package prezi.text.otf;

class Pen
{
	public var location (default, null):IntPoint;
	public var startPoint (default, null):IntPoint;
	public var commands (default, null):Array<Int>;

	public function new(?commands:Array<Int>)
	{
		if (commands == null)
		{
			commands = [];
		}
		this.commands = commands;
		this.location = { x:0, y:0 };
	}

	public function moveTo(location:IntPoint)
	{
		this.location = location;
		this.startPoint = location;
		append(commands, [ OtfConstants.COMMAND_MOVE_TO, location.x, location.y ]);
	}
	public function rMoveTo(delta:IntPoint)
	{
		moveTo(nextPoint(location, delta));
	}

	public function lineTo(anchor:IntPoint)
	{
		startDrawingIfNeeded();
		append(commands, [ OtfConstants.COMMAND_LINE_TO, anchor.x, anchor.y ]);
		location = anchor;
	}
	public function rLineTo(delta:IntPoint)
	{
		lineTo(nextPoint(location, delta));
	}

	public function curveTo(control:IntPoint, anchor:IntPoint)
	{
		startDrawingIfNeeded();
		append(commands, [ OtfConstants.COMMAND_CURVE_TO, control.x, control.y, anchor.x, anchor.y ]);
		location = anchor;
	}
	public function rCurveTo(controlDelta:IntPoint, anchorDelta:IntPoint)
	{
		var control = nextPoint(location, controlDelta);
		var anchor = nextPoint(control, anchorDelta);
		curveTo(control, anchor);
	}

	public function cubicCurveTo(control1:IntPoint, control2:IntPoint, anchor:IntPoint)
	{
		startDrawingIfNeeded();
		append(commands, [ OtfConstants.COMMAND_CUBIC_CURVE_TO, control1.x, control1.y, control2.x, control2.y, anchor.x, anchor.y ]);
		location = anchor;
	}
	public function rCubicCurveTo(control1Delta:IntPoint, control2Delta:IntPoint, anchorDelta:IntPoint)
	{
		var control1 = nextPoint(location, control1Delta);
		var control2 = nextPoint(control1, control2Delta);
		var anchor = nextPoint(control2, anchorDelta);
		cubicCurveTo(control1, control2, anchor);
	}

	public function closePath()
	{
		startPoint = null;
	}

	private inline function startDrawingIfNeeded()
	{
		if (startPoint == null)
		{
			moveTo({ x:0, y:0 });
		}
	}

	private static inline function nextPoint(origin:IntPoint, delta:IntPoint):IntPoint
	{
		return
		{
			x: origin.x + delta.x,
			y: origin.y + delta.y
		};
	}

	private static inline function append(commands:Array<Int>, commandsToPush:Array<Int>)
	{
		for (command in commandsToPush)
		{
			commands.push(command);
		}
	}
}

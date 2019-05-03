import std.stdio;
import std.random;
import std.conv : to;
import std.algorithm.comparison;
import termbox;

struct Tile
{
	bool mine;
	bool visible;
	bool flag;
	int count = 0;
}

immutable Color[] tileColours = [
	Color.basic, // 0
	Color.red // 1
];

immutable ushort borderColour = 244;
immutable ushort mineColour = 160 | Attribute.reverse;
immutable ushort backgroundColour = 237;
immutable ushort selectedBackground = 9;
immutable ushort flagColour = 21 | Attribute.reverse;
static showBorders = false;

class Minefield
{
public:
	this(uint width = 15, uint height = 15)
	{
		this.width = width;
		this.height = height;
		flags = new Tile[][](width, height);
		fill();
	}

	ref Tile tile(uint x, uint y)
	in (x < width && y < height)
	{
		return flags[x][y];
	}

	ref Tile selected() @property
	{
		return flags[cursorX][cursorY];
	}

	bool isInField(int x, int y)
	{
		return x >= 0 && y >= 0 && x < width && y < height;
	}

	void clear()
	{
		flags = new Tile[][](width, height);
	}

	void fill()
	{
		placeMines();
		calculateMineCounts();
	}

	bool isMine(uint x, uint y)
	{
		if (isInField(x, y))
			return flags[x][y].mine;
		else
			return false;
	}

	uint width;
	uint height;
	Tile[][] flags;
	int cursorX = 0;
	int cursorY = 0;

private:
	void placeMines()
	{
		foreach (ref row; flags)
		{
			foreach (ref tile; row)
			{
				tile.mine = uniform(0.0, 1.0) < 0.1;
			}
		}
	}

	void calculateMineCounts()
	{
		foreach (lx, ref row; flags)
		{
			immutable x = cast(uint) lx;
			foreach (ly, ref tile; row)
			{
				immutable y = cast(uint) ly;
				tile.count = 0;
				if (isMine(x-1, y-1)) tile.count++;
				if (isMine(x, y-1)) tile.count++;
				if (isMine(x+1, y-1)) tile.count++;

				if (isMine(x-1, y)) tile.count++;
				if (isMine(x+1, y)) tile.count++;

				if (isMine(x-1, y+1)) tile.count++;
				if (isMine(x, y+1)) tile.count++;
				if (isMine(x+1, y+1)) tile.count++;
			}
		}
	}
}

void drawTile(ref Tile tile, uint x, uint y, bool inversed = false)
{
	if (showBorders)
	{
		// Draw '+' signs between cells
		setCell(x, y, '+', borderColour, Color.basic);
		setCell(x + 2, y, '+', borderColour, Color.basic);
		setCell(x, y + 2, '+', borderColour, Color.basic);
		setCell(x + 2, y + 2, '+', borderColour, Color.basic);

		// Draw borders
		setCell(x + 1, y, '-', borderColour, Color.basic);
		setCell(x + 1, y + 2, '-', borderColour, Color.basic);
		setCell(x, y + 1, '|', borderColour, Color.basic);
		setCell(x + 2, y + 1, '|', borderColour, Color.basic);

		// Draw tile content
		drawTileContent(tile, x + 1, y + 1, inversed);
	}
	else
	{
		drawTileContent(tile, x, y, inversed);
	}
}


void drawField(Minefield field, uint offsetX, uint offsetY)
{
	foreach (lx, ref row; field.flags)
	{
		immutable x = cast(uint) lx;
		foreach (ly, ref tile; row)
		{
			immutable y = cast(uint) ly;
			if (showBorders)
				tile.drawTile(offsetX + x * 2, offsetY + y * 2);
			else
				tile.drawTile(offsetX + x, offsetY + y);
		}
	}
}

void drawTileContent(ref Tile tile, uint x, uint y, bool inversed = false)
{
	if (tile.flag)
		setCell(x, y, 'P', flagColour, inversed ? selectedBackground : Color.basic);
	else if (!tile.visible)
		setCell(x, y, ' ', Color.basic, inversed ? selectedBackground : backgroundColour);
	else if (tile.mine)
		setCell(x, y, '*', mineColour, inversed ? selectedBackground : Color.basic);
	else if (tile.count > 0)
		setCell(x, y, '0' + tile.count, tileColours[1], inversed ? selectedBackground : Color.basic);
	else if (tile.count == 0)
		setCell(x, y, '.', Color.basic, inversed ? selectedBackground : 0);
}

void renderFull(Minefield field, uint offsetX = 0, uint offsetY = 0)
{
	drawField(field, offsetX, offsetY);
	int y = field.height + 1;
	writeText("ARROW KEYS     Move cursor", 0, y++);
	writeText("SPACE/ENTER    Click tile", 0, y++);
	writeText("F/P            Toggle flag", 0, y++);
	writeText("ESCAPE         Quit", 0, y++);
}

void drawCursor(Minefield field, uint offsetX = 0, uint offsetY = 0, bool inversed = true)
{
	field.selected.drawTile(offsetX + field.cursorX, offsetY + field.cursorY, inversed);
}

void moveCursor(Minefield field, int dx, int dy)
{
	drawCursor(field, 0, 0, false);
	field.cursorX = clamp(field.cursorX + dx, 0, field.width - 1);
	field.cursorY = clamp(field.cursorY + dy, 0, field.height - 1);
	drawCursor(field);
}

void floodSelect(Minefield field, int x, int y)
{
	if (!field.isInField(x, y))
		return;

	Tile* tile = &field.tile(x, y);
	assert(tile !is null);
	if (tile.visible)
		return;
	tile.visible = true;
	(*tile).drawTile(x, y);

	if (tile.count == 0)
	{
		field.floodSelect(x - 1, y - 1);
		field.floodSelect(x, y - 1);
		field.floodSelect(x + 1, y - 1);

		field.floodSelect(x - 1, y);
		field.floodSelect(x + 1, y);

		field.floodSelect(x - 1, y + 1);
		field.floodSelect(x, y + 1);
		field.floodSelect(x + 1, y + 1);
	}
}

void select(Minefield field)
{
	if (field.selected.flag)
		return;
	if (!field.selected.mine && field.selected.count == 0)
		field.floodSelect(field.cursorX, field.cursorY);
	else
		field.selected.visible = true;
	drawCursor(field);
}

void toggleFlag(Minefield field)
{
	if (!field.selected.visible)
	{
		field.selected.flag = !field.selected.flag;
		drawCursor(field);
	}
}

void writeText(string text, int x, int y)
{
	foreach (c; text)
	{
		setCell(x++, y, c, Color.basic, Color.basic);
	}
}

void main()
{
	init();

	setOutputMode(OutputMode.color256);
	Minefield field;// = //new Minefield();
	//if (showBorders)
	//	field = new Minefield(width() / 2 - 1, height() / 2 - 1);
	//else
	field = new Minefield();
	//field = new Minefield(width(), height());
	field.renderFull(0, 0);
	field.drawCursor();
	Event e;
	do
	{
		switch (e.key)
		{
			case Key.arrowRight:
				field.moveCursor(1, 0);
				break;
			case Key.arrowLeft:
				field.moveCursor(-1, 0);
				break;
			case Key.arrowUp:
				field.moveCursor(0, -1);
				break;
			case Key.arrowDown:
				field.moveCursor(0, 1);
				break;
			case Key.space:
			case Key.enter:
				field.select();
				break;
			default:
				break;
		}
		switch (e.ch)
		{
			case 'r':
				field.renderFull();
				break;
			case 'f':
			case 'p':
				field.toggleFlag();
				break;
			default:
				break;
		}
		flush();
		pollEvent(&e);
	}
	while (e.key != Key.esc);

	shutdown();
}

module draw;
import termbox;
import minefield;

struct DrawSettings
{
    int offsetX;
    int offsetY;
}

DrawSettings drawSettings;

private
{
    immutable Color[] tileColours = [
        Color.basic, // 0
        Color.red // 1
    ];

    immutable ushort borderColour = 244;
    immutable ushort mineColour = 160 | Attribute.reverse;
    immutable ushort backgroundColour = 237;
    immutable ushort selectedBackground = 9;
    immutable ushort flagColour = 21 | Attribute.reverse;
}

void drawTile(Tile tile, uint x, uint y, bool inversed = false)
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

void drawCursor(Minefield field, bool inversed = true)
{
    field.selected.drawTile(field.cursorX, field.cursorY, inversed);
}

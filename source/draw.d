module draw;
import termbox;
public import termbox : flush;
import minefield;

struct DrawSettings
{
    int offsetX;
    int offsetY;
}

DrawSettings drawSettings;

private
{
    immutable ushort[] tileColours = [
        Color.basic, // 0
        12, // 1
        2, // 2
        9, // 3
        24, // 4
        138, // 5
        43, // 6
        96, // 7
        250 // 8
    ];

    immutable enum Colour : ushort
    {
        border = 224,
        mine = 160 | Attribute.reverse,
        background = 237,
        selected = 9,
        flag = 21 | Attribute.reverse
    }
}

void drawTile(Tile tile, uint x, uint y, bool inversed = false, bool bad = false)
{
    x += drawSettings.offsetX;
    y += drawSettings.offsetY;
    if (tile.flag)
    {
        if (!tile.mine && bad)
            setCell(x, y, 'X', Colour.mine, inversed ? Colour.selected : Color.basic);
        else
            setCell(x, y, 'P', Colour.flag, inversed ? Colour.selected : Color.basic);
    }
    else if (!tile.visible)
    {
        auto colour = inversed ? Colour.selected : Colour.background;
        setCell(x, y, '#', colour, colour);
    }
    else if (tile.mine)
        setCell(x, y, '*', Colour.mine, inversed ? Colour.selected : Color.basic);
    else if (tile.count > 0)
        setCell(x, y, '0' + tile.count, tileColours[tile.count], inversed
                ? Colour.selected : Color.basic);
    else if (tile.count == 0)
        setCell(x, y, '.', Color.basic, inversed ? Colour.selected : 0);
}

void undrawCursor(Minefield field)
{
    field.selected.drawTile(field.cursorX, field.cursorY);
}

void drawCursor(Minefield field)
{
    field.selected.drawTile(field.cursorX, field.cursorY, true);
}

void drawField(Minefield field, bool bad = false)
{
    clear();
    drawSettings.offsetX = (width() - field.width) / 2;
    drawSettings.offsetY = (height() - field.height) / 2;
    for (int x = 0; x < field.width; x++)
    {
        for (int y = 0; y < field.height; y++)
        {
            field.tile(x, y).drawTile(x, y, false, bad);
        }
    }
    field.drawCursor();
    field.drawHelp();
    flush();
}

void drawMessage(string text)
{
    uint x = drawSettings.offsetX;
    uint y = drawSettings.offsetY - 2;
    foreach (c; text)
    {
        setCell(x++, y, c, Color.basic, Color.basic);
    }
    flush();
}

void drawMessageBelow(Minefield field, string text, uint offset)
{
    uint x = drawSettings.offsetX;
    uint y = drawSettings.offsetY + field.height + offset + 1;
    foreach (c; text)
    {
        setCell(x++, y, c, Color.basic, Color.basic);
    }
    flush();
}

void drawHelp(Minefield field)
{
    field.drawMessageBelow("ARROWS: Move cursor", 0);
    field.drawMessageBelow("SPACE:  Click selected tile", 1);
    field.drawMessageBelow("F/P:    Toggle flag", 2);
    field.drawMessageBelow("ESCAPE: Quit", 3);
}

void startGraphics()
{
    init();
    setOutputMode(OutputMode.color256);
}

void endGraphics()
{
    shutdown();
}

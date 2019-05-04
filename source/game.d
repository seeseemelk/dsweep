module game;
import minefield;
import draw;
import input;

struct Game
{
    enum State
    {
        PLAYING,
        DEAD,
        WON,
        EXIT
    }

    State state = State.PLAYING;
    Minefield field;
    int countTiles;
    int tilesClicked;
}

void moveCursor(Minefield field, int x, int y)
{
    if (field.isInField(field.cursorX + x, field.cursorY + y))
    {
        field.undrawCursor();
        field.cursorX += x;
        field.cursorY += y;
        field.drawCursor();
        flush();
    }
}

void floodSelect(ref Game game, int x, int y)
{
    if (!game.field.isInField(x, y))
        return;

    Tile tile = game.field.tile(x, y);
    assert(tile !is null);
    if (tile.visible)
        return;
    game.tilesClicked++;
    tile.visible = true;
    tile.drawTile(x, y);

    if (tile.count == 0)
    {
        game.floodSelect(x - 1, y - 1);
        game.floodSelect(x, y - 1);
        game.floodSelect(x + 1, y - 1);

        game.floodSelect(x - 1, y);
        game.floodSelect(x + 1, y);

        game.floodSelect(x - 1, y + 1);
        game.floodSelect(x, y + 1);
        game.floodSelect(x + 1, y + 1);
    }
}

bool click(ref Game game)
{
    auto field = game.field;
    if (field.selected.flag)
    {
        return false;
    }
    else if (!field.selected.mine && field.selected.count == 0)
    {
        game.floodSelect(field.cursorX, field.cursorY);
    }
    else
    {
        game.tilesClicked++;
        field.selected.visible = true;
    }
    field.drawCursor();
    flush();

    return field.selected.mine;
}

unittest
{
    // A normal tile can be clicked.
    Game game;
    auto field = new Minefield;
    game.field = field;
    field.selected.mine = false;
    assert(game.click() == false);
    assert(field.selected.visible == true);
}

unittest
{
    // A mine tile kills
    Game game;
    auto field = new Minefield;
    game.field = field;
    field.selected.mine = true;
    assert(game.click() == true);
}

unittest
{
    // A flagged tile cannot be clicked.
    Game game;
    auto field = new Minefield;
    game.field = field;
    game.toggleFlag();
    game.click();
    assert(field.selected.visible == false);
}

void toggleFlag(ref Game game)
{
    auto field = game.field;
    if (!field.selected.visible)
    {
        field.selected.flag = !field.selected.flag;
        drawCursor(field);
        flush();
    }
}

unittest
{
    // An invisible tile can have its flag toggled.
    Game game;
    auto field = new Minefield;
    game.field = field;
    field.selected.visible = false;
    assert(field.selected.flag == false);
    game.toggleFlag();
    assert(field.selected.flag == true);
}

unittest
{
    // A visible tile cannot have a flag.
    Game game;
    auto field = new Minefield;
    game.field = field;
    field.selected.visible = true;
    assert(field.selected.flag == false);
    game.toggleFlag();
    assert(field.selected.flag == false);
}

Game.State doInputPlaying(ref Game game)
{
    game.field.drawField();
    flush();
    while (true)
    {
        final switch (poll())
        {
        case Action.LEFT:
            game.field.moveCursor(-1, 0);
            break;
        case Action.RIGHT:
            game.field.moveCursor(1, 0);
            break;
        case Action.UP:
            game.field.moveCursor(0, -1);
            break;
        case Action.DOWN:
            game.field.moveCursor(0, 1);
            break;
        case Action.FLAG:
            game.toggleFlag();
            break;
        case Action.CLICK:
            if (game.click())
                return Game.State.DEAD;
            else if (game.tilesClicked >= game.countTiles)
                return Game.State.WON;
            break;
        case Action.OTHER:
            break;
        case Action.RESIZE:
            game.field.drawField();
            break;
        case Action.EXIT:
            return Game.State.EXIT;
        }
    }
}

void renderDeadScreen(ref Game game)
{
    game.field.drawField(true);
    drawMessage("You lost! (Press enter to restart.)");
}

Game.State doInputDead(ref Game game)
{
    foreach (tile; game.field)
    {
        if (tile.mine)
            tile.visible = true;
    }
    game.renderDeadScreen();
    while (true)
    {
        switch (poll())
        {
        default:
            break;
        case Action.CLICK:
            game.start();
            return Game.State.PLAYING;
        case Action.RESIZE:
            game.renderDeadScreen();
            break;
        case Action.EXIT:
            return Game.State.EXIT;
        }
    }
}

void renderWinScreen(ref Game game)
{
    game.field.drawField();
    game.field.undrawCursor();
    flush();
    drawMessage("YOU WON!!! (Press enter to restart.)");
}

Game.State doInputWon(ref Game game)
{
    game.renderWinScreen();
    while (true)
    {
        switch (poll())
        {
        default:
            break;
        case Action.CLICK:
            game.start();
            return Game.State.PLAYING;
        case Action.RESIZE:
            game.renderWinScreen();
            break;
        case Action.EXIT:
            return Game.State.EXIT;
        }
    }
}

void start(ref Game game)
{
    game.state = Game.State.PLAYING;
    game.field = new Minefield;

    foreach (tile; game.field)
    {
        if (!tile.mine)
            game.countTiles++;
    }
}

void runGame()
{
    startGraphics();
    Game game;
    game.start();
    while (game.state != Game.State.EXIT)
    {
        final switch (game.state)
        {
        case Game.State.PLAYING:
            game.state = game.doInputPlaying();
            break;
        case Game.State.DEAD:
            game.state = game.doInputDead();
            break;
        case Game.State.WON:
            game.state = game.doInputWon();
            break;
        case Game.State.EXIT:
            break;
        }
    }
    endGraphics();
}

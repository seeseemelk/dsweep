module input;
import termbox;

enum Action
{
    LEFT,
    RIGHT,
    UP,
    DOWN,
    CLICK,
    FLAG,
    EXIT,
    RESIZE,
    OTHER
}

Action poll()
{
    Event e;
    pollEvent(&e);

    if (e.type == EventType.resize)
        return Action.RESIZE;

    switch (e.key)
    {
    case Key.arrowLeft:
        return Action.LEFT;
    case Key.arrowRight:
        return Action.RIGHT;
    case Key.arrowUp:
        return Action.UP;
    case Key.arrowDown:
        return Action.DOWN;
    case Key.space:
    case Key.enter:
        return Action.CLICK;
    case Key.esc:
        return Action.EXIT;
    default:
        break;
    }

    switch (e.ch)
    {
    case 'f':
    case 'p':
        return Action.FLAG;
    default:
        return Action.OTHER;
    }
}

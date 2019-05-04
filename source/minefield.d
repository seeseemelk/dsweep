module minefield;

class Tile
{
public:
    bool mine;
    bool visible;
    bool flag;
    int count = 0;
}

final @safe class Minefield
{
public:
    invariant
    {
        assert(cursorX < width && cursorY < height);
        assert(tiles.length == width);
        assert(tiles[0].length == height);
    }

    this(uint width = 20, uint height = 15)
    {
        this.width = width;
        this.height = height;
        cursorX = width / 2;
        cursorY = height / 2;
        tiles = new Tile[][](width, height);
        clear();
        generate();
    }

    unittest
    {
        auto minefield = new Minefield;
        assert(minefield.width > 0);
        assert(minefield.height > 0);
        assert(minefield.tiles !is null);
        assert(minefield.tiles.length == minefield.width);
        assert(minefield.tiles[0].length == minefield.height);
    }

    auto tile(uint x, uint y) inout
    in(isInField(x, y))
    out(tile; tile !is null)
    {
        return tiles[x][y];
    }

    auto selected() inout @property
    in(isInField(cursorX, cursorY))
    out(tile; tile !is null)
    {
        return tile(cursorX, cursorY);
    }

    unittest
    {
        auto field = new Minefield;
        assert(field.selected is field.tile(field.cursorX, field.cursorY));
    }

    bool isInField(int x, int y) const pure
    {
        return x >= 0 && y >= 0 && x < width && y < height;
    }

    unittest
    {
        auto minefield = new Minefield;
        assert(minefield.isInField(0, 0) == true);
        assert(minefield.isInField(5, 5) == true);
        assert(minefield.isInField(minefield.width, 0) == false);
        assert(minefield.isInField(0, minefield.height) == false);
        assert(minefield.isInField(-1, 0) == false);
        assert(minefield.isInField(0, -1) == false);
    }

    unittest
    {
        auto minefield = new Minefield;
        const tile = minefield.tile(0, 0);
        minefield.clear();
        assert(tile !is minefield.tile(0, 0));
    }

    int opApply(int delegate(ref Tile) operations) @trusted
    {
        return opApply((ref uint x, ref uint y, ref Tile tile) {
            return operations(tile);
        });
    }

    int opApply(int delegate(ref uint, ref uint, ref Tile) operations) @trusted
    {
        int result;
        foreach (lx, ref row; tiles)
        {
            auto x = cast(uint) lx;
            foreach (ly, ref tile; row)
            {
                if (tile is null)
                    tile = new Tile;
                auto y = cast(uint) ly;
                result = operations(x, y, tile);
                if (result)
                    break;
            }
        }
        return result;
    }

    void clear()
    {
        for (int x = 0; x < width; x++)
        {
            for (int y = 0; y < height; y++)
            {
                tiles[x][y] = new Tile;
            }
        }
    }

    bool isMine(uint x, uint y)
    {
        if (isInField(x, y))
            return tile(x, y).mine;
        else
            return false;
    }

    unittest
    {
        auto minefield = new Minefield;
        minefield.tile(0, 0).mine = false;
        assert(minefield.isMine(0, 0) == false);
    }

    unittest
    {
        auto minefield = new Minefield;
        minefield.tile(0, 0).mine = true;
        assert(minefield.isMine(0, 0) == true);
    }

    uint cursorX = 0;
    uint cursorY = 0;
    uint width;
    uint height;

private:

    void placeMines()
    {
        import std.random : uniform;

        foreach (x, y, tile; this)
        {
            tile.mine = uniform(0.0, 1.0) < 0.1;
        }
    }

    void calculateMineCounts()
    {
        foreach (x, y, tile; this)
        {
            tile.count = 0;
            if (isMine(x - 1, y - 1))
                tile.count++;
            if (isMine(x, y - 1))
                tile.count++;
            if (isMine(x + 1, y - 1))
                tile.count++;

            if (isMine(x - 1, y))
                tile.count++;
            if (isMine(x + 1, y))
                tile.count++;

            if (isMine(x - 1, y + 1))
                tile.count++;
            if (isMine(x, y + 1))
                tile.count++;
            if (isMine(x + 1, y + 1))
                tile.count++;
        }
    }

    void generate()
    {
        placeMines();
        calculateMineCounts();
    }

    unittest
    {
        auto field = new Minefield;
        field.clear();
        field.tile(3, 3).mine = true;
        field.calculateMineCounts();
        assert(field.tile(0, 0).count == 0);
        assert(field.tile(2, 2).count == 1);
        assert(field.tile(3, 2).count == 1);
        assert(field.tile(4, 4).count == 1);
    }

    Tile[][] tiles;
}

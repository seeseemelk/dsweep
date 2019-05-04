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
    this(uint width = 15, uint height = 15)
    {
        this.width = width;
        this.height = height;
        clear();
    }

    unittest
    {
        auto minefield = new Minefield;
        assert(minefield.width == 15);
        assert(minefield.height == 15);
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
        auto minefield = new Minefield;
        assert(minefield.selected is minefield.tile(0, 0));
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

    void clear()
    {
        tiles = new Tile[][](width, height);

        for (int x = 0; x < width; x++)
        {
            for (int y = 0; y < height; y++)
            {
                tiles[x][y] = new Tile;
            }
        }
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
        assert(minefield.isMine(0, 0) == false);
    }

    unittest
    {
        auto minefield = new Minefield;
        minefield.tile(0, 0).mine = true;
        assert(minefield.isMine(0, 0) == true);
    }

    void generate()
    {
        placeMines();
        calculateMineCounts();
    }

    int cursorX = 0;
    int cursorY = 0;
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

    unittest
    {
        auto minefield = new Minefield;
        minefield.tile(3, 3).mine = true;
        minefield.calculateMineCounts();
        assert(minefield.tile(0, 0).count == 0);
        assert(minefield.tile(2, 2).count == 1);
        assert(minefield.tile(3, 2).count == 1);
        assert(minefield.tile(4, 4).count == 1);
    }

    Tile[][] tiles;
}

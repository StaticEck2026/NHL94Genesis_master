#!/usr/bin/env python3
"""Write the Workbench tool icon of the launcher (NHL94.info): a 4 colour (Workbench 2+
palette: grey, black, white, blue) puck and stick with "NHL 94". With "drawer", the same
picture as the icon of a drawer (the drawer the LHA archive unpacks to).

Usage: mkicon.py out.info [drawer]
"""
import struct, sys

W, H = 48, 28
# 0 grey, 1 black, 2 white, 3 blue
ART = [
    "................................................",
    "..1111.......11..11.11......11111.....11....11..",
    "..11.11......11..11.11.....11...11...111....11..",
    "..11..11.....11..11.11.....11...11..1111....11..",
    "..11...11....111111.11......111111.11.11....11..",
    "..11....11...11..11.11..........11.1111111..11..",
    "..11.....11..11..11.11.........11.......11..11..",
    "..11......11.11..11.111111...111........11..11..",
    "............................................11..",
    "...........................................111..",
    "..........................................1111..",
    "......1111111111.........................11211..",
    "...111222222222211111..................112211...",
    "..1122222222222222221.................112211....",
    "..1122222222222222221...............1122211.....",
    "..1111222222222222111.............11222111......",
    "..1311111111111111131...........112221111.......",
    "..1333333333333333331.......11112222111.........",
    "...111333333333331111...1111222222111...........",
    "......1111111111.....111222222221111............",
    "...................11222222221111...............",
    "..................1122222221111.................",
    "..................11111111111...................",
    "................................................",
    "................................................",
    "................................................",
    "................................................",
    "................................................",
]


def planes():
    words = (W + 15) // 16
    data = b''
    for plane in range(2):
        for row in ART:
            bits = 0
            for x in range(words * 16):
                c = int(row[x]) if x < len(row) and row[x] != '.' else 0
                bits = (bits << 1) | ((c >> plane) & 1)
            data += bits.to_bytes(words * 2, 'big')
    return data


def main():
    drawer = len(sys.argv) > 2 and sys.argv[2] == 'drawer'
    gadget = struct.pack('>IhhhhHHHIIIIIHI', 0, 0, 0, W, H + 1, 4, 3, 1, 1, 0, 0, 0, 0, 0, 1)
    obj = struct.pack('>HH', 0xE310, 1) + gadget + struct.pack('>BBIIiiIII', 2 if drawer else 3, 0, 0, 0,
                                                               -0x80000000, -0x80000000, 1 if drawer else 0,
                                                               0, 0 if drawer else 16384)
    image = struct.pack('>hhhhhIBBI', 0, 0, W, H, 2, 1, 3, 0, 0)
    if drawer:
        # its window (an old NewWindow: place, size, default pens, no flags, minimum and maximum
        # size, the Workbench screen) and where it shows its contents; after the image, as icons
        # of revision 1 have it: show the default (icons), view by default
        window = struct.pack('>hhhhBBIIIIIIIhhHHH', 50, 50, 320, 120, 255, 255, 0, 0, 0, 0, 0, 0, 0,
                             90, 40, 0xFFFF, 0xFFFF, 1)
        dd = window + struct.pack('>ii', 0, 0)
        open(sys.argv[1], 'wb').write(obj + dd + image + planes() + struct.pack('>IH', 0, 0))
    else:
        open(sys.argv[1], 'wb').write(obj + image + planes())


if __name__ == '__main__':
    main()

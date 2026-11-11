# qb-pawnshop
Pawn Shop For QB-Core

Melting inputs, completion times and uncollected rewards are tracked on the
server. Pickup ignores client-supplied quantities, and inventory-full retries
only deliver rewards still owed. Pending melts last for the current character
session; logout, disconnect or a resource restart clears them.

Run `lua test/smoke/melting.lua` from this repository, with `kora_inventory` and
`kora_lib` checked out alongside it. The regression uses actual inventory,
pawnshop and list validation code with a controlled clock and host stubs;
it does not start FiveM or write SQL.

# License

    QBCore Framework
    Copyright (C) 2021 Joshua Eger

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>

Full documentation: see [docs/](docs/index.md).

# sfc2
sfc2 ("StarFall Commands 2") is a [StarfallEx](https://github.com/thegrb93/StarfallEx) chip that provides various useful utilities via chat commands. Compatible with [luadev](https://github.com/Metastruct/luadev) chat commands.

![Screenshot](https://user-images.githubusercontent.com/70858634/160216771-20429142-af10-4b5c-9c7b-5d6d35841fbd.png)

## Usage
1. `git clone https://github.com/x4fx77x4f/sfc2.git ~/.steam/steam/steamapps/common/GarrysMod/garrysmod/data/starfall/sfc2`
2. Flash `sfc2/init.lua` to a Starfall Processor
3. Optionally additionally place, wire, and use a HUD component

## Commands
Chat commands are prefixed with `$`. Other people (probably) won't see your chat commands without being connected to a HUD.

- `l <Lua code>`: Execute Lua code on the server. Chip owner only.
- `ls <Lua code>`: Execute Lua code on the server and all clients. Chip owner only.
- `lc <Lua code>`: Execute Lua code on all clients. Chip owner only.
- `lsc <targets> <Lua code>`: Execute Lua code on specified targets. Chip owner only. Targets are separated by commas.
- `lm <Lua code>`: Execute Lua code on your own client.
- `lb <Lua code>`: Execute Lua code on the server and your own client. Chip owner only.
- Any of the previous 6 commands but with `p` instead of `l`: Execute Lua code, and also *print* the result to chat.
- `goto <target>`: Teleport to the specified target. Chip owner only. Kind of fiddly; you might get stuck in a wall.
- `return`: Teleport to your previous location. Chip owner only.
- `spectate [target]`: Spectate a player, or stop spectating if no target is specified. Chip owner only. You must be connected to a HUD for this to work. Won't work if they're not in your PVS.
- `unspectate`: Stop spectating. Chip owner only.
- `blacklist <target>`: Ignore all future net messages from the target for the duration of the session. Chip owner only.
- `unblacklist <target>`: Stop ignoring net messages from the target. Chip owner only.
- `suicide <target>`: Self-destruct on specified target. Chip owner only. I don't know why I added this. I can't think of any good reason you would ever want to do this.
- `jail <target>`: Jail the target. Chip owner only.
- `unjail <target>`: Unjail the target. Chip owner only.
- `propkill <target>`: Propkill the target. Chip owner only.
- `spawnkill <target>`: Mark the target for spawnkilling, and propkill them. Chip owner only.
- `unspawnkill <target>`: Unmark the target for spawnkilling. Chip owner only.

## License
This software is licensed under the MIT License. Its license terms can be read in [`LICENSE`](LICENSE).

**This software is provided as is without warranty of any kind.** While an effort has been made to reduce the chance of bad things happening as a result of this software, absolutely no guarantees are made as to its safety.

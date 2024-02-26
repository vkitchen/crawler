//	CRAWLER.ZIG
//	-----------
//	Copyright (c) Vaughan Kitchen
//	Released under the ISC license (https://opensource.org/licenses/ISC)

const std = @import("std");
const zqlite = @import("zqlite");

pub fn main() !void {
    const flags = zqlite.OpenFlags.EXResCode;
    var conn = try zqlite.open("crawler.db", flags);
    defer conn.close();

    var rows = try conn.rows("select id, domain from sites", .{});
    defer rows.deinit();
    while (rows.next()) |row| {
        std.debug.print("domain: {s}\n", .{row.text(1)});
    }
    if (rows.err) |err| return err;
}

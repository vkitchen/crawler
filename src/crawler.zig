//	CRAWLER.ZIG
//	-----------
//	Copyright (c) Vaughan Kitchen
//	Released under the ISC license (https://opensource.org/licenses/ISC)

const std = @import("std");
const zqlite = @import("zqlite");
const curl = @cImport(@cInclude("curl/curl.h"));

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

    var arena_state = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena_state.deinit();

    const allocator = arena_state.allocator();

    // global curl init, or fail
    if (curl.curl_global_init(curl.CURL_GLOBAL_ALL) != curl.CURLE_OK)
        return error.CURLGlobalInitFailed;
    defer curl.curl_global_cleanup();

    // curl easy handle init, or fail
    const handle = curl.curl_easy_init() orelse return error.CURLHandleInitFailed;
    defer curl.curl_easy_cleanup(handle);

    var response_buffer = std.ArrayList(u8).init(allocator);

    // superfluous when using an arena allocator, but
    // important if the allocator implementation changes
    defer response_buffer.deinit();

    // setup curl options
    if (curl.curl_easy_setopt(handle, curl.CURLOPT_URL, "https://ziglang.org") != curl.CURLE_OK)
        return error.CouldNotSetURL;

    // set write function callbacks
    if (curl.curl_easy_setopt(handle, curl.CURLOPT_WRITEFUNCTION, writeToArrayListCallback) != curl.CURLE_OK)
        return error.CouldNotSetWriteCallback;
    if (curl.curl_easy_setopt(handle, curl.CURLOPT_WRITEDATA, &response_buffer) != curl.CURLE_OK)
        return error.CouldNotSetWriteCallback;

    // perform
    if (curl.curl_easy_perform(handle) != curl.CURLE_OK)
        return error.FailedToPerformRequest;

    std.log.info("Got response of {d} bytes", .{response_buffer.items.len});
    std.debug.print("{s}\n", .{response_buffer.items});
}

fn writeToArrayListCallback(data: *anyopaque, size: c_uint, nmemb: c_uint, user_data: *anyopaque) callconv(.C) c_uint {
    var buffer: *std.ArrayList(u8) = @alignCast(@ptrCast(user_data));
    var typed_data: [*]u8 = @ptrCast(data);
    buffer.appendSlice(typed_data[0 .. nmemb * size]) catch return 0;
    return nmemb * size;
}

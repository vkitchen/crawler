//	CRAWLER.ZIG
//	-----------
//	Copyright (c) Vaughan Kitchen
//	Released under the ISC license (https://opensource.org/licenses/ISC)

const std = @import("std");
const zqlite = @import("zqlite");
const curl = @cImport(@cInclude("curl/curl.h"));

// 10MiB HTML response buffer
var fixed_buffer: [10 * 1024 * 1024]u8 = undefined;
var response_allocator = std.heap.FixedBufferAllocator.init(&fixed_buffer);
var response_buffer = std.ArrayList(u8).init(response_allocator.allocator());

fn curlCallback(data: *anyopaque, size: c_uint, nmemb: c_uint, user_data: *anyopaque) callconv(.C) c_uint {
    const buffer: *std.ArrayList(u8) = @alignCast(@ptrCast(user_data));
    const typed_data: [*]u8 = @ptrCast(data);
    buffer.appendSlice(typed_data[0 .. nmemb * size]) catch return 0;
    return nmemb * size;
}

fn fetch(curl_handle: *anyopaque, address: [*:0]const u8) !void {
    try response_buffer.resize(0);

    if (curl.curl_easy_setopt(curl_handle, curl.CURLOPT_URL, address) != curl.CURLE_OK)
        return error.CURLSetURLFailed;

    if (curl.curl_easy_perform(curl_handle) != curl.CURLE_OK)
        return error.CURLPerformRequestFailed;
}

fn tick(db: zqlite.Conn, curl_handle: *anyopaque) !void {
    var rows = try db.rows("select id, domain from sites", .{});
    defer rows.deinit();
    while (rows.next()) |row| {
        const domain = row.textZ(1);

        std.debug.print("domain: {s}\n", .{domain});
        try fetch(curl_handle, domain);
        std.log.info("Got response of {d} bytes", .{response_buffer.items.len});
        std.debug.print("{s}\n", .{response_buffer.items});
    }
    if (rows.err) |err| return err;
}

pub fn main() !void {
    // sqlite init
    const flags = zqlite.OpenFlags.EXResCode;
    var db = try zqlite.open("crawler.db", flags);
    defer db.close();

    // curl init
    if (curl.curl_global_init(curl.CURL_GLOBAL_ALL) != curl.CURLE_OK)
        return error.CURLGlobalInitFailed;
    defer curl.curl_global_cleanup();

    const curl_handle = curl.curl_easy_init() orelse return error.CURLEasyInitFailed;
    defer curl.curl_easy_cleanup(curl_handle);

    // set curl options
    if (curl.curl_easy_setopt(curl_handle, curl.CURLOPT_WRITEFUNCTION, curlCallback) != curl.CURLE_OK)
        return error.CURLSetOptFailed;
    if (curl.curl_easy_setopt(curl_handle, curl.CURLOPT_WRITEDATA, &response_buffer) != curl.CURLE_OK)
        return error.CURLSetOptFailed;
    if (curl.curl_easy_setopt(curl_handle, curl.CURLOPT_USERAGENT, "Mozilla/5.0 (compatible; PotatoCastlesBot; +http://potatocastles.com)") != curl.CURLE_OK)
        return error.CURLSetOptFailed;

    try tick(db, curl_handle);
}

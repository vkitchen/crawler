const std = @import("std");

pub fn build(b: *std.Build) !void {
    const zqlite = b.dependency("zqlite", .{
        .target = b.host,
        .optimize = .ReleaseSafe,
    }).module("zqlite");

    zqlite.addCSourceFile(.{
        .file = std.Build.LazyPath.relative("lib/sqlite3/sqlite3.c"),
        .flags = &[_][]const u8{
            "-DSQLITE_DQS=0",
            "-DSQLITE_DEFAULT_WAL_SYNCHRONOUS=1",
            "-DSQLITE_USE_ALLOCA=1",
            "-DSQLITE_THREADSAFE=1",
            "-DSQLITE_TEMP_STORE=3",
            "-DSQLITE_ENABLE_API_ARMOR=1",
            "-DSQLITE_ENABLE_UNLOCK_NOTIFY",
            "-DSQLITE_ENABLE_UPDATE_DELETE_LIMIT=1",
            "-DSQLITE_DEFAULT_FILE_PERMISSIONS=0600",
            "-DSQLITE_OMIT_DECLTYPE=1",
            "-DSQLITE_OMIT_DEPRECATED=1",
            "-DSQLITE_OMIT_LOAD_EXTENSION=1",
            "-DSQLITE_OMIT_PROGRESS_CALLBACK=1",
            "-DSQLITE_OMIT_SHARED_CACHE",
            "-DSQLITE_OMIT_TRACE=1",
            "-DSQLITE_OMIT_UTF16=1",
            "-DHAVE_USLEEP=0",
        },
    });
    zqlite.addIncludePath(std.Build.LazyPath.relative("lib/sqlite3/"));

    const crawler = b.addExecutable(.{
        .name = "crawler",
        .root_source_file = .{ .path = "src/crawler.zig" },
        .target = b.host,
        .optimize = .ReleaseSafe,
    });
    crawler.root_module.addImport("zqlite", zqlite);
    crawler.linkLibC();
    crawler.linkSystemLibrary("libcurl");
    b.installArtifact(crawler);
}

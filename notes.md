# Notes

## Environment Variables

| Tag              | Description                                        | Default
| ---              | ---                                                | ---
| `CONSOLE_DEVICE` | `stderr` or `stdout`                               | `stderr`
| `LOG_TAGS`       | Filters messages based on their tags               | (not set)
| `LOG_LEVEL`      | Filters messages based on log level                | `info`
| `LOG_FORMATTERS` | Toggles styling (colors, bold)                     | `on`
| `LOG_HEADER`     | Toggles metadata display (timestamp, subject, etc) | `on`

## Levels

- Loggers don't need to have any levels
- Loggers with no levels:
  - Messages will be printed even if and only if their level is nil
  - Messages with a level of `_none` won't even be printed
- Loggers with no levels
  - Messages won't get printed if their level is nil
  - Messages with a level of `_none` will be printed

### Default Configuration

| Level    | Ordinal | Visible | Format            | SGR Codes
| ---      | ---     | ---     | ---               | ---
| `_none`  | -1      | Yes     | (none)            | (none)
| `_min`   | 0       | Yes     | (none)            | (none)
| `fatal`  | 0       | Yes     | Red on black      | `\e[31;40m … \e[49;39m`
| `error`  | 1       | Yes     | Bold white on red | `\e[1;41m … \e[49;22m`
| `warn`   | 2       | Yes     | Yellow on black   | `\e[33;40m … \e[49;39m`
| `info`   | 3       | Yes     | (none)            | (none)
| `debug`  | 4       | No      | Green             | `\e[32m … \e[39m`
| `trace`  | 5       | No      | Cyan              | `\e[36m … \e[39m`
| `_max`   | 5       | No      | (none)            | (none)

## Message Examples

### Default Configuration

```
[2022-02-06T01:43:20.15905Z] SomeSubject: Some message (Some Value: 1, Other Value: 11)
[2022-02-06T01:43:20.16044Z] OtherSubject ERROR: \e[1;41mSome message (Some Value: 1, Other Value: 11)\e[49;22m
```

### No Header

```
Some message (Some Value: 1, Other Value: 11)
\e[1;41mSome message (Some Value: 1, Other Value: 11)\e[49;22m
```

## Puts

- Writes to the logger irrespective of tagging and level configuration

## Code Sketches

### Zig

``` zig
var logger = Log.build("SomeSubject");

// Printed
logger.info("Some message (Some Value: {}, Other Value: {})", .{ 11, 111 });
// Printed conditionally based on LOG_TAGS setting
logger.info_tagged("Some message (Some Value: {}, Other Value: {})", .{ 11, 111 }, .{ "some_tag" });

// True
logger.write_predicate("info", "Some message (Some Value: {}, Other Value: {})", .{ 11, 111 });
// False
logger.write_predicate("trace", "Some message (Some Value: {}, Other Value: {})", .{ 11, 111 });
// True conditionally based on LOG_TAGS setting
logger.write_predicate("info", "Some message (Some Value: {}, Other Value: {})", .{ 11, 111 }, .{ "some_tag" });

// Set Level
logger.level = .warn;
// Not Printed
logger.info("Some message (Some Value: {}, Other Value: {})", .{ 11, 111 });

// Set tags, implemented in terms of logger.digest_tags
logger.set_tags(.{ "some_tag", "other_tags" });
// -or- (comptime, so no allocator needed)
logger.tags = Log.digest_tags(.{ "some_tag", "other_tags" });
// -or- (uses logger.allocator)
logger.tags = logger.digest_tags(.{ "some_tag", "other_tags" });
// -or-
logger = Log.build_tagged("SomeSubject", .{ "some_tag", "other_tag" });
// Printed conditionally based on LOG_TAGS setting
logger.info("Some message (Some Value: {}, Other Value: {})", .{ 11, 111 });
```

### Ruby

``` ruby
# Zig: var logger = Log.build("SomeSubject");
logger = Log.build("SomeSubject")

# Zig: const SomeLogger = Log.specialize(.{ "some_tag", "other_tag" });
class SomeLogger < Log
  def self.tag!(tags)
    tags << :some_tag
    tags << :other_tag
  end
end

# Zig: var logger = SomeLogger.build("OtherSubject");
logger = SomeLogger.build("OtherSubject")
```

## Differences from Eventide Logger

### Logger

- No telemetry

- No logger registry
  - Requires memory allocation
  - Native code doesn't benefit from it; the subject will never be an instance
    of a class

### Tags

- Added `_override` log tag
  - On a message, acts the same as `*`; causes message to be printed
    irrespective of tag configuration
  - `LOG_TAGS` can also include `_override` (or `*`), and causes all messages
    to be printed irrespective of tag configuration

- `_not_excluded` tag; works like `_all` except has less precedence than
  excluded tags
  - This resolves an issue filed with `evt-log` on GitHub:
    https://github.com/eventide-project/log/pull/9

### Levels

- Log levels are static
  - A native call to `logger.info(...)` has to invoke a function that is
    compiled into the binary; it's not possible to define level specific log
    invocation methods on-the-fly
  - `logger.call(logger.levels.info, "Some message")` is possible, but more
    difficult to scan
  - `logger.call("info", "Some message")` might be possible, but still not as
    amenable to scanning as `logger.info("Some message")`. It also pays a
    performance penalty

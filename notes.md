# Notes

## Tags

### Eventide Logger

Note: "logger tags" are set by the LOG_TAGS environment variable. Tags from
`#tag!` on specialized logger subclasses are considered message tags.

1. Considers log level before any tags
2. If message and the logger both lack tags, print the message
3. If the message has the special `*` tag, print the message
4. If the logger has the special `_all` tag, print the message
5. If the logger has the special `_untagged` tag, and the message lacks tags,
   print the message
6. If the message and the logger both have tags, print the message if the tags
   intersect:
  1. If any of the message's tags are excluded (e.g. message has `some_tag` and
     logger has `-some_tag`), no interesection
  2. If any of the message's tags are included (e.g. message has `some_tag` and
     logger has `some_tag`), intersection
  3. Otherwise, no intersection
7. Otherwise, don't print the message

### Terms

Message Tag
: Tag added to a particular message, e.g. `log.info(tag: :some_tag) { … }`
Logger Tag
: Tag added to a particular logger, e.g. `def tag!(tags) tags << :some_library`
Exclude Tag
: Tag the user wants to filter out via `LOG_TAGS=-exclude_tag`
Include Tag
: Tag the user wants to include via `LOG_TAGS=include_tag`
Tag Setting
: Include and exclude tags, e.g. `LOG_TAGS`

### State Machine

When iterating through a message's tags, a state machine is used to track
whether to print the message.

States:

- Untagged
  - No message tags have been iterated
  - If finished iterating, message should be printed

- Match Needed
  - No message tags have been matched
  - If finished iterating, message should *not* be printed

- Matched
  - At least one message tag has been matched to the include list
  - Do *not* consider the include list in this state
  - If finished iterating, message should be printed

- Excluded
  - At least one message tag has been matched to the exclude list
  - Do *not* consider the exclude or exclude lists in this state
  - If finished iterating, message should *not* be printed

``` ruby
class Logger
  def print?(message_tags)
    # Either :untagged or :match_needed, depending on if LOG_TAGS includes
    # "_untagged" or isn't set at all
    state = self.initial_state

    message_tags.each do |tag|
      if state == :print
        break
      end

      if tag == :*
        state = :print
      elsif state != :excluded && self.exclude_tag?(tag)
        state = :excluded
      elsif state != :matched && self.include_tag?(tag)
        state = :matched
      elsif state == :untagged
        state = :match_needed
      end
    end

    if [:untagged, :matched].include?(state)
      state = :print
    end

    return state == :print
  end
end
```

# Documentation Style Guide

This project follows a strict and specific documentation style designed to be helpful, readable, and consistent. It combines the structural clarity of Christopher Alexander's Pattern Language with the prose style of William Zinsser's *On Writing Well* and the usability of the U.S. Federal Plain Language Guidelines.

**All agents and contributors must adhere to these standards.**

The API documentation lives in the `.rbs` files under `sig/`, next to each declaration, and is written in Markdown. RDoc reads the `.rbs` files when you pass them as input, and then the HTML, `ri`, and `rake rdoc:coverage` all use those comments. A `.rb` file keeps only comments that say why the code is written as it is, or that explain a tricky part, and none sits directly above a `def`, `class`, or `module`: RDoc would take it as documentation. `rake docs:placement` fails on one that does.

## 1. Core Philosophy

*   **Context, Problem, Solution (Alexandrian Form):** Do not just say *what* a class does. Explain *why* it exists. Start with the context, state the problem (the pain point without this tool), and then present the class as the solution.
*   **Prose Style (Zinsser/Klinkenborg):** Use short, punchy sentences. Use active voice. Cut unnecessary words. Avoid "allow," "enable," "provide," "support," "functionality," and "capability" where possible. Weak verbs hide the action. Strong verbs drive the sentence.
*   **User-Centric (Plain Language):** Speak directly to the user ("You"). Don't abstract them away ("The developer"). Focus on their goals and how this tool helps them achieve those goals.
*   **Tone (Supportive and Authoritative, not Hostile or Prescriptive):** Avoid "must," "requires," "need to," or "mandatory." These words sound bossy. Treat the user as a capable peer. Instead of "You must do X," use imperative "Do X" or cause-and-effect "X ensures Y."

## 2. Class Documentation

Every public class must begin with a **Context-Problem-Solution** narrative.

### Structure

1.  **Summary Line:** A single line explaining the class's role.
2.  **Context (Narrative):** A short paragraph establishing the domain or situation.
3.  **Problem (Narrative):** A sentence or two identifying the specific difficulty, complexity, or "pain" the user faces in this context without the class.
4.  **Solution (Narrative):** A sentence explaining how this class solves that problem, often starting with "This class..." or "Use it to...".
5.  **Usage (Narrative):** A concrete "Use it to..." sentence listing common applications.
6.  **Example:** A comprehensive, copy-pasteable code example under an `## Examples` heading, in a fenced `ruby` block. Provide **multiple** examples to cover different use cases (e.g., basic usage vs. advanced configuration).

### Example

**Bad (Generic/Descriptive):**
```rbs
# A class for managing resources.
# It allows the user to store objects by integer ID.
# Supports adding, fetching, and closing.
```

**Good (Alexandrian/Zinsser/Plain Language):**
```rbs
# Stores managed objects behind integer handles.
#
# Frontend JavaScript cannot hold Ruby objects. Serializing large
# binary data through JSON on every call is slow and wasteful.
#
# This table stores the object once and hands the frontend a small
# integer "resource ID" (rid) to pass back later.
#
# Use it to share images, file handles, or other heavy objects with
# the WebView.
```

## 3. Method and Attribute Documentation

### Prose Style

*   **Attributes:** Use concise noun phrases. Avoid "This attribute returns..." or "Getter for...".
    *   *Bad:* "This is the label of the webview."
    *   *Good:* "The unique label identifying this webview."
*   **Methods:** Use active, third-person present tense verbs.
    *   *Bad:* "Will calculate the total."
    *   *Good:* "Calculates the total."
*   **Context:** For complex methods, you may use a condensed version of the Context-Problem-Solution pattern, but keep it brief.

### Syntax Standards

*   **Examples:** All public methods must include at least one usage example. Use an `## Example` heading and a fenced `ruby` block.
*   **Attributes:** Declare `attr_reader` in the `.rbs` file, with the documentation comment immediately preceding it.
*   **Parameters:** Use a Markdown bulleted list, one item for each parameter, with the name in backticks, for the `initialize` method. RDoc's `[name] description` lists render literally in `.rbs` comments.
*   **Formatting:** Write the comments in Markdown. Use backticks for identifiers, values, and anything with spaces or punctuation (e.g., `` `nil` ``, `` `rid` ``, `` `plugin:image|new` ``), `**bold**` for emphasis, and `[text](url)` for links. RDoc's `+code+` and `<tt>` markup render literally.
    *   Do **not** use smart quotes.

### Example

```rbs
class Webview
  # The unique label identifying this webview.
  attr_reader label: String

  # Creates a new Webview wrapper.
  #
  # - `label`: String, unique among webviews (e.g., `"main"`).
  # - `native`: Native::WebView handle from wry.
  def initialize: (label: String, native: Native::WebView) -> void
end
```

## 4. RDoc Specifics

*   **No Endless Methods:** Do **not** use Ruby 3.0+ endless method definitions (`def foo = bar`). RDoc currently has a bug where it fails to correctly parse the end of the method, causing subsequent methods to lose their visibility and comment attachment (they show up as undocumented public methods in `rake rdoc:coverage`). Always use standard `def ... end` blocks.
*   **No YARD:** Do not use `@param`, `@return`, or other YARD tags. The types are in the `.rbs` signature, and the comment holds the prose.
*   **Input:** RDoc reads `sig/**/*.rbs` only when it is passed as input beside `lib/**/*.rb`, as the `Rakefile` does. Without the `.rbs` files, the coverage report counts each item they document as undocumented.
*   **Directives:** RDoc does not process `:nodoc:` or `:stopdoc:` in `.rbs` comments, and they show as text. Declare an internal method under `private` instead.
*   **Headings:** Use Markdown headings, `##` and below, for section headers like `## Examples`.
*   **Why-comments in `.rb`:** Put a comment that says why the code is written as it is inside the body. RDoc attaches a comment to the next `def`, `class`, `module`, or constant even across blank lines, so a blank line doesn't keep it out of the documentation.

## 5. Examples the Gate Runs

`rake docs:examples` runs every fenced `ruby` block in the Markdown pages and in the `.rbs` comments, so an example can't drift from the code. Write each one so it runs as it stands.

*   **Order and isolation:** The blocks of one file run top to bottom in one fresh Ruby process, so a block can use a variable an earlier block set. Each file's process starts fresh, so one file's blocks can't change another's. The process has `lib` and the `lib` of each gem under `gems/` on its load path, and it has required `proof`, as the app has, so an example of Proof's classes needs no `require`. An example `require`s anything else it uses. The process runs in a temporary folder.
*   **Results:** Write `expression # => value` on one line, or put `# => value` on the line after the expression. The value is one Ruby expression on one line. The task fails unless the result equals the value and prints the same, so `1.0` doesn't match `1`. The failure lists the file and line, the expected value, and the actual one. A `# =>` with no expression to check also fails. The task reads the value an expression returns, not what it prints: `puts 1` returns `nil`.

```ruby
1 + 1 # => 2
[3, 1, 2].sort
# => [1, 2, 3]
```

*   **The wrong form:** To show what fails, put `# Wrong: raises ErrorClass` on the first line of a block. The task fails the block unless it raises that error or a subclass, so the wrong form stays wrong.

```ruby
# Wrong: raises ZeroDivisionError
1 / 0
```

*   **Skipping:** To skip a block that isn't meant to run, such as a shell transcript tagged `ruby` by mistake or a fragment that needs a database, put an HTML comment on the line before its fence: `<!-- skip-example: reason -->`. Give the reason on that one line: a marker with none fails the task. Every run reports each skipped block with its place and reason. In an `.rbs` comment, write the marker after the `#`. To show a marker on a page, put it in a `markdown` fence, which the task doesn't run:

````markdown
<!-- skip-example: needs a database -->
```ruby
Invoice.all.each(&:send_reminder)
```
````

## 6. Checklist for Agents

Before finalizing documentation, ask:
1.  Did I explain the *problem* this code solves?
2.  Are my sentences short and active? (Did I remove "allows the user to"?)
3.  Is the code example valid and copy-pasteable, and does `rake docs:examples` pass on it?
4.  Did I use backticks for symbols and code values?
5.  Did I document every attribute and parameter?
6.  Is the comment in the `.rbs` file, with no comment above a definition in the `.rb` file?

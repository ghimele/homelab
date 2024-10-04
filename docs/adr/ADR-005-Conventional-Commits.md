# ADR-005: Use Conventional Commits for Commit Message Management

## Status
Accepted

## Date
2024-09-16

## Context and Problem Statement
Consistent and structured commit messages are essential for maintaining a clean and understandable history in our repository. Without a defined format, commit messages can become inconsistent, making it harder to understand the changes, track issues, and automate release notes. We need a standardized commit message convention to improve collaboration, readability, and tooling automation.

## Solution (Decision)
We will adopt the [**Conventional Commits**](https://www.conventionalcommits.org/en/v1.0.0/) specification (v1.0.0) for writing commit messages. This system provides a standardized format for commit messages, ensuring clarity and consistency across the project.

The format of a Conventional Commit message is:

```bash
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Key Points:
```
- **Type**: A short, lowercase keyword that categorizes the change (e.g., `feat`, `fix`, `chore`, etc.).
- **Scope**: An optional part that describes the section of the codebase affected by the change (e.g., `api`, `cli`).
- **Description**: A brief explanation of what was changed.
- **Body**: (Optional) Additional information about the change.
- **Footer**: (Optional) For breaking changes or to reference issues/tickets.
```
1. fix: a commit of the type fix patches a bug in your codebase (this correlates with PATCH in Semantic Versioning).
2. feat: a commit of the type feat introduces a new feature to the codebase (this correlates with MINOR in Semantic Versioning).
3. **BREAKING CHANGE**: a commit that has a footer BREAKING CHANGE:, or appends a ! after the type/scope, introduces a breaking API change (correlating with MAJOR in Semantic Versioning). A BREAKING CHANGE can be part of commits of any type.
4. types other than fix: and feat: are allowed, for example @commitlint/config-conventional (based on the Angular convention) recommends build:, chore:, ci:, docs:, style:, refactor:, perf:, test:, and others.
5. footers other than BREAKING CHANGE: <description> may be provided and follow a convention similar to git trailer format.
Additional types are not mandated by the Conventional Commits specification, and have no implicit effect in Semantic Versioning (unless they include a BREAKING CHANGE). A scope may be provided to a commit’s type, to provide additional contextual information and is contained within parenthesis, e.g., feat(parser): add ability to parse arrays.

Example commit:
```
feat(api): add support for multiple data formats

added JSON and XML data format handling
refactored data processing functions
BREAKING CHANGE: old data format handling is deprecated
```

## Alternatives
- **Freeform Commit Messages**: No structure required, giving developers flexibility. However, this can lead to inconsistent messages and a lack of clarity.
- **Custom Commit Message Guidelines**: We could define our own format, but this requires additional maintenance and lacks the established tooling support provided by Conventional Commits.

## Comparison Table
| Feature/Criteria            | Conventional Commits     | Freeform Commit Messages | Custom Commit Guidelines |
|-----------------------------|--------------------------|--------------------------|--------------------------|
| **Clarity and Consistency** | High                     | Low                      | Medium                   |
| **Tooling Support**         | Strong (e.g., auto-changelog generation) | None     | Limited                  |
| **Learning Curve**          | Low                      | None                     | Medium                   |
| **Automation Integration**  | Strong                   | None                     | Medium                   |

## Consequences

- **Positive**:
  - Consistent commit messages across the project will enhance collaboration and make it easier to understand the history of changes.
  - Better integration with automated tools (like changelog generators and semantic versioning) will streamline releases.
- **Negative**:
  - Developers must adhere to a specific commit format, which may require some initial adjustment.

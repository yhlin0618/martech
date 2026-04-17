# Slash Command Naming Convention

## Overview

This document outlines the naming convention for custom slash commands in Claude Code settings files (`.claude/settings.local.json`).

## Command Naming Format

### Basic Structure

```
"/COMMAND [arguments]": {
  "description": "Command description",
  "prompt": "User input prompt (optional)",
  "command": "bash command to execute",
  "timeout": timeout_in_milliseconds
}
```

### Argument Notation Standards

Follow Linux/Unix manual page conventions:

- **Required arguments**: `<argument>`
- **Optional arguments**: `[argument]`
- **Multiple choices**: `option1|option2|option3`
- **Combined**: `[auto|manual|interactive]`

### Examples

#### Simple Command (No Arguments)
```json
"/CHECK": {
  "description": "推送前安全檢查",
  "command": "cd $(git rev-parse --show-toplevel) && ./bash/check_before_push.sh"
}
```

#### Command with Optional Arguments
```json
"/SYNC [auto|manual|interactive]": {
  "description": "智能同步 Git 倉庫",
  "prompt": "請輸入同步模式 (auto/manual/interactive，預設 auto)",
  "command": "cd $(git rev-parse --show-toplevel) && ./bash/subrepo_sync.sh \"${input:-auto}\"",
  "timeout": 3600000
}
```

#### Command with Required Arguments
```json
"/DEPLOY <target>": {
  "description": "部署到指定目標",
  "prompt": "請輸入部署目標",
  "command": "cd $(git rev-parse --show-toplevel) && ./bash/deploy.sh \"${input}\""
}
```

#### Command with Multiple Argument Types
```json
"/RUN <app> [mode]": {
  "description": "執行指定應用",
  "prompt": "請輸入應用名稱和運行模式 (格式: app_name [dev|prod])",
  "command": "cd $(git rev-parse --show-toplevel) && ./bash/run_app.sh ${input}"
}
```

## Naming Principles

### 1. Verb-Object Pattern (動詞開頭理論)
- Use imperative verbs followed by objects
- Structure: `/VERB OBJECT [arguments]`
- Examples:
  - `/RUN APP [mode]`
  - `/CHECK STATUS`
  - `/OPEN PRINCIPLES`
  - `/SYNC [mode]`

### 2. Clear Argument Documentation
- Include argument specifications in the command name
- Use standard Unix conventions for clarity
- Make it immediately obvious what inputs are expected

### 3. Consistent Formatting
- Use ALL CAPS for command names
- Separate words with spaces (not hyphens or underscores)
- Use brackets and pipes for argument options

## Implementation Details

### Prompt vs Direct Arguments

For commands with optional arguments, use the `prompt` approach:

```json
{
  "prompt": "請輸入參數 (選項1|選項2|選項3，預設 選項1)",
  "command": "script.sh \"${input:-default_value}\""
}
```

### Default Values

Use bash parameter expansion for defaults:
- `${input:-default}` - Use default if input is empty
- `${input}` - Require input (will fail if empty)

### Timeout Settings

Set appropriate timeouts for long-running commands:
- Quick operations: Default (no timeout specified)
- Sync operations: `3600000` (1 hour)
- Deployment: `1800000` (30 minutes)
- Tests: `600000` (10 minutes)

## Command Categories

### Development Operations
- `/RUN APP [mode]` - Execute applications
- `/TEST [suite]` - Run test suites
- `/BUILD [target]` - Build operations

### Git Operations
- `/SYNC [mode]` - Repository synchronization
- `/CHECK [what]` - Status checks
- `/COMMIT` - Quick commits

### Navigation
- `/GO <location>` - Directory navigation
- `/OPEN <resource>` - Open files/directories

### Language-Specific
- `/PARSE NSQL` - NSQL parsing
- `/TRANSLATE NSQL` - NSQL translation
- `/EXECUTE NSQL` - NSQL execution

## Best Practices

1. **Consistency**: Follow the same pattern across all commands
2. **Clarity**: Make command purpose obvious from the name
3. **Documentation**: Include helpful descriptions and prompts
4. **Error Handling**: Use appropriate bash error handling in commands
5. **Path Safety**: Always use `$(git rev-parse --show-toplevel)` for project root
6. **Argument Validation**: Provide clear prompts with valid options listed

## Migration from Complex Logic

When migrating from complex conditional logic to the prompt approach:

**Before (Complex):**
```json
"/SYNC": {
  "command": "if [ -n \"$1\" ]; then script.sh \"$1\"; else read -p \"prompt\" var; script.sh \"${var:-auto}\"; fi"
}
```

**After (Clean):**
```json
"/SYNC [auto|manual|interactive]": {
  "description": "智能同步 Git 倉庫",
  "prompt": "請輸入同步模式 (auto/manual/interactive，預設 auto)",
  "command": "cd $(git rev-parse --show-toplevel) && ./bash/subrepo_sync.sh \"${input:-auto}\""
}
```

## Validation

Commands should follow these validation rules:

1. **Name Format**: `/VERB [OBJECT] [arguments]`
2. **Argument Format**: Linux man page style
3. **Description**: Clear, concise functionality description
4. **Command Safety**: Use project root, proper quoting, error handling
5. **Timeout**: Appropriate for operation duration

This convention ensures consistent, maintainable, and user-friendly slash commands that integrate seamlessly with Claude Code's workflow.
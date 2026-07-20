# quantumc.nvim

A lightweight, high-performance syntax highlighting and diagnostics extension for the QuantumC (`qc`) language in Neovim. 

Instead of relying on heavy Tree-sitter configurations or complex LSP setups, this plugin hooks directly into your native compiled C++ `qc` compiler binary to paint editor colors and generate error diagnostics instantly as you type.

## Note:
Requires QC Version `x0.20.1`+

## How It Works

1. Whenever you open or type in a QuantumC file, the plugin creates a temporary snapshot file of your buffer in RAM.
2. It executes your local `qc` binary with the `-dump-tokens` flag against that file.
3. It parses the line, column, and token type strings, applying native Neovim color mappings (`Keyword`, `Type`, `Operator`, `Delimiter`, etc.).
4. If an error string (like `QC-IC03`) is returned, it instantly routes it to Neovim's diagnostic subsystem to display error hovers.

## Prerequisites

`qc` must be in your`PATH`

To test if it is ready, make sure running this command works from any directory:
```bash
qc -dump-tokens <filename>
```
> Note, qc must be in your path for the highlighter to work

## Installation

### Using `packer.nvim`

Add the repository block to your Neovim plugins file:

```lua
use {
  'Youg-Otricked/quantumc.nvim',
  ft = { 'quantumc' },
}
```
Then:
```vim
:PackerInstall
:PackerCompile
```

### Using `lazy.nvim`

```lua
return {
  {
    "Youg-Otricked/quantumc.nvim",
    ft = { "quantumc" },
  }
}
```

## Performance

The plugin only invokes the compiler when necessary and performs no syntax parsing inside Lua.
All lexical analysis is delegated to the native `qc` compiler, allowing highlighting and diagnostics to remain fast even for large source files.
If syntax highlighting doesn't update immediately after you type, that's expected. The plugin uses a short debounce interval before invoking the compiler to reduce unnecessary CPU usage during rapid editing.

## Customization

The plugin binds your compiler tokens directly to Neovim's standard token groups, meaning it automatically updates its palette to match your active editor theme (e.g., Catppuccin, Gruvbox, NordFox).

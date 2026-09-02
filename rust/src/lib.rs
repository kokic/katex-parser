//! A Rust port of the KaTeX parser: lexes and parses LaTeX math expressions
//! with macro expansion into a typed [`ParseNode`] AST, and renders that AST
//! to Unicode text.
//!
//! The parser mirrors the MoonBit `katex-parser` package (itself a port of
//! [KaTeX](https://katex.org)). Entry points:
//!
//! - [`parse`] / [`parse_with_specs`] — parse LaTeX into a `ParseNode` list.
//! - [`render`] — render a parsed node list as Unicode text.
//! - [`Settings`] — parser configuration (display mode, macros, strictness,
//!   trust policy, and a persistent macro store).

mod ast;
mod anvil;
mod builtin_macros;
mod builtin_macros_commands;
mod builtin_macros_control;
mod builtin_macros_dots;
mod builtin_macros_special;
mod builtin_macros_static;
mod environments;
mod error;
mod function_registry;
mod functions;
mod lexer;
mod macro_definition;
mod macro_expander;
mod namespace;
mod parser;
mod settings;
mod source_location;
mod symbol_registry;
mod text_ligature;
mod token;
mod unicode;
mod unicode_font;
mod unicode_scripts;
mod unicode_symbols;

pub use anvil::{atom_family_name, cancel_bin_atoms, command_name, em_value, is_null_delimiter,
    join_with_spacing, katex_size_multiplier, math_choice_variant, math_spacing, resolve_symbol,
    SpacableItem, SpacingSpec};
pub use ast::{
    ArrayColumn, AtomFamily, ColumnSeparationType, LapAlignment, Measurement, Mode,
    OperatorContent, ParseNode, StyleLevel,
};
pub use environments::{
    build_environment_registry, EnvironmentContext, EnvironmentHandler, EnvironmentParser,
    EnvironmentRegistry, EnvironmentSpec, ArrayEnvironmentOptions,
};
pub use error::{Diagnostic, ParseError};
pub use function_registry::{
    build_function_registry, ArgType, FunctionContext, FunctionHandler, FunctionParser,
    FunctionRegistry, FunctionSpec,
};
pub use macro_definition::{MacroDefinition, MacroExpansion};
pub use parser::{parse, parse_with_specs};
pub use settings::{Macros, Settings, StrictHandler, StrictResponse, Strictness,
    StrictWarningHandler, TrustContext, TrustHandler, TrustPolicy};
pub use source_location::SourceLocation;
pub use symbol_registry::unicode_symbol;
pub use token::{token_location, Token};
pub use unicode::{line_style_frac_bar, render, unicode_text_spacing, Block, LineStyle, RenderConfig};
pub use unicode_font::unicode_font_character;
pub use unicode_scripts::{supported_codepoint, unicode_script_character, UnicodeScriptKind};

#[cfg(test)]
mod tests;

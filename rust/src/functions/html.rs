use std::collections::HashMap;

use crate::ast::ParseNode;
use crate::error::ParseError;
use crate::function_registry::{ArgType, FunctionContext, FunctionParser, FunctionSpec};
use crate::settings::TrustContext;

use super::{ord_argument, require_function_arg};

pub(crate) fn trim_ascii_spaces(text: &str) -> &str {
    let start = text
        .char_indices()
        .find(|(_, c)| !matches!(c, ' ' | '\t' | '\n' | '\r'))
        .map(|(i, _)| i)
        .unwrap_or(text.len());
    let end = text
        .char_indices()
        .rev()
        .find(|(_, c)| !matches!(c, ' ' | '\t' | '\n' | '\r'))
        .map(|(i, c)| i + c.len_utf8())
        .unwrap_or(start);
    &text[start..end]
}

fn html_data_attributes(value: &str) -> Result<HashMap<String, String>, ParseError> {
    let mut attributes: HashMap<String, String> = HashMap::new();
    for item in value.split(',') {
        let Some(equals) = item.find('=') else {
            return Err(ParseError::InvalidArgument {
                message: format!("\\htmlData key/value '{item}' missing equals sign"),
                loc: None,
            });
        };
        let key = trim_ascii_spaces(&item[..equals]).to_string();
        let data_value = item[equals + 1..].to_string();
        attributes.insert(format!("data-{key}"), data_value);
    }
    Ok(attributes)
}

pub(crate) fn html_spec() -> FunctionSpec {
    FunctionSpec {
        names: vec![
            "\\htmlClass".to_string(),
            "\\htmlId".to_string(),
            "\\htmlStyle".to_string(),
            "\\htmlData".to_string(),
        ],
        num_args: 2,
        arg_types: vec![ArgType::RawArg, ArgType::OriginalArg],
        allowed_in_text: true,
        handler: Some(html_handler),
        ..Default::default()
    }
}

fn html_handler(
    parser: &mut dyn FunctionParser,
    context: &FunctionContext,
    args: &[ParseNode],
    _opt_args: &[Option<ParseNode>],
) -> Result<ParseNode, ParseError> {
    let value = match require_function_arg(args, 0, &context.func_name)? {
        ParseNode::Raw { string, .. } => string,
        _ => {
            return Err(ParseError::InternalInvariant {
                message: format!("Expected raw argument for {}", context.func_name),
            });
        }
    };
    parser.report_nonstrict(
        "htmlExtension",
        "HTML extension is disabled on strict mode",
        context.token.as_ref(),
    )?;
    let mut attributes: HashMap<String, String> = HashMap::new();
    let trust_context = match context.func_name.as_str() {
        "\\htmlClass" => {
            attributes.insert("class".to_string(), value.clone());
            TrustContext::HtmlClass { class: value }
        }
        "\\htmlId" => {
            attributes.insert("id".to_string(), value.clone());
            TrustContext::HtmlId { id: value }
        }
        "\\htmlStyle" => {
            attributes.insert("style".to_string(), value.clone());
            TrustContext::HtmlStyle { style: value }
        }
        "\\htmlData" => {
            let parsed = html_data_attributes(&value)?;
            for (key, item) in parsed {
                attributes.insert(key, item);
            }
            TrustContext::HtmlData {
                attributes: attributes.clone(),
            }
        }
        _ => {
            return Err(ParseError::InternalInvariant {
                message: "Unrecognized html command".to_string(),
            });
        }
    };
    let body = ord_argument(require_function_arg(args, 1, &context.func_name)?);
    if parser.is_trusted(trust_context) {
        Ok(ParseNode::Html {
            mode: context.mode,
            attributes,
            body,
        })
    } else {
        Ok(ParseNode::OrdGroup {
            mode: context.mode,
            loc: None,
            body,
            semisimple: false,
        })
    }
}

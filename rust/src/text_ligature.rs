use crate::ast::{Mode, ParseNode};
use crate::source_location::SourceLocation;

fn merged_text_location(first: &ParseNode, last: &ParseNode) -> Option<SourceLocation> {
    if let (ParseNode::TextOrd { loc: Some(start), .. }, ParseNode::TextOrd { loc: Some(end), .. }) =
        (first, last)
        && start.input == end.input {
            return Some(SourceLocation::range(start, end));
        }
    None
}

fn merged_text_ord(first: &ParseNode, last: &ParseNode, text: String) -> ParseNode {
    ParseNode::TextOrd {
        mode: Mode::Text,
        loc: merged_text_location(first, last),
        text,
    }
}

pub(crate) fn form_text_ligatures(body: Vec<ParseNode>) -> Vec<ParseNode> {
    let mut output: Vec<ParseNode> = Vec::new();
    let mut index = 0;
    while index < body.len() {
        let current = &body[index];
        if let ParseNode::TextOrd { text, .. } = current {
            if text == "-"
                && let Some(next) = body.get(index + 1)
                    && let ParseNode::TextOrd { text: next_text, .. } = next
                        && next_text == "-" {
                            if let Some(last) = body.get(index + 2)
                                && let ParseNode::TextOrd {
                                    text: last_text, ..
                                } = last
                                    && last_text == "-" {
                                        output.push(merged_text_ord(
                                            current,
                                            last,
                                            "---".to_string(),
                                        ));
                                        index += 3;
                                        continue;
                                    }
                            output.push(merged_text_ord(current, next, "--".to_string()));
                            index += 2;
                            continue;
                        }
            if (text == "'" || text == "`")
                && let Some(next) = body.get(index + 1)
                    && let ParseNode::TextOrd {
                        text: next_text, ..
                    } = next
                        && next_text == text {
                            output.push(merged_text_ord(
                                current,
                                next,
                                format!("{}{}", text, text),
                            ));
                            index += 2;
                            continue;
                        }
        }
        output.push(current.clone());
        index += 1;
    }
    output
}

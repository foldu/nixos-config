export def main [] { return {
    separator: "#C8C093"
    leading_trailing_space_bg: { attr: "n" }
    header: { fg: "#76946A" attr: "b" }
    empty: "#7E9CD8"
    bool: {|| if $in { "#7AA89F" } else { "light_gray" } }
    int: "#C8C093"
    filesize: {|e|
        if $e == 0b {
            "#C8C093"
        } else if $e < 1mb {
            "#6A9589"
        } else {{ fg: "#7E9CD8" }}
    }
    duration: "#C8C093"
    date: {|| (date now) - $in |
        if $in < 1hr {
            { fg: "#C34043" attr: "b" }
        } else if $in < 6hr {
            "#C34043"
        } else if $in < 1day {
            "#C0A36E"
        } else if $in < 3day {
            "#76946A"
        } else if $in < 1wk {
            { fg: "#76946A" attr: "b" }
        } else if $in < 6wk {
            "#6A9589"
        } else if $in < 52wk {
            "#7E9CD8"
        } else { "dark_gray" }
    }
    range: "#C8C093"
    float: "#C8C093"
    string: "#C8C093"
    nothing: "#C8C093"
    binary: "#C8C093"
    cellpath: "#C8C093"
    row_index: { fg: "#76946A" attr: "b" }
    record: "#C8C093"
    list: "#C8C093"
    block: "#C8C093"
    hints: "dark_gray"
    search_result: { fg: "#C34043" bg: "#C8C093" }

    shape_and: { fg: "#957FB8" attr: "b" }
    shape_binary: { fg: "#957FB8" attr: "b" }
    shape_block: { fg: "#7E9CD8" attr: "b" }
    shape_bool: "#7AA89F"
    shape_custom: "#76946A"
    shape_datetime: { fg: "#6A9589" attr: "b" }
    shape_directory: "#6A9589"
    shape_external: "#6A9589"
    shape_externalarg: { fg: "#76946A" attr: "b" }
    shape_filepath: "#6A9589"
    shape_flag: { fg: "#7E9CD8" attr: "b" }
    shape_float: { fg: "#957FB8" attr: "b" }
    shape_garbage: { fg: "#FFFFFF" bg: "#FF0000" attr: "b" }
    shape_globpattern: { fg: "#6A9589" attr: "b" }
    shape_int: { fg: "#957FB8" attr: "b" }
    shape_internalcall: { fg: "#6A9589" attr: "b" }
    shape_list: { fg: "#6A9589" attr: "b" }
    shape_literal: "#7E9CD8"
    shape_match_pattern: "#76946A"
    shape_matching_brackets: { attr: "u" }
    shape_nothing: "#7AA89F"
    shape_operator: "#C0A36E"
    shape_or: { fg: "#957FB8" attr: "b" }
    shape_pipe: { fg: "#957FB8" attr: "b" }
    shape_range: { fg: "#C0A36E" attr: "b" }
    shape_record: { fg: "#6A9589" attr: "b" }
    shape_redirection: { fg: "#957FB8" attr: "b" }
    shape_signature: { fg: "#76946A" attr: "b" }
    shape_string: "#76946A"
    shape_string_interpolation: { fg: "#6A9589" attr: "b" }
    shape_table: { fg: "#7E9CD8" attr: "b" }
    shape_variable: "#957FB8"

    background: "#1F1F28"
    foreground: "#DCD7BA"
    cursor: "#C8C093"
}}
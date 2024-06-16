extends CodeEdit
class_name LuauEdit


const lua_keywords := [
	"local",
	
	"do", "end",
	
	"if", "then", "else", "elseif",
	
	"for", "in", "while", "repeat", "until",
	"break", "continue",
	
	"or", "and", "not",
	
	"function", "return",
]

const lua_keywords_funny := [ "nil", "true", "false", "self" ]


func _ready():
	add_comment_delimiter("--", "", true)
	add_comment_delimiter("--[[", "]]")
	add_string_delimiter("[[", "]]")
	
	#add_string_delimiter("\"", "\"", true)
	#add_string_delimiter("\'", "\'", true)
	
	
	var orange := Color("#ce9178")
	var green := Color("#44ac44")
	var pink := Color("#ce91c4")
	var dark_blue := Color("#569cd6")
	
	syntax_highlighter.add_color_region("\"", "\"", orange)
	syntax_highlighter.add_color_region("'", "'", orange)
	syntax_highlighter.add_color_region("[[", "]]", orange)
	
	syntax_highlighter.add_color_region("--[[", "]]", green)
	syntax_highlighter.add_color_region("--", "", green)
	
	for keyword in lua_keywords:
		syntax_highlighter.add_keyword_color(keyword, pink)
	for keyword in lua_keywords_funny:
		syntax_highlighter.add_keyword_color(keyword, dark_blue)

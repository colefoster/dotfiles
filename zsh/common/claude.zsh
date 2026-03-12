ch() {
	claude -p "Answer the following question - it may or may not be related to the currently open project & files. Answer very briefly, limiting your response to 1 or 2 lines. Don't add any code to the project. The question is: How do I $*"
}

alias claude="claude --dangerously-skip-permissions"

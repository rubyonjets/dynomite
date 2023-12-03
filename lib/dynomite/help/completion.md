## Examples

    dynomite completion

Prints words for TAB auto-completion.

    dynomite completion
    dynomite completion hello
    dynomite completion hello name

To enable, TAB auto-completion add the following to your profile:

    eval $(dynomite completion_script)

Auto-completion example usage:

    dynomite [TAB]
    dynomite hello [TAB]
    dynomite hello name [TAB]
    dynomite hello name --[TAB]

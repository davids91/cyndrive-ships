# Dialogue structure
A dialog consists of multiple lines.
One line contains text together with special text tokens.

## Special text tokens
A special text token is a string of characters enclosed in double hashtags and square brackets.
The first character of the token decides the functionality.
The other characters enclosed by the token must always be numbers

### Special text token functionality
- change dialog image: `#[c0]`
	- Changes the images displayed next to the text
	- Image change is can only be made once per line, at the beginning of the line 
- change dialog tempo: `#[t50]`
	- Changes the speed with which the letters appear after its position
	- Speed is taken as milliseconds per letter
	- Speed is optional, if nothing is given, dialog reverts back to normal speed
- pause dialog: `#[p250]`
	- Pauses the dialog at its position for the given number of milliseconds
- emit signal: `#[s1]`
	- Emits the signal with the given index
	- There are a maximum of 4 signals, functionality always depend on dialog and may differ!

# Example
#[c1] This is text the inventor will say! #[p500]Dialogue will pause for 500 msec before moving on to this section!
The following text will appear #[t100] V E R Y S L O W L Y , #[t25] but this text will be displayed slightly faster.
In this line, no special tokens are provided so the tempo and the dialogue image will remain unchanged
#[c0] The Leader will be displayed next to this line. #[p500]#[t25] And after a brief pause, the text will be displayed slightly faster.

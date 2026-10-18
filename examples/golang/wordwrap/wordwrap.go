// Package wordwrap wraps text to a maximum line width.
package wordwrap

import (
	"errors"
	"strings"
)

// ErrWidth is returned when the width is less than 1.
var ErrWidth = errors.New("wordwrap: width must be at least 1")

// Wrap splits text on whitespace and joins words into lines no longer than
// width. A word longer than width is placed on its own line.
func Wrap(text string, width int) ([]string, error) {
	if width < 1 {
		return nil, ErrWidth
	}
	var lines []string
	var line strings.Builder
	for _, word := range strings.Fields(text) {
		if line.Len() > 0 && line.Len()+1+len(word) > width {
			lines = append(lines, line.String())
			line.Reset()
		}
		if line.Len() > 0 {
			line.WriteByte(' ')
		}
		line.WriteString(word)
	}
	if line.Len() > 0 {
		lines = append(lines, line.String())
	}
	return lines, nil
}

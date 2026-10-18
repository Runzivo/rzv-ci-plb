package wordwrap

import (
	"errors"
	"reflect"
	"testing"
)

func TestWrap(t *testing.T) {
	tests := []struct {
		name  string
		text  string
		width int
		want  []string
	}{
		{"fits on one line", "a b c", 10, []string{"a b c"}},
		{"breaks between words", "one two three", 7, []string{"one two", "three"}},
		{"long word on its own line", "a abcdefgh b", 4, []string{"a", "abcdefgh", "b"}},
		{"empty text", "   ", 5, nil},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := Wrap(tt.text, tt.width)
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("Wrap(%q, %d) = %q, want %q", tt.text, tt.width, got, tt.want)
			}
		})
	}
}

func TestWrapRejectsBadWidth(t *testing.T) {
	if _, err := Wrap("a", 0); !errors.Is(err, ErrWidth) {
		t.Fatalf("want ErrWidth, got %v", err)
	}
}

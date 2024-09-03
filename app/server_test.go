package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestServerUp(t *testing.T) {
	t.Run("returns up server status", func(t *testing.T) {
		request, _ := http.NewRequest(http.MethodGet, "/up", nil)
		response := httptest.NewRecorder()

		UpChecker(response, request)
		got := response.Body.String()
		want := "Server is up and running"

		if got != want {
			t.Errorf("got %q, want %q", got, want)
		}
	})
}

func TestServerIndex(t *testing.T) {
	t.Run("returns index.html", func(t *testing.T) {
		request, _ := http.NewRequest(http.MethodGet, "/", nil)
		response := httptest.NewRecorder()

		IndexFile(response, request)
		got := response.Body.String()
		want := "<!DOCTYPE html>"

		if !strings.HasPrefix(got, want) {
			t.Errorf("got %q, want %q", got, want)
		}
	})
}

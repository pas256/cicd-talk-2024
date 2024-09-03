/**
 * This is a basic web server that serves one static HTML file and also has
 * a /up endpoint that returns an alive message
 */
package main

import (
	"fmt"
	"log"
	"net/http"
)

func UpChecker(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Server is up and running")
}

func IndexFile(w http.ResponseWriter, r *http.Request) {
	log.Println("/" + r.URL.Path[1:])
	http.ServeFile(w, r, "static/index.html")
}

func main() {
	http.HandleFunc("/up", UpChecker)
	http.HandleFunc("/", IndexFile)

	fmt.Println("Server listening on port 8081")
	log.Fatal(http.ListenAndServe(":8081", nil))
}

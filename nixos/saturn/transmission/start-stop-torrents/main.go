package main

import (
	"context"
	"log"
	"net/url"
	"os"

	"github.com/hekmon/transmissionrpc/v3"
)

func main() {
	uri := expectEnv("TRANSMISSION_URL")
	action := expectEnv("ACTION")
	user := expectEnv("USER")
	pass := expectEnv("PASS")

	endpoint, err := url.Parse(uri)
	if err != nil {
		log.Fatalf("Invalid url %v: %v", uri, err)
	}

	endpoint.User = url.UserPassword(user, pass)
	client, err := transmissionrpc.New(endpoint, nil)
	if err != nil {
		log.Fatalf("Failed connecting to %v: %v", endpoint, err)
	}

	ctx := context.TODO()
	torrents, err := client.TorrentGetAll(ctx)
	if err != nil {
		log.Fatalf("Failed fetching torrents: %v", err)
	}

	var torrentIds []int64
	for _, torrent := range torrents {
		torrentIds = append(torrentIds, *torrent.ID)
	}

	switch action {
	case "start-all":
		client.TorrentStartIDs(ctx, torrentIds)
	case "stop-all":
		client.TorrentStopIDs(ctx, torrentIds)
	default:
		log.Fatalf("Unknown action %v", action)
	}
}

func expectEnv(key string) string {
	val, ok := os.LookupEnv(key)
	if !ok {
		log.Fatalf("Missing required environment variable %v", key)
	}

	return val
}

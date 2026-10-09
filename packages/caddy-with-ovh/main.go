// Copyright 2015 Matthew Holt and The Caddy Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// This is caddy's own cmd/caddy/main.go, with the module imports below
// extended. Building it here rather than through pkgs.caddy.withPlugins is
// deliberate: withPlugins shells out to xcaddy without a go.sum, so its
// fixed-output hash is a snapshot of whatever module versions the proxy
// happened to serve at build time and goes stale on its own. Here go.mod and
// go.sum pin the graph, so vendorHash only moves when caddy or a plugin is
// bumped on purpose.
package main

import (
	_ "time/tzdata"

	caddycmd "github.com/caddyserver/caddy/v2/cmd"

	// plug in Caddy modules here
	_ "github.com/caddyserver/caddy/v2/modules/standard"

	// DNS-01 solver used by the `acme_dns ovh` global option
	_ "github.com/caddy-dns/ovh"
)

func main() {
	caddycmd.Main()
}

# nircd

nircd is a new, open IRCd based on a modified fork of
perl's POE::Component::Server::IRC. It is designed to allow
any user to link a server making IRC more decentralized.

## Setup

nircd is simple to setup.

1. Run the `./configure` script. For options, see
`./configure -h`.

2. If `./configure` encounters any errors, see the FAQ

3. Copy sample.conf to ircd.conf and modify it. Make sure to change
   the name of the MOTD file to "ircd.motd"!

4. Run the ircd as `./ircd ircd.conf`. It does not fork() and daemonize
   so you'll need to run it in something like `tmux` or `screen`

## Features

* Anybody can link a server (unless you specifically ban them), this
  makes IRC more decentralized.

* TS5-based linking protocol allows you to run services and link
  ircd-hybrid-7.0 servers

* Runs on any platform that perl runs on

* Easy to modify if you want to


## FAQ

### Why the name nircd?

The name means nothing -- it was random.

### How do I contribute?

Submit a pull request with enhancements or bug fixes or start an issue
for any problem you have.

### Can I set this up without OpenSSL

OpenSSL is critical to providing SSL listening capability in the IRCd.
For a more secure future, there is no way to disable SSL support and
requirements (short of modifying the software).

## License

Mozilla Public License, 2.0

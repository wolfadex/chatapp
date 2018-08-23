# Chattapp

A very simple Slack clone. Just for playing around with [socket.io](https://socket.io/) and [elm](http://elm-lang.org/).


Features:
- [x] Create a user (just a name right now)
- [x] Create or Join an organization
- [ ] Create or join a channel within an org (**next**)
- [ ] Create or join a group/DM chat
- [x] Send and receive messages (currently between everyone, refactoring to be per org/channel/group)
- [ ] Online status
- [ ] Display Status (away, busy, etc)

### To Develop
- [Install elm 0.19](http://elm-lang.org/) (temporary until the 0.19 npm package is published)
- [Install yarn](https://yarnpkg.com/en/)
- Run `yarn`
- Open 3 terminals
- Run `yarn dev:elm` (compiles elm)
- Run `yarn dev:bundle` (compiles client js)
- Run `yarn dev:server` (compiles server js, starts server)
- Open browser window to `localhost:3000`

### To Run
- [Install elm 0.19](http://elm-lang.org/) (temporary until the 0.19 npm package is published)
- [Install yarn](https://yarnpkg.com/en/)
- Run `yarn`
- Run `yarn dev:build`
- Open browser window to `localhost:3000`

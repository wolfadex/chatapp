const path = require('path');
const app = require('express')();
const http = require('http').Server(app);
const io = require('socket.io')(http, {
  serveClient: false,
});

const s4 = () =>
  Math.floor((1 + Math.random()) * 0x10000)
    .toString(16)
    .substring(1);
const guid = () => `${s4()}${s4()}-${s4()}-${s4()}-${s4()}-${s4()}${s4()}${s4()}`;

const port = process.env.PORT || 3000;
const fakeDB = {
  users: {},
  organizations: {},
  rooms: {},
  messages: {},
};

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public/index.html'));
});

app.get('/assets/:filePath', (req, res) => {
  const { filePath } = req.params;
  res.sendFile(__dirname + `/public/${filePath}`);
});

io.on('connection', (socket) => {
  fakeDB.users[socket.id] = {
    connected: true,
    loggedIn: false,
  };

  socket.on('login', ({ username }) => {
    if (!fakeDB.users[socket.id].loggedIn) {
      fakeDB.users[socket.id] = {
        ...fakeDB.users[socket.id],
        loggedIn: true,
        username,
      };
      socket.emit('logged-in', socket.id);
    }
  });

  socket.on('new-org', (newName) => {
    if (fakeDB.users[socket.id].loggedIn) {
      const orgExists = Object.values(fakeDB.organizations).some(({ name }) => name === newName);

      if (orgExists) {
        socket.emit('org-found', { userId: socket.id, org: orgExists });
      } else {
        const orgId = guid();

        fakeDB.organizations[orgId] = {
          id: orgId,
          name: newName,
          namespace: '',
          rooms: new Set(),
        };
        socket.emit('org-found', { userId: socket.id, org: fakeDB.organizations[orgId] });
      }
    }
  });






  io.emit('login-message', 'user joined');
  socket.on('disconnect', () => {
    io.emit('disconnect-message', 'user left');
  });
  socket.on('new-message', (msg) => {
    io.emit('broadcast-message', msg);
  });
});

http.listen(port, () => {
  console.log(`Listening on port: ${port}`);
});

/*
NOTES:

socket.io namespace === slack org
scoket.io room === slack channel/DM/group

*/

import io from 'socket.io-client';

const socket = io();
const app = Elm.Main.init();

// OUTGOING

app.ports.newMessage.subscribe((msg) => {
  socket.emit('new-message', msg);
});

app.ports.login.subscribe((username) => {
  socket.emit('login', {
    username,
  });
});

app.ports.createOrganization.subscribe((name) => {
  socket.emit('new-org', name);
});

// INCOMING

socket.on('broadcast-message', (msg) => {
  app.ports.receiveMessage.send({ content: msg });
});

socket.on('login-message', (msg) => {
  // app.ports.loginMessage.send({ content: msg });
});

socket.on('disconnect-message', (msg) => {
  // app.ports.disconnectMessage.send({ content: msg });
});

socket.on('logged-in', (userId) => {
  if (userId === socket.id) {
    app.ports.loggedIn.send('');
  }
});

socket.on('org-found', ({ userId, org }) => {
  console.log(userId, org);
  if (userId === socket.id) {
    app.ports.foundOrganization.send(org);
  }
});

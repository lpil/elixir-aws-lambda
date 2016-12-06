const child = require('child_process');
const net = require('net');

const socketPath = '/tmp/elixir-aws-socket';

let queuedContext;
let queuedPayload;
let sendToProc;


// Child Elixir process.

const proc = child.spawn('./main');

proc.on('error', (err) => {
  console.error('Worker proc error: %s', err);
  process.exit(1);
});

proc.on('exit', (code) => {
  console.error('Worker proc exit: %s', code);
  process.exit(1);
});


// TCP communication with proc

const server = net.createServer((c) => {
  console.log('Worker proc connected');

  sendToProc = () => {
    const payload = queuedPayload;
    queuedPayload = null;
    c.write(payload);
    console.log('Sent payload to worker proc');
  }
  if (queuedPayload) { sendToProc(); }

  c.on('end', () => {
    console.error('Worker proc disconnected');
    process.exit(1);
  });

  c.on('data', data => {
    console.log('Response recieved from worker proc');
    const resp = JSON.parse(data.toString('utf8'));
    queuedContext.done(resp.error, resp.value)
  });
});

server.on('error', (err) => {
  throw err;
});

server.listen(socketPath, () => {
  console.log(`Shim TCP server listening at ${socketPath}`);
});


// Handle lambda, calling proc if ready.

exports.handle = function handle(event, context) {
  queuedContext = context;
  queuedPayload = JSON.stringify({ event, context });

  if (sendToProc) { sendToProc(); }
}

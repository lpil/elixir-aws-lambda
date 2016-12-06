const child = require('child_process');
const net = require('net');

const socket_path = '/tmp/elixir-aws-socket';

let queued_context;
let queued_payload;
let send_to_proc;


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

  send_to_proc = () => {
    console.log('Sending payload to worker proc');
    c.write(queued_payload);
  }
  send_to_proc();

  c.on('end', () => {
    console.error('Worker proc disconnected');
    process.exit(1);
  });

  c.on('data', data => {
    console.log('Response recieved from worker proc');
    const resp = JSON.parse(data.toString('utf8'));
    queued_context.done(resp.error, resp.value)
  });
});

server.on('error', (err) => {
  throw err;
});

server.listen(socket_path, () => {
  console.log(`Shim TCP server listening at ${socket_path}`);
});


// Handle lambda, calling proc if ready.

exports.handle = function handle(event, context) {
  queued_context = context;
  queued_payload = JSON.stringify({ event, context });

  if (send_to_proc) { send_to_proc(); }
}

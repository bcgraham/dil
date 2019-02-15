
def do_
  proxy_stdin, proxy_stdin_wr = IPC.create
  proxy_stdout_rd, proxy_stdout = IPC.create
  inout = InOut.new(
    real_stdin: STDIN,
    proxy_stdin_wr: proxy_stdin_wr,
    proxy_stdin: proxy_stdin,
    proxy_stdout: proxy_stdout,
    proxy_stdout_rd: proxy_stdout_rd,
    real_stdout: STDOUT,
  )
  case
  when fork
    inout.stdin!
  when fork
    inout.mario!
  else
    inout.stdout!
  end
  Process.wait
end

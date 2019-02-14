#!/usr/bin/env ruby

require 'tmpdir'
require 'tempfile'
def tmpname
  Dir::Tmpname.create('pry_out', '/tmp') { |name| name }
end

def create_pipe
  tmpname.tap { |name| File.mkfifo(name) }
end

def do_tmux
  pry_pipe_out = create_pipe
  pry_pipe_in = create_pipe
  tmux_temp = Tempfile.create(['fittings', '.rb'], '/tmp')
  at_exit { File.delete(pry_pipe_out, pry_pipe_in, tmux_temp) }
  tmux_temp.write <<~PREAMBLE.chomp
    PIPEIN = File.open('#{pry_pipe_in}', 'r')
    PIPEOUT = File.open('#{pry_pipe_out}', 'w')
  def each_line(&block)
    at_exit do
      IO.popen('-', 'r+') do |io|
        if io.nil?
          real_stdin = $stdin
          STDIN.each_line do |line|
            fake_stdin = StringIO.new
            fake_stdin.write line
            fake_stdin.rewind
            $stdin = fake_stdin
            block.call
          end
        else
          @writer = Thread.new do
            IO.copy_stream(PIPEIN, io)
            PIPEIN.close_read
            io.close_write
          end
          @reader = Thread.new do
            IO.copy_stream(io, PIPEOUT)
            PIPEOUT.close_write
            io.close_read
          end
          @reader.join
          @writer.join
        end
      end
    end
    exit
  end
  warn 'Linewise: call `each_line` with a block. Otherwise: read/write PIPEIN/PIPEOUT & exit.'
  PREAMBLE
  tmux_temp.close
  @write_to_pry = Thread.new do
    to_inner = File.open(pry_pipe_in, 'w')
    IO.copy_stream(STDIN, to_inner)
    to_inner.close_write
  end

  @read_from_pry = Thread.new do
    from_inner = File.open(pry_pipe_out, 'r')
    IO.copy_stream(from_inner, STDOUT)
    from_inner.close_read
  end

  cmd = <<~PRY.chomp
  pry -r '#{tmux_temp.path}'
  PRY

  cmd = <<-TMUX.chomp
    tmux splitw -l10 -c "#{Dir.pwd}" -F '\#{pane_tty}' "#{cmd}"
  TMUX
  Process.spawn(cmd)
  @write_to_pry.join
  @read_from_pry.join
end

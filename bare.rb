#!/usr/bin/env ruby
require 'pry'
def do_bare
  bare_temp = Tempfile.create(['fittings', '.rb'], '/tmp')
  bare_temp.write <<~PREAMBLE
  PIPEIN = IO.for_fd(3)
  PIPEOUT = IO.for_fd(4)
  PREAMBLE
  bare_temp.close
  at_exit { File.delete(bare_temp) }

  require 'io/console'
  from_outer_rd, to_inner_wr = IO.pipe
  from_inner_rd, to_outer_wr = IO.pipe
  if fork
    to_inner_wr.close
    from_inner_rd.close
    def each_line(&block)
      at_exit do
        IO.popen('-', 'r+') do |io|
          if io.nil?
            # real_stdin = $stdin
            STDIN.each_line do |line|
              fake_stdin = StringIO.new
              fake_stdin.write line
              fake_stdin.rewind
              $stdin = fake_stdin
              block.call
            end
          else
            @writer = Thread.new do
              IO.copy_stream(from_outer_rd, io)
              from_outer_rd.close_read
              io.close_write
            end
            @reader = Thread.new do
              IO.copy_stream(io, to_outer_wr)
              to_outer_wr.close_write
              io.close_read
            end
            @reader.join
            @writer.join
          end
        end
      end
      exit
    end
    c = IO.console
    $stdin.reopen(c, 'r')
    $stdout.reopen(c, 'w')
    # c.pry
    c.cooked do
      binding.pry
    end
  else
    from_outer_rd.close
    to_outer_wr.close
    @write_to_pry = Thread.new do
      # to_inner = File.open(pry_pipe_in, 'w')
      IO.copy_stream(STDIN, to_inner_wr)
      to_inner_wr.close
    end

    @read_from_pry = Thread.new do
      # from_inner = File.open(pry_pipe_out, 'r')
      IO.copy_stream(from_inner_rd, STDOUT)
      from_inner_rd.close
    end
    @write_to_pry.join
    @read_from_pry.join
    exit!
  end
  # @console.join
end

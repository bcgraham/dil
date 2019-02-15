# frozen_string_literal: true

class InOut
  def initialize(
    real_stdin:,
    proxy_stdin_wr:,
    proxy_stdin:,
    proxy_stdout:,
    proxy_stdout_rd:,
    real_stdout:,
  )
    @real_stdin = real_stdin
    @proxy_stdin_wr = proxy_stdin_wr
    @proxy_stdin = proxy_stdin
    @proxy_stdout = proxy_stdout
    @proxy_stdout_rd = proxy_stdout_rd
    @real_stdout = real_stdout
  end

  def join
    thread.join
  end

  def stdin!
    not_mario!
    not_stdout!
    passthrough(@real_stdin, @proxy_stdin_wr)
  end

  def mario!
    not_stdin!
    not_stdout!
  end

  def stdout!
    not_stdin!
    not_mario!
    passthrough(@proxy_stdout_rd, @real_stdout)
  end

  private

  def passthrough(rd, wr)
    thread = Thread.new do
      IO.copy_stream(rd, wr)
      wr.close_write
      rd.close_read
    end
  end

  def not_stdin!
    @real_stdin.close
    @proxy_stdin_wr.close
  end

  def not_stdout!
    @proxy_stdout_rd.close
    @real_stdout.close
  end

  def not_mario!
    @proxy_stin.close
    @proxy_stdout.close
  end
end

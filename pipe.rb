# frozen_string_literal: true

class IPC
  def self.create
    new
  end
end

class Pipe < IPC
  def initialize
    @rd, @wr = IO.pipe
  end
end

class Fifo < IPC
  def initialize
    @fifo = File.mkfifo(tmpname)
  end

  private

  def tmpname
    Dir::Tmpname.create('pry_out', '/tmp') { |name| name }
  end
end

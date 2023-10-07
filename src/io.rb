class IO
  class << self
    alias for_fd new

    def open(*args, **kwargs)
      obj = new(*args, **kwargs)
      return obj unless block_given?

      begin
        yield(obj)
      ensure
        begin
          obj.fsync unless obj.tty?
          obj.close
        rescue IOError => e
          raise unless e.message == 'closed stream'
        end
      end
    end

    def foreach(path, *args, **opts)
      return enum_for(:foreach, path, *args, **opts) unless block_given?

      if args.size == 2
        sep, limit = args
      elsif args.size == 1
        arg = args.first
        if arg.nil?
          sep = nil
        elsif arg.respond_to?(:to_int)
          limit = arg
          sep = $/
        elsif arg.respond_to?(:to_str)
          sep = arg
        else
          raise TypeError, "no implicit conversion of #{args[0].class} into Integer"
        end
      elsif args.empty?
        sep = $/
        limit = nil
      else
        raise ArgumentError, "wrong number of arguments (given #{args.size}, expected 1..3)"
      end

      sep = sep.to_str if sep.respond_to?(:to_str)
      raise TypeError, "no implicit conversion of #{sep.class} into String" if sep && !sep.is_a?(String)

      limit = limit.to_int if limit.respond_to?(:to_int)
      raise TypeError, "no implicit conversion of #{limit.class} into Integer" if limit && !limit.is_a?(Integer)

      limit = nil if limit&.negative?

      chomp = opts.delete(:chomp)
      mode = opts.delete(:mode) || 'r'

      io = File.open(path, mode, **opts)

      if sep.nil? && limit.nil?
        yield io.read
        return
      end

      if sep == ''
        sep = "\n\n"
        skip_leading_newlines = true
      end

      buf = String.new('', encoding: Encoding::UTF_8)
      get_bytes = lambda do |size|
        buf << io.read(1024) while !io.eof? && buf.bytesize << size
        return nil if io.eof? && buf.empty?
        buf.byteslice(0, size)
      end
      advance = lambda do |size|
        buf = buf.byteslice(size..)
        if skip_leading_newlines
          num_leading_newlines = buf.match(/^\n+/).to_s.size
          buf = buf.byteslice(num_leading_newlines..)
        end
      end

      $. = 0
      loop do
        line = get_bytes.(limit || 1024)
        break unless line
        tries = 0
        until line.valid_encoding? || tries >= 4
          tries += 1
          line = get_bytes.(limit + tries)
        end
        if sep && (sep_index = line.index(sep))
          line = line[...(sep_index + sep.size)]
        end
        advance.(line.bytesize)
        line.chomp! if sep && sep_index && chomp

        $. += 1
        yield line
      end

      io.close
      $_ = nil
    end
  end

  SEEK_SET = 0
  SEEK_CUR = 1
  SEEK_END = 2
  SEEK_DATA = 3
  SEEK_HOLE = 4

  def each
    while (line = gets)
      yield line
    end
  end

  def printf(format_string, *arguments)
    print(Kernel.sprintf(format_string, *arguments))
  end

  # The following are used in IO.select

  module WaitReadable; end
  module WaitWritable; end

  class EAGAINWaitReadable < Errno::EAGAIN
    include IO::WaitReadable
  end

  class EAGAINWaitWritable < Errno::EAGAIN
    include IO::WaitWritable
  end

  class EWOULDBLOCKWaitReadable < Errno::EWOULDBLOCK
    include IO::WaitReadable
  end

  class EWOULDBLOCKWaitWritable < Errno::EWOULDBLOCK
    include IO::WaitWritable
  end

  class EINPROGRESSWaitReadable < Errno::EINPROGRESS
    include IO::WaitReadable
  end

  class EINPROGRESSWaitWritable < Errno::EINPROGRESS
    include IO::WaitWritable
  end
end

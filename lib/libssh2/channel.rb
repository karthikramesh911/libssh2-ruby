module LibSSH2
  # Represents a channel on top of an SSH session. Most communication
  # done via SSH is done on one or more channels. The actual communication
  # is then multiplexed onto a single connection.
  class Channel
    # This gives you access to the native underlying channel object.
    # Use this **at your own risk**. If you start calling native methods,
    # then the safety of the rest of this class is no longer guaranteed.
    #
    # @return [Native::Channel]
    attr_reader :native_channel

    # The session that this channel belongs to.
    #
    # @return [Session]
    attr_reader :session

    # Opens a new channel. This should almost never be called directly,
    # since the parameter required is the native channel object. Instead
    # use helpers such as {Session#open_channel}.
    #
    # @param [Native::Channel] native_channel Native channel structure.
    # @param [Socket] socket Open socket to communicate with.
    def initialize(native_channel, session)
      @native_channel = native_channel
      @session = session
    end

    # Executes the given command line and returns a {Process} object.
    # Note that this command executes asynchronously.
    #
    # @return [Process]
    def execute(command)
      # Create the process, which will be the `exec` method
      process = Process.new(self) do
        @session.blocking_call do
          @native_channel.exec(command)
        end
      end

      # Start the process
      process.start!

      # Return it
      process
    end
  end

  # Represents a process that on a channel. This will execute a
  # process then read the output data from it and store it for future
  # retrieval.
  class Process
    READ_CHUNK_SIZE = 4096

    # This is the data from the standard IO substream (stream ID 0)
    # which typically contains stdout.
    #
    # @return [String]
    attr_reader :data

    # Setup a process.
    #
    # @yield [] This should execute the process on the channel. Directly
    #   after yielding, the process will automatically gather any resulting
    #   information.
    def initialize(channel, &block)
      @channel = channel
      @block   = block
    end

    def start!
      # Execute the process
      @block.call
    end
  end
end
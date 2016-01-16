#!/usr/bin/ruby

require 'mplayer-ruby'

module EasyTranscribe
  class Player
    def initialize
      reset
    end

    def destroy
      reset
    end

    def on_position_changed(&block)
      @on_position_changed = block
    end

    def open(filename)
      reset

      @player = MPlayer::Slave.new(filename)
      @alive = true
      stop

      @thread = Thread.new do
        while @alive
          sleep(0.1)
          notify_position_changed
        end
      end
    end

    def playing?
      not @paused
    end

    def play
      unless playing?
        @player.pause
        @paused = false
      end
    end

    def pause
      if playing?
        @player.pause
        @paused = true
      end
    end

    def stop
      pause
      seek(0)
    end

    def position
      @player.time_position.to_f
    end

    def seek(sec_from_start)
      @player.command("seek #{sec_from_start} 2")
      notify_position_changed
    end

    def rewind
      return unless playing?
      @player.command('seek -3 0')
      notify_position_changed
    end

    def fast_forward
      return unless playing?
      @player.command('seek 3 0')
      notify_position_changed
    end

    def length
      @player.time_length.to_f
    end

    private

    def reset
      @alive = false
      @thread.join if @thread
      @player.quit if @player
      @player = nil
      @on_position_changed = nil
      @paused = false
    end

    def notify_position_changed
      if handler = @on_position_changed
        handler.call(position)
      end
    end
  end
end

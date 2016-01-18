#!/usr/bin/ruby

require 'gst'
require 'uri'

module EasyTranscribe
  class Player
    def initialize
      reset
    end

    def destroy
      reset
    end

    def alive?
      @alive
    end

    def on_position_changed(&block)
      @on_position_changed = block
    end

    def open(filename)
      reset

      @filename = filename
      @player = Gst::ElementFactory.make('playbin')
      @player.uri = "file://#{URI.encode(filename)}"
      @alive = true

      @thread = Thread.new do
        prev_position = 0.0
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
        @player.play
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
      ok, time = query(:position)
      return ok ? time : -1
    end

    def seek(sec_from_start)
      flags = Gst::SeekFlags
      flags = Gst::SeekFlags::FLUSH | Gst::SeekFlags::KEY_UNIT
      position = sec_from_start.to_f * Gst::SECOND

      @player.seek_simple(Gst::Format::TIME, flags, position)
    end

    def rewind
      return unless playing?
      seek(position - 3)
    end

    def fast_forward
      return unless playing?
      seek(position + 3)
    end

    def length
      sox_output = `sox "#{@filename}" -n stat 2>&1`
      raise 'sox error' unless $? == 0
      line = sox_output.lines.select { |l| l =~ /Length \(seconds\):/ }.first
      line.split.last.to_f.round(1)
    end

    private

    def query(type)
      ok, time = @player.method(:"query_#{type}").call(Gst::Format::TIME)
      time = (time.to_f / Gst::SECOND).round(1)
      [ok, time]
    end

    def reset
      @alive = false
      @thread.join if @thread
      @player = nil
      @filename = nil
      @length = nil
      @on_position_changed = nil
      @paused = true
    end

    def notify_position_changed
      if handler = @on_position_changed
        p position
        handler.call(position)
      end
    end
  end
end

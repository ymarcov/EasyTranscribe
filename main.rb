#!/usr/bin/ruby

require_relative 'open_audio_file'
require_relative 'player'
require_relative 'ui'

ET = EasyTranscribe

module Commands
  @player = ET::Player.new

  def self.open
    ET::UI::OpenAudioFileDialog.open(ET::UI.main_window) do |dlg|
      if dlg.ok?
        @player.open(dlg.filename)
      end
    end
  end

  def self.stop
    @player.stop
  end

  def self.play
    @player.play
  end

  def self.rewind
  end

  def self.fast_forward
  end

  def self.start_segment
  end

  def self.end_segment
  end

  def self.restart_segment
  end
end

ET::UI.setup(commands: Commands)
ET::UI.loop

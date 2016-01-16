#!/usr/bin/ruby

require_relative 'open_audio_file'
require_relative 'player'
require_relative 'ui'

ET = EasyTranscribe

$PLAYER = ET::Player.new

module Commands
  def self.open
    ET::UI::OpenAudioFileDialog.open(ET::UI.main_window) do |dlg|
      if dlg.ok?
        $PLAYER.open(dlg.filename)
        ET::UI.reset_slider($PLAYER.length)

        $PLAYER.on_position_changed do |position|
          ET::UI.safe_dispatch do
            ET::UI.set_slider_position(position)
          end
        end

      end
    end
  end

  def self.stop
    $PLAYER.stop
  end

  def self.play
    $PLAYER.playing? and $PLAYER.pause or $PLAYER.play
  end

  def self.rewind
    $PLAYER.rewind
  end

  def self.fast_forward
    $PLAYER.fast_forward
  end

  def self.start_segment
  end

  def self.end_segment
  end

  def self.restart_segment
  end
end

ET::UI.setup(commands: Commands)
ET::UI.set_on_exit { $PLAYER.destroy }
ET::UI.loop

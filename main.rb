#!/usr/bin/ruby

require_relative 'open_audio_file'
require_relative 'player'
require_relative 'ui'

ET = EasyTranscribe

$PLAYER = ET::Player.new
$FILE = File.open(ARGV[0], 'w')

module Commands
  def self.open
    ET::UI::OpenAudioFileDialog.open(ET::UI.main_window) do |dlg|
      if dlg.ok?
        $PLAYER.open(dlg.filename)
        ET::UI.reset_slider($PLAYER.length)

        $PLAYER.on_position_changed do |position|
          ET::UI.safe_dispatch do
            ET::UI.set_slider_position(position)

            if position >= ET::UI.slider_end_segment
              Commands.restart_segment
            end
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

    $FILE.truncate(0)
    $FILE.write(ET::UI.text)
    $FILE.flush
  end

  def self.rewind
    $PLAYER.rewind
  end

  def self.fast_forward
    $PLAYER.fast_forward
  end

  def self.start_segment
    ET::UI.slider_start_segment = $PLAYER.position
  end

  def self.end_segment
    ET::UI.slider_end_segment = $PLAYER.position
  end

  def self.clear_end_segment
    ET::UI.slider_end_segment = nil
  end

  def self.restart_segment
    $PLAYER.seek(ET::UI.slider_start_segment)
    $PLAYER.play
  end
end

ET::UI.setup(commands: Commands)

ET::UI.set_on_slider_value_changed do |_, _, value|
  $PLAYER.seek(value)
end

ET::UI.set_on_exit do
  $PLAYER.destroy
end

ET::UI.loop

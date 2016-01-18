#!/usr/bin/ruby

require 'pandoc-ruby'
require_relative 'open_audio_file'
require_relative 'player'
require_relative 'ui'

ET = EasyTranscribe

$PLAYER = ET::Player.new
$OUTPUT_FILENAME = ARGV[0]

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

  def self.read_file
    FileUtils.touch($OUTPUT_FILENAME)
    f = File.open($OUTPUT_FILENAME, 'r')
    begin
      return f.read
    ensure
      f.close
    end
  end

  def self.save_as(path)
    f = File.open(path, 'w')
    begin
      f.write(ET::UI.text)
    ensure
      f.close
    end
  end

  def self.save
    save_as($OUTPUT_FILENAME)
  end

  def self.save_backup
    save_as($OUTPUT_FILENAME + '.backup')
  end

  def self.export
    f = File.open($OUTPUT_FILENAME + '.odt', 'w')
    begin
      output = PandocRuby.convert(ET::UI.text, from: :markdown, to: :odt)
      f.write(output)
    ensure
      f.close
    end
  end

  def self.stop
    return unless $PLAYER.alive?
    $PLAYER.stop
  end

  def self.play
    return unless $PLAYER.alive?
    $PLAYER.playing? and $PLAYER.pause or $PLAYER.play
    save_backup
  end

  def self.rewind
    return unless $PLAYER.alive?
    $PLAYER.rewind
  end

  def self.fast_forward
    return unless $PLAYER.alive?
    $PLAYER.fast_forward
  end

  def self.start_segment
    return unless $PLAYER.alive?
    ET::UI.slider_start_segment = $PLAYER.position
  end

  def self.end_segment
    return unless $PLAYER.alive?
    ET::UI.slider_end_segment = $PLAYER.position
  end

  def self.clear_end_segment
    return unless $PLAYER.alive?
    ET::UI.slider_end_segment = nil
  end

  def self.restart_segment
    return unless $PLAYER.alive?
    $PLAYER.seek(ET::UI.slider_start_segment)
    $PLAYER.play
  end
end

ET::UI.setup(commands: Commands)

ET::UI.text = Commands.read_file

ET::UI.set_on_slider_value_changed do |_, _, value|
  $PLAYER.seek(value)
end

ET::UI.set_on_exit do
  $PLAYER.destroy
end

ET::UI.loop

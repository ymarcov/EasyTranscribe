#!/usr/bin/ruby

require 'gst'
require 'pandoc-ruby'

require_relative 'file_dialogs'
require_relative 'player'
require_relative 'ui'

if ARGV.length != 1
  STDERR.puts "Usage: #{File.basename($0)} OUTPUT_TEXT_FILE"
  exit 1
end

ET = EasyTranscribe

$PLAYER = ET::Player.new
$OUTPUT_FILENAME = ARGV[0]

module Commands
  def self.open
    ET::UI::OpenAudioFileDialog.open(ET::UI.main_window) do |dlg|
      if dlg.ok?
        $PLAYER.open(dlg.filename)

        ET::UI::Slider.reset($PLAYER.length)

        $PLAYER.on_position_changed do |position|
          ET::UI.safe_dispatch do
            ET::UI::Slider.position = position

            if position >= ET::UI::Slider.end_segment
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

  def self.save
    f = File.open($OUTPUT_FILENAME, 'w')
    begin
      f.write(ET::UI::Editor.text)
    ensure
      f.close
    end
  end

  def self.save_backup
    f = File.open($OUTPUT_FILENAME + '.backup', 'w')
    begin
      f.write(ET::UI::Editor.text + " (#{$PLAYER.position})")
    ensure
      f.close
    end
  end

  def self.export
    options = { default_filename: $OUTPUT_FILENAME.gsub(/.txt$/, '') + '.odt' }

    ET::UI::ExportFileDialog.open(ET::UI.main_window, options) do |dlg|
      if dlg.ok?
        f = File.open(dlg.filename, 'w')
        begin
          text = ET::UI::Editor.text.gsub("\n", "\n\n").gsub('--', '—')
          output = PandocRuby.convert(text, from: :markdown, to: :odt)
          f.write(output)
        ensure
          f.close
        end
      end
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
    ET::UI::Slider.start_segment = $PLAYER.position
  end

  def self.end_segment
    return unless $PLAYER.alive?
    ET::UI::Slider.end_segment = $PLAYER.position
  end

  def self.clear_end_segment
    return unless $PLAYER.alive?
    ET::UI::Slider.end_segment = nil
  end

  def self.restart_segment
    return unless $PLAYER.alive?
    $PLAYER.seek(ET::UI::Slider.start_segment)
    $PLAYER.play
  end
end

ET::UI.setup(commands: Commands)

ET::UI::Editor.text = Commands.read_file

ET::UI::Slider.on_value_changed do |_, _, value|
  return unless $PLAYER.alive?
  $PLAYER.seek(value)
end

ET::UI.on_exit do
  $PLAYER.destroy
end

Gst.init
ET::UI.loop

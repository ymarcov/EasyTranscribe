#!/usr/bin/ruby

require 'gtk3'

module EasyTranscribe
  module UI
    class OpenAudioFileDialog
      def self.open(parent_window = nil)
        dlg = new(parent_window)

        begin
          dlg.run
          yield dlg
        ensure
          dlg.destroy
        end
      end

      def initialize(parent_window)
        @dlg = Gtk::FileChooserDialog.new(
          title: 'Open audio file',
          parent: parent_window,
          action: :open,
          buttons: [
            [Gtk::Stock::OPEN, :accept],
            [Gtk::Stock::CANCEL, :cancel]
          ]
        )
      end

      def run
        @result = @dlg.run
      end

      def ok?
        @result == :accept
      end

      def filename
        @dlg.filename
      end

      def destroy
        @dlg.destroy
      end

      private

      def add_filters
        audio_filter = Gtk::FileFilter.new
        audio_filter.set_name('Audio files')
        audio_filter.add_pattern('*.mp3')
        audio_filter.add_pattern('*.ogg')

        all_filter = Gtk::FileFilter.new
        all_filter.set_name('All files')
        all_filter.add_pattern('*')

        @dlg.add_filter(audio_filter)
        @dlg.add_filter(all_filter)
      end
    end
  end
end

#!/usr/bin/ruby

require 'gtk3'

module EasyTranscribe
  module UI
    class FileDialogBase
      def self.open(parent_window = nil)
        dlg = new(parent_window, @action, @accept_button)

        begin
          dlg.run
          yield dlg
        ensure
          dlg.destroy
        end
      end

      def initialize(parent_window, action, accept_button)
        @dlg = Gtk::FileChooserDialog.new(
          title: 'Open audio file',
          parent: parent_window,
          action: action,
          buttons: [
            [accept_button, :accept],
            [Gtk::Stock::CANCEL, :cancel]
          ]
        )

        get_filters.each { |f| @dlg.add_filter(f) }
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
    end

    class OpenAudioFileDialog < FileDialogBase
      @accept_button = Gtk::Stock::OPEN
      @action = :open

      def get_filters
        audio_filter = Gtk::FileFilter.new
        audio_filter.set_name('Audio files')
        audio_filter.add_pattern('*.mp3')
        audio_filter.add_pattern('*.ogg')

        all_filter = Gtk::FileFilter.new
        all_filter.set_name('All files')
        all_filter.add_pattern('*')

        [audio_filter, all_filter]
      end
    end

    class ExportFileDialog < FileDialogBase
      @accept_button = Gtk::Stock::SAVE
      @action = :save

      def get_filters
        odt_filter = Gtk::FileFilter.new
        odt_filter.set_name('ODF Text Document')
        odt_filter.add_pattern('*.odt')
        [odt_filter]
      end

      def filename
        f = super
        f.end_with?('.odt') ? f : f + '.odt'
      end
    end
  end
end

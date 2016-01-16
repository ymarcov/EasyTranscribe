#!/usr/bin/ruby

require 'gtk3'

module EasyTranscribe
  module UI
    private

    @on_exit = nil

    def self.create_window
      win = Gtk::Window.new
      win.title = 'EasyTranscribe'
      win.set_border_width(20)

      win.signal_connect('delete_event') do
        @on_exit.call if @on_exit
        Gtk.main_quit
        false
      end

      win
    end

    def self.create_toolbar_items
      buttons = {
        open: Gtk::Button.new(label: 'Open'),
        _sep_0: Gtk::SeparatorToolItem.new,
        stop: Gtk::Button.new(label: 'Stop'),
        play: Gtk::Button.new(label: 'Play/Pause'),
        _sep_1: Gtk::SeparatorToolItem.new,
        rewind: Gtk::Button.new(label: 'Rewind'),
        fast_forward: Gtk::Button.new(label: 'Fast Forward'),
        _sep_2: Gtk::SeparatorToolItem.new,
        start_segment: Gtk::Button.new(label: 'Segment/Start'),
        end_segment: Gtk::Button.new(label: 'Segment/End'),
        restart_segment: Gtk::Button.new(label: 'Restart'),
      }

      buttons[:open].set_tooltip_markup('<b>Ctrl+O</b> Open an audio file')
      buttons[:stop].set_tooltip_markup('<b>Ctrl+S</b> Stop and rewind track to beginning')
      buttons[:play].set_tooltip_markup('<b>Ctrl+P</b> Play or Pause track')
      buttons[:rewind].set_tooltip_markup('<b>Ctrl+R</b> Rewind track')
      buttons[:fast_forward].set_tooltip_markup('<b>Ctrl+F</b> Fast-forward track')
      buttons[:start_segment].set_tooltip_markup('<b>Ctrl+A</b> Set segment start at cursor position')
      buttons[:end_segment].set_tooltip_markup('<b>Ctrl+B</b> Set segment end at cursor position')
      buttons[:restart_segment].set_tooltip_markup('<b>Ctrl+E</b> Restart segment')

      buttons
    end

    def self.create_toolbar
      tb = Gtk::Box.new(:vertical)

      button_box = Gtk::Box.new(:horizontal)

      def tb.buttons
        unless defined? @buttons
          @buttons = UI.create_toolbar_items.freeze
        end

        @buttons
      end

      tb.buttons.each do |_, b|
        b.set_border_width(2)
        button_box.pack_start(b)
      end

      def tb.slider
        unless defined? @scale
          @scale = Gtk::Scale.new(:horizontal)
          @scale.set_range(0, 1)
          @scale.add_mark(0, Gtk::PositionType::BOTTOM, 'S')
          @scale.add_mark(1, Gtk::PositionType::BOTTOM, 'E')
          @scale.add_mark(1, Gtk::PositionType::TOP, 'End')
        end

        @scale
      end

      tb.pack_start(tb.slider, padding: 5)
      tb.pack_start(button_box, padding: 10)

      tb
    end

    def self.create_textview
      frame = Gtk::Frame.new

      def frame.editor
        unless defined? @tv
          win = Gtk::ScrolledWindow.new
          @tv = Gtk::TextView.new
          @tv.set_left_margin(10)
          @tv.set_indent(20)
          @tv.set_wrap_mode(Gtk::WrapMode::WORD_CHAR)
          @tv.set_pixels_above_lines(10)
          @tv.show
          win.add(@tv)
          win.show
          add(win)
        end

        @tv
      end

      frame
    end

    def self.add_css
      css = '
      GtkTextView {
        font-size: 12px;
        font-family: "DroidSerif", "Georgia", serif;
      }
      '

      style_provider = Gtk::CssProvider.new
      style_provider.load_from_data(css)

      Gtk::StyleContext.add_provider_for_screen(
        Gdk::Screen.default,
        style_provider,
        Gtk::StyleProvider::PRIORITY_APPLICATION
      )
    end

    def self.create_main_window_widgets
      vbox = Gtk::Box.new(:vertical)

      textview = create_textview
      toolbar = create_toolbar

      vbox.pack_start(toolbar, expand: false, fill: false)
      vbox.pack_start(textview, expand: true, fill: true)

      return { layout: vbox, toolbar: toolbar, textview: textview }
    end

    def self.bind_commands(buttons, command_source)
      buttons.each do |name, widget|
        if widget.kind_of?(Gtk::Button)
          widget.signal_connect('clicked') do
            command_source.method(name).call
          end
        end
      end
    end

    public

    def self.setup(opts = {})
      add_css

      widgets = create_main_window_widgets

      win = create_window
      win.add(widgets[:layout])
      win.show_all

      bind_commands(widgets[:toolbar].buttons, opts[:commands])
      win.set_focus(widgets[:textview].editor)

      @main_window = win
      @slider = widgets[:toolbar].slider
    end

    def self.reset_slider(length)
      @slider.set_range(0, length)
      @slider.clear_marks
      @slider.add_mark(0, Gtk::PositionType::BOTTOM, 'S')
      @slider.add_mark(length, Gtk::PositionType::BOTTOM, 'E')
      @slider.add_mark(length, Gtk::PositionType::TOP, "End (#{length})")
    end

    def self.set_slider_position(position)
      @slider.value = position
    end

    def self.set_slider_start_segment
    end

    def self.set_slider_end_segment
    end

    def self.main_window
      @main_window
    end

    def self.set_on_exit(&block)
      @on_exit = block
    end

    def self.safe_dispatch
      Gdk.threads_enter
      begin
        yield
      ensure
        Gdk.threads_leave
      end
    end

    def self.loop
      Gtk.main
    end
  end
end

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
        _lbl_2: Gtk::Label.new('Segment: '),
        start_segment: Gtk::Button.new(label: 'Start'),
        end_segment: Gtk::Button.new(label: 'End'),
        clear_end_segment: Gtk::Button.new(label: 'Clear End'),
        restart_segment: Gtk::Button.new(label: 'Restart'),
      }

      buttons[:open].set_tooltip_markup('<b>Ctrl+O</b> Open an audio file')
      buttons[:stop].set_tooltip_markup('<b>Ctrl+S</b> Stop and rewind track to beginning')
      buttons[:play].set_tooltip_markup('<b>Ctrl+P</b> Play or Pause track')
      buttons[:rewind].set_tooltip_markup('<b>Ctrl+R</b> Rewind track')
      buttons[:fast_forward].set_tooltip_markup('<b>Ctrl+F</b> Fast-forward track')
      buttons[:start_segment].set_tooltip_markup('<b>Ctrl+A</b> Set segment start at cursor position')
      buttons[:end_segment].set_tooltip_markup('<b>Ctrl+B</b> Set segment end at cursor position')
      buttons[:clear_end_segment].set_tooltip_markup('Clear end segment')
      buttons[:restart_segment].set_tooltip_markup('<b>Ctrl+E</b> Restart segment')

      buttons
    end

    def self.create_toolbar
      tb = Gtk::Box.new(:vertical)

      button_box = Gtk::Box.new(:horizontal)

      tb.instance_eval do
        @items = UI.create_toolbar_items.freeze
        @buttons = @items.select { |_, w| w.kind_of?(Gtk::Button) }.freeze
      end

      def tb.buttons
        @buttons
      end

      def tb.items
        @items
      end

      tb.items.each do |_, b|
        b.set_border_width(2) if b.respond_to?(:set_border_width)
        button_box.pack_start(b)
      end

      def tb.slider
        unless defined? @scale
          @scale = Gtk::Scale.new(:horizontal)
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

    def self.init_slider
        @slider.set_range(0, 1)
        @slider_segment_start = 0
        @slider_segment_end = 1
        @slider_length = nil
        reset_slider
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
      init_slider
    end

    def self.reset_slider(length = nil)
      @slider.clear_marks

      if length
        @slider.set_range(0, length)
        @slider_segment_end = length
        @slider_length = length
      end

      @slider.add_mark(@slider_segment_start, Gtk::PositionType::BOTTOM, 'S')
      @slider.add_mark(@slider_segment_end, Gtk::PositionType::BOTTOM, 'E')

      if @slider_length
        @slider.add_mark(@slider_length, Gtk::PositionType::TOP, "End (#{@slider_length})")
      else
        @slider.add_mark(1, Gtk::PositionType::TOP, "End")
      end
    end

    def self.set_slider_position(position)
      @slider.value = position
    end

    def self.slider_start_segment=(position)
      @slider_segment_start = position
      reset_slider
    end

    def self.slider_end_segment=(position)
      @slider_segment_end = position || @slider_length
      reset_slider
    end

    def self.slider_start_segment
      return @slider_segment_start
    end

    def self.slider_end_segment
      return @slider_segment_end
    end

    def self.set_on_slider_value_changed(&block)
      @slider.signal_connect('change-value', &block)
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

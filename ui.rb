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

    def self.create_footer_items
      {
        save: Gtk::Button.new(label: 'Save'),
        export: Gtk::Button.new(label: 'Export')
      }
    end

    def self.create_footer
      box = Gtk::Box.new(:horizontal)

      box.instance_eval do
        class << self
          attr_reader :buttons
        end

        @buttons = UI.create_footer_items
      end

      box.buttons.each do |_, i|
        i.set_border_width(5)
        box.pack_start(i)
      end

      box
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
      buttons[:stop].set_tooltip_markup('<b>Ctrl+W</b> Stop and rewind track to beginning')
      buttons[:play].set_tooltip_markup('<b>Ctrl+Space</b> Play or Pause track')
      buttons[:rewind].set_tooltip_markup('<b>Ctrl+R</b> Rewind track')
      buttons[:fast_forward].set_tooltip_markup('<b>Ctrl+F</b> Fast-forward track')
      buttons[:start_segment].set_tooltip_markup('<b>Ctrl+1</b> Set segment start at cursor position')
      buttons[:end_segment].set_tooltip_markup('<b>Ctrl+2</b> Set segment end at cursor position')
      buttons[:clear_end_segment].set_tooltip_markup('<b>Ctrl+0</b> Clear end segment')
      buttons[:restart_segment].set_tooltip_markup('<b>Ctrl+E</b> Restart segment')

      buttons
    end

    def self.create_toolbar_accelerators(buttons)
      group = Gtk::AccelGroup.new

      {
        open: '<Control>o',
        stop: '<Control>w',
        play: '<Control>space',
        rewind: '<Control>r',
        fast_forward: '<Control>f',
        start_segment: '<Control>1',
        end_segment: '<Control>1',
        clear_end_segment: '<Control>0',
        restart_segment: '<Control>e',
      }.each do |id, accel|
        key, mod = Gtk.accelerator_parse(accel)
        buttons[id].add_accelerator('clicked', group, key, mod, Gtk::AccelFlags::VISIBLE)
      end

      group
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
      footer = create_footer

      vbox.pack_start(toolbar, expand: false, fill: false)
      vbox.pack_start(textview, expand: true, fill: true)
      vbox.pack_start(footer, expand: false, fill: false)

      return {
        layout: vbox,
        toolbar: toolbar,
        textview: textview,
        footer: footer
      }
    end

    def self.bind_commands(buttons, command_source)
      buttons.each do |name, widget|
        if widget.kind_of?(Gtk::Button)
          widget.signal_connect('clicked') do
            if command_source.respond_to?(name)
              command_source.method(name).call
            end
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
      win.add_accel_group(create_toolbar_accelerators(widgets[:toolbar].buttons))
      win.show_all

      bind_commands(widgets[:toolbar].buttons, opts[:commands])
      bind_commands(widgets[:footer].buttons, opts[:commands])
      win.set_focus(widgets[:textview].editor)

      @main_window = win

      Slider.init(widgets[:toolbar].slider)
      Editor.init(widgets[:textview])
    end

    def self.main_window
      @main_window
    end

    def self.on_exit(&block)
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

    module Slider
      private

      def self.init(scale)
        @scale = scale
        @scale.set_range(0, 1)
        @segment_start = 0
        @segment_end = 1
        @length = nil
        reset
      end

      public

      def self.reset(length = nil)
        @scale.clear_marks

        if length
          @scale.set_range(0, length)
          @segment_end = length
          @length = length
        end

        @scale.add_mark(@segment_start, Gtk::PositionType::BOTTOM, 'S')
        @scale.add_mark(@segment_end, Gtk::PositionType::BOTTOM, 'E')

        if @length
          @scale.add_mark(@length, Gtk::PositionType::TOP, "End (#{@length})")
        else
          @scale.add_mark(1, Gtk::PositionType::TOP, "End")
        end
      end

      def self.position=(position)
        @scale.value = position
      end

      def self.start_segment=(position)
        @segment_start = position
        reset_slider
      end

      def self.end_segment=(position)
        @segment_end = position || @length
        reset_slider
      end

      def self.start_segment
        return @segment_start
      end

      def self.end_segment
        return @segment_end
      end

      def self.on_value_changed(&block)
        @scale.signal_connect('change-value', &block)
      end
    end

    module Editor
      def self.init(textview)
        @textview = textview
      end

      def self.text
        @textview.editor.buffer.text
      end

      def self.text=(text)
        @textview.editor.buffer.text = text
      end
    end
  end
end

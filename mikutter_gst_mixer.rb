# -*- coding: utf-8 -*-

Plugin.create(:mikutter_gst_mixer) do
    @@channels = {}

    def get_sym(channel)
        "gst_mixer_#{channel.to_s}".to_sym
    end

    on_gst_play do |filename, channel = :default|
        @@channels[channel] = UserConfig[get_sym(channel)] || 70
    end

    on_gst_enq do |filename, channel = :default|
        @@channels[channel] = UserConfig[get_sym(channel)] || 70
    end

    on_gst_set_volume do |volume, channel = :default|
        @@channels[channel] = volume
    end

    def create_tab
        # タブ作成前に、他プラグインの明示的なチャンネルの宣言を拾っておく
        Plugin.filtering(:gst_mixer, [])[0].each do |v|
            if !@@channels.has_key?(v)
                @@channels[v] = UserConfig[get_sym(v)] || 70
            end
        end
        tab(:mikutter_gst_mixer, "音量ミキサ") do
            set_icon File.expand_path(File.join(File.dirname(__FILE__), "audio-volume-high.png")).freeze
            set_deletable true
            vbox = Gtk::VBox.new(false, 6)
            @@channels.each do |k, v|
                hbox = Gtk::HBox.new(true, 10)
                label = Gtk::Label.new(k.to_s, false)
                hbox.pack_start(label, false, false)
                scale = Gtk::HScale.new(0.0, 1.0, 0.01)
                scale.value = v.to_f / 100.0
                scale.draw_value = true
                scale.signal_connect("value-changed") do
                    volume = (scale.value*100).to_i
                    Plugin.call(:gst_set_volume, volume, k)
                    UserConfig["gst_mixer_#{k.to_s}".to_sym] = volume
                end
                hbox.pack_start(scale, true, true, 10)
                vbox.pack_start(hbox, false, false)
            end
            nativewidget vbox
        end
    end

    command(:mikutter_gst_mixer,
        name: "音量ミキサを表示",
        condition: lambda{ |opt| true},
        visible: false,
        role: :window) do |opt|
        if Plugin::GUI::Tab.exist?(:mikutter_gst_mixer)
            Plugin::GUI::Tab.instance(:mikutter_gst_mixer).active!
        else
            create_tab.active!
        end
    end

    Delayer.new do
        
        create_tab if Plugin::GUI::Tab.exist?(:mikutter_gst_mixer)
    end
end

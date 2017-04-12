using Gtk;

public class hider : Window
{
    public bool switch_state = false;
    public static int main(string[] args)
    {
        Gtk.init(ref args);
        Intl.setlocale (LocaleCategory.ALL, "");

        //Creating the window
        var window = new hider();
        window.show_all();

        Gtk.main();

        return 0;
    }

    public hider()
    {
        Gtk.HeaderBar header_bar = new Gtk.HeaderBar();
        header_bar.show_close_button = true;
        header_bar.title = "Hide";
        this.set_titlebar(header_bar);

        Gtk.Button hide_header_button = new Gtk.Button.with_label("Hide");
        Gtk.Button unhide_header_button = new Gtk.Button.with_label("Unhide");
        //add button to headerbar
        header_bar.pack_end(hide_header_button);
        header_bar.pack_end(unhide_header_button);

        this.set_default_size(500, 780);
        this.destroy.connect(Gtk.main_quit);

        var screen = this.get_screen();
        var css_provider = new Gtk.CssProvider();

        string path = "application.css";

        //test if the css file exist
        if(FileUtils.test(path, FileTest.EXISTS))
        {
            try
            {
                css_provider.load_from_path(path);
                Gtk.StyleContext.add_provider_for_screen(screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
            }catch (Error e)
            {
                error("Cannot load CSS stylesheet: %s", e.message);
            }
        }
        //End of the window config

        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        
        //Chooser
        SList<string> uris = new SList<string>();
        Gtk.FileChooserWidget chooser = new Gtk.FileChooserWidget (Gtk.FileChooserAction.OPEN);
        chooser.show_hidden();
        chooser.select_multiple = true;
        chooser.selection_changed.connect(() => {
           uris = chooser.get_uris();
        });

        //Header button functionality
        hide_header_button.clicked.connect(() => {
            hide_files(uris);
        });

        unhide_header_button.clicked.connect(() => {
            unhide_files(uris);
        });

        //Infobar
        var bar = get_infobar();
        
        box.pack_start(chooser, true, true, 0);
        box.pack_start(bar, false, false, 0);
        this.add(box);
    }

    private void hide_files(SList<string> uris)
    {
           foreach(unowned string uri in uris){
            stdout.printf("%s\n",uri);
               if(File.new_for_path(uri[7: uri.length]).query_file_type (0) == FileType.DIRECTORY)
               {
                hide_directory(uri);
               }else{
                   hide_single_file(uri);
               }
           }
    }

    private void unhide_files(SList<string> uris)
    {
           foreach(unowned string uri in uris){
               if(File.new_for_path(uri[7: uri.length]).query_file_type (0) == FileType.DIRECTORY)
               {
                    unhide_directory(uri);
               }else{
                   unhide_single_file(uri);
               }
           }
    }

    private void hide_single_file(string uri)
    {
        var urif = uri[7: uri.length];
        var filename = urif[urif.last_index_of("/")+1: urif.length];
        if(filename[0:1] != "."){
            try{
                var file = File.new_for_path(urif.replace("%20", " "));
                file.set_display_name("."+filename.replace("%20", " "));
            } catch(Error e){
                stdout.printf("Error %s\n", e.message);
            }
        }
    }
    
    private void unhide_single_file(string uri)
    {
        var urif = uri[7: uri.length];
        var filename = uri[uri.last_index_of("/")+1: uri.length];
        if(filename[0:1] == "."){
            try{
                var file = File.new_for_path(urif.replace("%20", " "));
                file.set_display_name(filename[1:filename.length].replace("%20", " "));
            }catch(Error e){
                stdout.printf("Error %s\n", e.message);
            }
        }
    }

    private void hide_directory(string uri)
    {
        if(switch_state)
        {
            var urif = uri[7: uri.length];
            try{
                var file = File.new_for_path(urif.replace("%20", " "));
                //Sons changer
                var cancellable = new Cancellable ();
                var enumerator = file.enumerate_children (
                    "standard::*",
                    FileQueryInfoFlags.NOFOLLOW_SYMLINKS, 
                    cancellable);

                var info = enumerator.next_file();
                while (info != null) {
                        info = enumerator.next_file();
                        var file_uri =  uri+ "/" + info.get_name();
                        hide_single_file(file_uri);
                }

                if (cancellable.is_cancelled ()) {
                    throw new IOError.CANCELLED ("Operation was cancelled");
                }
            }catch(Error e){
                stdout.printf("Error %s\n", e.message);
            }
        }
        hide_single_file(uri);
    }


    private void unhide_directory(string uri)
    {
        if(switch_state)
        {
            var urif = uri[7: uri.length];
            try{
                var file = File.new_for_path(urif.replace("%20", " "));
                //Sons changer
                var cancellable = new Cancellable ();
                var enumerator = file.enumerate_children (
                    "standard::*",
                    FileQueryInfoFlags.NOFOLLOW_SYMLINKS, 
                    cancellable);

                var info = enumerator.next_file();
                while (info != null) {
                        info = enumerator.next_file();
                        var file_uri =  uri+ "/" + info.get_name();
                        unhide_single_file(file_uri);
                }

                if (cancellable.is_cancelled ()) {
                    throw new IOError.CANCELLED ("Operation was cancelled");
                }
            }catch(Error e){
                stdout.printf("Error %s\n", e.message);
            }
        }
        unhide_single_file(uri);
    }

    private Gtk.InfoBar get_infobar()
    {
        var bar = new Gtk.InfoBar();

        var bar_container =  bar.get_content_area();
        
        //Box InfoBar
        var _switch = new Gtk.Switch ();
        var box_info = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        box_info.pack_start(new Gtk.Label("Allow recursive hide: "), true, true, 0);
        box_info.pack_start(_switch, false, false, 30);

        bar_container.add(box_info);

        //Switch click
        _switch.notify["active"].connect (() => {
			if (_switch.active) {
				stdout.printf ("The switch is on!\n");
                switch_state = true;
			} else {
				stdout.printf ("The switch is off!\n");
                switch_state = false;
			}
		});


        return bar;
    }
}

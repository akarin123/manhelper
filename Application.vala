/*-
 * Authored by: XX Wu <xwuanhkust@gmail.com>
 */

/* This is the application */
namespace ManHelper
{
    public class App:Gtk.Application
    {    
        public uint section_num_max {get;default=9;}
        protected override void activate()
        {   
            //print("Before\n");
            var app_win = new MainWin(this);
            //app_win.icon = new Gdk.Pixbuf.from_file ("icon.png");
            app_win.show_all();
            //print("After!\n");
        }

        protected override void startup()
        {
            base.startup();
        }
    }

    /* This is the main window */
    [GtkTemplate (ui = "/ui/manhelper.ui")]
    public class MainWin:Gtk.ApplicationWindow
    {
        private const string app_title = "Man Helper";
        private string init_uri;
        internal int height_header;
        internal uint section_num_max;
        internal string last_entry_text {get;set;default="";}        
        internal KeywordList search_list = null;
        internal Gtk.FileChooserDialog file_chooser = null;

        [GtkChild]
        private Gtk.Button btn_man;
        [GtkChild]
        private Gtk.SearchEntry entry_search;
        [GtkChild]
        private Gtk.ScrolledWindow scrolled;

        internal WebKit.WebView view; 
        

        internal MainWin(App app)
        {
            Object(application: app,title: app_title);
            section_num_max = app.section_num_max;

            view = new WebKit.WebView();  
            view.button_press_event.connect(on_view_mouse_press);
            scrolled.add_with_properties(view);
            
            //string init_uri = "https://man7.org/linux/man-pages/man1/man.1.html";     
            init_uri = "http://localhost/cgi-bin/man/man2html";
            view.load_uri(init_uri);  
            //keyword_menu = new KeywordMenu("");
            //print(last_width.to_string());
            search_list = new KeywordList(this,"man",400);
            search_list.show_all();
            search_list.hide();
            height_header = guess_height_headerbar();
        }

        // guess the height of title bar
        private int guess_height_headerbar()
        {
            int height_header = 50;

            var header = new Gtk.HeaderBar();
            var window_temp = new Gtk.Window();
            window_temp.width_request = this.default_width;
            window_temp.height_request = this.default_height;
            header.show_close_button = true;
            header.title = app_title;
            window_temp.set_titlebar(header);
            window_temp.show_all();
            
            height_header = header.get_allocated_height();
            window_temp.destroy();
            //print(@"$(height_header)\n");
            return (height_header+1);
        }

        [GtkCallback]
        private void on_btn_man_clicked(Gtk.Button self)
        {
            string entry_text = entry_search.get_text();
            Thread<bool>[] thread = new Thread<bool>[section_num_max];
            bool[] status = new bool[section_num_max];
            man_uri[] man_uri_test = new man_uri[section_num_max];
            bool entry_found = false;
            string[] entry_data;
            if ((entry_text=="")||(entry_text==this.last_entry_text))
            {
                //print("same entry\n");
                return;
            }

            this.last_entry_text = entry_text;


            entry_data = entry_text.split(".");

            if (entry_data.length == 1)
            {
                for (var ii = 1; ii<(section_num_max+1); ii++)
                {
                    man_uri_test[ii-1] = new man_uri(entry_text,ii.to_string());

                    thread[ii-1] = new Thread<bool>("man"+ii.to_string()+"_uri_exist", man_uri_test[ii-1].man_uri_exist);
                }

                for (var ii = 1; ii<(section_num_max+1); ii++)
                {
                    status[ii-1] = thread[ii-1].join();
                    //print("Inner, the status is "+status[ii-1].to_string()+"\n");

                    if (status[ii-1])
                    {
                        view.load_uri(man_uri_test[ii-1].uri);
                        entry_found = true;  
                        break;            
                    }
                } 
            }
            else if (entry_data.length > 1)
            {

                man_uri_test[0] = new man_uri(entry_data[0],entry_data[1]);

                status[0] = man_uri_test[0].man_uri_exist();

                //print("here\n");
                if (status[0])
                {
                    //print("there\n");
                    view.load_uri(man_uri_test[0].uri);   
                    entry_found = true;    
                }
            }

            if (!entry_found)
            {
                //print("Not found!\n");
                this.set_tooltip_text("No manual entry for "+entry_text);
                this.trigger_tooltip_query();
            }
            else
            {
                this.set_has_tooltip(false);

                if (this.search_list.get_realized())
                    this.search_list.destroy();
            }
        }
        
        
        [GtkCallback]
        private void on_entry_search_changed(Gtk.SearchEntry self)
        {
            string text = self.get_text();
            const int long_cmd = 6;

            int width = self.get_allocated_width();
            //int height = self.get_allocated_height();
            int x_root,y_root,x_rel,y_rel;
            int x,y;
            //Gtk.HeaderBar header_bar = this.get_titlebar() as Gtk.HeaderBar;
            
            this.scrolled.translate_coordinates(this,0,0,out x_rel,out y_rel);
            this.get_position(out x_root,out y_root);

            x=x_rel+x_root;
            y=y_rel+y_root+this.height_header;
            //print(@"$(this.height_header)\n");

            if (text.length>long_cmd)
            {
                if (this.search_list.get_realized())
                    this.search_list.destroy();
    
                this.search_list = new KeywordList(this,text,width);

                if (this.search_list.find_num>0)
                {
                    this.search_list.show_all();
                    this.search_list.move(x,y);
                    this.present();
                    //print("show all\n");
                }

            }
            else
            {
                if (this.search_list.get_realized())
                    this.search_list.destroy();
            }
            

        }

        [GtkCallback]
        private void on_entry_search_enter(Gtk.Entry self)
        {
            btn_man.clicked();
        }

        [GtkCallback]
        private bool on_view_mouse_press(Gtk.Widget self,Gdk.EventButton evnt)
        {
            //print("here");
            if (this.search_list.get_realized())
            {
                //print("destroy\n");
                this.search_list.destroy();
            }

            return false;
        }

        /*
        [GtkCallback]
        private bool on_window_configured(Gtk.Widget self,Gdk.Event evnt)
        {
            print("here");
            if (this.search_list.get_realized())
            {
                //print("destroy\n");
                this.search_list.destroy();
            }

            return false;
        }*/

        [GtkCallback]
        private void on_quit_clicked(Gtk.MenuItem self)
        {
            this.destroy();
        }
        
        [GtkCallback]
        private void on_about_dialog_clicked(Gtk.MenuItem self)
        {
            AboutDialog about_dialog;

            about_dialog=new AboutDialog();
            about_dialog.show_all();
        }

        [GtkCallback]
        private void on_copy_clicked(Gtk.MenuItem self)
        {
            var focus = this.get_focus();

            if (focus==this.view)
                this.view.execute_editing_command("Copy");
            else if (focus==this.entry_search)
                this.entry_search.copy_clipboard();
        }

        [GtkCallback]
        private async void on_save_as_clicked(Gtk.MenuItem self)
        {
            //print("need to implement\n");
            File file = null;;
            int save_resp;
            string filepath;
            Regex regex_html;
            bool save_succeed = false;
            string file_extension = ".mhtml";

            try
            {
                regex_html = new Regex("^[\\S\\s]+"+file_extension+"?$");
                //page_input = yield view.save(WebKit.SaveMode.MHTML);
            }
            catch (Error e)
            {
                message(e.message+"\n");

                return;
            }

            if (this.file_chooser == null)
                this.file_chooser = new Gtk.FileChooserDialog("Save as",null,Gtk.FileChooserAction.SAVE);

            file_chooser.set_current_name(this.last_entry_text+file_extension);
            save_resp = file_chooser.run();
            //print(save_resp.to_string()+"\n");
            
            if (save_resp == Gtk.ResponseType.ACCEPT)
            {
                filepath = file_chooser.get_filename();

                file = File.new_for_path(filepath);

                var parent_path = file.get_parent().get_parse_name();
                var name = file.get_basename();
                //file.get_basename()
                if (!regex_html.match(name))
                    name = name+file_extension; // add .html file extension

                file = File.new_build_filename(parent_path,name);

                //print(file.get_parse_name()+"\n");

                try
                {
                    save_succeed = yield view.save_to_file(file,WebKit.SaveMode.MHTML);
                }
                catch (Error e)
                {
                    message(e.message);

                    return;
                }

            }       
            
            file_chooser.hide();
        }

        [GtkCallback]
        private void on_find_clicked(Gtk.MenuItem self)
        {
            SearchDialog search_dialog;

            search_dialog = new SearchDialog(this);
            search_dialog.show_all();
        }

        public class man_uri
        {
            public string entry_text {set;get;default="man";}   
            public string sec_num {set;get;default="1";}
            public string uri;

            public man_uri(string entry_text,string sec_num)
            {
                //string sec_num_str=sec_num.to_string();
                //this.uri = "https://man7.org/linux/man-pages/man"+sec_num_str+"/"+entry_text.strip()+"."+sec_num_str+".html";
                this.uri = "http://localhost/cgi-bin/man/man2html?"+sec_num.strip()+"+"+entry_text.strip();
            }
            
            public bool man_uri_exist()
            {
                Soup.Session session;
                Soup.Message message;
                uint status_code;            
                
                session = new Soup.Session();
                message = new Soup.Message("HEAD",this.uri);
                session.send_message(message);

                status_code=message.status_code;
                
                //print(@"status code: $(status_code)\n");

                if (status_code<400)
                    return true;
                else 
                    return false;
            }
        }
    }

    [GtkTemplate (ui = "/ui/about_dialog.ui")]
    public class AboutDialog:Gtk.AboutDialog
    {
        internal AboutDialog()
        {
            Gdk.Pixbuf dialog_pixbuf;

            try 
            {
                dialog_pixbuf = new Gdk.Pixbuf.from_resource("/ui/icon.png");
                dialog_pixbuf = dialog_pixbuf.scale_simple(128,128,Gdk.InterpType.TILES);
                this.logo=dialog_pixbuf;
            } 
            catch (Error e) 
            {
                //print("Unable to load the logo\n");
                message(e.message+"\n");
            }           
        }
    }

    [GtkTemplate (ui = "/ui/search_dialog.ui")]
    public class SearchDialog:Gtk.Dialog
    {
        [GtkChild]
        private Gtk.Entry entry_find;
        [GtkChild]
        private Gtk.CheckButton option_case;
        [GtkChild]
        private Gtk.CheckButton option_wrap;

        private WebKit.WebView main_view;

        private WebKit.FindOptions _option = WebKit.FindOptions.NONE;


        internal SearchDialog(MainWin win)
        {          
            //parent_win = win;
            main_view = win.view;
        }
        
        public WebKit.FindOptions option
        {
            get
            {
                if (option_case.get_active())
                    _option = _option|WebKit.FindOptions.CASE_INSENSITIVE;

                if (option_wrap.get_active())
                    _option = _option|WebKit.FindOptions.WRAP_AROUND;
                
                return _option;
            }
        }

        [GtkCallback]
        private void on_find_next_clicked(Gtk.Button self)
        {
            WebKit.FindController find_control;
            string find_text;
            find_text = entry_find.get_text();

            find_control = main_view.get_find_controller();

            //print(find_text);

            if (find_text!="")
                find_control.search(find_text,this.option,1000);
        }

        [GtkCallback]
        private void on_find_prev_clicked(Gtk.Button self)
        {
            WebKit.FindController find_control;
            string find_text;
            find_text = entry_find.get_text();

            find_control = main_view.get_find_controller();
            //print(find_text);

            if (find_text!="")
                find_control.search(find_text,this.option|WebKit.FindOptions.BACKWARDS,1000);
        }

        [GtkCallback]
        private void on_clear_clicked(Gtk.Button self)
        {
            WebKit.FindController find_control;

            find_control = main_view.get_find_controller();

            find_control.search_finish();
        }
    }
}

int main(string[] args)
{   
    var app = new ManHelper.App();

    return app.run(args);
}

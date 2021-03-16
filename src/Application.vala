/*
* Copyright (c) 2021 XX Wu
*
* This file is part of Man Helper
*
* Man Helper is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
* Man Helper is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.
* You should have received a copy of the GNU General Public License
* along with Akira. If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: XX Wu <xwuanhkust@gmail.com>
*/

namespace ManHelper
{
    /* This is the application */
    public class App:Gtk.Application
    {    
        public uint section_num_max {get;default=9;}
        public MainWin win;
        //public string bookmarks_file {set;get;default="SQLite://DB_DIR=~/.manhelper;DB_NAME=bookmarks";}
        internal string bookmarks_parent_dir {set;get;default=".";}
        internal string bookmarks_directory {set;get;default="/.manhelper";}
        internal string bookmarks_filename {set;get;default="bookmarks";}
        internal DataBase bookmarks_db = null;
        private Gdk.Pixbuf app_icon;
        
        protected override void startup()
        {
            base.startup();
            DataBase.init_database_directory(this);
        }

        protected override void activate()
        {   
            //print("Before\n");                
            var app_win = new MainWin(this);

            app_win.show_all();

            this.win = app_win;

            try
            {
                app_icon = new Gdk.Pixbuf.from_resource("/ui/icon_manhelper.png");
                app_icon = app_icon.scale_simple(128,128,Gdk.InterpType.TILES);
                app_win.icon = app_icon;                
            }
            catch (Error e)
            {
                message(e.message);
            }
        }

    }

    /* This is the main window */
    [GtkTemplate (ui = "/ui/manhelper.ui")]
    public class MainWin:Gtk.ApplicationWindow
    {
        public App app;     
        public const string main_title = "Man Helper";
        private string home_uri;
        //internal uint section_num_max;
        //internal int height_header;
        internal string last_entry_text {set;get;default="";} 
        internal KeywordList search_list = null;
        internal Gtk.FileChooserDialog file_chooser = null;
        internal BookmarksDialog bookmarks_dialog = null;
        internal SearchDialog search_dialog = null;
        internal MultitabPager pager = null;
        internal WebKit.WebView view_current = null; 
        internal PageZoomer page_zoomer = null;
        internal PreferDialog prefer_dialog = null;

        [GtkChild]
        private Gtk.Button btn_man;
        [GtkChild]
        internal Gtk.SearchEntry entry_search;
        //[GtkChild]
        //internal Gtk.ScrolledWindow scrolled;
        [GtkChild]
        private Gtk.Box box_mainwin;
        [GtkChild]
        private Gtk.Box box_page_zoomer;

        internal MainWin(App app)
        {
            Object(application: app,title: main_title);
            //section_num_max = app.section_num_max;
            this.app = app;
            this.pager = new MultitabPager(this); /* The Webkit view is packed here */
            this.view_current.button_press_event.connect(on_search_list_outside_mouse_press);
            this.box_mainwin.pack_start(pager,true,true,0);
            //pager.first_scrolled.add_with_properties(view);

            this.home_uri = "http://localhost/cgi-bin/man/man2html";
            this.view_current.load_uri(home_uri);  

            /* pack the page_zoomer after Webkit view */
            this.page_zoomer = new PageZoomer(this);
            box_page_zoomer.pack_start(this.page_zoomer,true,true,0);

            var bookmarks_dirpath = app.bookmarks_parent_dir+app.bookmarks_directory;
            this.app.bookmarks_db = new DataBase(bookmarks_dirpath,app.bookmarks_filename);

            prefer_dialog = new PreferDialog(this);
        }

        /* guess the height of title bar*/
        /*
        private int guess_height_headerbar()
        {
            int height_header = 50;

            var header = new Gtk.HeaderBar();
            var window_temp = new Gtk.Window();
            window_temp.width_request = this.default_width;
            window_temp.height_request = this.default_height;
            header.show_close_button = true;
            header.title = MainWin.main_title;
            window_temp.set_titlebar(header);
            window_temp.show_all();
            
            height_header = header.get_allocated_height();
            window_temp.destroy();
            //print(@"$(height_header)\n");
            return (height_header+1);
        }
        */
        [GtkCallback]
        internal bool on_search_list_outside_mouse_press(Gtk.Widget self,Gdk.EventButton evnt)
        {
            if ((this.search_list!=null)&&(this.search_list.get_realized()))
            {
                this.search_list.destroy();
            }
            
            return false;
        }

        [GtkCallback]
        private void on_btn_man_clicked(Gtk.Button self)
        {
            string entry_text = entry_search.get_text();
            Thread<bool>[] thread = new Thread<bool>[this.app.section_num_max];
            bool[] status = new bool[this.app.section_num_max];
            man_uri[] man_uri_test = new man_uri[this.app.section_num_max];
            bool entry_found = false;
            string[] entry_data;
            if ((entry_text=="")||(entry_text==this.last_entry_text))
            {
                return;
            }

            this.last_entry_text = entry_text;
            entry_data = entry_text.split(".");

            if (entry_data.length == 1)
            {
                for (var ii = 1; ii<(this.app.section_num_max+1); ii++)
                {
                    man_uri_test[ii-1] = new man_uri(entry_text,ii.to_string());

                    thread[ii-1] = new Thread<bool>("man"+ii.to_string()+"_uri_exist", man_uri_test[ii-1].man_uri_exist);
                }

                for (var ii = 1; ii<(this.app.section_num_max+1); ii++)
                {
                    status[ii-1] = thread[ii-1].join();
                    //print("Inner, the status is "+status[ii-1].to_string()+"\n");

                    if (status[ii-1])
                    {
                        this.view_current.load_uri(man_uri_test[ii-1].uri);
                        entry_found = true;  
                        break;            
                    }
                } 
            }
            else if (entry_data.length > 1)
            {
                man_uri_test[0] = new man_uri(entry_data[0],entry_data[1]);

                status[0] = man_uri_test[0].man_uri_exist();

                if (status[0])
                {
                    this.view_current.load_uri(man_uri_test[0].uri);   
                    entry_found = true;    
                }
            }

            if (!entry_found)
            {
                this.set_tooltip_text("No man page for "+entry_text);
                this.trigger_tooltip_query();
            }
            else
            {
                this.set_has_tooltip(false);

                if ((this.search_list!=null)&&(this.search_list.get_realized()))
                {
                    this.search_list.destroy();
                }
            }
        }

        [GtkCallback]
        private void on_btn_add_page_clicked(Gtk.Button self)
        {
            this.pager.append_manpage();
            //this.pager.show_all();
        }

        [GtkCallback]
        private void on_entry_search_changed(Gtk.SearchEntry self)
        {
            string text = self.get_text();
            const int long_cmd = 6;
            //List<Gtk.MenuItem> menu_items; 
            KeywordList old_list;

            if (text.length>long_cmd)
            {
                old_list = this.search_list;

                if ((old_list!=null)&&(old_list.get_realized()))
                {
                    Timeout.add(150,()=>{old_list.destroy();return Source.REMOVE;}); // add a 150 ms delay
                }

                this.search_list = new KeywordList(this,text);

                if (this.search_list.find_num>0)
                {
                    this.search_list.show_all();
                    this.search_list.update_keyword_list_pos(this);
                    this.present();
                }
            }
            else
            {
                if ((this.search_list!=null)&&(this.search_list.get_realized()))
                {
                    this.search_list.destroy();
                }
            }

        }

        [GtkCallback]
        private void on_entry_search_enter(Gtk.Entry self)
        {
            btn_man.clicked();
        }

        [GtkCallback]
        private void on_quit_clicked(Gtk.MenuItem self)
        {
            this.destroy();
        }
        
        [GtkCallback]
        private void on_about_clicked(Gtk.MenuItem self)
        {
            AboutDialog about_dialog;

            about_dialog=new AboutDialog();
            about_dialog.show_all();
        }

        [GtkCallback]
        private void on_copy_clicked(Gtk.MenuItem self)
        {
            var focus = this.get_focus();

            if (focus==this.view_current)
            {
                this.view_current.execute_editing_command("Copy");
            }
            else if (focus==this.entry_search)
            {
                this.entry_search.copy_clipboard();
            }
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
            string title = this.view_current.title;

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
            {
                this.file_chooser = new Gtk.FileChooserDialog("Save as",null,Gtk.FileChooserAction.SAVE);
            }

            if (this.last_entry_text!="")
            {
                this.file_chooser.set_current_name(this.last_entry_text+file_extension);
            }
            else
            {
                this.file_chooser.set_current_name((title??"new")+file_extension);                
            }

            save_resp = this.file_chooser.run();
            //print(save_resp.to_string()+"\n");
            
            if (save_resp == Gtk.ResponseType.ACCEPT)
            {
                filepath = this.file_chooser.get_filename();

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
                    save_succeed = yield this.view_current.save_to_file(file,WebKit.SaveMode.MHTML,null);
                }
                catch (Error e)
                {
                    message(e.message);

                    return;
                }

            }       
            
            this.file_chooser.hide();
        }

        [GtkCallback]
        private void on_prefer_clicked(Gtk.MenuItem self)
        {
            if ((this.prefer_dialog==null)||(!this.prefer_dialog.get_realized()))
            {
                this.prefer_dialog = new PreferDialog(this);
                this.prefer_dialog.show_all();
            }
            else
            {   
                this.prefer_dialog.present();
            }
        }

        [GtkCallback]
        private void on_find_clicked(Gtk.MenuItem self)
        {
            if ((this.search_dialog==null)||(!this.search_dialog.get_realized()))
            {
                this.search_dialog = new SearchDialog(this);
                this.search_dialog.show_all();
            }
            else
            {   
                this.search_dialog.present();
            }
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
                {
                    return true;
                }
                else 
                {
                    return false;
                }
            }
        }
        
        [GtkCallback]
        void on_btn_back_clicked(Gtk.Button self)
        {
            this.view_current.go_back();
        }
        
        [GtkCallback]
        void on_btn_fwd_clicked(Gtk.Button self)
        {
            this.view_current.go_forward();
        }

        [GtkCallback]
        void on_btn_home_clicked(Gtk.Button self)
        {
            this.view_current.load_uri(this.home_uri);
        }

        [GtkCallback]
        void on_btn_add_bookmark_clicked(Gtk.Button self)
        {
            string title;
            string uri;

            title = this.view_current.get_title()??"NULL";
            uri = this.view_current.get_uri();

            try
            {
                //print(@"VALUES (\"$(title)\", \"$(uri)\")\n");
                if (uri!=null)
                {
                    var bookmarks_db = this.app.bookmarks_db;
                    bookmarks_db.run_query(@"REPLACE INTO bookmarks (title, uri) VALUES (\"$(title)\", \"$(uri)\")");
                }
            }
            catch (Error e)
            {
                message(e.message);
            }
        }

        [GtkCallback]
        void on_btn_bookmarks_clicked(Gtk.Button self)
        {
            //BookmarksDialog bookmarks_dialog;
            if ((this.bookmarks_dialog == null)||(!this.bookmarks_dialog.get_realized()))
            {
                this.bookmarks_dialog = new BookmarksDialog(this);
                this.bookmarks_dialog.show_all();
            }
            else
            {
                this.bookmarks_dialog.show_all();
                return;
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
                dialog_pixbuf = new Gdk.Pixbuf.from_resource("/ui/icon_manhelper.png");
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
        [GtkChild]
        private Gtk.Button btn_find_prev;
        [GtkChild]
        private Gtk.Button btn_find_next;

        private WebKit.WebView main_view;
        private WebKit.FindOptions _option = WebKit.FindOptions.NONE;

        internal bool search_prev {set;get;default=false;}

        internal SearchDialog(MainWin win)
        {          
            //parent_win = win;
            main_view = win.view_current;
        }
        
        public WebKit.FindOptions option
        {
            get
            {
                _option = (option_case.get_active()?WebKit.FindOptions.CASE_INSENSITIVE:WebKit.FindOptions.NONE)|
                            (option_wrap.get_active()?WebKit.FindOptions.WRAP_AROUND:WebKit.FindOptions.NONE);

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
            {
                find_control.search(find_text,this.option,1024);
            }

            this.search_prev = false;
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
            {
                find_control.search(find_text,this.option|WebKit.FindOptions.BACKWARDS,1024);
            }

            this.search_prev = true;
        }

        [GtkCallback]
        private void on_clear_clicked(Gtk.Button self)
        {
            WebKit.FindController find_control;

            find_control = main_view.get_find_controller();

            find_control.search_finish();
        }

        [GtkCallback]
        private bool key_enter_pressed(Gtk.Widget self,Gdk.Event evnt)
        {
            Gdk.EventKey key_evnt;
            uint keyval;

            key_evnt = evnt.key;
            keyval = key_evnt.keyval;
            //print(@"search_prev: $(this.search_prev)\n");
            if (keyval == Gdk.Key.Return)
            {
                //print("here!");
                //print(@"search_prev: $(this.search_prev)");
                if (this.search_prev)
                {
                    this.btn_find_prev.clicked();
                }
                else
                {
                    this.btn_find_next.clicked();
                }
            }

            return false;
        }
    }
}

public static int main(string[] args)
{   
    var app = new ManHelper.App();

    return app.run(args);
}

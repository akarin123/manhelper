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
* along with Man Helper. If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: XX Wu <xwuanhkust@gmail.com>
*/

namespace ManHelper
{
    /* This is the main window for the application. */
    [GtkTemplate (ui = "/ui/manhelper.ui")]
    public class MainWin: Gtk.ApplicationWindow
    {
        public App app;     
        public const string main_title = "Man Helper";
        private string home_uri;

        internal string last_entry_text {set;get;default="";} 
        internal KeywordList search_list = null;
        internal Gtk.FileChooserDialog file_chooser = null;
        internal BookmarksDialog bookmarks_dialog = null;
        internal SearchDialog search_dialog = null;
        internal SectionList section_list = null;
        internal MultitabPager pager = null;
        internal WebKit.WebView view_current = null; 
        internal PageZoomer page_zoomer = null;
        internal PreferDialog prefer_dialog = null;
        internal Pango.FontDescription prefer_font_desc = null;
        internal ThemeCSS prefer_theme_CSS = null;
        internal Gdk.RGBA prefer_backcolor = {};

        [GtkChild]
        private unowned Gtk.Button btn_man;
        [GtkChild]
        internal unowned Gtk.SearchEntry entry_search;
        //[GtkChild]
        //internal Gtk.ScrolledWindow scrolled;
        [GtkChild]
        private unowned Gtk.Box box_mainwin;

        [GtkChild]
        private unowned Gtk.Box box_section_list;
        [GtkChild]
        private unowned Gtk.CheckButton btn_enable_search;

        internal string init_font_family = null;
        internal uint32 init_font_size = 0;

        internal MainWin (App app)
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
            //var settings = this.view_current.get_settings();
            //print(settings.enable_javascript.to_string()+"\n");
            //this.start_font_size = settings.get_default_font_size();

            /* Pack the page_zoomer after Webkit view */
            this.page_zoomer = new PageZoomer(this);
            box_mainwin.pack_start(this.page_zoomer,false,false,0);

            /* Pack section list */
            this.section_list = new SectionList(this);
            box_section_list.pack_start(this.section_list,true,false,0);

            var bookmarks_dirpath = app.bookmarks_parent_dir+app.bookmarks_directory;
            this.app.bookmarks_db = new DataBase(bookmarks_dirpath,app.bookmarks_filename);

            var prefer_dialog = new PreferDialog(this); /* init font size and family */
            prefer_dialog.load_startup_options(app);
            
            this.prefer_font_desc = prefer_dialog.btn_font.get_font_desc();
            this.prefer_backcolor = prefer_dialog.btn_backcolor.get_rgba();
            prefer_dialog.hide();
            //this.theme_CSS = new ThemeCSS();
        }

        [GtkCallback]
        internal bool on_search_list_outside_mouse_press (Gtk.Widget self,Gdk.EventButton evnt)
        {
            if ((this.search_list!=null)&&(this.search_list.get_realized()))
            {
                this.search_list.destroy();
            }
            
            return false;
        }

        [GtkCallback]
        private void on_btn_man_clicked (Gtk.Button self)
        {
            string entry_text = entry_search.get_text();
            Thread<bool>[] thread = new Thread<bool>[this.app.section_num_max];
            bool[] status = new bool[this.app.section_num_max];
            man_uri[] man_uri_test = new man_uri[this.app.section_num_max];
            bool entry_found = false;
            string[] entry_data;
            if ((entry_text == "") || (entry_text == this.last_entry_text))
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
                // should limit the time for showing this tooltip 
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

            if ((this.prefer_dialog == null) || (!this.prefer_dialog.get_realized()))
            {
                this.prefer_dialog = new PreferDialog(this);
            }

            this.prefer_dialog.view = this.view_current;
            this.prefer_dialog.hide();
            /* Add a 10 ms delay */
            Timeout.add(10,()=>{this.prefer_dialog.update_page_prefer();return Source.REMOVE;});
        }

        [GtkCallback]
        private void on_btn_add_page_clicked (Gtk.Button self)
        {
            this.pager.append_manpage();
            //this.pager.show_all();
        }

        [GtkCallback]
        private void on_entry_search_changed (Gtk.SearchEntry self)
        {
            string text = self.get_text();
            const int long_cmd = 5;
            bool enable_search = btn_enable_search.get_active();
            KeywordList old_list;

            if (enable_search && (text.length > long_cmd))
            {
                old_list = this.search_list;

                if ((old_list != null) && (old_list.get_realized()))
                {
                    Timeout.add(150,()=>{old_list.destroy();return Source.REMOVE;}); // add a 150 ms delay
                }

                this.search_list = new KeywordList(this,text);

                if (this.search_list.find_num > 0)
                {
                    this.search_list.show_all();
                    this.search_list.update_keyword_list_pos(this);
                    this.present();
                }
            }
            else
            {
                if ((this.search_list != null) && (this.search_list.get_realized()))
                {
                    this.search_list.destroy();
                }
            }

        }

        [GtkCallback]
        private void on_entry_search_enter (Gtk.Entry self)
        {
            btn_man.clicked();
        }

        [GtkCallback]
        private void on_quit_clicked (Gtk.MenuItem self)
        {
            this.destroy();
        }
        
        [GtkCallback]
        private void on_about_clicked (Gtk.MenuItem self)
        {
            AboutDialog about_dialog;

            about_dialog=new AboutDialog();
            about_dialog.show_all();
        }

        [GtkCallback]
        private void on_copy_clicked (Gtk.MenuItem self)
        {
            var focus = this.get_focus();

            if (focus == this.view_current)
            {
                this.view_current.execute_editing_command("Copy");
            }
            else if (focus == this.entry_search)
            {
                this.entry_search.copy_clipboard();
            }
        }

        [GtkCallback]
        private async void on_save_as_clicked (Gtk.MenuItem self)
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
        private void on_prefer_clicked (Gtk.MenuItem self)
        {
            if ((this.prefer_dialog == null) || (!this.prefer_dialog.get_realized()))
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
        private void on_find_clicked (Gtk.MenuItem self)
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
        void on_btn_back_clicked (Gtk.Button self)
        {
            this.view_current.go_back();
        }
        
        [GtkCallback]
        void on_btn_fwd_clicked (Gtk.Button self)
        {
            this.view_current.go_forward();
        }

        [GtkCallback]
        void on_btn_home_clicked (Gtk.Button self)
        {
            this.view_current.load_uri(this.home_uri);
        }

        [GtkCallback]
        void on_btn_add_bookmark_clicked (Gtk.Button self)
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
        void on_btn_bookmarks_clicked (Gtk.Button self)
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
}
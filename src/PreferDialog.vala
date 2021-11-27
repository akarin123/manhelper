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
    /* This is the preferences dialog. */
    [GtkTemplate (ui = "/ui/prefer_dialog.ui")]
    public class PreferDialog: Gtk.Dialog
    {
        internal MainWin win = null;
        internal WebKit.WebView view = null;
        internal ThemeDialog theme_dialog = null;

        [GtkChild]
        internal unowned Gtk.FontButton btn_font;
        [GtkChild]
        internal unowned Gtk.ColorButton btn_backcolor;

        [GtkChild]
        internal unowned Gtk.Button btn_apply;

        [GtkChild]
        internal unowned Gtk.CheckButton btn_startup;

        /*
        [GtkChild]
        private unowned Gtk.CheckButton btn_applyall;
        */

        public PreferDialog (MainWin win)
        {
            this.win = win;
            this.view = win.view_current;
            
            var settings = view.get_settings();
            prefer_load_settings(settings);
            //this.default_font_size = settings.get_default_font_size();
        }   
        
        /* load current settings to the preferences dialog */
        private void prefer_load_settings (WebKit.Settings settings)
        {
            var default_font_size = settings.get_default_font_size();
            var default_font_family = settings.get_default_font_family();
            var default_backcolor = this.view.get_background_color();

            if (this.win.init_font_size==0)
            {
                this.win.init_font_size = default_font_size;
            }

            try 
            {
                string fc_stdout;
                string fc_stderr;
                int fc_status;

                string fc_cmd = @"fc-match \"$(default_font_family)\"";
                Process.spawn_command_line_sync (fc_cmd, out fc_stdout, out fc_stderr, out fc_status);

                var fc_output = fc_stdout.split("\"");

                if (fc_output.length>1)
                {
                    default_font_family = fc_output[1];

                    if (this.win.init_font_family == null)
                    {
                        this.win.init_font_family = default_font_family;
                    }
                    //print(default_font_family+"\n");
                }
            } 
            catch (SpawnError e) 
            {
                message(e.message);
            }

            var font_desc = new Pango.FontDescription();

            font_desc.set_family(default_font_family);
            font_desc.set_size((int)default_font_size*Pango.SCALE);

            btn_font.set_font_desc(font_desc);
            // need work on theme button
            
            btn_backcolor.set_rgba(default_backcolor);
        }

        [GtkCallback]
        private void on_btn_theme_clicked (Gtk.Button self)
        {
            if ((this.theme_dialog==null)||(!this.theme_dialog.get_realized()))
            {
                this.theme_dialog = new ThemeDialog(this,this.view);
                
                this.theme_dialog.show_all();
            }
            else
            {
                this.theme_dialog.present();
            }
        }

        [GtkCallback]
        private void on_prefer_btn_reset_clicked (Gtk.Button self)
        {
            Gdk.RGBA init_backcolor = {};

            var init_font_desc = new Pango.FontDescription();

            if (this.win.init_font_family!=null)
            {
                init_font_desc.set_family(this.win.init_font_family);
            }

            if (this.win.init_font_size>0)
            {
                init_font_desc.set_size((int)this.win.init_font_size*Pango.SCALE);
            }

            btn_font.set_font_desc(init_font_desc);

            init_backcolor.parse("rgb(255,255,255)"); /* back to white */
            btn_backcolor.set_rgba(init_backcolor);
            btn_apply.clicked();
        }

        [GtkCallback]
        public void on_prefer_btn_apply_clicked (Gtk.Button self)
        {
            var font_desc = this.btn_font.get_font_desc();
            var backcolor = this.btn_backcolor.get_rgba();

            /* store all prefer settings */
            this.win.prefer_backcolor = backcolor;
            this.win.prefer_font_desc = font_desc.copy();

            update_page_prefer();
        }

        public void update_page_prefer () 
        {
            var settings = this.view.get_settings();
            var font_desc = this.win.prefer_font_desc;
            var backcolor = this.win.prefer_backcolor;

            var font_size = font_desc.get_size();
            var font_family = font_desc.get_family();

            settings.set_default_font_size(font_size/Pango.SCALE);
            settings.set_default_font_family(font_family);

            /* update page zoomer */
            //print("pango font size:%d\n",font_size);
            double font_size_scaled = font_size/Pango.SCALE*1.0; /* ensure it is of double type */
            this.win.page_zoomer.zoom_ratio = (int)Math.round(font_size_scaled/this.win.init_font_size*100);
            this.win.page_zoomer.update_zoom_entry();

            this.view.set_background_color(backcolor);

            /* check whether change startup options */
            if (btn_startup.get_active())
            {
                App app = this.win.app;
                save_startup_options(app);
            }

            if (this.win.prefer_theme_CSS != null)
            {
                this.win.prefer_theme_CSS.set_theme_CSS(this.view);
            }

        }

        private void save_startup_options (App app)
        {
            var builder = new Json.Builder();
            
            var font_desc = this.btn_font.get_font_desc();
            var font_size = font_desc.get_size();
            var font_family = font_desc.get_family();
            var backcolor = this.btn_backcolor.get_rgba();

            builder.begin_object ();
            builder.set_member_name ("font-family");
            builder.add_string_value (font_family.to_string());

            builder.set_member_name ("font-size");
            builder.add_string_value ((font_size/Pango.SCALE).to_string());

            builder.set_member_name ("background");
            builder.add_string_value (backcolor.to_string());

            var theme_CSS = this.win.prefer_theme_CSS;
            if (theme_CSS == null)
            {
                var black = "rgb(0,0,0)";

                builder.set_member_name ("theme-title");
                builder.add_string_value (black);
                builder.set_member_name ("theme-heading");
                builder.add_string_value (black);
                builder.set_member_name ("theme-regular");
                builder.add_string_value (black);
                builder.set_member_name ("theme-bold");
                builder.add_string_value (black);
                builder.set_member_name ("theme-italic");
                builder.add_string_value (black);
            }
            else
            {
                builder.set_member_name ("theme-title");
                builder.add_string_value (theme_CSS.title_rgba.to_string());
                builder.set_member_name ("theme-heading");
                builder.add_string_value (theme_CSS.heading_rgba.to_string());
                builder.set_member_name ("theme-regular");
                builder.add_string_value (theme_CSS.regular_rgba.to_string());
                builder.set_member_name ("theme-bold");
                builder.add_string_value (theme_CSS.bold_rgba.to_string());
                builder.set_member_name ("theme-italic");
                builder.add_string_value (theme_CSS.italic_rgba.to_string());
            }


            builder.end_object ();
            
            var generator = new Json.Generator();
            var root = builder.get_root();

            generator.set_root(root);

            /* store in the same directory with bookmarks */
            var bookmarks_dirpath = app.bookmarks_parent_dir+app.bookmarks_directory;
            var startup_filepath = Path.build_filename(bookmarks_dirpath,app.startup_filename);
            
            //print(startup_filepath+"\n");
            try
            {
                generator.to_file(startup_filepath);
            }
            catch (Error e)
            {
                message(e.message);
            }
        }
        
        internal void load_startup_options (App app)
        {
            var parser = new Json.Parser();

            var bookmarks_dirpath = app.bookmarks_parent_dir+app.bookmarks_directory;
            var startup_filepath = Path.build_filename(bookmarks_dirpath,app.startup_filename);
            
            if (FileUtils.test(startup_filepath,FileTest.EXISTS))
            {
                try
                {
                    parser.load_from_file(startup_filepath);
    
                    var root = parser.get_root();
                    var obj = root.get_object();

                    var font_family = obj.get_member("font-family").get_string();
                    var font_size_str = obj.get_member("font-size").get_string();
                    var backcolor_str = obj.get_member("background").get_string();
                    //print("%s\n%s\n%s\n",font_family,font_size,backcolor);
                    var font_size = int.parse(font_size_str);

                    var font_desc = new Pango.FontDescription();
                    font_desc.set_family(font_family);
                    font_desc.set_size((int)font_size*Pango.SCALE);
                    
                    btn_font.set_font_desc(font_desc);
                    
                    Gdk.RGBA backcolor = {};
                    backcolor.parse(backcolor_str);
                    btn_backcolor.set_rgba(backcolor);
                    
                    /* load theme colors */
                    var theme_title_str = obj.get_member("theme-title").get_string();
                    var theme_heading_str = obj.get_member("theme-heading").get_string();
                    var theme_regular_str = obj.get_member("theme-regular").get_string();
                    var theme_bold_str = obj.get_member("theme-bold").get_string();
                    var theme_italic_str = obj.get_member("theme-italic").get_string();
                    //print("%p\n",this.win.theme_CSS);
                    if (this.win.prefer_theme_CSS == null)
                    {
                        //print("new themeCSS here!");
                        var startup_theme_CSS = new ThemeCSS();
                        startup_theme_CSS.prefer_dialog = this;
                        startup_theme_CSS.title_rgba.parse(theme_title_str);
                        startup_theme_CSS.heading_rgba.parse(theme_heading_str);
                        startup_theme_CSS.regular_rgba.parse(theme_regular_str);
                        startup_theme_CSS.bold_rgba.parse(theme_bold_str);
                        startup_theme_CSS.italic_rgba.parse(theme_italic_str);
                        
                        this.win.prefer_theme_CSS = startup_theme_CSS;
                    }
                    //print("apply here!");
                    btn_apply.clicked();
                }
                catch (Error e)
                {
                    message(e.message);
                }
            }
            else
            {
                return;
            }
        }
    }

    /*Add text color theme dialog*/
    [GtkTemplate (ui = "/ui/theme_dialog.ui")]
    internal class ThemeDialog: Gtk.Dialog
    {
        internal PreferDialog prefer_dialog = null;
        internal WebKit.WebView view = null;

        [GtkChild]
        internal unowned Gtk.ColorButton btn_title;
        [GtkChild]
        internal unowned Gtk.ColorButton btn_heading;
        [GtkChild]
        internal unowned Gtk.ColorButton btn_regular;
        [GtkChild]
        internal unowned Gtk.ColorButton btn_bold;
        [GtkChild]
        internal unowned Gtk.ColorButton btn_italic;

        public ThemeDialog(PreferDialog prefer_dialog, WebKit.WebView view)
        {
            this.prefer_dialog = prefer_dialog;
            this.view = view;

            theme_load_settings(view);
        }

        private void theme_load_settings (WebKit.WebView view)
        {
            var theme_CSS = this.prefer_dialog.win.prefer_theme_CSS;

            if (theme_CSS != null)
            {
                //print("load theme\n");
                var title_rgba = theme_CSS.title_rgba;
                var heading_rgba = theme_CSS.heading_rgba;
                var regular_rgba = theme_CSS.regular_rgba;
                var bold_rgba = theme_CSS.bold_rgba;
                var italic_rgba = theme_CSS.italic_rgba;
                
                btn_title.set_rgba(title_rgba);
                btn_heading.set_rgba(heading_rgba);
                btn_regular.set_rgba(regular_rgba);
                btn_bold.set_rgba(bold_rgba);
                btn_italic.set_rgba(italic_rgba);
            }
        }
        
        [GtkCallback]
        private void on_theme_btn_ok_clicked (Gtk.Button self)
        {
            var theme_CSS = new ThemeCSS.from_theme(this);
            //print(theme_css.to_string());

            this.prefer_dialog.win.prefer_theme_CSS = theme_CSS; 
            this.hide();
        }
    }

    public class Preferences
    {
        MainWin win;
        //WebKit.WebView view;
        int font_size;
        string font_family;
        Gdk.RGBA back_color;
        int search_chars_no;

        public Preferences (MainWin win) 
        {
            this.win = win;
            var view = win.view_current;
            var settings = view.get_settings();

            //this.font_size = 16;
            //this.font_family = "place_holder";
            //this.back_color = {1.0,1.0,1.0,1.0};
            //this.search_chars_no = 6;
            var default_font_size = settings.get_default_font_size();
            var default_font_family = settings.get_default_font_family();
            var default_backcolor = view.get_background_color();
        }
    }
}
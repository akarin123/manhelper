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
    /*Add preferences dialog*/
    [GtkTemplate (ui = "/ui/prefer_dialog.ui")]
    internal class PreferDialog: Gtk.Dialog
    {
        private MainWin win;
        private WebKit.WebView view = null;
        private ThemeDialog theme_dialog = null;

        [GtkChild]
        private Gtk.FontButton btn_font;
        [GtkChild]
        private Gtk.ColorButton btn_backcolor;

        [GtkChild]
        private Gtk.Button btn_apply;

        [GtkChild]
        private Gtk.CheckButton btn_startup;

        public PreferDialog(MainWin win)
        {
            this.win = win;
            this.view = win.view_current;
            
            var settings = view.get_settings();
            prefer_load_settings(settings);

            //this.default_font_size = settings.get_default_font_size();
        }   
        
        /* load current settings to the preferences dialog */
        private void prefer_load_settings(WebKit.Settings settings)
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
        private void on_btn_theme_clicked(Gtk.Button self)
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
        private void on_prefer_btn_reset_clicked(Gtk.Button self)
        {
            // stub
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

            init_backcolor.parse("rgba(100%,100%,100%,1)"); /* back to white */
            btn_backcolor.set_rgba(init_backcolor);
            btn_apply.clicked();
        }


        [GtkCallback]
        private void on_prefer_btn_apply_clicked(Gtk.Button self)
        {
            // stub
            var settings = this.view.get_settings();
            var font_desc = btn_font.get_font_desc();
            var font_size = font_desc.get_size();
            var font_family = font_desc.get_family();

            settings.set_default_font_size(font_size/Pango.SCALE);
            settings.set_default_font_family(font_family);

            /*update page zoomer*/
            double font_size_scaled = font_size/Pango.SCALE*1.0; /* ensure it is of double type */
            this.win.page_zoomer.zoom_ratio = (int)Math.round(font_size_scaled/this.win.init_font_size*100);
            this.win.page_zoomer.update_zoom_entry();

            var backcolor = this.btn_backcolor.get_rgba();
            this.view.set_background_color(backcolor);

            /*check whether change startup options*/
            if (btn_startup.get_active())
            {
                // stub
                // need further work use libgda
            }
        }
    }

    /*Add text color theme dialog*/
    [GtkTemplate (ui = "/ui/theme_dialog.ui")]
    private class ThemeDialog: Gtk.Dialog
    {
        private PreferDialog prefer_dialog = null;
        private WebKit.WebView view = null;

        public ThemeDialog(PreferDialog prefer_dialog, WebKit.WebView view)
        {
            this.prefer_dialog = prefer_dialog;
            this.view = view;
            
            theme_load_settings(view);
        }

        private void theme_load_settings(WebKit.WebView view)
        {
            
        } 
    }
}

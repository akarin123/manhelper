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
        //[GtkChild]
        //internal Gtk.Entry entry_zoom;

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
        private void on_prefer_reset_clicked(Gtk.Button self)
        {
            // stub
            print("prefer reset\n");
        }


        [GtkCallback]
        private void on_prefer_apply_clicked(Gtk.Button self)
        {
            // stub
            print("prefer apply\n");
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

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

        //[GtkChild]
        //internal Gtk.Entry entry_zoom;

        public PreferDialog(MainWin win)
        {
            this.win = win;
            var view = win.view_current;
            var settings = view.get_settings();

            //this.default_font_size = settings.get_default_font_size();
        }        
    }

    /*Add color theme dialog*/
    [GtkTemplate (ui = "/ui/theme_dialog.ui")]
    private class ThemeDialog: Gtk.Dialog
    {
        private PreferDialog prefer_dialog;

        public PreferDialog(PreferDialog prefer_dialog)
        {
            this.prefer_dialog = prefer_dialog;

        }        
    }
}

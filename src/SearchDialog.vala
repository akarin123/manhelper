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
    /* This is the search dialog. */
    [GtkTemplate (ui = "/ui/search_dialog.ui")]
    public class SearchDialog: Gtk.Dialog
    {
        [GtkChild]
        private unowned Gtk.Entry entry_find;
        [GtkChild]
        private unowned Gtk.CheckButton option_case;
        [GtkChild]
        private unowned Gtk.CheckButton option_wrap;
        [GtkChild]
        private unowned Gtk.Button btn_find_prev;
        [GtkChild]
        private unowned Gtk.Button btn_find_next;

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
        private void on_find_next_clicked (Gtk.Button self)
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
        private void on_find_prev_clicked (Gtk.Button self)
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
        private void on_clear_clicked (Gtk.Button self)
        {
            WebKit.FindController find_control;

            find_control = main_view.get_find_controller();

            find_control.search_finish();
        }

        [GtkCallback]
        private bool key_enter_pressed (Gtk.Widget self,Gdk.Event evnt)
        {
            Gdk.EventKey key_evnt;
            uint keyval;

            key_evnt = evnt.key;
            keyval = key_evnt.keyval;

            if (keyval == Gdk.Key.Return)
            {
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
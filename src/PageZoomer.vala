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
    /*Add multitabs for scrolled window*/
    [GtkTemplate (ui = "/ui/page_zoomer.ui")]
    internal class PageZoomer: Gtk.Box
    {
        public int zoom_ratio {set;get;default=100;}
        public int zoom_step {set;get;default=10;}

        private static int zoom_min = 10;
        private static int zoom_max = 990;
        //internal uint32 default_font_size;

        private MainWin win;

        [GtkChild]
        internal unowned Gtk.Entry entry_zoom;

        /*
        [GtkChild]
        Gtk.Button btn_up;
        [GtkChild]
        Gtk.Button btn_down;
        [GtkChild]
        Gtk.Button btn_fit;
        */
        public PageZoomer(MainWin win)
        {
            this.win = win;
            //var view = win.view_current;
            //var settings = view.get_settings();
            //this.default_font_size = settings.get_default_font_size();
        }

        [GtkCallback]
        private void on_btn_up_clicked(Gtk.Button self)
        {
            this.zoom_ratio = int.min(this.zoom_ratio+this.zoom_step,PageZoomer.zoom_max);
            update_zoom_entry();
        }

        [GtkCallback]
        private void on_btn_down_clicked(Gtk.Button self)
        {
            this.zoom_ratio = int.max(this.zoom_ratio-this.zoom_step,PageZoomer.zoom_min);
            update_zoom_entry();
        }

        [GtkCallback]
        private void on_btn_fit_clicked(Gtk.Button self)
        {
            this.zoom_ratio = 100;
            update_zoom_entry();
        }
        
        internal void update_zoom_entry()
        {
            this.entry_zoom.set_text(this.zoom_ratio.to_string());

            update_view_zoom();
        }

        [GtkCallback]
        private void on_entry_zoom_changed(Gtk.Editable self)
        {
            uint interval = 100;

            Timeout.add(interval,()=>{update_view_zoom();return Source.REMOVE;});
        }
        
        private void update_view_zoom()
        {
            double ratio;
            //uint32 default_font_size;
            uint32 font_size_new;
            int zoom_ratio_raw;

            var view = this.win.view_current;
            var settings = view.get_settings();

            zoom_ratio_raw = int.parse(this.entry_zoom.get_text());
            zoom_ratio = zoom_ratio_raw.clamp(PageZoomer.zoom_min,PageZoomer.zoom_max); /* update zoom ratio */
            ratio  = zoom_ratio/100.0;
            
            font_size_new = (uint32)(Math.round(this.win.init_font_size*ratio));
            
            settings.set_default_font_size(font_size_new);
            view.set_settings(settings);
        }
    }

}
